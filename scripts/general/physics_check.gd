class_name PhysicsCheck
extends Node2D
## 物理检测组件（替代 Unity 项目里的 PhysicsCheck）
##
## 提供三处 OverlapCircle 风格的检测：
##   - is_ground   底部
##   - touch_left  左侧
##   - touch_right 右侧
##
## Godot 2D 没有 OverlapCircle，但 PhysicsServer2D 的 intersect_shape 等价。
## 默认从父节点的 CollisionShape2D / CapsuleShape2D 推导偏移。

@export var ground_layer: int = 0xFFFFFFFF       # 默认所有层
@export var wall_layer: int = 0xFFFFFFFF
@export var check_radius: float = 0.2

@export var bottom_offset: Vector2 = Vector2.ZERO
@export var left_offset: Vector2 = Vector2.ZERO
@export var right_offset: Vector2 = Vector2.ZERO
@export var front_ground_offset: Vector2 = Vector2.ZERO
@export var auto_derive_offsets: bool = true

var is_ground: bool = false
var touch_left: bool = false
var touch_right: bool = false
var front_is_ground: bool = false

var _query: PhysicsShapeQueryParameters2D
var _shape: CircleShape2D


func _ready() -> void:
	_shape = CircleShape2D.new()
	_shape.radius = check_radius
	_query = PhysicsShapeQueryParameters2D.new()
	_query.shape = _shape
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	if auto_derive_offsets:
		_derive_offsets_from_parent()


func _physics_process(_delta: float) -> void:
	_shape.radius = check_radius
	is_ground = _check(bottom_offset, ground_layer)
	touch_left = _check(left_offset, wall_layer)
	touch_right = _check(right_offset, wall_layer)
	front_is_ground = has_ground_ahead(1)


func _check(local_offset: Vector2, mask: int) -> bool:
	var space := get_world_2d().direct_space_state
	if space == null:
		return false
	_query.transform = Transform2D(0.0, global_position + local_offset)
	_query.collision_mask = mask
	# 排除自己所在的物理层
	var parent := get_parent()
	if parent is PhysicsBody2D:
		_query.exclude = [parent.get_rid()]
	return not space.intersect_shape(_query, 1).is_empty()


func has_ground_ahead(direction: int) -> bool:
	var dir := -1 if direction < 0 else 1
	var offset := front_ground_offset
	if offset == Vector2.ZERO:
		offset = bottom_offset + Vector2(check_radius * 2.0, 0.0)
	offset.x = absf(offset.x) * dir
	return _check(offset, ground_layer)


func touches_wall_in_direction(direction: int) -> bool:
	if direction < 0:
		return touch_left
	return touch_right


func should_turn_for_patrol(direction: int) -> bool:
	return touches_wall_in_direction(direction) or not has_ground_ahead(direction)


func _derive_offsets_from_parent() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var collider: CollisionShape2D = null
	for child in parent.get_children():
		if child is CollisionShape2D:
			collider = child
			break
	if collider == null or collider.shape == null:
		return
	var size := Vector2.ZERO
	var shape := collider.shape
	if shape is CapsuleShape2D:
		size = Vector2(shape.radius, shape.height * 0.5)
	elif shape is RectangleShape2D:
		size = shape.size * 0.5
	elif shape is CircleShape2D:
		size = Vector2(shape.radius, shape.radius)
	bottom_offset = collider.position + Vector2(0.0, size.y)
	left_offset = collider.position + Vector2(-size.x, 0.0)
	right_offset = collider.position + Vector2(size.x, 0.0)
	front_ground_offset = collider.position + Vector2(size.x + check_radius * 1.5, size.y + check_radius)
