extends Node
## 音频管理器（替代 Unity 项目里的 AudioManager + AudioMixer）
##
## 功能：
##   1. 维持一个 BGM 播放器（背景音乐，循环）
##   2. 维持一个 FX 播放池（短促音效，按需播放）
##   3. 通过总线 "Master" 调整音量
##   4. 监听 GameEvents.play_bgm / play_fx / volume_changed / pause_toggled

const FX_POOL_SIZE := 8
const MASTER_BUS := &"Master"

var _bgm_player: AudioStreamPlayer
var _fx_pool: Array[AudioStreamPlayer] = []
var _is_paused: bool = false


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = String(MASTER_BUS)
	_bgm_player.autoplay = false
	add_child(_bgm_player)

	for i in FX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = String(MASTER_BUS)
		add_child(p)
		_fx_pool.append(p)

	GameEvents.play_bgm.connect(_on_play_bgm)
	GameEvents.play_fx.connect(_on_play_fx)
	GameEvents.volume_changed.connect(_on_volume_changed)
	GameEvents.pause_toggled.connect(_on_pause_toggled)
	GameEvents.after_scene_loaded.connect(_on_after_scene_loaded)


# ----- 事件 ---------------------------------------------------------------------

func _on_play_bgm(stream: AudioStream) -> void:
	if stream == null:
		_bgm_player.stop()
		return
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.play()


func _on_play_fx(stream: AudioStream, _world_pos: Vector2) -> void:
	if stream == null:
		return
	var slot := _next_free_fx_slot()
	slot.stream = stream
	slot.play()


func _on_volume_changed(amount: float) -> void:
	var bus_idx := AudioServer.get_bus_index(MASTER_BUS)
	if bus_idx < 0:
		return
	var clamped := clampf(amount, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamped))
	GameEvents.raise_volume_synced(amount)


func _on_pause_toggled() -> void:
	_is_paused = not _is_paused
	_bgm_player.stream_paused = _is_paused


func _on_after_scene_loaded() -> void:
	# 跳场景后重置 FX，BGM 由具体场景挂的触发器决定
	for p in _fx_pool:
		p.stop()


# ----- 内部 ---------------------------------------------------------------------

func _next_free_fx_slot() -> AudioStreamPlayer:
	for p in _fx_pool:
		if not p.playing:
			return p
	# 全在播 -> 复用第一个
	return _fx_pool[0]
