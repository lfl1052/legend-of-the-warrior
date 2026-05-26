extends GdUnitTestSuite

const COLLECTIBLE_SCRIPT := preload("res://scripts/general/collectible_reward.gd")
const PLAYER_PROGRESSION_SCRIPT := preload("res://scripts/player/player_progression.gd")

var _collectible: Area2D
var _progression: PlayerProgression
var _player: Node2D


func before_test() -> void:
	DataManager.override_save_paths_for_test("user://TEST_COLLECTIBLE_REWARD/")
	_progression = auto_free(PLAYER_PROGRESSION_SCRIPT.new()) as PlayerProgression
	_progression.save_id = "test_collectible_progression"
	add_child(_progression)
	_player = auto_free(Node2D.new())
	_player.add_to_group(&"player")
	add_child(_player)
	_collectible = auto_free(COLLECTIBLE_SCRIPT.new()) as Area2D
	_collectible.auto_register_save = false
	_collectible.reward_id = &"upgrade-token"
	_collectible.amount = 1
	var def := DataDefinition.new()
	def.id = "test_collectible_a"
	_collectible.add_child(def)
	add_child(_collectible)
	await get_tree().process_frame


func after_test() -> void:
	_collectible = null
	_progression = null
	_player = null
	DataManager.clear_test_overrides()


func test_collectible_rewards_player_once_and_removes_itself() -> void:
	_collectible.collect(_player)
	_collectible.collect(_player)

	assert_int(_progression.upgrade_tokens).is_equal(1)
	assert_float(DataManager.get_float("test_collectible_a_collected", 0.0)).is_equal(1.0)
	var collectible_ref := _collectible
	await get_tree().process_frame
	assert_bool(is_instance_valid(collectible_ref)).is_false()


func test_collectible_ignores_non_player_body() -> void:
	var prop := Node2D.new()
	add_child(prop)
	auto_free(prop)

	_collectible.collect(prop)

	assert_int(_progression.upgrade_tokens).is_equal(0)
	assert_bool(_collectible.is_queued_for_deletion()).is_false()


func test_collectible_load_collected_state_removes_pickup() -> void:
	var data := DataManager._make_empty_data()
	data["float_data"] = {"test_collectible_a_collected": 1.0}

	_collectible.load_save_data(data)
	var collectible_ref := _collectible
	await get_tree().process_frame

	assert_bool(is_instance_valid(collectible_ref)).is_false()
