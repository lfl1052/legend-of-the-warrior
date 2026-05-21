class_name FadeCanvas
extends CanvasLayer
## 全屏淡入淡出（替代 Unity 项目里的 FadeCanvas.cs）
##
## 监听 GameEvents.fade_requested(target_color, duration, fade_in)：
## 通过覆盖整个屏幕的 ColorRect 调整 modulate.a 实现淡入淡出。
## 期间不阻塞输入。

@export_node_path("ColorRect") var fade_rect_path: NodePath
var _fade_rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 100
	if fade_rect_path != NodePath():
		_fade_rect = get_node_or_null(fade_rect_path) as ColorRect
	if _fade_rect == null:
		_fade_rect = ColorRect.new()
		_fade_rect.color = Color(0, 0, 0, 0)
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_fade_rect)
	_fade_rect.color.a = 0.0
	if not GameEvents.fade_requested.is_connected(_on_fade_requested):
		GameEvents.fade_requested.connect(_on_fade_requested)


func _on_fade_requested(target_color: Color, duration: float, fade_in: bool) -> void:
	if _fade_rect == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()

	# fade_in=true 表示从黑屏淡入到亮（透明）；false 表示淡出到 target_color
	var goal := target_color
	if fade_in:
		goal = Color(target_color.r, target_color.g, target_color.b, 0.0)

	if duration <= 0.0:
		_fade_rect.color = goal
		return

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_fade_rect, "color", goal, duration)
