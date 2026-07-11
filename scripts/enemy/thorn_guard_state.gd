class_name ThornGuardState
extends BaseState
## Thorn Sprout 的定点守卫状态：不追逐，只在玩家进入范围后执行预警攻击。


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.velocity.x = 0.0
	if current_enemy.anim != null and current_enemy.anim.has_animation(&"idle"):
		current_enemy.anim.play(&"idle")


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead:
		return
	current_enemy.velocity.x = 0.0
	if current_enemy.has_method("tick_guard_attack"):
		current_enemy.call("tick_guard_attack", delta)


func physics_update(_delta: float) -> void:
	if current_enemy != null:
		current_enemy.velocity.x = 0.0


func on_exit() -> void:
	if current_enemy != null and current_enemy.has_method("cancel_guard_attack"):
		current_enemy.call("cancel_guard_attack")
	super.on_exit()
