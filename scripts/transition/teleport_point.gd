class_name TeleportPoint
extends Area2D
## 传送点（替代 Unity 项目里的 TeleportPoint.cs）
##
## 作为 Interactable：玩家走入并按下交互键时，把场景切换请求广播给
## SceneLoader 自动加载脚本。

@export var scene_to_go: GameSceneResource
@export var position_to_go: Vector2 = Vector2.ZERO
@export var fade_screen: bool = true


func _ready() -> void:
	add_to_group(&"interactable")


func trigger_action() -> void:
	if scene_to_go == null:
		push_warning("TeleportPoint: scene_to_go 未配置")
		return
	var target_position := Vector3(position_to_go.x, position_to_go.y, 0.0)
	GameEvents.raise_scene_load_requested(scene_to_go, target_position, fade_screen)
