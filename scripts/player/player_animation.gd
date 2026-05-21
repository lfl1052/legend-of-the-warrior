extends Node
## 玩家动画桥接（替代 Unity 项目里的 PlayerAnimation）
##
## Unity 端通过 Animator 参数驱动状态混合。
## Godot 端使用 AnimationPlayer，把同样的逻辑用脚本控制：
##   - 监听 PlayerController 状态变化
##   - 调用 AnimationPlayer.play(...) 切换动画
##
## 这里只做"参数 -> 动画名"的兜底，主控仍在 PlayerController 里。

@export_node_path("PlayerController") var controller_path: NodePath
@export_node_path("AnimationPlayer") var animation_player_path: NodePath

@onready var _controller: PlayerController = get_node_or_null(controller_path)
@onready var _anim: AnimationPlayer = get_node_or_null(animation_player_path)


func _ready() -> void:
	if _anim != null:
		_anim.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(anim_name: StringName) -> void:
	if _controller == null:
		return
	var name_str := String(anim_name)
	if name_str.begins_with("attack"):
		_controller.on_attack_animation_finished()
	elif name_str == "hurt":
		_controller.on_hurt_animation_finished()
