extends GdUnitTestSuite

const ARENA_LOCK_SCRIPT := preload("res://scripts/enemy/boss_arena_lock.gd")
const BOSS_SCENE := preload("res://scenes/enemy/boss_enemy.tscn")


func test_arena_lock_closes_on_engage_and_reopens_after_boss_death() -> void:
	var root := auto_free(Node2D.new()) as Node2D
	add_child(root)
	var boss := auto_free(BOSS_SCENE.instantiate()) as BossEnemy
	boss.name = "Boss"
	boss.auto_register_save = false
	root.add_child(boss)
	var entrance := _make_gate("EntranceGate")
	var exit_gate := _make_gate("ExitGate")
	root.add_child(entrance)
	root.add_child(exit_gate)
	var lock := auto_free(ARENA_LOCK_SCRIPT.new()) as BossArenaLock
	lock.name = "ArenaLock"
	lock.boss_path = NodePath("../Boss")
	lock.gate_paths = [NodePath("../EntranceGate"), NodePath("../ExitGate")]
	root.add_child(lock)
	await get_tree().physics_frame

	assert_bool(lock.is_locked()).is_false()
	assert_int(entrance.collision_layer).is_zero()
	boss._engage_arena()
	await get_tree().physics_frame
	assert_bool(lock.is_locked()).is_true()
	assert_int(entrance.collision_layer).is_equal(1)
	assert_int(exit_gate.collision_layer).is_equal(1)

	boss.arena_completed.emit()
	await get_tree().physics_frame
	assert_bool(lock.is_locked()).is_false()
	assert_int(entrance.collision_layer).is_zero()


func _make_gate(gate_name: String) -> StaticBody2D:
	var gate := auto_free(StaticBody2D.new()) as StaticBody2D
	gate.name = gate_name
	gate.collision_layer = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24.0, 180.0)
	collider.shape = shape
	collider.disabled = true
	gate.add_child(collider)
	return gate
