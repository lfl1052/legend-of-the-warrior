extends GdUnitTestSuite


var _attack: Attack
var _target: TestTarget


func before_test() -> void:
	_attack = auto_free(Attack.new())
	_attack.damage = 1
	_attack.per_target_one_hit = true
	add_child(_attack)
	_target = auto_free(TestTarget.new())
	_target.global_position = Vector2(32.0, 48.0)
	add_child(_target)


func after_test() -> void:
	_attack = null
	_target = null


func test_attack_hit_requests_configurable_feedback() -> void:
	var state := {
		"count": 0,
		"strength": 0.0,
		"hitstop": 0.0,
		"position": Vector2.ZERO,
	}
	var on_feedback := func(strength: float, hitstop: float, world_pos: Vector2) -> void:
		state["count"] += 1
		state["strength"] = strength
		state["hitstop"] = hitstop
		state["position"] = world_pos
	GameEvents.combat_hit_feedback_requested.connect(on_feedback)
	_attack.feedback_strength = 1.75
	_attack.hitstop_duration = 0.05

	_attack._try_apply_damage(_target)
	_attack._try_apply_damage(_target)

	assert_int(state["count"]).is_equal(1)
	assert_float(state["strength"]).is_equal(1.75)
	assert_float(state["hitstop"]).is_equal(0.05)
	assert_vector(state["position"]).is_equal(Vector2(32.0, 48.0))
	GameEvents.combat_hit_feedback_requested.disconnect(on_feedback)


class TestTarget extends Node2D:
	var hit_count: int = 0

	func take_damage(_attacker: Node, _amount: float = 1.0) -> void:
		hit_count += 1
