extends GdUnitTestSuite
## DataManager save/load 往返测试
##
## 测试范围：
##   - 保存时写入 schema_version=1
##   - 加载时还原 float_data
##   - 损坏文件被隔离到 .bak

const TEST_SAVE_DIR := "user://TEST_SAVE_DATA/"

var _manager: Node


func before_test() -> void:
	# 用全局 autoload 引用，但路径重定向到测试隔离目录
	_manager = DataManager
	_clean_test_dir()
	_manager.override_save_paths_for_test(TEST_SAVE_DIR)


func after_test() -> void:
	_manager.clear_test_overrides()
	_clean_test_dir()
	_manager = null


# ----- save 路径 --------------------------------------------------------------

func test_data_manager_save_writes_schema_v1() -> void:
	# Arrange
	var probe: FakeSaveable = auto_free(FakeSaveable.new())
	probe.id = "probe_a"
	probe.float_value = 12.5
	_manager.register(probe)
	# Act
	_manager.save()
	# Assert
	assert_bool(FileAccess.file_exists(_manager.save_file)).is_true()
	var raw := FileAccess.get_file_as_string(_manager.save_file)
	var parsed: Variant = JSON.parse_string(raw)
	assert_int(int(parsed.get("schema_version", 0))).is_equal(1)
	assert_dict(parsed.get("float_data", {})).contains_key_value("probe_a", 12.5)
	assert_bool(FileAccess.file_exists(_manager.save_file + ".tmp")).is_false()


func test_data_manager_second_save_rotates_previous_complete_file() -> void:
	var probe: FakeSaveable = auto_free(FakeSaveable.new())
	probe.id = "probe_atomic"
	probe.float_value = 10.0
	_manager.register(probe)
	assert_bool(_manager.save()).is_true()

	probe.float_value = 20.0
	assert_bool(_manager.save()).is_true()

	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_manager.save_file))
	var previous_path: String = _manager.save_file + ".previous"
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(previous_path))
	assert_bool(FileAccess.file_exists(previous_path)).is_true()
	assert_bool(FileAccess.file_exists(_manager.save_file + ".tmp")).is_false()
	assert_float(float(current.get("float_data", {}).get("probe_atomic", 0.0))).is_equal(20.0)
	assert_float(float(previous.get("float_data", {}).get("probe_atomic", 0.0))).is_equal(10.0)


func test_data_manager_save_emits_success_result() -> void:
	var results: Array[bool] = []
	var recorder := func(success: bool) -> void: results.append(success)
	GameEvents.save_completed.connect(recorder)

	var success: bool = _manager.save()

	if GameEvents.save_completed.is_connected(recorder):
		GameEvents.save_completed.disconnect(recorder)
	assert_bool(success).is_true()
	assert_bool(_manager.last_save_succeeded).is_true()
	assert_array(results).contains_exactly([true])


# ----- load 路径 --------------------------------------------------------------

func test_data_manager_load_restores_float_data() -> void:
	# Arrange: 直接铺一份合法存档到磁盘
	_write_save_to_disk({
		"schema_version": 1,
		"scene_to_save": {},
		"character_pos": {},
		"float_data": {"probe_b": 42.0},
	})
	var probe: FakeSaveable = auto_free(FakeSaveable.new())
	probe.id = "probe_b"
	_manager.register(probe)
	# Act
	_manager.load_from_disk()
	# Assert
	assert_float(probe.float_value).is_equal(42.0)
	assert_float(_manager.get_float("probe_b")).is_equal(42.0)


func test_pending_scene_restore_applies_to_late_registered_saveable_once() -> void:
	_write_save_to_disk({
		"schema_version": 1,
		"scene_to_save": {},
		"character_pos": {},
		"float_data": {"late_probe": 77.0},
	})
	_manager.load_from_disk()
	var probe: FakeSaveable = auto_free(FakeSaveable.new())
	probe.id = "late_probe"
	_manager.register(probe)

	assert_bool(_manager.apply_pending_scene_restore()).is_true()
	assert_float(probe.float_value).is_equal(77.0)
	probe.float_value = 5.0
	assert_bool(_manager.apply_pending_scene_restore()).is_false()
	assert_float(probe.float_value).is_equal(5.0)


func test_data_manager_migrates_course_v0_aliases_to_schema_v1() -> void:
	_write_save_to_disk({
		"sceneToSave": {
			"scenePath": "res://scenes/levels/level_demo.tscn",
			"sceneName": "Demo",
			"sceneType": 0,
		},
		"characterPosDict": {"player": {"x": 12.0, "y": 34.0}},
		"floatDataDict": {"legacy_probe": 9.5},
	})

	_manager.load_from_disk()

	assert_bool(_manager.last_load_succeeded).is_true()
	assert_int(int(_manager.get_data().get("schema_version", 0))).is_equal(1)
	assert_str(_manager.try_get_saved_scene_path()).is_equal(
		"res://scenes/levels/level_demo.tscn")
	assert_vector(_manager.get_character_position("player")).is_equal(Vector3(12.0, 34.0, 0.0))
	assert_float(_manager.get_float("legacy_probe")).is_equal(9.5)


