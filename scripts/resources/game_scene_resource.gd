class_name GameSceneResource
extends Resource
## 替代 Unity 的 GameSceneSO（ScriptableObject）
##
## 字段含义对应 Unity 端：
##   sceneReference  -> scene_path（PackedScene 路径）
##   sceneType       -> scene_type（菜单/关卡）
##   sceneName       -> display_name（用于 UI 与本地化键）
##
## 作为 .tres 资源放在 res://resources/scenes/ 下复用。

@export_file("*.tscn") var scene_path: String = ""
@export var display_name: String = ""
@export var scene_type: int = Enums.SceneType.LOACTION       # 注意保留 Unity 拼写


func is_menu() -> bool:
	return scene_type == Enums.SceneType.MENU


func is_location() -> bool:
	return scene_type == Enums.SceneType.LOACTION
