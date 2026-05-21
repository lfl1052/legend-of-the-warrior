extends GdUnitTestSuite
## GameEvents 信号总线单元测试
##
## 测试范围：
##   - 信号确实存在（GDScript 类型安全）
##   - raise_xxx 方法可调用
##   - 信号连接可触发回调

var _events: Node


func before_test() -> void:
	# 使用全局 autoload 引用
	_events = GameEvents


func after_test() -> void:
	_events = null


# ----- 信号存在性（确保信号未被意外删除） --------------------------------------

func test_game_events_has_flow_signals() -> void:
	assert_bool(_events.has_signal("new_game_started")).is_true()
	assert_bool(_events.has_signal("save_data_requested")).is_true()
	assert_bool(_events.has_signal("load_data_requested")).is_true()
	assert_bool(_events.has_signal("back_to_menu_requested")).is_true()
	assert_bool(_events.has_signal("game_over")).is_true()
	assert_bool(_events.has_signal("after_scene_loaded")).is_true()
	assert_bool(_events.has_signal("camera_shake")).is_true()
	assert_bool(_events.has_signal("pause_toggled")).is_true()


func test_game_events_has_audio_signals() -> void:
	assert_bool(_events.has_signal("play_bgm")).is_true()
	assert_bool(_events.has_signal("play_fx")).is_true()
	assert_bool(_events.has_signal("volume_changed")).is_true()
	assert_bool(_events.has_signal("volume_synced")).is_true()


func test_game_events_has_character_signals() -> void:
	assert_bool(_events.has_signal("character_health_changed")).is_true()
	assert_bool(_events.has_signal("character_took_damage")).is_true()
	assert_bool(_events.has_signal("character_died")).is_true()


func test_game_events_has_scene_signals() -> void:
	assert_bool(_events.has_signal("scene_load_requested")).is_true()
	assert_bool(_events.has_signal("scene_unloaded")).is_true()
	assert_bool(_events.has_signal("fade_requested")).is_true()


func test_game_events_has_encounter_signals() -> void:
	assert_bool(_events.has_signal("encounter_focus_changed")).is_true()
	assert_bool(_events.has_signal("encounter_phase_changed")).is_true()
	assert_bool(_events.has_signal("encounter_poise_changed")).is_true()
	assert_bool(_events.has_signal("encounter_skill_cooldown_changed")).is_true()


func test_game_events_has_reward_signal() -> void:
	assert_bool(_events.has_signal("reward_notification")).is_true()


# ----- raise 方法连通性 -------------------------------------------------------

func test_raise_new_game_emits_signal() -> void:
	# Arrange
	var received := false
	var on_received := func() -> void: received = true
	_events.new_game_started.connect(on_received)
	# Act
	_events.raise_new_game_started()
	# Assert
	assert_bool(received).is_true()
	_events.new_game_started.disconnect(on_received)


func test_raise_volume_changed_emits_with_amount() -> void:
	# Arrange
	var received_value: float = -1.0
	var on_received := func(amount: float) -> void: received_value = amount
	_events.volume_changed.connect(on_received)
	# Act
	_events.raise_volume_changed(0.75)
	# Assert
	assert_float(received_value).is_equal(0.75)
	_events.volume_changed.disconnect(on_received)
