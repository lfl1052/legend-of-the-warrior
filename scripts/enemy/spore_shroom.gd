class_name SporeShroom
extends Boar
## 慢速空间占用者：接近玩家后停下，以明显预警释放短时孢子伤害区。

@export_node_path("Area2D") var attack_box_path: NodePath = ^"AttackBox"
@export var pulse_windup: float = 0.52
@export var pulse_active_time: float = 0.38
@export var pulse_recovery: float = 1.6
@export var pulse_trigger_distance: float = 72.0

var _attack_box: Attack
var _pulse_windup_timer := 0.0
var _pulse_active_timer := 0.0
var _pulse_recovery_timer := 0.0


func _ready() -> void:
	_attack_box = get_node_or_null(attack_box_path) as Attack
	_set_pulse_active(false)
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	_tick_spore_pulse(delta)


func _tick_spore_pulse(delta: float) -> void:
	if is_dead or is_hurt:
		_set_pulse_active(false)
		_pulse_windup_timer = 0.0
		_pulse_active_timer = 0.0
		return

	_pulse_recovery_timer = maxf(0.0, _pulse_recovery_timer - delta)
	if _pulse_active_timer > 0.0:
		velocity.x = 0.0
		_pulse_active_timer = maxf(0.0, _pulse_active_timer - delta)
		_set_pulse_active(true)
		if visual_root != null:
			visual_root.modulate = Color(0.82, 0.5, 1.0, 1.0)
		if _pulse_active_timer <= 0.0:
			_set_pulse_active(false)
			_pulse_recovery_timer = pulse_recovery
			_restore_spore_visual()
		return

	if _pulse_windup_timer > 0.0:
		velocity.x = 0.0
		_pulse_windup_timer = maxf(0.0, _pulse_windup_timer - delta)
		_set_pulse_active(false)
		if visual_root != null:
			visual_root.modulate = Color(1.0, 0.72, 0.92, 1.0)
		if _pulse_windup_timer <= 0.0:
			_pulse_active_timer = pulse_active_time
			if _attack_box != null:
				_attack_box.reset_hits()
		return

	_set_pulse_active(false)
	if attacker is Node2D and _pulse_recovery_timer <= 0.0:
		var target := attacker as Node2D
		if global_position.distance_to(target.global_position) <= pulse_trigger_distance:
			_pulse_windup_timer = pulse_windup


func is_spore_pulse_active() -> bool:
	return _pulse_active_timer > 0.0


func _set_pulse_active(active: bool) -> void:
	if _attack_box != null:
		_attack_box.set_active(active)


func _restore_spore_visual() -> void:
	if visual_root != null and not is_hurt:
		visual_root.modulate = _visual_base_modulate
