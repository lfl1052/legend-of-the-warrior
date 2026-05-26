extends GdUnitTestSuite

const ENEMY_SCRIPT := preload("res://scripts/enemy/enemy_combatant.gd")

var _enemy: EnemyCombatant
var _character: Character


func before_test() -> void:
	DataManager.override_save_paths_for_test("user://TEST_ENEMY_COMBATANT/")
	_enemy = auto_free(ENEMY_SCRIPT.new()) as EnemyCombatant
	_enemy.auto_register_save = false
	_enemy.despawn_after_death = 0.0
	_character = Character.new()
	_character.name = "Character"
	_enemy.add_child(_character)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = RectangleShape2D.new()
	_enemy.add_child(shape)
	var attack_box := Area2D.new()
	attack_box.name = "AttackBox"
	var attack_shape := CollisionShape2D.new()
	attack_shape.shape = RectangleShape2D.new()
	attack_box.add_child(attack_shape)
	_enemy.add_child(attack_box)
	add_child(_enemy)
	await get_tree().process_frame


func after_test() -> void:
	_enemy = null
	_character = null
	DataManager.clear_test_overrides()


func test_enemy_death_disables_collisions_records_state_and_despawns() -> void:
	var attacker := Node.new()
	add_child(attacker)
	auto_free(attacker)

	_enemy.take_damage(attacker, 999.0)

	assert_bool(_enemy.is_dead).is_true()
	assert_int(_enemy.collision_layer).is_equal(0)
	assert_int(_enemy.collision_mask).is_equal(0)
	assert_float(DataManager.get_float(str(_enemy.get_path()) + "_dead", 0.0)).is_equal(1.0)
	var enemy_ref := _enemy
	await get_tree().process_frame
	assert_bool(is_instance_valid(enemy_ref)).is_false()


func test_enemy_load_dead_state_removes_saved_body() -> void:
	var data := DataManager._make_empty_data()
	data["float_data"] = {str(_enemy.get_path()) + "_dead": 1.0}

	_enemy.load_save_data(data)

	assert_bool(_enemy.is_dead).is_true()
	assert_int(_enemy.collision_layer).is_equal(0)
	var enemy_ref := _enemy
	await get_tree().process_frame
	assert_bool(is_instance_valid(enemy_ref)).is_false()
