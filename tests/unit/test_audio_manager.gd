extends GdUnitTestSuite

const AUDIO_MANAGER_SCRIPT := preload("res://scripts/autoload/audio_manager.gd")

var _manager: Node


func before_test() -> void:
	_manager = auto_free(AUDIO_MANAGER_SCRIPT.new())
	add_child(_manager)
	await get_tree().process_frame


func after_test() -> void:
	_manager = null


func test_audio_manager_provides_at_least_five_placeholder_sfx() -> void:
	var ids: Array = _manager.get_available_sfx_ids()

	assert_bool(ids.has(&"attack")).is_true()
	assert_bool(ids.has(&"hurt")).is_true()
	assert_bool(ids.has(&"jump")).is_true()
	assert_bool(ids.has(&"chest_open")).is_true()
	assert_bool(ids.has(&"breakable_break")).is_true()
	assert_int(ids.size()).is_greater_equal(5)


func test_audio_manager_play_sfx_id_uses_fx_volume() -> void:
	_manager.set_fx_volume(0.25)

	_manager.play_sfx_id(&"attack", Vector2(12.0, 4.0))

	var slot: AudioStreamPlayer = _manager.get_debug_last_fx_player()
	assert_object(slot.stream).is_not_null()
	assert_float(db_to_linear(slot.volume_db)).is_equal_approx(0.25, 0.01)


func test_audio_manager_bgm_id_uses_separate_volume_and_looping_stream() -> void:
	_manager.set_fx_volume(0.2)
	_manager.set_bgm_volume(0.65)

	_manager.play_bgm_id(&"demo_theme", 0.0)

	var player: AudioStreamPlayer = _manager.get_debug_bgm_player()
	assert_object(player.stream).is_not_null()
	assert_float(db_to_linear(player.volume_db)).is_equal_approx(0.65, 0.01)
	assert_float(db_to_linear(_manager.get_debug_last_fx_player().volume_db)).is_not_equal(0.65)


func test_audio_manager_placeholder_bgm_has_rhythmic_energy_changes() -> void:
	_manager.play_bgm_id(&"demo_theme", 0.0)

	var player: AudioStreamPlayer = _manager.get_debug_bgm_player()
	var stream := player.stream as AudioStreamWAV
	assert_object(stream).is_not_null()
	assert_int(stream.loop_end).is_greater_equal(stream.mix_rate * 4)

	var energies := _measure_window_energy(stream, 0.25)
	var min_energy: float = energies[0]
	var max_energy: float = energies[0]
	for energy in energies:
		min_energy = minf(min_energy, energy)
		max_energy = maxf(max_energy, energy)

	assert_float(max_energy).is_greater(14.0)
	assert_float(min_energy).is_less(max_energy * 0.65)


func test_audio_manager_bgm_fade_duration_starts_from_silence() -> void:
	_manager.set_bgm_volume(0.6)

	_manager.play_bgm_id(&"demo_theme", 0.2)

	var player: AudioStreamPlayer = _manager.get_debug_bgm_player()
	assert_object(player.stream).is_not_null()
	assert_bool(db_to_linear(player.volume_db) <= 0.01).is_true()


func test_audio_manager_stop_all_clears_active_streams() -> void:
	_manager.play_sfx_id(&"attack")
	_manager.play_bgm_id(&"demo_theme", 0.0)

	_manager.stop_all()

	assert_object(_manager.get_debug_last_fx_player().stream).is_null()
	assert_object(_manager.get_debug_bgm_player().stream).is_null()


func test_audio_manager_shutdown_ignores_late_events() -> void:
	_manager.play_bgm_id(&"demo_theme", 0.0)

	_manager.shutdown_for_tests()
	_manager.play_bgm_id(&"demo_theme", 0.0)

	assert_object(_manager.get_debug_bgm_player()).is_null()
	assert_int(_manager.get_available_sfx_ids().size()).is_equal(0)


func _measure_window_energy(stream: AudioStreamWAV, window_seconds: float) -> Array[float]:
	var data := stream.data
	var window_size := maxi(1, int(float(stream.mix_rate) * window_seconds))
	var energies: Array[float] = []
	var start := 0
	while start < data.size():
		var end := mini(data.size(), start + window_size)
		var sum := 0.0
		for i in range(start, end):
			sum += absf(float(data[i]) - 127.5)
		energies.append(sum / float(end - start))
		start = end
	return energies
