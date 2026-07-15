class_name Sign
extends Area2D
## 交互提示（替代 Unity 项目里的 Sign）
##
## 玩家附近出现可交互对象时显示按钮提示，按下 interact 触发目标的 trigger_action。
## 设计要点：
##   - 用 Area2D 监听 Interactable 组的对象
##   - signSprite 显示当前可按提示，朝向跟随玩家
##   - 仅在玩家未死亡 / 输入开启 / 时间未暂停时响应

@export_node_path("PlayerController") var player_controller_path: NodePath
@export_node_path("Node2D") var player_visual_path: NodePath
@export_node_path("Node2D") var sign_sprite_path: NodePath
@export_node_path("AnimationPlayer") var sign_animation_player_path: NodePath

var _player_controller: PlayerController
var _player_visual: Node2D
var _sign_sprite: CanvasItem
var _sign_anim: AnimationPlayer
var _target: Node = null
var _can_press: bool = false
var _candidates: Dictionary = {}
var _prompt_shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_player_controller = get_node_or_null(player_controller_path) as PlayerController
	_player_visual = get_node_or_null(player_visual_path) as Node2D
	_sign_sprite = get_node_or_null(sign_sprite_path) as CanvasItem
	_sign_anim = get_node_or_null(sign_animation_player_path) as AnimationPlayer
	if _sign_anim != null and not _sign_anim.animation_finished.is_connected(_on_prompt_animation_finished):
		_sign_anim.animation_finished.connect(_on_prompt_animation_finished)
	if _sign_sprite != null:
		_sign_sprite.visible = false
	_resolve_player_controller()


func _process(_delta: float) -> void:
	_resolve_player_controller()
	_refresh_target()
	var should_show := _can_press and _can_process_interaction_input()
	_set_prompt_visible(should_show)

	if _sign_sprite != null and _player_visual != null:
		var target_scale: Vector2 = _sign_sprite.scale
		target_scale.x = absf(target_scale.x) * signf(_player_visual.scale.x if _player_visual.scale.x != 0.0 else 1.0)
		_sign_sprite.scale = target_scale


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and _can_press and is_instance_valid(_target) \
			and _can_process_interaction_input():
		if _target.has_method("trigger_action"):
			_target.call("trigger_action")
			GameEvents.raise_play_sfx(&"interact", global_position)
			var audio := get_node_or_null("AudioDefinition")
			if audio != null and audio.has_method("play_audio_clip"):
				audio.call("play_audio_clip")


# ----- 触发器 ------------------------------------------------------------------

func _on_body_entered(body: Node) -> void:
	_try_capture_target(body)


func _on_body_exited(body: Node) -> void:
	_remove_candidate(body)


func _on_area_entered(area: Node) -> void:
	_try_capture_target(area)


func _on_area_exited(area: Node) -> void:
	_remove_candidate(area)


func _try_capture_target(node: Node) -> void:
	if node == null:
		return
	if node.is_in_group(&"interactable") or node.has_method("trigger_action"):
		_candidates[node.get_instance_id()] = weakref(node)
		_refresh_target()


func _remove_candidate(node: Node) -> void:
	if node != null:
		_candidates.erase(node.get_instance_id())
	_refresh_target()


func _refresh_target() -> void:
	var best_target: Node = null
	var best_distance_squared := INF
	var stale_ids: Array = []
	for candidate_id: Variant in _candidates:
		var reference := _candidates[candidate_id] as WeakRef
		var candidate := reference.get_ref() as Node if reference != null else null
		if candidate == null or not is_instance_valid(candidate) \
				or not (candidate.is_in_group(&"interactable") or candidate.has_method("trigger_action")):
			stale_ids.append(candidate_id)
			continue
		var distance_squared := INF
		if candidate is Node2D:
			distance_squared = global_position.distance_squared_to((candidate as Node2D).global_position)
		if best_target == null or distance_squared < best_distance_squared \
				or (is_equal_approx(distance_squared, best_distance_squared) \
				and candidate.get_instance_id() < best_target.get_instance_id()):
			best_target = candidate
			best_distance_squared = distance_squared
	for stale_id: Variant in stale_ids:
		_candidates.erase(stale_id)
	_target = best_target
	_can_press = _target != null


func _set_prompt_visible(should_show: bool) -> void:
	if _sign_sprite == null or should_show == _prompt_shown:
		return
	_prompt_shown = should_show
	if should_show:
		_sign_sprite.visible = true
		if _sign_anim != null and _sign_anim.has_animation(&"show"):
			_sign_anim.play(&"show")
		else:
			_sign_sprite.modulate.a = 1.0
	elif _sign_anim != null and _sign_anim.has_animation(&"hide"):
		_sign_anim.play(&"hide")
	else:
		_sign_sprite.visible = false


func _on_prompt_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"hide" and not _prompt_shown and _sign_sprite != null:
		_sign_sprite.visible = false


# ----- 内部 --------------------------------------------------------------------

func _resolve_player_controller() -> void:
	if _player_controller != null:
		return
	if get_parent() is PlayerController:
		_player_controller = get_parent()
		return
	var players := get_tree().get_nodes_in_group(&"player")
	if not players.is_empty() and players[0] is PlayerController:
		_player_controller = players[0]


func _can_process_interaction_input() -> bool:
	_resolve_player_controller()
	if _player_controller == null:
		return false
	if not _player_controller.input_enabled:
		return false
	if _player_controller.is_dead:
		return false
	if get_tree().paused:
		return false
	if Engine.time_scale <= 0.0:
		return false
	return true
