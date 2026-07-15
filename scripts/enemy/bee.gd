class_name Bee
extends EnemyMinion
## 蜜蜂（替代 Unity 项目里的 Bee.cs）
##
## 飞行型杂兵：悬停高度可配置，攻击具备启动 / 命中窗口 / 撤离三段。
## 关键差异：
##   - Godot 没有 OverlapBoxAll，攻击命中盒以子节点 Area2D 形式存在并按 timer 启停。
##   - patrol_half_extents 替代 Unity 的 patrolRadius，矩形随机点。

@export var patrol_radius: float = 1.4
@export var patrol_center_offset: Vector2 = Vector2.ZERO
@export var patrol_half_extents: Vector2 = Vector2(1.4, 0.8)

@export_node_path("Area2D") var attack_box_path: NodePath = ^"AttackBox"
@export_node_path("CollisionShape2D") var attack_hitbox_path: NodePath = ^"AttackBox/CollisionShape2D"

@export var attack_startup_delay: float = 0.35
@export var attack_active_duration: float = 0.12
@export var chase_hover_height: float = 24.0
@export var attack_hover_height: float = 38.0
@export var attack_damage: int = 1
@export var attack_range: float = 12.0
@export var attack_interval: float = 2.4
@export var attack_horizontal_tolerance: float = 12.0
@export var attack_vertical_tolerance: float = 8.0
@export var post_attack_retreat_duration: float = 0.55
@export var retreat_speed_multiplier: float = 1.35
@export var retreat_hover_height: float = 56.0

var _attack_box: Area2D
var _attack_hitbox: CollisionShape2D
var _attack_startup_counter: float = 0.0
var _attack_active_counter: float = 0.0


func _ready() -> void:
	_attack_box = get_node_or_null(attack_box_path) as Area2D
	_attack_hitbox = get_node_or_null(attack_hitbox_path) as CollisionShape2D
	_set_hitbox_active(false)
	super._ready()


func _setup_states() -> void:
	patrol_state = BeePatrolState.new()
	chase_state = BeeChaseState.new()


func _process(delta: float) -> void:
	super._process(delta)
	# 攻击窗口由 Chase 状态调用 tick_attack_window 推进
	if attacker == null and not is_dead:
		if found_player():
			pass


# ----- 巡逻 ------------------------------------------------------------------

func get_new_patrol_point() -> Vector2:
	var extents := _resolved_patrol_half_extents()
	var center := _resolved_patrol_center()
	var ox := randf_range(-extents.x, extents.x)
	var oy := randf_range(-extents.y, extents.y)
	return center + Vector2(ox, oy)


func _resolved_patrol_center() -> Vector2:
	return spawn_point + patrol_center_offset


func _resolved_patrol_half_extents() -> Vector2:
	var fallback := maxf(0.1, patrol_radius * 64.0)   # 1.4 单位 ≈ 90px
	var ex := patrol_half_extents.x if patrol_half_extents.x > 0.0 else fallback
	var ey := patrol_half_extents.y if patrol_half_extents.y > 0.0 else fallback
	return Vector2(ex, ey)


# ----- 攻击窗口 --------------------------------------------------------------

func queue_attack_window() -> void:
	_attack_startup_counter = attack_startup_delay
	_attack_active_counter = attack_active_duration
	_set_hitbox_active(false)


func tick_attack_window(delta: float) -> void:
	if _attack_hitbox == null:
		return
	if _attack_startup_counter > 0.0:
		_attack_startup_counter = maxf(0.0, _attack_startup_counter - delta)
		if _attack_startup_counter > 0.0:
			return
	if _attack_active_counter > 0.0:
		_attack_active_counter = maxf(0.0, _attack_active_counter - delta)
		_set_hitbox_active(_attack_active_counter > 0.0)
		return
	_set_hitbox_active(false)


func cancel_attack_window() -> void:
	_attack_startup_counter = 0.0
	_attack_active_counter = 0.0
	_set_hitbox_active(false)


func has_attack_window_in_progress() -> bool:
	var attack_active := false
	if _attack_box is Attack:
		attack_active = (_attack_box as Attack).monitoring
	elif _attack_hitbox != null:
		attack_active = not _attack_hitbox.disabled
	return _attack_startup_counter > 0.0 \
		or _attack_active_counter > 0.0 \
		or attack_active


func _set_hitbox_active(active: bool) -> void:
	if _attack_box is Attack:
		var attack := _attack_box as Attack
		attack.damage = attack_damage
		if attack.monitoring != active:
			attack.set_active(active)
	elif _attack_hitbox != null:
		_attack_hitbox.set_deferred("disabled", not active)


# ----- Chase 接口（被状态机调用） --------------------------------------------

func get_attack_range() -> float:
	return attack_range


func get_attack_interval() -> float:
	return attack_interval


func get_attack_horizontal_tolerance() -> float:
	return attack_horizontal_tolerance


func get_attack_vertical_tolerance() -> float:
	return attack_vertical_tolerance


func get_post_attack_retreat_duration() -> float:
	return post_attack_retreat_duration


func get_retreat_speed_multiplier() -> float:
	return retreat_speed_multiplier


func get_attack_target_position(target: Node2D) -> Vector2:
	if target == null:
		return global_position
	return Vector2(target.global_position.x, target.global_position.y - attack_hover_height)


func get_chase_target_position(target: Node2D) -> Vector2:
	if target == null:
		return global_position
	return Vector2(target.global_position.x, target.global_position.y - chase_hover_height)


func get_retreat_target_position(target: Node2D, retreat_direction: int) -> Vector2:
	if target == null:
		return global_position
	var dir := retreat_direction
	if dir == 0:
		dir = 1 if global_position.x >= target.global_position.x else -1
	return Vector2(
			target.global_position.x + dir * 80.0,
			target.global_position.y - retreat_hover_height)
