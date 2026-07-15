class_name GameplayOverlay
extends Control

signal pause_continue_pressed
signal pause_menu_pressed
signal game_over_restart_pressed
signal game_over_menu_pressed

var _dim: ColorRect
var _game_over_panel: PanelContainer
var _pause_panel: PanelContainer
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_overlay()
	hide_overlay()


func show_game_over() -> void:
	_game_over_panel.visible = true
	_pause_panel.visible = false
	visible = true
	_dim.color = Color(0.015, 0.02, 0.04, 0.78)
	(_game_over_panel.get_node("Content/Restart") as Button).grab_focus()


func show_pause() -> void:
	_pause_panel.visible = true
	_game_over_panel.visible = false
	visible = true
	_dim.color = Color(0.015, 0.02, 0.04, 0.68)
	(_pause_panel.get_node("Content/Continue") as Button).grab_focus()
	_sync_audio_sliders()


func hide_overlay() -> void:
	visible = false
	_game_over_panel.visible = false
	_pause_panel.visible = false


func _build_overlay() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.015, 0.02, 0.04, 0.78)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_game_over_panel = _make_panel("GameOverPanel", "你已倒下", "选择继续冒险或返回主菜单")
	_game_over_panel.get_node("Content/Restart").pressed.connect(func() -> void:
		game_over_restart_pressed.emit())
	_game_over_panel.get_node("Content/Menu").pressed.connect(func() -> void:
		game_over_menu_pressed.emit())
	_add_centered_panel(_game_over_panel)

	_pause_panel = _make_panel("PausePanel", "游戏暂停", "调整设置或继续冒险")
	var content := _pause_panel.get_node("Content") as VBoxContainer
	var restart_button := content.get_node("Restart") as Button
	restart_button.name = "Continue"
	restart_button.text = "继续游戏"
	restart_button.pressed.connect(func() -> void: pause_continue_pressed.emit())
	var menu_button := content.get_node("Menu") as Button
	menu_button.name = "Menu"
	menu_button.text = "返回主菜单"
	menu_button.pressed.connect(func() -> void: pause_menu_pressed.emit())
	_master_slider = _add_slider(content, "主音量")
	_music_slider = _add_slider(content, "音乐音量")
	_sfx_slider = _add_slider(content, "音效音量")
	_master_slider.value_changed.connect(_on_master_volume_changed)
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	_add_centered_panel(_pause_panel)


func _make_panel(panel_name: String, title: String, subtitle: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size = Vector2(360.0, 292.0) if panel_name == "PausePanel" else Vector2(320.0, 220.0)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24 if panel_name == "PausePanel" else 28)
	content.add_child(heading)
	var hint := Label.new()
	hint.text = subtitle
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	content.add_child(hint)
	var restart := Button.new()
	restart.name = "Restart"
	restart.text = "重新开始"
	restart.custom_minimum_size.y = 30.0
	content.add_child(restart)
	var menu := Button.new()
	menu.name = "Menu"
	menu.text = "返回主菜单"
	menu.custom_minimum_size.y = 30.0
	content.add_child(menu)
	return panel


func _add_centered_panel(panel: PanelContainer) -> void:
	var center := CenterContainer.new()
	center.name = panel.name + "Center"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(panel)


func _add_slider(content: VBoxContainer, label_text: String) -> HSlider:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	content.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size.y = 18.0
	content.add_child(slider)
	return slider


func _sync_audio_sliders() -> void:
	_master_slider.set_value_no_signal(AudioManager.get_master_volume())
	_music_slider.set_value_no_signal(AudioManager.get_bgm_volume())
	_sfx_slider.set_value_no_signal(AudioManager.get_sfx_volume())


func _on_master_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(value)


func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_bgm_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_fx_volume(value)
