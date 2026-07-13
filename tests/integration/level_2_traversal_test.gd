extends Node2D
## 几何回归：自动玩家必须能从 level_2 出生区穿过全部平台到达奖励区。

const LEVEL := preload("res://scenes/levels/level_2.tscn")
const TARGET_X := 2250.0
const TIMEOUT := 30.0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame

	for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
		if level.is_ancestor_of(enemy):
			enemy.set_process(false)
			enemy.set_physics_process(false)
			if enemy is CollisionObject2D:
				(enemy as CollisionObject2D).collision_layer = 0
				(enemy as CollisionObject2D).collision_mask = 0

	var player := level.get_node_or_null("Player") as PlayerController
	if player == null:
		_fail("缺少 PlayerController")
		return
	player.enable_automation(true)
	player.automation_move(1.0)

	var elapsed := 0.0
	var jump_cooldown := 0.0
	while elapsed < TIMEOUT and player.global_position.x < TARGET_X:
		jump_cooldown = maxf(0.0, jump_cooldown - 1.0 / 60.0)
		if player.is_on_floor() and jump_cooldown <= 0.0:
			player.automation_jump()
			jump_cooldown = 0.72
		await get_tree().physics_frame
		elapsed += 1.0 / 60.0
		if player.global_position.y > 700.0:
			_fail("玩家跌出关卡：%s" % player.global_position)
			return

	player.automation_move(0.0)
	player.enable_automation(false)
	if player.global_position.x < TARGET_X:
		_fail("超时，玩家停在 %s" % player.global_position)
		return

	print("[level_2_traversal] PASS: reached %s in %.2fs" % [player.global_position, elapsed])
	get_tree().quit()


func _fail(message: String) -> void:
	push_error("[level_2_traversal] FAIL: %s" % message)
	get_tree().quit(1)
