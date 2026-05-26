class_name MainMenu
extends Control
## 主菜单（替代 Unity 项目里的 Menu.cs）
##
## 三个按钮：新游戏 / 继续 / 退出，外加一个音量 Slider。
## - 新游戏：发出 GameEvents.new_game_started 让 DataManager 进入新存档流程
## - 继续：仅当 user://SAVE_DATA/data.sav 存在时可点，发出 load_data_requested
## - 退出：调用 get_tree().quit()
## 音量 Slider 双向同步：onValueChanged 广播 volume_changed，外部 volume_synced
## 触发时把值反向回填。

@export_node_path("Button") var new_game_button_path: NodePath
@export_node_path("Button") var continue_button_path: NodePath
@export_node_path("Button") var exit_button_path: NodePath
@export_node_path("Slider") var volume_slider_path: NodePath

const _CONTINUE_DISABLED_ALPHA := 0.55

var _new_game_button: Button
var _continue_button: Button
var _exit_button: Button
var _volume_slider: Slider


func _ready() -> void:
	_new_game_button = get_node_or_null(new_game_button_path) as Button
	_continue_button = get_node_or_null(continue_button_path) as Button
	_exit_button = get_node_or_null(exit_button_path) as Button
	_volume_slider = get_node_or_null(volume_slider_path) as Slider

	if _new_game_button != null and not _new_game_button.pressed.is_connected(_on_new_game):
		_new_game_button.pressed.connect(_on_new_game)
	if _continue_button != null and not _continue_button.pressed.is_connected(_on_continue):
		_continue_button.pressed.connect(_on_continue)
	if _exit_button != null and not _exit_button.pressed.is_connected(_on_exit):
		_exit_button.pressed.connect(_on_exit)
	if _volume_slider != null and not _volume_slider.value_changed.is_connected(_on_volume_changed):
		_volume_slider.value_changed.connect(_on_volume_changed)
	if not GameEvents.volume_synced.is_connected(_on_volume_synced):
		GameEvents.volume_synced.connect(_on_volume_synced)

	_refresh_continue_state()
	_select_default_button()


func _on_new_game() -> void:
	GameEvents.raise_new_game_started()


func _on_continue() -> void:
	if DataManager.has_saved_game():
		GameEvents.raise_load_data_requested()


func _on_exit() -> void:
	get_tree().quit()


func _on_volume_changed(value: float) -> void:
	GameEvents.raise_volume_changed(clampf(value, 0.0, 1.0))


func _on_volume_synced(value: float) -> void:
	if _volume_slider != null:
		_volume_slider.set_value_no_signal(value)


func _refresh_continue_state() -> void:
	if _continue_button == null:
		return
	var has_save := DataManager.has_saved_game()
	_continue_button.disabled = not has_save
	_continue_button.modulate.a = 1.0 if has_save else _CONTINUE_DISABLED_ALPHA


func _select_default_button() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var target: Button = null
	if _continue_button != null and not _continue_button.disabled:
		target = _continue_button
	elif _new_game_button != null:
		target = _new_game_button
	elif _exit_button != null:
		target = _exit_button
	if target != null and target.is_inside_tree():
		target.grab_focus()
