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

const SAVE_DIR := "user://SAVE_DATA/"
const SAVE_FILE := SAVE_DIR + "data.sav"
const SAVE_QUARANTINE := SAVE_DIR + "data.sav.bak"
const CURRENT_SCHEMA_VERSION := 1

# ISaveable 协议：实现需要 get_save_id() / get_save_data(data:Dictionary) / load_save_data(data:Dictionary)
var _saveables: Array[Object] = []
var _data: Dictionary = _make_empty_data()


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


func capture_runtime_state() -> void:
	for saveable in _saveables:
		if is_instance_valid(saveable) and saveable.has_method("get_save_data"):
			saveable.call("get_save_data", _data)


func try_capture_runtime_state_for_scene_transition(_capture: bool = true) -> void:
	## 与 Unity 端保持同名接口，外部可在切场景前调用
	if _capture:
		capture_runtime_state()


func save() -> void:
	capture_runtime_state()
	_data["schema_version"] = CURRENT_SCHEMA_VERSION
	_ensure_save_dir()
	var f := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if f == null:
		push_error("DataManager: 无法写入存档 %s" % SAVE_FILE)
		return
	f.store_string(JSON.stringify(_data))


func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		_data = _make_empty_data()
		return
	var raw := FileAccess.get_file_as_string(SAVE_FILE)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		_quarantine_corrupted()
		_data = _make_empty_data()
		return
	_data = parsed
	# 通知所有 saveable 注入持久数据
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
	return FileAccess.file_exists(SAVE_FILE)


# ----- 内部 ------------------------------------------------------------------

func _on_new_game() -> void:
	begin_fresh_session()


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _quarantine_corrupted() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.copy_absolute(SAVE_FILE, SAVE_QUARANTINE)
		DirAccess.remove_absolute(SAVE_FILE)
	push_warning("DataManager: 检测到损坏存档，已隔离至 %s" % SAVE_QUARANTINE)


static func _make_empty_data() -> Dictionary:
	return {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"scene_to_save": {},
		"character_pos": {},
		"float_data": {},
	}
