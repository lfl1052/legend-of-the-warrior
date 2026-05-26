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
@export var shake_strength: float = 8.0
@export var shake_duration: float = 0.25

var _shake_time_left: float = 0.0
var _shake_strength: float = 0.0
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


func _process(delta: float) -> void:
	if follow_player:
		var players := get_tree().get_nodes_in_group(&"player")
		if not players.is_empty() and players[0] is Node2D:
			var target: Vector2 = (players[0] as Node2D).global_position
			global_position = global_position.lerp(target, clampf(delta * follow_lerp, 0.0, 1.0))

	if _has_bounds:
		var half: Vector2 = get_viewport_rect().size * 0.5 / maxf(zoom.x, 0.0001)
		var min_pos: Vector2 = _bounds.position + half
		var max_pos: Vector2 = _bounds.position + _bounds.size - half
		if min_pos.x <= max_pos.x:
			global_position.x = clampf(global_position.x, min_pos.x, max_pos.x)
		if min_pos.y <= max_pos.y:
			global_position.y = clampf(global_position.y, min_pos.y, max_pos.y)

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
