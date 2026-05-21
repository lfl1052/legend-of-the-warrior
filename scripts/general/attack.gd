class_name Attack
extends Area2D
## 攻击体（替代 Unity 项目里的 Attack）
##
## 设计：
##   - 玩家攻击：one-shot，进入触发即造成伤害（per_target_one_hit = true）
##   - 敌人攻击：repeat，按 attack_rate 周期造成伤害
##
## 命中目标需要满足：节点拥有 take_damage(attacker:Node) 方法或属于 "damageable" 组。

@export var damage: int = 1
@export var attack_range: float = 0.25
@export var attack_rate: float = 1.0
@export var per_target_one_hit: bool = false       # true = 玩家用，false = 敌人用

var _cooldowns: Dictionary = {}                    # target_instance_id -> 下次可击时间戳


func _ready() -> void:
	body_entered.connect(_on_target_entered)
	area_entered.connect(_on_target_entered)
	if not per_target_one_hit:
		body_exited.connect(_on_target_exited)
		area_exited.connect(_on_target_exited)
		# 与 Unity OnTriggerStay 等价：每物理帧持续触发
		set_physics_process(true)
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	if per_target_one_hit:
		return
	# 重复攻击模式：定时扫描所有当前在攻击范围里的目标
	for body in get_overlapping_bodies():
		_try_apply_damage(body)
	for area in get_overlapping_areas():
		_try_apply_damage(area)


func _on_target_entered(target: Node) -> void:
	_try_apply_damage(target)


func _on_target_exited(target: Node) -> void:
	if target == null:
		return
	_cooldowns.erase(target.get_instance_id())


func _try_apply_damage(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not _is_damageable(target):
		return
	var id := target.get_instance_id()
	var now := Time.get_ticks_msec() / 1000.0
	if per_target_one_hit:
		if _cooldowns.has(id):
			return
		_cooldowns[id] = INF
	else:
		var next_time: float = _cooldowns.get(id, 0.0)
		if now < next_time:
			return
		_cooldowns[id] = now + attack_rate

	if target.has_method("take_damage"):
		target.call("take_damage", get_parent())


func _is_damageable(target: Node) -> bool:
	return target.has_method("take_damage") or target.is_in_group(&"damageable")
