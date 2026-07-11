extends Node

const FX_POOL_SIZE := 8
const MASTER_BUS := &"Master"
const DEFAULT_MASTER_VOLUME := 0.0
const DEFAULT_SFX_IDS := [
	&"attack",
	&"hurt",
	&"jump",
	&"chest_open",
	&"breakable_break",
]
const DEFAULT_BGM_IDS := [
	&"demo_theme",
]

var _bgm_player: AudioStreamPlayer
var _fx_pool: Array[AudioStreamPlayer] = []
var _is_paused: bool = false
var _sfx_volume: float = 0.8
var _bgm_volume: float = 0.55
var _sfx_library: Dictionary = {}
var _bgm_library: Dictionary = {}
var _last_fx_player: AudioStreamPlayer = null
var _audio_shutdown := false
var _disable_real_playback := false
var _bgm_fade_tween: Tween = null


func _ready() -> void:
	_disable_real_playback = DisplayServer.get_name() == "headless"
	_build_placeholder_library()
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = String(MASTER_BUS)
	_bgm_player.autoplay = false
	_bgm_player.volume_db = linear_to_db(_bgm_volume)
	add_child(_bgm_player)

	for i in FX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = String(MASTER_BUS)
		player.volume_db = linear_to_db(_sfx_volume)
		add_child(player)
		_fx_pool.append(player)
	if not _fx_pool.is_empty():
		_last_fx_player = _fx_pool[0]

	GameEvents.play_bgm.connect(_on_play_bgm)
	GameEvents.play_bgm_id.connect(_on_play_bgm_id)
	GameEvents.play_fx.connect(_on_play_fx)
	GameEvents.play_sfx.connect(_on_play_sfx)
	GameEvents.volume_changed.connect(_on_volume_changed)
	GameEvents.pause_toggled.connect(_on_pause_toggled)
	GameEvents.after_scene_loaded.connect(_on_after_scene_loaded)
	_set_master_volume(DEFAULT_MASTER_VOLUME)


func _exit_tree() -> void:
	_shutdown_audio()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_shutdown_audio()


func _on_play_bgm(stream: AudioStream) -> void:
	_play_bgm(stream, 0.0)


func _play_bgm(stream: AudioStream, fade_duration: float) -> void:
	if _audio_shutdown or _bgm_player == null:
		return
	if stream == null:
		_bgm_player.stop()
		return
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	if fade_duration > 0.0:
		_bgm_player.volume_db = linear_to_db(0.0001)
	else:
		_bgm_player.volume_db = linear_to_db(_bgm_volume)
	if not _disable_real_playback:
		_bgm_player.play()
	_start_bgm_fade(fade_duration)


func _on_play_bgm_id(bgm_id: StringName, fade_duration: float = 0.2) -> void:
	play_bgm_id(bgm_id, fade_duration)


func _on_play_fx(stream: AudioStream, _world_pos: Vector2) -> void:
	if _audio_shutdown or stream == null or _fx_pool.is_empty():
		return
	var slot := _next_free_fx_slot()
	slot.stream = stream
	slot.volume_db = linear_to_db(_sfx_volume)
	_last_fx_player = slot
	if not _disable_real_playback:
		slot.play()


func _on_play_sfx(sfx_id: StringName, world_pos: Vector2) -> void:
	play_sfx_id(sfx_id, world_pos)


func _on_volume_changed(amount: float) -> void:
	_set_master_volume(amount)


func _set_master_volume(amount: float) -> void:
	var bus_idx := AudioServer.get_bus_index(MASTER_BUS)
	if bus_idx < 0:
		return
	var normalized := clampf(amount, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_idx, is_zero_approx(normalized))
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(maxf(normalized, 0.0001)))
	GameEvents.raise_volume_synced(normalized)


func _on_pause_toggled() -> void:
	_is_paused = not _is_paused
	if _bgm_player != null:
		_bgm_player.stream_paused = _is_paused


func _on_after_scene_loaded() -> void:
	if _audio_shutdown:
		return
	for player in _fx_pool:
		player.stop()


func get_available_sfx_ids() -> Array:
	var ids: Array = []
	for key in _sfx_library.keys():
		ids.append(key)
	return ids


func set_fx_volume(amount: float) -> void:
	_sfx_volume = clampf(amount, 0.0001, 1.0)
	for player in _fx_pool:
		player.volume_db = linear_to_db(_sfx_volume)


func set_bgm_volume(amount: float) -> void:
	_bgm_volume = clampf(amount, 0.0001, 1.0)
	if _bgm_player != null:
		_bgm_player.volume_db = linear_to_db(_bgm_volume)


func play_sfx_id(sfx_id: StringName, world_pos: Vector2 = Vector2.ZERO) -> void:
	var stream := _sfx_library.get(sfx_id) as AudioStream
	if stream == null:
		return
	_on_play_fx(stream, world_pos)


func play_bgm_id(bgm_id: StringName, _fade_duration: float = 0.2) -> void:
	var stream := _bgm_library.get(bgm_id) as AudioStream
	_play_bgm(stream, _fade_duration)


func stop_all() -> void:
	_stop_playback(true)


func shutdown_for_tests() -> void:
	_shutdown_audio()


func get_debug_last_fx_player() -> AudioStreamPlayer:
	return _last_fx_player


