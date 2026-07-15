extends GdUnitTestSuite


class DamageTarget extends StaticBody2D:
	var damage_received: float = 0.0

	func take_damage(_attacker: Node, amount: float = 1.0) -> void:
		damage_received += amount


var _player: PlayerController
var _character: Character
var _skill: PlayerSkillSlash


func before_test() -> void:
	var packed := load("res://scenes/player/player.tscn") as PackedScene
	_player = auto_free(packed.instantiate()) as PlayerController
	add_child(_player)
	await get_tree().process_frame
	_character = _player.get_node("Character") as Character
	_skill = _player.get_node("SkillSlash") as PlayerSkillSlash


func after_test() -> void:
	_player = null
	_character = null
	_skill = null


func test_skill_slash_consumes_power_then_resolves_on_active_frame() -> void:
	var target := await _add_target(Vector2(80.0, 0.0))

	assert_bool(_skill.try_use(_player)).is_true()
	assert_float(_character.current_power).is_equal(65.0)
	assert_float(target.damage_received).is_zero()
	assert_bool(_player.is_using_skill).is_true()
	assert_str(_player.get_node("AnimationPlayer").current_animation).is_equal("skill_slash")

	_player.on_skill_slash_active()
	assert_float(target.damage_received).is_equal(2.0)
	_player.on_skill_slash_animation_finished()
	assert_bool(_player.is_using_skill).is_false()


func test_skill_slash_uses_controller_facing_direction() -> void:
	var left_target := await _add_target(Vector2(-80.0, 0.0))
	var right_target := await _add_target(Vector2(80.0, 0.0))
	_player._facing = -1

	assert_bool(_skill.try_use(_player)).is_true()
	_player.on_skill_slash_active()

	assert_float(left_target.damage_received).is_equal(2.0)
	assert_float(right_target.damage_received).is_zero()


func test_skill_slash_rejected_during_attack_without_consuming_power() -> void:
	_player.is_attacking = true
	var power_before := _character.current_power

	assert_bool(_skill.try_use(_player)).is_false()
	assert_float(_character.current_power).is_equal(power_before)
	assert_bool(_player.is_using_skill).is_false()


func test_skill_slash_preview_uses_exact_hitbox_dimensions() -> void:
	assert_bool(_skill.try_use(_player)).is_true()
	assert_bool(_skill._preview_visible).is_true()
	assert_int(_skill._preview_facing).is_equal(_player.get_facing_direction())
	assert_vector(_skill.hit_box_size).is_equal(Vector2(160.0, 80.0))

	_player.on_skill_slash_active()
	assert_bool(_skill._preview_active).is_true()
	_player.on_skill_slash_animation_finished()
	assert_bool(_skill._preview_visible).is_false()


func test_skill_slash_respects_visible_range_boundary() -> void:
	var inside_target := await _add_target(Vector2(159.0, 0.0))
	var outside_target := await _add_target(Vector2(173.0, 0.0))

	assert_bool(_skill.try_use(_player)).is_true()
	_player.on_skill_slash_active()

	assert_float(inside_target.damage_received).is_equal(2.0)
	assert_float(outside_target.damage_received).is_zero()


func _add_target(position: Vector2) -> DamageTarget:
	var target := auto_free(DamageTarget.new()) as DamageTarget
	target.collision_layer = 1 << 2
	target.global_position = position
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24.0, 32.0)
	collider.shape = shape
	target.add_child(collider)
	add_child(target)
	await get_tree().physics_frame
	await get_tree().physics_frame
	return target
