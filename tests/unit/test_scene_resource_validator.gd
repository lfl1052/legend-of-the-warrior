extends GdUnitTestSuite
## SceneResourceValidator 单元测试

const DATA_DIR := "res://data"
const FIXTURE_DIR := "res://tests/unit/fixtures/scene_validator"


func test_scene_resource_validator_returns_entry_per_tres() -> void:
	# Arrange
	var expected_count := _count_game_scene_resource_files(DATA_DIR)
	# Act
	var results := SceneResourceValidator.validate(DATA_DIR)
	# Assert
	assert_int(results.size()).is_equal(expected_count)


func test_scene_resource_validator_marks_missing_path_as_dead() -> void:
	# Act
	var results := SceneResourceValidator.validate(FIXTURE_DIR)
	var dead_entry := _find_by_tres_path(results, FIXTURE_DIR.path_join("dead_link.tres"))
	# Assert
	assert_dict(dead_entry).is_not_empty()
	assert_bool(dead_entry["scene_exists"]).is_false()


func test_scene_resource_validator_marks_existing_path_as_alive() -> void:
	# Act
	var results := SceneResourceValidator.validate(DATA_DIR)
	var menu_entry := _find_by_tres_path(results, DATA_DIR.path_join("scene_warrior_menu.tres"))
	# Assert
	assert_dict(menu_entry).is_not_empty()
	assert_bool(menu_entry["scene_exists"]).is_true()


func test_scene_resource_validator_marks_level_2_path_as_alive() -> void:
	# Act
	var results := SceneResourceValidator.validate(DATA_DIR)
	var level_entry := _find_by_tres_path(results, DATA_DIR.path_join("scene_level_2.tres"))
	# Assert
	assert_dict(level_entry).is_not_empty()
	assert_bool(level_entry["scene_exists"]).is_true()
	assert_str(level_entry["scene_path"]).is_equal("res://scenes/levels/level_2.tscn")


func test_scene_resource_validator_skips_non_game_scene_tres() -> void:
	# Act
	var results := SceneResourceValidator.validate(FIXTURE_DIR)
	var skipped_entry := _find_by_tres_path(results, FIXTURE_DIR.path_join("non_game_scene.tres"))
	# Assert
	assert_dict(skipped_entry).is_empty()


func _count_game_scene_resource_files(path: String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	var count := 0
	for file_name in dir.get_files():
		if file_name.get_extension() == "tres":
			var resource := ResourceLoader.load(path.path_join(file_name))
			if resource != null and _resource_has_property(resource, "scene_path"):
				count += 1
	return count


func _find_by_tres_path(results: Array[Dictionary], tres_path: String) -> Dictionary:
	for entry in results:
		if String(entry["tres_path"]) == tres_path:
			return entry
	return {}


func _resource_has_property(resource: Resource, property_name: String) -> bool:
	for property_info in resource.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false
