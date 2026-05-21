extends Node
## 启动场景引导（替代 Unity 项目里的 InitialLoad.cs）
##
## 把启动场景里挂载该节点的位置作为入口；_ready 时立刻请求加载持久化场景。
## 通过 SceneLoader 自动加载完成实际跳转。

@export var persistent_scene: GameSceneResource
@export var spawn_position: Vector2 = Vector2.ZERO
@export var fade_screen: bool = true

static var _has_requested_load: bool = false


func _ready() -> void:
	if _has_requested_load:
		return
	_has_requested_load = true
	if persistent_scene == null:
		push_warning("InitialLoad: persistent_scene 未配置")
		return
	GameEvents.raise_scene_load_requested(persistent_scene, spawn_position, fade_screen)
