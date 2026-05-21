class_name BoarPatrolState
extends BaseState
## 野猪巡逻（替代 Unity 项目里的 BoarPatrolState）
##
## 沿地面左右走动，遇墙或边缘转向；发现玩家立即追击。

var _direction: int = -1
var _wait_timer: float = 0.0


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.current_speed = current_enemy.normal_speed
	if current_enemy.anim != null and current_enemy.anim.has_animation("walk"):
		current_enemy.anim.play("walk")
	_direction = -1
	_wait_timer = 0.0


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead or current_enemy.is_hurt:
		return

	if current_enemy.has_method("found_player") and current_enemy.found_player():
		current_enemy.switch_state(Enums.NPCState.CHASE)
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		current_enemy.velocity.x = 0.0
		return

	var pc: PhysicsCheck = current_enemy.physics_check
	# 撞墙或没地面时转向
	if pc != null:
		var should_turn := false
		if _direction < 0 and pc.touch_left:
			should_turn = true
		elif _direction > 0 and pc.touch_right:
			should_turn = true
		if not pc.is_ground:
			should_turn = true
		if should_turn:
			_direction = -_direction
			_wait_timer = 0.4
			current_enemy.velocity.x = 0.0
			return

	current_enemy.face_direction(_direction)
	current_enemy.velocity.x = _direction * current_enemy.normal_speed


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	super.on_exit()
