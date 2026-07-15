extends GdUnitTestSuite

const CONTROLLER_SCRIPT := preload("res://scripts/enemy/encounter_reward_controller.gd")


func test_encounter_rewards_only_after_all_enemies_die_and_only_once() -> void:
	var controller: EncounterRewardController = auto_free(CONTROLLER_SCRIPT.new())
	controller.encounter_id = "test_encounter_reward"
	controller.loot_table_id = &"level_2_boss_encounter"
	add_child(controller)
	var first: FakeEnemy = auto_free(FakeEnemy.new())
	var second: FakeEnemy = auto_free(FakeEnemy.new())
	add_child(first)
	add_child(second)
	var progression: FakeProgression = auto_free(FakeProgression.new())
	add_child(progression)
	progression.add_to_group(&"player_progression")

	var enemies: Array[Node] = [first, second]
	controller.set("_enemies", enemies)
	first.is_dead = true
	controller.call("_on_enemy_died", first)
	assert_int(progression.apply_count).is_equal(0)
	second.is_dead = true
	controller.call("_on_enemy_died", second)
	controller.call("_on_enemy_died", second)

	assert_int(progression.apply_count).is_equal(1)
	assert_str(progression.last_encounter_id).is_equal("test_encounter_reward")
	assert_int(progression.notification_count).is_equal(2)


class FakeEnemy extends Node:
	signal died_event
	var is_dead: bool = false


class FakeProgression extends Node:
	var apply_count: int = 0
	var notification_count: int = 0
	var last_encounter_id: String = ""

	func _ready() -> void:
		GameEvents.reward_notification.connect(_on_reward)

	func try_apply_chest_rewards(encounter: String, _table: StringName) -> bool:
		apply_count += 1
		last_encounter_id = encounter
		return true

	func _on_reward(_reward_id: StringName, payload: Dictionary) -> void:
		if bool(payload.get("_progression_applied", false)):
			notification_count += 1