func test_data_manager_rejects_future_schema_without_applying_it() -> void:
	_write_save_to_disk({
		"schema_version": DataManager.CURRENT_SCHEMA_VERSION + 1,
		"scene_to_save": {},
		"character_pos": {},
		"float_data": {"future_probe": 100.0},
	})

	_manager.load_from_disk()

	assert_bool(_manager.last_load_succeeded).is_false()
	assert_bool(FileAccess.file_exists(_manager.save_file)).is_false()
	assert_bool(FileAccess.file_exists(_manager.save_quarantine)).is_true()
	assert_bool(_manager.has_float("future_probe")).is_false()


func test_data_manager_rejects_wrong_field_types() -> void:
	_write_save_to_disk({
		"schema_version": 1,
		"scene_to_save": {},
		"character_pos": {"player": {"x": "not-a-number", "y": 20.0, "z": 0.0}},
		"float_data": {},
	})

	_manager.load_from_disk()

	assert_bool(_manager.last_load_succeeded).is_false()
	assert_bool(FileAccess.file_exists(_manager.save_quarantine)).is_true()
	assert_object(_manager.get_character_position("player")).is_null()


func test_data_manager_rejects_file_over_size_limit() -> void:
	_write_raw_to_disk("x".repeat(DataManager.MAX_SAVE_BYTES + 1))

	_manager.load_from_disk()

	assert_bool(_manager.last_load_succeeded).is_false()
	assert_bool(FileAccess.file_exists(_manager.save_file)).is_false()
	assert_bool(FileAccess.file_exists(_manager.save_quarantine)).is_true()


func test_data_manager_record_helpers_round_trip_validated_fields() -> void:
	_manager.record_character_position("player", Vector3(14.0, 28.0, 3.0))
	_manager.record_float("coins", 6.0)
	assert_bool(_manager.save()).is_true()
	_manager.begin_fresh_session()

	_manager.load_from_disk()

	assert_vector(_manager.get_character_position("player")).is_equal(Vector3(14.0, 28.0, 3.0))
	assert_float(_manager.get_float("coins")).is_equal(6.0)


func test_new_game_event_clears_previous_runtime_session_data() -> void:
	# Arrange
	_manager.record_character_position("player", Vector3(20.0, 30.0, 0.0))
	_manager.record_float("upgrade_tokens", 4.0)

	# Act
	GameEvents.raise_new_game_started()

	# Assert
	assert_object(_manager.get_character_position("player")).is_null()
	assert_bool(_manager.has_float("upgrade_tokens")).is_false()
	assert_str(_manager.try_get_saved_scene_path()).is_empty()
	assert_bool(_manager.last_load_succeeded).is_false()


# ----- 损坏文件隔离 ----------------------------------------------------------

func test_data_manager_corrupted_file_quarantines_to_bak() -> void:
	# Arrange: 写一份非法 JSON
	_write_raw_to_disk("{this is not json")
	# Act
	_manager.load_from_disk()
	# Assert
	assert_bool(FileAccess.file_exists(_manager.save_file)).is_false()
	assert_bool(FileAccess.file_exists(_manager.save_quarantine)).is_true()
	# 内存回到空状态
	assert_dict(_manager.get_data().get("float_data", {})).is_empty()


# ----- 辅助 -------------------------------------------------------------------

func _clean_test_dir() -> void:
	if not DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		return
	var d := DirAccess.open(TEST_SAVE_DIR)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	DirAccess.remove_absolute(TEST_SAVE_DIR)


func _write_save_to_disk(payload: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	var f := FileAccess.open(_manager.save_file, FileAccess.WRITE)
	f.store_string(JSON.stringify(payload))
	f.close()


func _write_raw_to_disk(raw: String) -> void:
	if not DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	var f := FileAccess.open(_manager.save_file, FileAccess.WRITE)
	f.store_string(raw)
	f.close()


# ----- 内部 fake 类 ------------------------------------------------------------

class FakeSaveable extends RefCounted:
	var id: String = "probe"
	var float_value: float = 0.0

	func get_save_id() -> String:
		return id

	func get_save_data(data: Dictionary) -> void:
		var floats: Dictionary = data.get("float_data", {})
		floats[id] = float_value
		data["float_data"] = floats

	func load_save_data(data: Dictionary) -> void:
		var floats: Dictionary = data.get("float_data", {})
		float_value = float(floats.get(id, 0.0))
