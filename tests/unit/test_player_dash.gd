extends GdUnitTestSuite

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _player: PlayerController
var _character: Character


func before_test() -> void:
	_player = auto_free(PLAYER_SCENE.instantiate()) as PlayerController
	_player.slide_duration = 0.2
	_player.slide_cooldown = 0.6
	_character = _player.get_node("Character") as Character
	_character.invulnerable_duration = 0.0
	add_child(_player)
	await get_tree().process_frame


func after_test() -> void:
	_player = null
	_character = null


func test_dash_starts_fast_movement_and_invulnerability() -> void:
	var power_before := _character.current_power
	_player._begin_slide(1.0)

	assert_bool(_player.is_sliding).is_true()
	assert_float(_player.velocity.x).is_equal(_player.slide_speed)
	assert_bool(_character.is_invulnerable).is_true()
	assert_float(_character.current_power).is_equal(power_before - _player.slide_power_cost)
	assert_float(_player.get("_slide_target_x")).is_equal(_player.slide_distance)


func test_dash_uses_left_facing_for_fixed_target_distance() -> void:
	_player.global_position.x = 80.0

	_player._begin_slide(-1.0)

	assert_float(_player.velocity.x).is_equal(-_player.slide_speed)
	assert_float(_player.get("_slide_target_x")).is_equal(80.0 - _player.slide_distance)


func test_dash_does_not_start_or_spend_power_when_energy_is_insufficient() -> void:
	_character.current_power = _player.slide_power_cost - 1.0

	var started := _player._begin_slide(1.0)

	assert_bool(started).is_false()
	assert_bool(_player.is_sliding).is_false()
	assert_float(_character.current_power).is_equal(_player.slide_power_cost - 1.0)


func test_dash_rejects_duplicate_begin_without_double_spending_power() -> void:
	_player._begin_slide(1.0)
	var power_after_first := _character.current_power

	var started_again := _player._begin_slide(1.0)

	assert_bool(started_again).is_false()
	assert_float(_character.current_power).is_equal(power_after_first)


func test_dash_cooldown_blocks_immediate_reuse() -> void:
	_player._begin_slide(1.0)

	assert_bool(_player.can_dash()).is_false()
	_player._tick_dash_cooldown(0.59)
	assert_bool(_player.can_dash()).is_false()
	_player._tick_dash_cooldown(0.02)
	assert_bool(_player.can_dash()).is_true()


func test_dash_shortens_colliders_and_restores_foot_baselines() -> void:
	var body := _player.get_node("CollisionShape2D") as CollisionShape2D
	var hurtbox := _player.get_node("HurtBox/CollisionShape2D") as CollisionShape2D
	var body_height_before := (body.shape as CapsuleShape2D).height
	var hurtbox_height_before := (hurtbox.shape as CapsuleShape2D).height
	var body_bottom_before := body.position.y + body_height_before * 0.5
	var hurtbox_bottom_before := hurtbox.position.y + hurtbox_height_before * 0.5

	_player._begin_slide(1.0)

	assert_float((body.shape as CapsuleShape2D).height).is_equal(24.0)
	assert_float((hurtbox.shape as CapsuleShape2D).height).is_equal(20.0)
	assert_float(body.position.y + 12.0).is_equal(body_bottom_before)
	assert_float(hurtbox.position.y + 10.0).is_equal(hurtbox_bottom_before)

	_player._end_slide()

	assert_float((body.shape as CapsuleShape2D).height).is_equal(body_height_before)
	assert_float((hurtbox.shape as CapsuleShape2D).height).is_equal(hurtbox_height_before)


func test_disabling_input_during_dash_restores_mask_and_colliders() -> void:
	var normal_mask := _player.collision_mask
	var body := _player.get_node("CollisionShape2D") as CollisionShape2D
	_player._begin_slide(1.0)
	assert_int(_player.collision_mask).is_not_equal(normal_mask)

	_player.set_gameplay_input_active(false)

	assert_bool(_player.is_sliding).is_false()
	assert_int(_player.collision_mask).is_equal(normal_mask)
	assert_float((body.shape as CapsuleShape2D).height).is_equal(40.0)


func test_dash_ends_immediately_when_not_grounded() -> void:
	_player._begin_slide(1.0)

	_player._tick_slide(0.016)

	assert_bool(_player.is_sliding).is_false()


