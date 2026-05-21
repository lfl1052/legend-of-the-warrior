extends Node
## 菜单流控（替代 Unity 项目里的 MenuController 行为）
##
## 把主菜单按钮事件 new_game_started / load_data_requested
## 翻译成 SceneLoader 可以执行的 scene_load_requested。
##
## 与 InitialLoad 的区别：
##   InitialLoad  在 _ready 立即触发，适合启动场景。
##   MenuFlow     仅在用户点了新游戏 / 继续之后再触发。

@export var default_level: GameSceneResource
@export var default_spawn_position: Vector2 = Vector2.ZERO
@export var fade_screen: bool = true


func _ready() -> void:
	if not GameEvents.new_game_started.is_connected(_on_new_game_started):
		GameEvents.new_game_started.connect(_on_new_game_started)
	if not GameEvents.load_data_requested.is_connected(_on_load_data_requested):
		GameEvents.load_data_requested.connect(_on_load_data_requested)


func _on_new_game_started() -> void:
	if default_level == null:
		push_warning("MenuFlow: default_level 未配置")
		return
	_request_load(default_level, default_spawn_position)


func _on_load_data_requested() -> void:
	# DataManager 已经把存档读进内存（autoload 同名信号），这里只挑选目标场景
	var saved_path: String = DataManager.try_get_saved_scene_path()
	if saved_path.is_empty() or not ResourceLoader.exists(saved_path):
		# 无可恢复目标，按"新游戏"流程走
		if default_level != null:
			_request_load(default_level, default_spawn_position)
		return

	var scene_res := GameSceneResource.new()
	scene_res.scene_path = saved_path
	scene_res.scene_type = Enums.SceneType.LOACTION
	# 位置由 player 自己 load_save_data 还原，这里仅传 0
	_request_load(scene_res, Vector2.ZERO)


func _request_load(scene_res: GameSceneResource, spawn_2d: Vector2) -> void:
	var spawn_3d := Vector3(spawn_2d.x, spawn_2d.y, 0.0)
	GameEvents.raise_scene_load_requested(scene_res, spawn_3d, fade_screen)
