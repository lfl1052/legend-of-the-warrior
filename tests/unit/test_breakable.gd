extends GdUnitTestSuite

const BREAKABLE_SCRIPT := preload("res://scripts/general/breakable.gd")
const PLAYER_PROGRESSION_SCRIPT := preload("res://scripts/player/player_progression.gd")

var _breakable: Node
var _progression: Node


func before_test() -> void:
	DataManager.override_save_paths_for_test("user://TEST_BREAKABLE/")
	_progression = auto_free(PLAYER_PROGRESSION_SCRIPT.new())
	_progression.save_id = "test_player_progression"
	add_child(_progression)
	_breakable = auto_free(BREAKABLE_SCRIPT.new())
	_breakable.name = "TutorialPot"
	_breakable.loot_table_id = &"tutorial_chest_basic"
	_breakable.max_health = 2
	_breakable.auto_register_save = false
	var def := DataDefinition.new()
	def.id = "test_pot_001"
	_breakable.add_child(def)
	add_child(_breakable)


func after_test() -> void:
	_breakable = null
	_progression = null
	DataManager.clear_test_overrides()


func test_breakable_takes_damage_then_breaks_and_rewards_once() -> void:
	# Arrange
	var attacker := Node2D.new()
	add_child(attacker)
	auto_free(attacker)
	# Act
	_breakable.take_damage(attacker, 1.0)
	_breakable.take_damage(attacker, 1.0)
	_breakable.take_damage(attacker, 1.0)
	# Assert
	assert_bool(_breakable.is_broken()).is_true()
	assert_int(_progression.tutorial_economy_tokens).is_equal(1)
	assert_bool(_progression.opened_chest_rewards.has("test_pot_001")).is_true()


func test_breakable_load_save_data_restores_broken_state() -> void:
	# Arrange
	var data := DataManager._make_empty_data()
	data["float_data"] = {"test_pot_001_broken": 1.0}
	# Act
	_breakable.load_save_data(data)
	# Assert
	assert_bool(_breakable.is_broken()).is_true()
