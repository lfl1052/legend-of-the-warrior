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
	_set_contact_attack_active(true)


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead or current_enemy.is_hurt:
		return

	if current_enemy.has_method("found_player") and current_enemy.found_player():
		current_enemy.switch_state(Enums.NPCState.CHASE)
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		current_enemy.velocity.x = 0.0
		_set_contact_attack_active(false)
		return

	var pc: PhysicsCheck = current_enemy.physics_check
	# 撞墙或没地面时转向
	if pc != null:
		var should_turn := pc.should_turn_for_patrol(_direction)
		if should_turn:
			_direction = -_direction
			_wait_timer = 0.4
			current_enemy.velocity.x = 0.0
			_set_contact_attack_active(false)
			_play_animation(&"idle")
			return

	current_enemy.face_direction(_direction)
	_set_contact_attack_active(true)
	current_enemy.velocity.x = _direction * current_enemy.normal_speed
	_play_animation(&"walk")


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	_set_contact_attack_active(false)
	super.on_exit()


func _play_animation(animation_name: StringName) -> void:
	if current_enemy.anim != null and current_enemy.anim.has_animation(animation_name) \
			and current_enemy.anim.current_animation != animation_name:
		current_enemy.anim.play(animation_name)


func _set_contact_attack_active(active: bool) -> void:
	if current_enemy != null and current_enemy.has_method("set_contact_attack_active"):
		current_enemy.call("set_contact_attack_active", active)
