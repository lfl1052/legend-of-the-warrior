extends Node
## 存档管理器（替代 Unity 项目里的 DataManager 单例）
##
## 关键差异：
##   Unity 用 Newtonsoft.Json + persistentDataPath 写入 data.sav；
##   Godot 端使用 user:// 路径与内置 JSON。
## 模块对外用单例 DataManager 访问。
##
## 数据约定（与 Unity 保留一致）：
##   schema_version : int
##   scene_to_save  : Dictionary  (GameSceneResource 的 path / type / display_name 序列化)
##   character_pos  : Dictionary  id -> {x,y,z}
##   float_data     : Dictionary  key -> float

const DEFAULT_SAVE_DIR := "user://SAVE_DATA/"
const DEFAULT_SAVE_FILE := DEFAULT_SAVE_DIR + "data.sav"
const DEFAULT_SAVE_QUARANTINE := DEFAULT_SAVE_DIR + "data.sav.bak"
const CURRENT_SCHEMA_VERSION := 1
const MAX_SAVE_BYTES := 1024 * 1024

# 路径运行期可改写（测试用）。生产代码不应触碰，只读 DEFAULT_* 常量。
var save_dir: String = DEFAULT_SAVE_DIR
var save_file: String = DEFAULT_SAVE_FILE
var save_quarantine: String = DEFAULT_SAVE_QUARANTINE

# ISaveable 协议：实现需要 get_save_id() / get_save_data(data:Dictionary) / load_save_data(data:Dictionary)
var _saveables: Array[Object] = []
var _data: Dictionary = _make_empty_data()
var _pending_scene_restore: bool = false
var last_save_succeeded: bool = false
var last_load_succeeded: bool = false


func _ready() -> void:
	_ensure_save_dir()
	GameEvents.new_game_started.connect(_on_new_game)
	GameEvents.save_data_requested.connect(save)
	GameEvents.load_data_requested.connect(load_from_disk)


# ----- 注册 / 注销 ------------------------------------------------------------

func register(saveable: Object) -> void:
	if saveable == null:
		return
	if not _saveables.has(saveable):
		_saveables.append(saveable)


func unregister(saveable: Object) -> void:
	_saveables.erase(saveable)


# ----- 主入口 -----------------------------------------------------------------

func begin_fresh_session() -> void:
	_data = _make_empty_data()
	_pending_scene_restore = false
	last_load_succeeded = false


func capture_runtime_state() -> void:
	for saveable in _saveables:
		if is_instance_valid(saveable) and saveable.has_method("get_save_data"):
			saveable.call("get_save_data", _data)


func try_capture_runtime_state_for_scene_transition(_capture: bool = true) -> void:
	## 与 Unity 端保持同名接口，外部可在切场景前调用
	if _capture:
		capture_runtime_state()


func save() -> bool:
	capture_runtime_state()
	_data["schema_version"] = CURRENT_SCHEMA_VERSION
	var normalized: Variant = _validate_schema_v1(_data)
	if typeof(normalized) != TYPE_DICTIONARY:
		return _fail_save("DataManager: 运行态存档字段校验失败")
	_data = normalized
	var serialized := JSON.stringify(_data)
	if serialized.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return _fail_save("DataManager: 存档超过 %d 字节上限" % MAX_SAVE_BYTES)
	_ensure_save_dir()
	var temporary_file := save_file + ".tmp"
	var previous_file := save_file + ".previous"
	var f := FileAccess.open(temporary_file, FileAccess.WRITE)
	if f == null:
		last_save_succeeded = false
		GameEvents.raise_save_completed(false)
		push_error("DataManager: 无法写入临时存档 %s" % temporary_file)
		return false
	f.store_string(serialized)
	f.flush()
	f.close()
	var temporary_abs := ProjectSettings.globalize_path(temporary_file)
	var save_abs := ProjectSettings.globalize_path(save_file)
	var previous_abs := ProjectSettings.globalize_path(previous_file)
	if FileAccess.file_exists(previous_file):
		DirAccess.remove_absolute(previous_abs)
	if FileAccess.file_exists(save_file):
		var rotate_error := DirAccess.rename_absolute(save_abs, previous_abs)
		if rotate_error != OK:
			last_save_succeeded = false
			DirAccess.remove_absolute(temporary_abs)
			GameEvents.raise_save_completed(false)
			push_error("DataManager: 无法轮换旧存档 %s" % save_file)
			return false
	var replace_error := DirAccess.rename_absolute(temporary_abs, save_abs)
	if replace_error != OK:
		if FileAccess.file_exists(previous_file):
			DirAccess.rename_absolute(previous_abs, save_abs)
		last_save_succeeded = false
		GameEvents.raise_save_completed(false)
		push_error("DataManager: 无法提交存档 %s" % save_file)
		return false
	last_save_succeeded = true
	GameEvents.raise_save_completed(true)
	return true


