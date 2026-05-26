extends Node
## 全局事件总线（替代 Unity 项目里的 ScriptableObject EventChannel）
##
## 原 Unity 版本里有以下几类事件通道：
##   VoidEventSO        -> 无参信号
##   FloatEventSO       -> float 参数
##   PlayAudioEventSO   -> 播放一段 AudioStream
##   CharacterEventSO   -> 角色受击/血量变化等
##   FadeEventSO        -> 淡入淡出请求
##   SceneLoadEventSO   -> 场景加载请求/卸载完成
##
## 这里全部合并到一个 autoload 单例上，使用 Godot 信号机制驱动。

# === 流程类（VoidEventSO） =====================================================
signal new_game_started
signal save_data_requested
signal load_data_requested
signal back_to_menu_requested
signal game_over
signal after_scene_loaded
signal camera_shake
signal camera_shake_requested(strength: float, duration: float)
signal pause_toggled

# === 数值类（FloatEventSO） ====================================================
## 玩家或滑块拖动时实时改变音量
signal volume_changed(amount: float)
## 加载存档时同步给 UI 滑块
signal volume_synced(amount: float)

# === 音频类（PlayAudioEventSO） ================================================
signal play_bgm(stream: AudioStream)
signal play_bgm_id(bgm_id: StringName, fade_duration: float)
signal play_fx(stream: AudioStream, position: Vector2)
signal play_sfx(sfx_id: StringName, position: Vector2)

# === 角色事件（CharacterEventSO） ==============================================
## character: 任意拥有 max_health/current_health/max_power/current_power 的对象
signal character_health_changed(character: Object)
signal character_took_damage(character: Object, attacker: Node)
signal character_died(character: Object)
signal combat_hit_feedback_requested(strength: float, hitstop_duration: float, position: Vector2)

# === 淡入淡出（FadeEventSO） ===================================================
## fade_in = true 表示画面渐变到目标颜色（黑屏），false 表示从该颜色淡出
signal fade_requested(color: Color, duration: float, fade_in: bool)

# === 场景加载（SceneLoadEventSO） ==============================================
## scene_resource: GameSceneResource，position_to_go: Vector2/3，fade_screen: 是否需要淡入
signal scene_load_requested(scene_resource: Resource, position_to_go: Vector3, fade_screen: bool)
signal scene_unloaded(scene_resource: Resource, position_to_go: Vector3, fade_screen: bool)

# === UI / 进度反馈 =============================================================
signal reward_notification(reward_id: StringName, payload: Dictionary)
signal encounter_focus_changed(encounter_owner: Object)
signal encounter_phase_changed(encounter_owner: Object, phase_index: int)
signal encounter_poise_changed(encounter_owner: Object, ratio: float)
signal encounter_skill_cooldown_changed(encounter_owner: Object, skill_id: StringName, ratio: float)


# ----- 便捷方法（保持与 Unity 端 RaiseXxx 命名相近） --------------------------------

func raise_new_game() -> void:
	new_game_started.emit()


func raise_save_data() -> void:
	save_data_requested.emit()


func raise_load_data() -> void:
	load_data_requested.emit()


func raise_back_to_menu() -> void:
	back_to_menu_requested.emit()


func raise_game_over() -> void:
	game_over.emit()


func raise_after_scene_loaded() -> void:
	after_scene_loaded.emit()


func raise_camera_shake(strength: float = 1.0, duration: float = 0.2) -> void:
	camera_shake.emit()
	camera_shake_requested.emit(strength, duration)


func raise_pause_toggled() -> void:
	pause_toggled.emit()


func raise_volume_changed(amount: float) -> void:
	volume_changed.emit(amount)


func raise_volume_synced(amount: float) -> void:
	volume_synced.emit(amount)


func raise_play_bgm(stream: AudioStream) -> void:
	play_bgm.emit(stream)


func raise_play_bgm_id(bgm_id: StringName, fade_duration: float = 0.2) -> void:
	play_bgm_id.emit(bgm_id, fade_duration)


