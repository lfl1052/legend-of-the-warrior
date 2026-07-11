class_name BoarChaseState
extends BaseState
## 野猪追击（替代 Unity 项目里的 BoarChaseState）
##
## 加速冲向玩家，遇墙短停顿。lost_time 用尽返回巡逻。

var _direction: int = -1


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.current_speed = current_enemy.chase_speed
	current_enemy.lost_time_counter = current_enemy.lost_time
	if current_enemy.anim != null and current_enemy.anim.has_animation("run"):
		current_enemy.anim.play("run")


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead or current_enemy.is_hurt:
		return

	if current_enemy.attacker == null:
		current_enemy.switch_state(Enums.NPCState.PATROL)
		return

	current_enemy.lost_time_counter -= delta
	if current_enemy.lost_time_counter <= 0.0:
		current_enemy.switch_state(Enums.NPCState.PATROL)
		return

	var attacker_node: Node2D = current_enemy.attacker
	_direction = -1 if attacker_node.global_position.x < current_enemy.global_position.x else 1
	current_enemy.face_direction(_direction)

	var pc: PhysicsCheck = current_enemy.physics_check
	if pc != null and not pc.is_ground:
		current_enemy.velocity.x = 0.0
		return
	if pc != null and pc.should_turn_for_patrol(_direction):
		current_enemy.velocity.x = 0.0
		return

	current_enemy.velocity.x = move_toward(
		current_enemy.velocity.x,
		_direction * current_enemy.chase_speed,
		current_enemy.chase_acceleration * delta)


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	super.on_exit()
