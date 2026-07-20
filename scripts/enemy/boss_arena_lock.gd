class_name BossArenaLock
extends Node
## 将 Boss 的交战状态转换为真实物理门锁；门锁本身不参与战斗规则。

@export_node_path("BossEnemy") var boss_path: NodePath
@export var gate_paths: Array[NodePath] = []
@export var gate_visual_paths: Array[NodePath] = []

var _boss: BossEnemy
var _is_locked: bool = true


func _ready() -> void:
	_boss = get_node_or_null(boss_path) as BossEnemy
	if _boss != null:
		if not _boss.arena_engaged.is_connected(_on_boss_engaged):
			_boss.arena_engaged.connect(_on_boss_engaged)
		if not _boss.arena_completed.is_connected(_on_boss_completed):
			_boss.arena_completed.connect(_on_boss_completed)
	set_locked(false)


func set_locked(locked: bool) -> void:
	if _is_locked == locked:
		return
	_is_locked = locked
	for path in gate_paths:
		_set_gate_enabled(get_node_or_null(path) as StaticBody2D, locked)
	for path in gate_visual_paths:
		var visual := get_node_or_null(path) as CanvasItem
		if visual != null:
			visual.visible = locked


func is_locked() -> bool:
	return _is_locked


func _on_boss_engaged() -> void:
	set_locked(true)


func _on_boss_completed() -> void:
	set_locked(false)


func _set_gate_enabled(gate: StaticBody2D, enabled: bool) -> void:
	if gate == null:
		return
	gate.collision_layer = 1 if enabled else 0
	for child in gate.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not enabled)