func load_from_disk() -> void:
	if not FileAccess.file_exists(save_file):
		_data = _make_empty_data()
		_pending_scene_restore = false
		last_load_succeeded = false
		return
	var file := FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		_reject_disk_save("无法读取")
		return
	var file_size := file.get_length()
	file.close()
	if file_size > MAX_SAVE_BYTES:
		_reject_disk_save("文件超过 %d 字节上限" % MAX_SAVE_BYTES)
		return
	var raw := FileAccess.get_file_as_string(save_file)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		_reject_disk_save("JSON 根节点不是 Dictionary")
		return
	var prepared: Variant = _prepare_loaded_data(parsed)
	if typeof(prepared) != TYPE_DICTIONARY:
		_reject_disk_save("Schema 版本或字段无效")
		return
	_data = prepared
	_pending_scene_restore = true
	last_load_succeeded = true
	_apply_data_to_registered_saveables()


func apply_pending_scene_restore() -> bool:
	if not _pending_scene_restore:
		return false
	_apply_data_to_registered_saveables()
	_pending_scene_restore = false
	return true


func _apply_data_to_registered_saveables() -> void:
	for saveable in _saveables:
		if is_instance_valid(saveable) and saveable.has_method("load_save_data"):
			saveable.call("load_save_data", _data)


# ----- 数据访问帮助方法 -------------------------------------------------------

func get_data() -> Dictionary:
	return _data


func record_character_position(id: String, position: Vector3) -> void:
	if id.is_empty():
		return
	var dict: Dictionary = _data.get("character_pos", {})
	dict[id] = {"x": position.x, "y": position.y, "z": position.z}
	_data["character_pos"] = dict


func get_character_position(id: String) -> Variant:
	var dict: Dictionary = _data.get("character_pos", {})
	if not dict.has(id):
		return null
	var entry: Dictionary = dict[id]
	return Vector3(entry.get("x", 0.0), entry.get("y", 0.0), entry.get("z", 0.0))


func record_float(key: String, value: float) -> void:
	if key.is_empty():
		return
	var dict: Dictionary = _data.get("float_data", {})
	dict[key] = value
	_data["float_data"] = dict


func get_float(key: String, default_value: float = 0.0) -> float:
	var dict: Dictionary = _data.get("float_data", {})
	return float(dict.get(key, default_value))


func has_float(key: String) -> bool:
	var dict: Dictionary = _data.get("float_data", {})
	return dict.has(key)


func record_scene(scene_resource: Resource) -> void:
	if scene_resource == null:
		_data["scene_to_save"] = {}
		return
	var entry := {
		"path": scene_resource.get("scene_path") if scene_resource.get("scene_path") != null else "",
		"display_name": scene_resource.get("display_name") if scene_resource.get("display_name") != null else "",
		"scene_type": scene_resource.get("scene_type") if scene_resource.get("scene_type") != null else 0,
	}
	_data["scene_to_save"] = entry


func try_get_saved_scene_path() -> String:
	var entry: Dictionary = _data.get("scene_to_save", {})
	return String(entry.get("path", ""))


func has_saved_game() -> bool:
	return FileAccess.file_exists(save_file)


# ----- 测试辅助（生产代码不应调用） -------------------------------------------

## 仅供测试：重定向存档路径到隔离目录，并清空内存数据。
## 调用方负责调用 [method clear_test_overrides] 还原。
func override_save_paths_for_test(new_dir: String) -> void:
	if not new_dir.ends_with("/"):
		new_dir += "/"
	save_dir = new_dir
	save_file = new_dir + "data.sav"
	save_quarantine = new_dir + "data.sav.bak"
	_data = _make_empty_data()
	_saveables.clear()
	_pending_scene_restore = false
	last_load_succeeded = false


func clear_test_overrides() -> void:
	save_dir = DEFAULT_SAVE_DIR
	save_file = DEFAULT_SAVE_FILE
	save_quarantine = DEFAULT_SAVE_QUARANTINE
	_data = _make_empty_data()
	_saveables.clear()
	_pending_scene_restore = false
	last_load_succeeded = false


# ----- 内部 ------------------------------------------------------------------

func _on_new_game() -> void:
	begin_fresh_session()


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_recursive_absolute(save_dir)


func _quarantine_corrupted() -> void:
	_ensure_save_dir()
	var quarantined := false
	if FileAccess.file_exists(save_file):
		if FileAccess.file_exists(save_quarantine):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_quarantine))
		var copy_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(save_file),
			ProjectSettings.globalize_path(save_quarantine))
		if copy_error == OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_file))
			quarantined = true
		else:
			push_error("DataManager: 无法隔离损坏存档，保留原文件")
	if quarantined:
		push_warning("DataManager: 检测到损坏存档，已隔离至 %s" % save_quarantine)


func _fail_save(message: String) -> bool:
	last_save_succeeded = false
	GameEvents.raise_save_completed(false)
	push_error(message)
	return false


func _reject_disk_save(reason: String) -> void:
	_quarantine_corrupted()
	_data = _make_empty_data()
	_pending_scene_restore = false
	last_load_succeeded = false
	push_warning("DataManager: 已拒绝存档（%s）" % reason)


