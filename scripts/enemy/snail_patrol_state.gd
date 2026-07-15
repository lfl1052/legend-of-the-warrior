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
	_set_contact_attack_active(true)
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
		_set_contact_attack_active(false)
		return

	var pc: PhysicsCheck = current_enemy.physics_check
	if pc != null:
		var should_turn := pc.should_turn_for_patrol(_direction)
		if should_turn:
			_direction = -_direction
			_wait_timer = 0.6
			current_enemy.velocity.x = 0.0
			_set_contact_attack_active(false)
			if current_enemy.anim != null and current_enemy.anim.has_animation("idle"):
				current_enemy.anim.play("idle")
			return

	current_enemy.face_direction(_direction)
	_set_contact_attack_active(true)
	current_enemy.velocity.x = _direction * current_enemy.normal_speed
	if current_enemy.anim != null and current_enemy.anim.has_animation("walk") \
			and current_enemy.anim.current_animation != "walk":
		current_enemy.anim.play("walk")


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	_set_contact_attack_active(false)
	super.on_exit()


func _set_contact_attack_active(active: bool) -> void:
	if current_enemy != null and current_enemy.has_method("set_contact_attack_active"):
		current_enemy.call("set_contact_attack_active", active)
