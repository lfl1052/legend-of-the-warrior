extends GdUnitTestSuite

const CHEST_SCRIPT := preload("res://scripts/general/chest.gd")
const PLAYER_PROGRESSION_SCRIPT := preload("res://scripts/player/player_progression.gd")

var _chest: Node
var _progression: Node


func before_test() -> void:
	DataManager.override_save_paths_for_test("user://TEST_CHEST/")
	_progression = auto_free(PLAYER_PROGRESSION_SCRIPT.new())
	_progression.save_id = "test_player_progression"
	add_child(_progression)
	_chest = auto_free(CHEST_SCRIPT.new())
	_chest.name = "TutorialChest"
	_chest.loot_table_id = &"tutorial_chest_basic"
	_chest.auto_register_save = false
	var def := DataDefinition.new()
	def.id = "test_chest_001"
	_chest.add_child(def)
	add_child(_chest)


func after_test() -> void:
	_chest = null
	_progression = null
	DataManager.clear_test_overrides()


func test_chest_open_applies_rewards_through_player_progression_once() -> void:
	# Arrange
	# Act
	_chest.trigger_action()
	_chest.trigger_action()
	# Assert
	assert_int(_progression.tutorial_economy_tokens).is_equal(1)
	assert_bool(_progression.opened_chest_rewards.has("test_chest_001")).is_true()


func test_chest_save_data_records_opened_state() -> void:
	# Arrange
	_chest.trigger_action()
	var data := DataManager._make_empty_data()
	# Act
	_chest.get_save_data(data)
	# Assert
	var floats: Dictionary = data.get("float_data", {})
	assert_float(float(floats.get("test_chest_001_opened", 0.0))).is_equal(1.0)


func test_chest_without_data_definition_uses_stable_scene_path() -> void:
	# Arrange
	var chest: Node = auto_free(CHEST_SCRIPT.new())
	chest.name = "PathFallbackChest"
	chest.set("auto_register_save", false)
	add_child(chest)
	await get_tree().process_frame
	# Act
	var save_id := String(chest.call("get_save_id"))
	# Assert
	assert_str(save_id).is_equal(str(chest.get_path()))
