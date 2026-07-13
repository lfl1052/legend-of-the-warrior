class_name CameraControl
extends Camera2D
## 主相机（替代 Unity 项目里的 CameraControl.cs / Cinemachine 配置）
##
## 功能：
##   - 监听 GameEvents.camera_shake，做一次小幅噪声晃动
##   - 监听 GameEvents.after_scene_loaded，按 &"camera_bounds" 组的 Area2D
##     更新跟随限制框（替代 Cinemachine Confiner2D）
##   - 跟随 &"player" 组里的第一个节点

@export var follow_player: bool = true
@export var follow_lerp: float = 8.0
@export var look_ahead_distance: float = 72.0
@export var look_ahead_response: float = 360.0
@export var vertical_offset: float = -64.0
@export var dead_zone: Vector2 = Vector2(48.0, 24.0)
@export var shake_strength: float = 8.0
@export var shake_duration: float = 0.25

var _shake_time_left: float = 0.0
var _shake_strength: float = 0.0
var _look_ahead_x: float = 0.0
var _bounds: Rect2 = Rect2()
var _has_bounds: bool = false


func _ready() -> void:
	if not GameEvents.camera_shake.is_connected(_on_camera_shake):
		GameEvents.camera_shake.connect(_on_camera_shake)
	if not GameEvents.camera_shake_requested.is_connected(_on_camera_shake_requested):
		GameEvents.camera_shake_requested.connect(_on_camera_shake_requested)
	if not GameEvents.after_scene_loaded.is_connected(_on_after_scene_loaded):
		GameEvents.after_scene_loaded.connect(_on_after_scene_loaded)
	make_current()
	_refresh_bounds()
	if follow_player:
		_snap_to_follow_target()


func _physics_process(delta: float) -> void:
	if not follow_player:
		return
	var player := _player()
	if player == null:
		return

	var direction := 0.0
	if player is CharacterBody2D:
		direction = signf((player as CharacterBody2D).velocity.x)
	var look_ahead_target := direction * look_ahead_distance
	_look_ahead_x = move_toward(
		_look_ahead_x,
		look_ahead_target,
		look_ahead_response * delta)

	var desired := player.global_position + Vector2(_look_ahead_x, vertical_offset)
	var dead_zone_target := _dead_zone_corrected_position(global_position, desired)
	var follow_weight := 1.0 - exp(-maxf(0.0, follow_lerp) * delta)
	global_position = global_position.lerp(dead_zone_target, follow_weight)
	global_position = _clamp_position_to_bounds(global_position)


func _process(delta: float) -> void:

	if _shake_time_left > 0.0:
		_shake_time_left -= delta
		var t := clampf(_shake_time_left / max(shake_duration, 0.0001), 0.0, 1.0)
		offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * _shake_strength * t
		if _shake_time_left <= 0.0:
			offset = Vector2.ZERO


func _on_camera_shake() -> void:
	_shake_time_left = shake_duration
	_shake_strength = shake_strength


func _on_camera_shake_requested(strength: float, duration: float) -> void:
	_shake_time_left = maxf(0.0, duration)
	_shake_strength = shake_strength * maxf(0.0, strength)


func _on_after_scene_loaded() -> void:
	_refresh_bounds()
	if follow_player:
		_snap_to_follow_target()


func _refresh_bounds() -> void:
	_has_bounds = false
	for node in get_tree().get_nodes_in_group(&"camera_bounds"):
		if node is Node2D:
			var aabb := _node_aabb(node)
			if aabb.size != Vector2.ZERO:
				_bounds = aabb
				_has_bounds = true
				return


func _node_aabb(node: Node2D) -> Rect2:
	# Area2D / StaticBody2D 等带有 CollisionShape2D 的节点：用第一个矩形子节点作为限制框
	for child in node.get_children():
		if child is CollisionShape2D and (child as CollisionShape2D).shape is RectangleShape2D:
			var rect := (child as CollisionShape2D).shape as RectangleShape2D
			var origin: Vector2 = node.global_position - rect.size * 0.5
			return Rect2(origin, rect.size)
	return Rect2(node.global_position, Vector2.ZERO)


func _player() -> Node2D:
	var players := get_tree().get_nodes_in_group(&"player")
	if players.is_empty() or not players[0] is Node2D:
		return null
	return players[0] as Node2D


func _snap_to_follow_target() -> void:
	var player := _player()
	if player == null:
		return
	_look_ahead_x = 0.0
	global_position = _clamp_position_to_bounds(
		player.global_position + Vector2(0.0, vertical_offset))


func _dead_zone_corrected_position(current: Vector2, desired: Vector2) -> Vector2:
	var corrected := current
	var difference := desired - current
	if absf(difference.x) > dead_zone.x:
		corrected.x = desired.x - signf(difference.x) * dead_zone.x
	if absf(difference.y) > dead_zone.y:
		corrected.y = desired.y - signf(difference.y) * dead_zone.y
	return corrected


func _clamp_position_to_bounds(value: Vector2) -> Vector2:
	if not _has_bounds:
		return value
	var viewport_size := get_viewport_rect().size / Vector2(
		maxf(absf(zoom.x), 0.0001),
		maxf(absf(zoom.y), 0.0001))
	var half := viewport_size * 0.5
	var min_pos := _bounds.position + half
	var max_pos := _bounds.end - half
	var result := value
	if min_pos.x <= max_pos.x:
		result.x = clampf(result.x, min_pos.x, max_pos.x)
	if min_pos.y <= max_pos.y:
		result.y = clampf(result.y, min_pos.y, max_pos.y)
	return result
