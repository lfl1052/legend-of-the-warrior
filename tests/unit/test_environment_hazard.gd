extends GdUnitTestSuite

const HAZARD_SCRIPT := preload("res://scripts/general/environment_hazard.gd")


func test_hazard_applies_damage_through_receiver_and_respects_tick_interval() -> void:
	var hazard: EnvironmentHazard = auto_free(HAZARD_SCRIPT.new())
	add_child(hazard)
	var receiver: FakeDamageReceiver = auto_free(FakeDamageReceiver.new())
	add_child(receiver)

	assert_bool(hazard.call("_try_damage_target", receiver)).is_true()
	assert_bool(hazard.call("_try_damage_target", receiver)).is_false()
	assert_int(receiver.hit_count).is_equal(1)
	assert_float(receiver.last_damage).is_equal(1.0)

	hazard.call("_physics_process", 0.8)
	assert_bool(hazard.call("_try_damage_target", receiver)).is_true()
	assert_int(receiver.hit_count).is_equal(2)


func test_hazard_resolves_hurtbox_to_single_canonical_receiver() -> void:
	var hazard: EnvironmentHazard = auto_free(HAZARD_SCRIPT.new())
	add_child(hazard)
	var receiver: FakeDamageReceiver = auto_free(FakeDamageReceiver.new())
	add_child(receiver)
	var hurtbox: FakeHurtBox = auto_free(FakeHurtBox.new())
	hurtbox.receiver = receiver
	add_child(hurtbox)

	assert_bool(hazard.call("_try_damage_target", hurtbox)).is_true()
	assert_bool(hazard.call("_try_damage_target", receiver)).is_false()
	assert_int(receiver.hit_count).is_equal(1)
	assert_bool(hazard.bypasses_block()).is_true()


class FakeDamageReceiver extends Node2D:
	var hit_count: int = 0
	var last_damage: float = 0.0

	func take_damage(_attacker: Node, amount: float = 1.0) -> void:
		hit_count += 1
		last_damage = amount


class FakeHurtBox extends Node:
	var receiver: Node

	func get_damage_receiver() -> Node:
		return receiver