func test_dash_ends_early_when_hitting_wall() -> void:
	_player.set_physics_process(false)
	_add_static_rectangle(Vector2(0.0, 30.0), Vector2(400.0, 20.0))
	_add_static_rectangle(Vector2(50.0, 0.0), Vector2(20.0, 100.0))
	await get_tree().physics_frame
	_player.global_position = Vector2.ZERO
	_player.velocity = Vector2(0.0, 40.0)
	_player.move_and_slide()
	assert_bool(_player.is_on_floor()).is_true()

	_player._begin_slide(1.0)
	for _frame in 20:
		_player._tick_slide(1.0 / 60.0)
		if not _player.is_sliding:
			break

	assert_bool(_player.is_sliding).is_false()
	assert_float(_player.global_position.x).is_less(_player.slide_distance)


func test_player_movement_assist_windows_use_forgiving_defaults() -> void:
	assert_float(_player.coyote_time).is_equal_approx(0.12, 0.001)
	assert_float(_player.jump_buffer_time).is_equal_approx(0.12, 0.001)
	assert_float(_player.wall_jump_input_lock).is_equal_approx(0.10, 0.001)
	assert_float(_player.wall_jump_horizontal_velocity).is_equal(380.0)
	assert_float(_player.wall_jump_vertical_velocity).is_equal(-560.0)
	assert_float(_player.wall_slide_max_speed).is_equal(140.0)
	assert_float(_player.run_speed).is_equal(220.0)
	assert_float(_player.walk_speed).is_equal(110.0)
	assert_float(_player.ground_deceleration).is_greater(_player.ground_acceleration)


func test_attack_buffer_chains_all_three_combo_steps() -> void:
	_player._begin_attack()
	assert_int(_player.combo_index).is_equal(1)

	_player._queue_attack()
	_player.on_attack_animation_finished()
	assert_bool(_player.is_attacking).is_true()
	assert_int(_player.combo_index).is_equal(2)

	_player._queue_attack()
	_player.on_attack_animation_finished()
	assert_bool(_player.is_attacking).is_true()
	assert_int(_player.combo_index).is_equal(3)

	_player.on_attack_animation_finished()
	assert_bool(_player.is_attacking).is_false()


func test_player_jump_release_reduces_upward_velocity() -> void:
	_player.jump_velocity = -600.0
	_player.jump_release_ratio = 0.5
	_player.velocity.y = -520.0

	_player._apply_jump_release()

	assert_float(_player.velocity.y).is_equal(-300.0)


func test_wall_slide_requires_falling_input_toward_wall() -> void:
	_player.velocity.y = 80.0

	assert_bool(_player._should_wall_slide(-1.0, false, true, false)).is_true()
	assert_bool(_player._should_wall_slide(1.0, false, true, false)).is_false()
	assert_bool(_player._should_wall_slide(0.0, false, true, false)).is_false()

	_player.velocity.y = -80.0
	assert_bool(_player._should_wall_slide(-1.0, false, true, false)).is_false()


func test_player_death_disables_body_and_interaction_then_hides() -> void:
	var sign := _player.get_node("Sign") as Area2D
	_player.hide_body_after_death = 0.0
	var attacker: Node = auto_free(Node.new())
	add_child(attacker)

	_character.take_damage(attacker, 999.0)
	await get_tree().process_frame

	assert_bool(_player.input_enabled).is_false()
	assert_int(_player.collision_layer).is_equal(0)
	assert_int(_player.collision_mask).is_equal(0)
	assert_bool(sign.monitoring).is_false()
	assert_bool(_player.visible).is_false()


func test_player_revive_restores_body_and_interaction() -> void:
	var sign := _player.get_node("Sign") as Area2D
	_player.hide_body_after_death = 0.0
	var attacker: Node = auto_free(Node.new())
	add_child(attacker)
	_character.take_damage(attacker, 999.0)
	await get_tree().process_frame

	_player.revive_at(Vector2(24.0, 48.0))

	assert_bool(_player.input_enabled).is_true()
	assert_int(_player.collision_layer).is_not_equal(0)
	assert_bool(sign.monitoring).is_true()
	assert_bool(_player.visible).is_true()


func _add_static_rectangle(position: Vector2, size: Vector2) -> void:
	var body := auto_free(StaticBody2D.new()) as StaticBody2D
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision_shape.shape = rectangle
	body.add_child(collision_shape)
	add_child(body)
