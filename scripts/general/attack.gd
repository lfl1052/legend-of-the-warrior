class_name Attack
extends Area2D

@export var damage: int = 1
@export var attack_range: float = 0.25
@export var attack_rate: float = 1.0
@export var per_target_one_hit: bool = false
@export var active_on_ready: bool = true
@export var feedback_enabled: bool = true
@export_range(0.0, 4.0, 0.05) var feedback_strength: float = 1.0
@export_range(0.0, 0.12, 0.005) var hitstop_duration: float = 0.035
@export_node_path("Node") var attacker_path: NodePath = ^".."

var _cooldowns: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_target_entered)
	area_entered.connect(_on_target_entered)
	body_exited.connect(_on_target_exited)
	area_exited.connect(_on_target_exited)
	set_physics_process(true)
	monitorable = false
	set_active(active_on_ready)


func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		_try_apply_damage(body)
	for area in get_overlapping_areas():
		_try_apply_damage(area)
	_hit_shape_intersections()


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
		target.call("take_damage", _resolve_attacker(), float(damage))
		_emit_hit_feedback(target)


func _is_damageable(target: Node) -> bool:
	return target.has_method("take_damage") or target.is_in_group(&"damageable")


func reset_hits() -> void:
	_cooldowns.clear()


func set_active(active: bool) -> void:
	monitoring = active
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", not active)
	if active:
		call_deferred("_hit_current_overlaps")


func _hit_current_overlaps() -> void:
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		_try_apply_damage(body)
	for area in get_overlapping_areas():
		_try_apply_damage(area)
	_hit_shape_intersections()


func _hit_shape_intersections() -> void:
	var space := get_world_2d().direct_space_state
	if space == null:
		return
	for child in get_children():
		var hitbox := child as CollisionShape2D
		if hitbox == null or hitbox.shape == null:
			continue
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = hitbox.shape
		query.transform = hitbox.global_transform
		query.collision_mask = collision_mask
		query.collide_with_bodies = true
		query.collide_with_areas = true
		for hit in space.intersect_shape(query, 16):
			var target: Node = hit.get("collider")
			if target != self:
				_try_apply_damage(target)


func _resolve_attacker() -> Node:
	var explicit_attacker := get_node_or_null(attacker_path)
	if explicit_attacker != null:
		return explicit_attacker
	return get_parent()


func _emit_hit_feedback(target: Node) -> void:
	if not feedback_enabled:
		return
	var hit_pos := global_position
	if target is Node2D:
		hit_pos = (target as Node2D).global_position
	GameEvents.raise_combat_hit_feedback(feedback_strength, hitstop_duration, hit_pos)
