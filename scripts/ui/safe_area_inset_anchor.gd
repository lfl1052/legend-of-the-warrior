class_name SafeAreaInsetAnchor
extends Control
## 安全区适配（替代 Unity 项目里的 SafeAreaInsetAnchor.cs）
##
## Godot 4.x 的 DisplayServer.screen_get_usable_rect() 提供了与 Unity
## Screen.safeArea 相似的"可用矩形"。把当前节点的 anchored 偏移按当前
## 屏幕的安全区进行调整。仅当锚点贴边（0 或 1）时生效。

@export var extra_padding: Vector2 = Vector2(16, 16)
@export var monitor_changes: bool = true

var _last_safe_area: Rect2i
var _last_screen_size: Vector2i
var _base_offset_left: float
var _base_offset_right: float
var _base_offset_top: float
var _base_offset_bottom: float
var _captured: bool = false


func _ready() -> void:
	_capture_base_offsets()
	_apply()


func _process(_delta: float) -> void:
	if not monitor_changes:
		return
	var screen := DisplayServer.window_get_size()
	var safe := DisplayServer.screen_get_usable_rect()
	if safe != _last_safe_area or screen != _last_screen_size:
		_apply()


func _capture_base_offsets() -> void:
	if _captured:
		return
	_base_offset_left = offset_left
	_base_offset_right = offset_right
	_base_offset_top = offset_top
	_base_offset_bottom = offset_bottom
	_captured = true


func _apply() -> void:
	if not _captured:
		_capture_base_offsets()
	var safe := DisplayServer.screen_get_usable_rect()
	var screen := DisplayServer.window_get_size()
	if screen.x <= 0 or screen.y <= 0:
		return

	var left_inset := float(safe.position.x)
	var top_inset := float(safe.position.y)
	var right_inset := float(screen.x - (safe.position.x + safe.size.x))
	var bottom_inset := float(screen.y - (safe.position.y + safe.size.y))

	if is_equal_approx(anchor_left, anchor_right):
		if is_equal_approx(anchor_left, 0.0) and left_inset > 0.0:
			offset_left = _base_offset_left + left_inset + extra_padding.x
		elif is_equal_approx(anchor_left, 1.0) and right_inset > 0.0:
			offset_right = _base_offset_right - (right_inset + extra_padding.x)
	if is_equal_approx(anchor_top, anchor_bottom):
		if is_equal_approx(anchor_top, 0.0) and top_inset > 0.0:
			offset_top = _base_offset_top + top_inset + extra_padding.y
		elif is_equal_approx(anchor_top, 1.0) and bottom_inset > 0.0:
			offset_bottom = _base_offset_bottom - (bottom_inset + extra_padding.y)

	_last_safe_area = safe
	_last_screen_size = screen
