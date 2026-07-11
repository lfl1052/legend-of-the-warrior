class_name ThornSprout
extends EnemyMinion
## 定点近战守卫。玩家进入感知半径后按“预警—生效—恢复”循环攻击。

@export_node_path("Area2D") var attack_box_path: NodePath = ^"AttackBox"
@export var attack_windup: float = 0.38
@export var attack_active_time: float = 0.28
@export var attack_recovery: float = 0.9

var _attack_box: Attack
var _windup_timer := 0.0
var _active_timer := 0.0
var _recovery_timer := 0.0


func _ready() -> void:
	_attack_box = get_node_or_null(attack_box_path) as Attack
	_set_attack_active(false)
	super._ready()


func _setup_states() -> void:
	patrol_state = ThornGuardState.new()
	chase_state = ThornGuardState.new()


func tick_guard_attack(delta: float) -> void:
	if is_dead:
		_set_attack_active(false)
		return
	if is_hurt:
		_set_attack_active(false)
		_windup_timer = 0.0
		_active_timer = 0.0
		return

	if _active_timer > 0.0:
		_active_timer = maxf(0.0, _active_timer - delta)
		_set_attack_active(true)
		if visual_root != null:
			visual_root.modulate = Color(1.0, 0.45, 0.3, 1.0)
		if _active_timer <= 0.0:
			_set_attack_active(false)
			_recovery_timer = attack_recovery
			_restore_guard_visual()
		return

	if _windup_timer > 0.0:
		_windup_timer = maxf(0.0, _windup_timer - delta)
		_set_attack_active(false)
		if visual_root != null:
			visual_root.modulate = Color(1.0, 0.78, 0.35, 1.0)
		if _windup_timer <= 0.0:
			_active_timer = attack_active_time
			if _attack_box != null:
				_attack_box.reset_hits()
		return

	if _recovery_timer > 0.0:
		_recovery_timer = maxf(0.0, _recovery_timer - delta)
		_set_attack_active(false)
		return

	if found_player():
		_windup_timer = attack_windup
		if anim != null and anim.has_animation(&"walk"):
			anim.play(&"walk")
	elif anim != null and anim.has_animation(&"idle") and anim.current_animation != &"idle":
		anim.play(&"idle")


func cancel_guard_attack() -> void:
	_windup_timer = 0.0
	_active_timer = 0.0
	_recovery_timer = 0.0
	_set_attack_active(false)
	_restore_guard_visual()


func is_guard_attack_active() -> bool:
	return _active_timer > 0.0


func _set_attack_active(active: bool) -> void:
	if _attack_box != null:
		_attack_box.set_active(active)


func _restore_guard_visual() -> void:
	if visual_root != null and not is_hurt:
		visual_root.modulate = _visual_base_modulate
