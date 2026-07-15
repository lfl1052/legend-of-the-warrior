extends GdUnitTestSuite


var _player: PlayerController
var _character: Character


func before_test() -> void:
	var packed := load("res://scenes/player/player.tscn") as PackedScene
	_player = auto_free(packed.instantiate()) as PlayerController
	add_child(_player)
	await get_tree().process_frame
	_character = _player.get_node("Character") as Character
	_character.invulnerable_duration = 0.0


func after_test() -> void:
	_player = null
	_character = null


func test_extended_player_actions_have_input_map_entries() -> void:
	for action in [&"move_up", &"move_down", &"block"]:
		assert_bool(InputMap.has_action(action)).is_true()


func test_crouch_changes_collider_without_moving_feet() -> void:
	var collider := _player.get_node("CollisionShape2D") as CollisionShape2D
	var capsule := collider.shape as CapsuleShape2D
	var hurt_collider := _player.get_node("HurtBox/CollisionShape2D") as CollisionShape2D
	var hurt_capsule := hurt_collider.shape as CapsuleShape2D
	var standing_bottom := collider.position.y + capsule.height * 0.5
	var standing_hurt_bottom := hurt_collider.position.y + hurt_capsule.height * 0.5

	assert_bool(_player._set_crouching(true)).is_true()
	assert_bool(_player.is_crouching).is_true()
	assert_float(capsule.height).is_equal(28.0)
	assert_float(collider.position.y + capsule.height * 0.5).is_equal(standing_bottom)
	assert_float(hurt_capsule.height).is_equal(_player.crouch_hurtbox_height)
	assert_float(hurt_collider.position.y + hurt_capsule.height * 0.5).is_equal(
			standing_hurt_bottom)

	assert_bool(_player._set_crouching(false)).is_true()
	assert_float(capsule.height).is_equal(40.0)
	assert_float(collider.position.y).is_zero()
	assert_float(hurt_capsule.height).is_equal(34.0)


func test_combo_stages_use_progressively_larger_authored_hitboxes() -> void:
	var hitbox := _player.get_node("AttackPivot/Attack/CollisionShape2D") as CollisionShape2D
	var previous_width := 0.0
	var previous_reach := 0.0
	for attack_index in [1, 2, 3]:
		_player._configure_combo_hitbox(attack_index)
		var rectangle := hitbox.shape as RectangleShape2D
		var reach := hitbox.position.x + rectangle.size.x * 0.5
		assert_float(rectangle.size.x).is_greater(previous_width)
		assert_float(reach).is_greater(previous_reach)
		previous_width = rectangle.size.x
		previous_reach = reach


func test_crouch_cannot_stand_into_world_ceiling() -> void:
	_player.set_physics_process(false)
	assert_bool(_player._set_crouching(true)).is_true()
	var ceiling := auto_free(StaticBody2D.new()) as StaticBody2D
	ceiling.collision_layer = 1
	ceiling.global_position = _player.global_position + Vector2(0.0, -14.0)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24.0, 6.0)
	collider.shape = shape
	ceiling.add_child(collider)
	add_child(ceiling)
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_bool(_player._set_crouching(false)).is_false()
	assert_bool(_player.is_crouching).is_true()


func test_block_stops_front_damage_but_not_rear_damage() -> void:
	var attacker := auto_free(Node2D.new()) as Node2D
	add_child(attacker)
	_player.is_blocking = true
	_player._facing = 1
	attacker.global_position = _player.global_position + Vector2.RIGHT * 40.0

	_player.take_damage(attacker, 1.0)
	assert_float(_character.current_health).is_equal(_character.max_health)
	assert_float(_character.current_power).is_equal(_character.max_power - _player.block_power_cost)

	attacker.global_position = _player.global_position + Vector2.LEFT * 40.0
	_player.take_damage(attacker, 1.0)
	assert_float(_character.current_health).is_equal(_character.max_health - 1.0)


func test_heal_resolves_on_active_frame_and_then_consumes_power() -> void:
	var heal_skill := _player.get_node("HealSkill") as PlayerHealSkill
	_character.current_health = 1.0
	_character.current_power = _character.max_power

	assert_bool(heal_skill.try_use(_player)).is_true()
	assert_float(_character.current_health).is_equal(1.0)
	assert_float(_character.current_power).is_equal(_character.max_power)
	assert_str((_player.get_node("AnimationPlayer") as AnimationPlayer).current_animation).is_equal("heal")

	_player.on_heal_active()
	assert_float(_character.current_health).is_equal(3.25)
	assert_float(_character.current_power).is_zero()
	_player.on_heal_animation_finished()
	assert_bool(_player.is_using_skill).is_false()


func test_ladder_entry_climb_and_exit_restore_normal_state() -> void:
	var ladder := auto_free(Area2D.new()) as Area2D
	ladder.global_position = Vector2(40.0, 0.0)
	add_child(ladder)
	_player.enter_ladder(ladder)
	_player.is_climbing = true

	_player._tick_ladder_climb(-1.0, 0.05)
	assert_float(_player.velocity.y).is_equal(-_player.climb_speed)
	assert_float(_player.global_position.x).is_greater(0.0)

	_player.exit_ladder(ladder)
	assert_bool(_player.is_climbing).is_false()


func test_land_visual_is_selected_without_locking_player_state() -> void:
	_player._land_visual_timer = _player.land_visual_duration
	_player._update_animation(0.0, true, false)

	assert_str((_player.get_node("AnimationPlayer") as AnimationPlayer).current_animation).is_equal("land")
	assert_bool(_player.is_attacking).is_false()
	assert_bool(_player.is_using_skill).is_false()