func raise_play_fx(stream: AudioStream, world_pos: Vector2 = Vector2.ZERO) -> void:
	play_fx.emit(stream, world_pos)


func raise_play_sfx(sfx_id: StringName, world_pos: Vector2 = Vector2.ZERO) -> void:
	play_sfx.emit(sfx_id, world_pos)


func raise_combat_hit_feedback(strength: float = 1.0, hitstop_duration: float = 0.035, world_pos: Vector2 = Vector2.ZERO) -> void:
	var safe_strength := maxf(0.0, strength)
	var safe_hitstop := clampf(hitstop_duration, 0.0, 0.12)
	combat_hit_feedback_requested.emit(safe_strength, safe_hitstop, world_pos)
	raise_camera_shake(safe_strength, 0.12 + safe_strength * 0.05)
	raise_play_sfx(&"attack", world_pos)
	_spawn_placeholder_hit_effect(world_pos, safe_strength)
	if safe_hitstop > 0.0:
		_start_hitstop(safe_hitstop)


func raise_character_health_changed(character: Object) -> void:
	character_health_changed.emit(character)


func raise_character_took_damage(character: Object, attacker: Node) -> void:
	character_took_damage.emit(character, attacker)


func raise_character_died(character: Object) -> void:
	character_died.emit(character)


func raise_fade_in(color: Color = Color.BLACK, duration: float = 0.4) -> void:
	fade_requested.emit(color, duration, true)


func raise_fade_out(color: Color = Color.BLACK, duration: float = 0.4) -> void:
	fade_requested.emit(color, duration, false)


func raise_scene_load_requested(scene_resource: Resource, position_to_go: Vector3, fade_screen: bool = true) -> void:
	scene_load_requested.emit(scene_resource, position_to_go, fade_screen)


func raise_scene_unloaded(scene_resource: Resource, position_to_go: Vector3, fade_screen: bool) -> void:
	scene_unloaded.emit(scene_resource, position_to_go, fade_screen)


func raise_reward_notification(reward_id: StringName, payload: Dictionary = {}) -> void:
	reward_notification.emit(reward_id, payload)


# ----- 命名别名（与 UI 调用点保持兼容） ----------------------------------------
func raise_new_game_started() -> void:
	new_game_started.emit()


func raise_load_data_requested() -> void:
	load_data_requested.emit()


func raise_save_data_requested() -> void:
	save_data_requested.emit()


func raise_back_to_menu_requested() -> void:
	back_to_menu_requested.emit()


func raise_encounter_focus_changed(source: Object) -> void:
	encounter_focus_changed.emit(source)


func raise_encounter_phase_changed(source: Object, phase_index: int) -> void:
	encounter_phase_changed.emit(source, phase_index)


func raise_encounter_poise_changed(source: Object, ratio: float) -> void:
	encounter_poise_changed.emit(source, ratio)


func raise_encounter_skill_cooldown_changed(source: Object, skill_id: StringName, ratio: float) -> void:
	encounter_skill_cooldown_changed.emit(source, skill_id, ratio)


func _start_hitstop(duration: float) -> void:
	if Engine.time_scale < 0.999:
		return
	Engine.time_scale = 0.08
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(_finish_hitstop, CONNECT_ONE_SHOT)


func _finish_hitstop() -> void:
	Engine.time_scale = 1.0


func _spawn_placeholder_hit_effect(world_pos: Vector2, strength: float) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var effect := CPUParticles2D.new()
	effect.name = "HitFeedbackEffect"
	effect.global_position = world_pos
	effect.amount = 10
	effect.lifetime = 0.18
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.spread = 180.0
	effect.initial_velocity_min = 55.0 * maxf(0.5, strength)
	effect.initial_velocity_max = 95.0 * maxf(0.5, strength)
	effect.scale_amount_min = 1.5
	effect.scale_amount_max = 3.0
	effect.color = Color(1.0, 0.9, 0.35, 1.0)
	tree.current_scene.add_child(effect)
	effect.emitting = true
	var timer := tree.create_timer(effect.lifetime + 0.1)
	timer.timeout.connect(effect.queue_free, CONNECT_ONE_SHOT)
