class_name BossChaseState
extends BaseState

var _move_dir: Vector2 = Vector2.ZERO


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.current_speed = current_enemy.call("get_phase_chase_speed") \
			if current_enemy.has_method("get_phase_chase_speed") else current_enemy.chase_speed
	current_enemy.lost_time_counter = current_enemy.lost_time
	if current_enemy.anim != null and current_enemy.anim.has_animation("chase"):
		current_enemy.anim.play("chase")


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead or current_enemy.is_hurt:
		return
	if current_enemy.attacker == null:
		if current_enemy.has_method("found_player") and current_enemy.found_player():
			pass
		else:
			current_enemy.switch_state(Enums.NPCState.PATROL)
			return

	var attacker_node := current_enemy.attacker as Node2D
	if attacker_node == null:
		_move_dir = Vector2.ZERO
		return
	var target_offset := Vector2.ZERO
	if current_enemy.has_method("get_chase_offset"):
		target_offset = current_enemy.call("get_chase_offset")
	var target_position := attacker_node.global_position + target_offset
	_move_dir = (target_position - current_enemy.global_position).normalized()
	current_enemy.face_direction(_move_dir.x)


func physics_update(_delta: float) -> void:
	if current_enemy == null or current_enemy.is_hurt or current_enemy.is_dead:
		return
	current_enemy.velocity = _move_dir * current_enemy.current_speed


func on_exit() -> void:
	_move_dir = Vector2.ZERO
	super.on_exit()
