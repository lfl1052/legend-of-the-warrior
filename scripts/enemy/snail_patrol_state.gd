class_name SnailPatrolState
extends BaseState
## 蜗牛巡逻（替代 Unity 项目里的 SnailPatrolState）
##
## 缓慢爬行，遇墙或边缘原地停顿；发现玩家立即缩壳（Skill）。

var _direction: int = -1
var _wait_timer: float = 0.0


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.current_speed = current_enemy.normal_speed
	_direction = -1
	_wait_timer = 0.0
	if current_enemy.anim != null and current_enemy.anim.has_animation("walk"):
		current_enemy.anim.play("walk")


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead or current_enemy.is_hurt:
		return

	if current_enemy.has_method("found_player") and current_enemy.found_player():
		current_enemy.switch_state(Enums.NPCState.SKILL)
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		current_enemy.velocity.x = 0.0
		return

	var pc: PhysicsCheck = current_enemy.physics_check
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
			_wait_timer = 0.6
			current_enemy.velocity.x = 0.0
			if current_enemy.anim != null and current_enemy.anim.has_animation("idle"):
				current_enemy.anim.play("idle")
			return

	current_enemy.face_direction(_direction)
	current_enemy.velocity.x = _direction * current_enemy.normal_speed
	if current_enemy.anim != null and current_enemy.anim.has_animation("walk") \
			and current_enemy.anim.current_animation != "walk":
		current_enemy.anim.play("walk")


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	super.on_exit()
