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


func _write_raw_to_disk(raw: String) -> void:
	if not DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	var f := FileAccess.open(_manager.save_file, FileAccess.WRITE)
	f.store_string(raw)


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
