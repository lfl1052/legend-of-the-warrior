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
var _overlay: GameplayOverlay
var _game_over_visible: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root_layer = CanvasLayer.new()
	_root_layer.name = "UIRootLayer"
	_root_layer.layer = HUD_LAYER
	add_child(_root_layer)
	_overlay = GameplayOverlay.new()
	_root_layer.add_child(_overlay)
	_overlay.pause_continue_pressed.connect(_on_pause_continue_pressed)
	_overlay.pause_menu_pressed.connect(_on_pause_menu_pressed)
	_overlay.game_over_restart_pressed.connect(_on_game_over_restart_pressed)
	_overlay.game_over_menu_pressed.connect(_on_game_over_menu_pressed)

	GameEvents.pause_toggled.connect(_on_pause_toggled)
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.after_scene_loaded.connect(_on_after_scene_loaded)


func _process(_delta: float) -> void:
	if not _game_over_visible and Input.is_action_just_pressed(&"pause") \
			and get_tree().get_first_node_in_group(&"player") != null:
		GameEvents.raise_pause_toggled()


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
	if _game_over_visible:
		return
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	if _is_paused:
		_overlay.show_pause()
	else:
		_overlay.hide_overlay()
	ui_pause_state_changed.emit(_is_paused)


func _on_pause_continue_pressed() -> void:
	GameEvents.raise_pause_toggled()


func _on_pause_menu_pressed() -> void:
	_unpause()
	GameEvents.raise_back_to_menu_requested()


func _on_game_over() -> void:
	_game_over_visible = true
	_is_paused = false
	get_tree().paused = true
	AudioManager.set_paused(true)
	_overlay.show_game_over()


func _on_game_over_restart_pressed() -> void:
	_unpause()
	_game_over_visible = false
	GameEvents.raise_restart_requested()


func _on_game_over_menu_pressed() -> void:
	_unpause()
	_game_over_visible = false
	GameEvents.raise_back_to_menu_requested()


func _on_after_scene_loaded() -> void:
	_game_over_visible = false
	_unpause()
	_overlay.hide_overlay()


func _unpause() -> void:
	_is_paused = false
	get_tree().paused = false
	AudioManager.set_paused(false)
