class_name BeeChaseState
extends BaseState
## 蜜蜂追击状态（替代 Unity 项目里的 BeeChaseState）
##
## 行为流程：
##   1. 不断追到玩家头顶悬停高度 chase_hover_height
##   2. 接近攻击容差时锁定 attack_hover_height，触发 attack_window
##   3. 攻击窗口结束后退避 retreat 一段距离
##   4. lost_time 用尽则回到 Patrol

var _attack_rate_counter: float = 0.0
var _retreat_counter: float = 0.0
var _retreat_pending: bool = false
var _retreat_direction: int = 0
var _is_attacking: bool = false
var _move_dir: Vector2 = Vector2.ZERO


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.current_speed = current_enemy.chase_speed
	current_enemy.lost_time_counter = current_enemy.lost_time
	_retreat_counter = 0.0
	_retreat_pending = false
	_retreat_direction = 0
	if current_enemy.anim != null and current_enemy.anim.has_animation("chase"):
		current_enemy.anim.play("chase")
	if current_enemy.has_method("cancel_attack_window"):
		current_enemy.call("cancel_attack_window")


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead:
		return

	if current_enemy.has_method("tick_attack_window"):
		current_enemy.call("tick_attack_window", delta)

	if current_enemy.lost_time_counter <= 0.0:
		current_enemy.switch_state(Enums.NPCState.PATROL)
		return

	_attack_rate_counter = maxf(0.0, _attack_rate_counter - delta)

	if current_enemy.attacker == null:
		_is_attacking = false
		_move_dir = Vector2.ZERO
		current_enemy.current_speed = current_enemy.chase_speed
		return

	if current_enemy.is_hurt or current_enemy.is_dead:
		if current_enemy.has_method("cancel_attack_window"):
			current_enemy.call("cancel_attack_window")
		_retreat_pending = false
		_retreat_counter = 0.0
		_is_attacking = false
		_move_dir = Vector2.ZERO
		current_enemy.current_speed = 0.0
		return

	var attacker_node: Node2D = current_enemy.attacker as Node2D
	var chase_target: Vector2 = current_enemy.call("get_chase_target_position", attacker_node)
	var attack_target: Vector2 = current_enemy.call("get_attack_target_position", attacker_node)

	var attack_range: float = current_enemy.call("get_attack_range")
	var attack_interval: float = current_enemy.call("get_attack_interval")
	var horizontal_tol: float = current_enemy.call("get_attack_horizontal_tolerance")
	var vertical_tol: float = current_enemy.call("get_attack_vertical_tolerance")
	var window_in_progress: bool = current_enemy.call("has_attack_window_in_progress")

	if _retreat_pending and not window_in_progress:
		_retreat_pending = false
		_retreat_counter = float(current_enemy.call("get_post_attack_retreat_duration"))
		_play_chase_animation()

	if window_in_progress:
		_is_attacking = true
		_move_dir = Vector2.ZERO
		current_enemy.current_speed = 0.0
	elif _retreat_counter > 0.0:
		_retreat_counter = maxf(0.0, _retreat_counter - delta)
		_is_attacking = false
		var retreat_target: Vector2 = current_enemy.call(
				"get_retreat_target_position", attacker_node, _retreat_direction)
		_move_dir = (retreat_target - current_enemy.global_position).normalized()
		current_enemy.current_speed = current_enemy.chase_speed * float(current_enemy.call("get_retreat_speed_multiplier"))
		_play_chase_animation()
	else:
		current_enemy.current_speed = current_enemy.chase_speed
		var can_attack := absf(attack_target.x - current_enemy.global_position.x) <= horizontal_tol \
				and absf(attack_target.y - current_enemy.global_position.y) <= vertical_tol
		if can_attack and _attack_rate_counter <= 0.0:
			_is_attacking = true
			_move_dir = Vector2.ZERO
			current_enemy.current_speed = 0.0
			if current_enemy.anim != null and current_enemy.anim.has_animation("attack"):
				current_enemy.anim.play("attack")
			_attack_rate_counter = attack_interval
			_retreat_direction = 1 if current_enemy.global_position.x >= attacker_node.global_position.x else -1
			_retreat_pending = true
			if current_enemy.has_method("queue_attack_window"):
				current_enemy.call("queue_attack_window")
		else:
			_is_attacking = false
			_move_dir = (chase_target - current_enemy.global_position).normalized()
			_play_chase_animation()

	current_enemy.face_direction(_move_dir.x)


func physics_update(_delta: float) -> void:
	if current_enemy == null:
		return
	if current_enemy.is_hurt or current_enemy.is_dead or _is_attacking:
		return
	current_enemy.velocity = _move_dir * current_enemy.current_speed


func on_exit() -> void:
	if current_enemy != null and current_enemy.has_method("cancel_attack_window"):
		current_enemy.call("cancel_attack_window")
	if current_enemy != null and current_enemy.anim != null and current_enemy.anim.has_animation("idle"):
		current_enemy.anim.play("idle")
	super.on_exit()


func _play_chase_animation() -> void:
	if current_enemy != null and current_enemy.anim != null \
			and current_enemy.anim.has_animation(&"chase") \
			and current_enemy.anim.current_animation != &"chase":
		current_enemy.anim.play(&"chase")
