class_name ISaveable
extends RefCounted
## 存档接口（替代 Unity 项目里的 ISaveable）
##
## 任何节点要参与存档，需要：
##   1. 在 _enter_tree / _ready 时调用 DataManager.register(self)
##   2. 在 _exit_tree 时调用 DataManager.unregister(self)
##   3. 实现以下三个方法：
##        get_save_id() -> String                 唯一持久化键
##        get_save_data(data: Dictionary) -> void DataManager 调用以收集状态
##        load_save_data(data: Dictionary) -> void  DataManager 调用以恢复状态

func get_save_id() -> String:
	return ""


func get_save_data(_data: Dictionary) -> void:
	pass


func load_save_data(_data: Dictionary) -> void:
	pass