func get_debug_bgm_player() -> AudioStreamPlayer:
	return _bgm_player


func _next_free_fx_slot() -> AudioStreamPlayer:
	for player in _fx_pool:
		if not player.playing:
			return player
	return _fx_pool[0]


func _build_placeholder_library() -> void:
	if not _sfx_library.is_empty():
		return
	var frequencies := {
		&"attack": 420.0,
		&"hurt": 180.0,
		&"jump": 620.0,
		&"chest_open": 520.0,
		&"breakable_break": 120.0,
	}
	for id in DEFAULT_SFX_IDS:
		_sfx_library[id] = _make_placeholder_wav(float(frequencies.get(id, 330.0)), 0.11, false)
	for id in DEFAULT_BGM_IDS:
		_bgm_library[id] = _make_placeholder_bgm_loop()


func _shutdown_audio() -> void:
	if _audio_shutdown:
		return
	_audio_shutdown = true
	if _bgm_fade_tween != null:
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null
	_stop_playback(true)
	if _bgm_player != null:
		_bgm_player.free()
		_bgm_player = null
	for player in _fx_pool:
		if player != null and is_instance_valid(player):
			player.free()
	_fx_pool.clear()
	_last_fx_player = null
	_sfx_library.clear()
	_bgm_library.clear()


func _stop_playback(clear_streams: bool) -> void:
	if _bgm_fade_tween != null:
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null
	if _bgm_player != null:
		_bgm_player.stop()
		if clear_streams:
			_bgm_player.stream = null
	for player in _fx_pool:
		if player != null:
			player.stop()
			if clear_streams:
				player.stream = null


func _start_bgm_fade(fade_duration: float) -> void:
	if _bgm_player == null:
		return
	if _bgm_fade_tween != null:
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null
	if fade_duration <= 0.0:
		_bgm_player.volume_db = linear_to_db(_bgm_volume)
		return
	if _disable_real_playback:
		return
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(_bgm_player, "volume_db", linear_to_db(_bgm_volume), fade_duration)


func _make_placeholder_wav(frequency: float, duration: float, loop: bool) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var sample_count: int = maxi(1, int(sample_rate * duration))
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(sample_count)
	for i in sample_count:
		var t: float = float(i) / float(sample_rate)
		var envelope: float = 1.0 if loop else 1.0 - (float(i) / float(sample_count))
		var wave: float = sin(TAU * frequency * t) * 0.35 * envelope
		bytes[i] = int(clampf((wave + 1.0) * 127.5, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream


func _make_placeholder_bgm_loop() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var bpm: float = 108.0
	var beat_seconds: float = 60.0 / bpm
	var beats: int = 16
	var sample_count: int = int(sample_rate * beat_seconds * float(beats))
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(sample_count)
	var bass_notes: Array[float] = [110.0, 110.0, 146.83, 130.81, 110.0, 164.81, 146.83, 98.0]
	var arp_notes: Array[float] = [440.0, 554.37, 659.25, 554.37, 392.0, 493.88, 587.33, 493.88]
	var melody_beats: Array[int] = [2, 3, 6, 7, 10, 11, 14, 15]
	var rest_beats: Array[int] = [7, 15]
	for i in sample_count:
		var t: float = float(i) / float(sample_rate)
		var beat_pos: float = t / beat_seconds
		var beat_floor: float = floor(beat_pos)
		var beat_index: int = int(beat_floor) % beats
		var beat_frac: float = beat_pos - beat_floor
		var half_beat_pos: float = beat_pos * 2.0
		var half_beat_floor: float = floor(half_beat_pos)
		var half_beat_index: int = int(half_beat_floor) % arp_notes.size()
		var half_frac: float = half_beat_pos - half_beat_floor

		var pulse: float = _decay_envelope(beat_frac, 0.18)
		var offbeat: float = _decay_envelope(fmod(beat_frac + 0.5, 1.0), 0.10)
		var bass: float = sin(TAU * bass_notes[beat_index % bass_notes.size()] * t) * 0.16 * pulse
		var kick: float = sin(TAU * 58.0 * t) * 0.22 * pulse
		var hat: float = _noise_sample(i) * 0.06 * offbeat

		var arp_gate: float = _decay_envelope(half_frac, 0.35)
		var melody_gate: float = 1.0 if melody_beats.has(beat_index) else 0.0
		var arp: float = sin(TAU * arp_notes[half_beat_index] * t) * 0.12 * arp_gate
		var melody: float = sin(TAU * arp_notes[(half_beat_index + 2) % arp_notes.size()] * t) * 0.08 * arp_gate * melody_gate

		var phrase_duck: float = 0.55 if rest_beats.has(beat_index) and beat_frac > 0.5 else 1.0
		var wave: float = (kick + bass + hat + arp + melody) * phrase_duck * 1.9
		bytes[i] = int(clampf((wave + 1.0) * 127.5, 0.0, 255.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func _decay_envelope(position: float, decay: float) -> float:
	if position < 0.0 or position > 1.0:
		return 0.0
	return exp(-position / maxf(decay, 0.001))


func _noise_sample(index: int) -> float:
	var n := int((index * 1103515245 + 12345) & 0x7fffffff)
	return (float(n % 2000) / 1000.0) - 1.0
