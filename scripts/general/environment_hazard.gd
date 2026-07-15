class_name EnvironmentHazard
extends Area2D
## 常驻环境伤害区。视觉与规则独立，伤害始终转发到目标现有 take_damage 入口。

@export var damage: float = 1.0
@export_range(0.1, 5.0, 0.05) var tick_interval: float = 0.75
@export var damage_on_enter: bool = true

var _cooldowns: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_target_entered)
	area_entered.connect(_on_target_entered)


func _physics_process(delta: float) -> void:
	for receiver in _cooldowns.keys():
		if not is_instance_valid(receiver):
			_cooldowns.erase(receiver)
			continue
		var remaining := float(_cooldowns[receiver]) - delta
		if remaining <= 0.0:
			_cooldowns.erase(receiver)
		else:
			_cooldowns[receiver] = remaining
	for body in get_overlapping_bodies():
		_try_damage_target(body)
	for area in get_overlapping_areas():
		_try_damage_target(area)


func bypasses_block() -> bool:
	return true


func _on_target_entered(target: Node) -> void:
	if damage_on_enter:
		_try_damage_target(target)


func _try_damage_target(target: Node) -> bool:
	var receiver := _resolve_damage_receiver(target)
	if receiver == null or _cooldowns.has(receiver):
		return false
	receiver.call("take_damage", self, damage)
	_cooldowns[receiver] = tick_interval
	return true


func _resolve_damage_receiver(target: Node) -> Node:
	if target == null:
		return null
	if target.has_method("get_damage_receiver"):
		var receiver := target.call("get_damage_receiver") as Node
		if receiver != null and receiver.has_method("take_damage"):
			return receiver
	if target.has_method("take_damage"):
		return target
	return null
