extends Node
## 场景加载（替代 Unity 项目里的 SceneLoader / Addressables 加载流程）
##
## Unity 端通过 SceneReference 异步增量加载，并控制相机模式与玩家可用性。
## Godot 4.7 的 load_threaded_request 存在 LoadToken 泄漏回归（godot#120661），
## 因此当前版本由 SceneLoader 持有工作线程执行普通 ResourceLoader.load，
## 并在主线程分帧执行场景切换与收尾。
##
## 与 Unity 一致的事件流：
##   GameEvents.scene_load_requested   -> 开始加载
##   GameEvents.fade_requested(true)   -> 黑屏
##   场景切换 / 玩家位置应用
##   GameEvents.fade_requested(false)  -> 淡出
##   GameEvents.after_scene_loaded     -> 通知摄像机 / UI 更新

const FADE_DURATION_DEFAULT := 0.4
const MENU_SCENE_RESOURCE := preload("res://data/scene_warrior_menu.tres")

enum TransitionPhase {
	IDLE,
	FADING_TO_BLACK,
	LOADING,
	REVEALING,
}

var current_scene_resource: Resource = null
var _is_loading: bool = false
var _phase: TransitionPhase = TransitionPhase.IDLE
var _pending_position: Vector3 = Vector3.ZERO
var _pending_fade: bool = true
var _pending_scene_resource: Resource = null
var _queued_scene_path: String = ""
var _load_thread: Thread = null
var _scene_change_needs_finish: bool = false


func _ready() -> void:
	GameEvents.scene_load_requested.connect(_on_scene_load_requested)
	GameEvents.new_game_started.connect(_on_new_game_started)
	GameEvents.back_to_menu_requested.connect(_on_back_to_menu_requested)
	GameEvents.restart_requested.connect(_on_restart_requested)


func _process(_delta: float) -> void:
	if _scene_change_needs_finish:
		_scene_change_needs_finish = false
		_finish_scene_change()
	if _load_thread == null or _load_thread.is_alive():
		return
	var packed := _load_thread.wait_to_finish() as PackedScene
	_load_thread = null
	_apply_packed_scene(packed)


func _exit_tree() -> void:
	if _load_thread != null and _load_thread.is_started():
		_load_thread.wait_to_finish()
	_load_thread = null


# ----- 事件处理 ---------------------------------------------------------------

func _on_scene_load_requested(scene_resource: Resource, position_to_go: Vector3, fade_screen: bool) -> void:
	if _is_loading or scene_resource == null:
		return
	var scene_path: String = String(scene_resource.get("scene_path"))
	if scene_path.is_empty():
		push_error("SceneLoader: GameSceneResource 未配置 scene_path")
		return
	_is_loading = true
	_pending_scene_resource = scene_resource
	_pending_position = position_to_go
	_pending_fade = fade_screen
	_queued_scene_path = scene_path
	_phase = TransitionPhase.FADING_TO_BLACK
	_set_player_input_active(false)

	if fade_screen:
		GameEvents.raise_fade_in(Color.BLACK, FADE_DURATION_DEFAULT)
		await get_tree().create_timer(FADE_DURATION_DEFAULT).timeout
		if not _is_loading or _queued_scene_path.is_empty():
			return

	# 切换场景前先让数据管理器把当前场景的状态写下来
	if current_scene_resource != null:
		DataManager.try_capture_runtime_state_for_scene_transition(true)
		GameEvents.raise_scene_unloaded(current_scene_resource, _pending_position, _pending_fade)

	var load_path := _queued_scene_path
	_queued_scene_path = ""
	_phase = TransitionPhase.LOADING
	_load_thread = Thread.new()
	var err := _load_thread.start(_load_scene_on_worker.bind(load_path))
	if err != OK:
		_load_thread = null
		_recover_from_load_failure("工作线程启动失败 %d: %s" % [err, load_path])
		return


func _on_new_game_started() -> void:
	# 由具体业务模块响应（玩家进度清空等），SceneLoader 自身只负责跳转
	pass


func _on_back_to_menu_requested() -> void:
	_on_scene_load_requested(MENU_SCENE_RESOURCE, Vector3.ZERO, true)


func _on_restart_requested() -> void:
	if current_scene_resource == null:
		return
	_on_scene_load_requested(current_scene_resource, Vector3(NAN, NAN, 0.0), true)


func is_transition_active() -> bool:
	return _is_loading


# ----- 内部 -------------------------------------------------------------------

func _load_scene_on_worker(scene_path: String) -> PackedScene:
	return ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REUSE) as PackedScene


func _apply_packed_scene(packed: PackedScene) -> void:
	if packed == null:
		_recover_from_load_failure("场景资源加载失败")
		return
	var tree := get_tree()
	if tree == null:
		_recover_from_load_failure("场景树不可用")
		return
	var err := tree.change_scene_to_packed(packed)
	if err != OK:
		_recover_from_load_failure("change_scene_to_packed 失败 %d" % err)
		return
	current_scene_resource = _pending_scene_resource
	_scene_change_needs_finish = true


func _finish_scene_change() -> void:
	# change_scene_to_packed 在当前帧结束时替换场景；下一帧由 _process 同步收尾。
	# 新场景中的 Player 在此刻才出现，因此必须再次锁定，不能让黑屏期间收到输入。
	_phase = TransitionPhase.REVEALING
	_set_player_input_active(false)
	_apply_player_position()
	DataManager.apply_pending_scene_restore()

	if _pending_fade:
		GameEvents.raise_fade_out(Color.BLACK, FADE_DURATION_DEFAULT)
		get_tree().create_timer(FADE_DURATION_DEFAULT).timeout.connect(
			_complete_scene_reveal,
			CONNECT_ONE_SHOT)
		return
	_complete_scene_reveal()


func _complete_scene_reveal() -> void:
	if not _is_loading:
		return
	GameEvents.raise_after_scene_loaded()
	_play_bgm_for_loaded_scene()
	_set_player_input_active(true)
	_clear_active_transition()


func _recover_from_load_failure(reason: String) -> void:
	push_error("SceneLoader: %s" % reason)
	_scene_change_needs_finish = false
	_phase = TransitionPhase.REVEALING
	_queued_scene_path = ""

	# 原场景仍然有效；先揭开此前的黑屏，再恢复控制，避免玩家陷在不可见状态。
	if _pending_fade:
		GameEvents.raise_fade_out(Color.BLACK, FADE_DURATION_DEFAULT)
		get_tree().create_timer(FADE_DURATION_DEFAULT).timeout.connect(
			_complete_failure_recovery,
			CONNECT_ONE_SHOT)
		return
	_complete_failure_recovery()


func _complete_failure_recovery() -> void:
	if not _is_loading:
		return
	_set_player_input_active(true)
	_clear_active_transition()


func _clear_active_transition() -> void:
	_is_loading = false
	_phase = TransitionPhase.IDLE
	_pending_position = Vector3.ZERO
	_pending_fade = true
	_pending_scene_resource = null
	_queued_scene_path = ""


func _apply_player_position() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var players := tree.get_nodes_in_group(&"player")
	if players.is_empty():
		return
	var player := players[0] as Node2D
	if player == null:
		return
	# Godot 是 2D 项目，位置只取 xy
	if is_nan(_pending_position.x) or is_nan(_pending_position.y):
		return
	player.global_position = Vector2(_pending_position.x, _pending_position.y)


func _play_bgm_for_loaded_scene() -> void:
	pass


func _set_player_input_active(active: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for player in tree.get_nodes_in_group(&"player"):
		if player.has_method("set_gameplay_input_active"):
			player.call("set_gameplay_input_active", active)