func _prepare_loaded_data(parsed: Dictionary) -> Variant:
	var version := _read_schema_version(parsed)
	if version < 0 or version > CURRENT_SCHEMA_VERSION:
		return null
	var migrated := parsed.duplicate(true)
	while version < CURRENT_SCHEMA_VERSION:
		match version:
			0:
				migrated = _migrate_v0_to_v1(migrated)
			_:
				return null
		version += 1
	return _validate_schema_v1(migrated)


func _read_schema_version(data: Dictionary) -> int:
	if not data.has("schema_version") and not data.has("schemaVersion"):
		return 0
	var raw_version: Variant = data.get("schema_version", data.get("schemaVersion"))
	if not _is_finite_number(raw_version):
		return -1
	var numeric_version := float(raw_version)
	if numeric_version < 0.0 or not is_equal_approx(numeric_version, roundf(numeric_version)):
		return -1
	return int(numeric_version)


func _migrate_v0_to_v1(legacy: Dictionary) -> Dictionary:
	var migrated := _make_empty_data()
	var scene: Variant = legacy.get(
		"scene_to_save",
		legacy.get("sceneToSave", legacy.get("sceneData", {})))
	if typeof(scene) == TYPE_DICTIONARY:
		var legacy_scene := scene as Dictionary
		migrated["scene_to_save"] = {
			"path": legacy_scene.get("path", legacy_scene.get("scenePath", "")),
			"display_name": legacy_scene.get(
				"display_name",
				legacy_scene.get("sceneName", legacy_scene.get("displayName", ""))),
			"scene_type": legacy_scene.get("scene_type", legacy_scene.get("sceneType", 0)),
		} if not legacy_scene.is_empty() else {}
	else:
		migrated["scene_to_save"] = scene
	migrated["character_pos"] = legacy.get(
		"character_pos",
		legacy.get("characterPos", legacy.get("characterPosDict", {})))
	migrated["float_data"] = legacy.get(
		"float_data",
		legacy.get("floatData", legacy.get("floatDataDict", {})))
	return migrated


func _validate_schema_v1(candidate: Dictionary) -> Variant:
	var scene_value: Variant = candidate.get("scene_to_save", {})
	var positions_value: Variant = candidate.get("character_pos", {})
	var floats_value: Variant = candidate.get("float_data", {})
	if typeof(scene_value) != TYPE_DICTIONARY or typeof(positions_value) != TYPE_DICTIONARY \
			or typeof(floats_value) != TYPE_DICTIONARY:
		return null

	var normalized := _make_empty_data()
	var scene := scene_value as Dictionary
	if not scene.is_empty():
		var path_value: Variant = scene.get("path", "")
		var display_name_value: Variant = scene.get("display_name", "")
		var scene_type_value: Variant = scene.get("scene_type", 0)
		if typeof(path_value) != TYPE_STRING or typeof(display_name_value) != TYPE_STRING \
				or not _is_integer_number(scene_type_value):
			return null
		var scene_path := String(path_value)
		var scene_type := int(scene_type_value)
		if not scene_path.is_empty() and (not scene_path.begins_with("res://") \
				or not scene_path.ends_with(".tscn")):
			return null
		if scene_type < Enums.SceneType.LOACTION or scene_type > Enums.SceneType.MENU:
			return null
		normalized["scene_to_save"] = {
			"path": scene_path,
			"display_name": String(display_name_value),
			"scene_type": scene_type,
		}

	var normalized_positions: Dictionary = {}
	for raw_key: Variant in (positions_value as Dictionary):
		if not _is_string_key(raw_key):
			return null
		var key := String(raw_key)
		var position_value: Variant = (positions_value as Dictionary)[raw_key]
		if key.is_empty() or typeof(position_value) != TYPE_DICTIONARY:
			return null
		var position := position_value as Dictionary
		var x_value: Variant = position.get("x", 0.0)
		var y_value: Variant = position.get("y", 0.0)
		var z_value: Variant = position.get("z", 0.0)
		if not _is_finite_number(x_value) or not _is_finite_number(y_value) \
				or not _is_finite_number(z_value):
			return null
		normalized_positions[key] = {
			"x": float(x_value),
			"y": float(y_value),
			"z": float(z_value),
		}
	normalized["character_pos"] = normalized_positions

	var normalized_floats: Dictionary = {}
	for raw_key: Variant in (floats_value as Dictionary):
		if not _is_string_key(raw_key):
			return null
		var key := String(raw_key)
		var value: Variant = (floats_value as Dictionary)[raw_key]
		if key.is_empty() or not _is_finite_number(value):
			return null
		normalized_floats[key] = float(value)
	normalized["float_data"] = normalized_floats
	return normalized


func _is_string_key(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME


func _is_finite_number(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return is_finite(float(value))


func _is_integer_number(value: Variant) -> bool:
	if not _is_finite_number(value):
		return false
	var number := float(value)
	return is_equal_approx(number, roundf(number))


static func _make_empty_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"scene_to_save": {},
		"character_pos": {},
		"float_data": {},
	}
