extends GdUnitTestSuite


var _player: PlayerController
var _character: Character


func before_test() -> void:
	_player = auto_free(PlayerController.new())
	_player.slide_duration = 0.2
	_player.slide_cooldown = 0.6
	_character = Character.new()
	_character.name = "Character"
	_character.invulnerable_duration = 0.0
	_player.add_child(_character)
	add_child(_player)
	await get_tree().process_frame


func after_test() -> void:
	_player = null
	_character = null


func test_dash_starts_fast_movement_and_invulnerability() -> void:
	_player._begin_slide(1.0)

	assert_bool(_player.is_sliding).is_true()
	assert_float(_player.velocity.x).is_equal(_player.slide_speed)
	assert_bool(_character.is_invulnerable).is_true()


func test_dash_cooldown_blocks_immediate_reuse() -> void:
	_player._begin_slide(1.0)

	assert_bool(_player.can_dash()).is_false()
	_player._tick_dash_cooldown(0.59)
	assert_bool(_player.can_dash()).is_false()
	_player._tick_dash_cooldown(0.02)
	assert_bool(_player.can_dash()).is_true()


func test_player_movement_assist_windows_use_forgiving_defaults() -> void:
	assert_float(_player.coyote_time).is_equal_approx(0.12, 0.001)
	assert_float(_player.jump_buffer_time).is_equal_approx(0.12, 0.001)
	assert_float(_player.wall_jump_input_lock).is_equal_approx(0.10, 0.001)


func test_player_jump_release_reduces_upward_velocity() -> void:
	_player.jump_velocity = -600.0
	_player.jump_release_ratio = 0.5
	_player.velocity.y = -520.0

	_player._apply_jump_release()

	assert_float(_player.velocity.y).is_equal(-300.0)


func test_player_death_disables_body_and_interaction_then_hides() -> void:
	var sign := Area2D.new()
	sign.name = "Sign"
	_player.add_child(sign)
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
	var sign := Area2D.new()
	sign.name = "Sign"
	_player.add_child(sign)
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
