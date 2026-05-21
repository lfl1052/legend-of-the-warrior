extends Node
## UI 管理器（替代 Unity 项目里的 UIManager）
##
## 角色：
##   1. 维护一个根 CanvasLayer，承载常驻 UI（暂停菜单、淡入淡出层、HUD）。
##   2. 提供 register / get / show / hide 等 API。
##   3. 监听暂停事件并切换 process_mode。

signal ui_pause_state_changed(is_paused: bool)

const HUD_LAYER := 10
const FADE_LAYER := 100

var _registered: Dictionary = {}    # name -> Control
var _is_paused: bool = false
var _root_layer: CanvasLayer


func _ready() -> void:
	_root_layer = CanvasLayer.new()
	_root_layer.name = "UIRootLayer"
	_root_layer.layer = HUD_LAYER
	add_child(_root_layer)

	GameEvents.pause_toggled.connect(_on_pause_toggled)


# ----- 注册接口 -----------------------------------------------------------------

func register(ui_name: StringName, ui_node: Control) -> void:
	if ui_node == null:
		return
	_registered[ui_name] = ui_node


func unregister(ui_name: StringName) -> void:
	_registered.erase(ui_name)


func get_ui(ui_name: StringName) -> Control:
	return _registered.get(ui_name, null)


func get_root_layer() -> CanvasLayer:
	return _root_layer


# ----- 操作 ---------------------------------------------------------------------

func show_ui(ui_name: StringName) -> void:
	var ui := get_ui(ui_name)
	if ui != null:
		ui.show()


func hide_ui(ui_name: StringName) -> void:
	var ui := get_ui(ui_name)
	if ui != null:
		ui.hide()


func is_paused() -> bool:
	return _is_paused


# ----- 内部 ---------------------------------------------------------------------

func _on_pause_toggled() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	ui_pause_state_changed.emit(_is_paused)
