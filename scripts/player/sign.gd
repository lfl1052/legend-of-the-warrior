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


func _ready() -> void:
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
	_resolve_player_controller()


func _process(_delta: float) -> void:
	_resolve_player_controller()
	var should_show := _can_press and _can_process_interaction_input()
	if _sign_sprite != null:
		_sign_sprite.visible = should_show

	if _sign_sprite != null and _player_visual != null:
		var target_scale := _sign_sprite.scale
		target_scale.x = absf(target_scale.x) * signf(_player_visual.scale.x if _player_visual.scale.x != 0.0 else 1.0)
		_sign_sprite.scale = target_scale


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and _can_press and _target != null and _can_process_interaction_input():
		if _target.has_method("trigger_action"):
			_target.call("trigger_action")
			var audio := get_node_or_null("AudioDefinition")
			if audio != null and audio.has_method("play_audio_clip"):
				audio.call("play_audio_clip")


# ----- 触发器 ------------------------------------------------------------------

func _on_body_entered(body: Node) -> void:
	_try_capture_target(body)


func _on_body_exited(body: Node) -> void:
	if _target == body:
		_clear_target()


func _on_area_entered(area: Node) -> void:
	_try_capture_target(area)


func _on_area_exited(area: Node) -> void:
	if _target == area:
		_clear_target()


func _try_capture_target(node: Node) -> void:
	if node == null:
		return
	if node.is_in_group(&"interactable") or node.has_method("trigger_action"):
		_target = node
		_can_press = true


func _clear_target() -> void:
	_target = null
	_can_press = false


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
	if Engine.time_scale <= 0.0:
		return false
	return true
