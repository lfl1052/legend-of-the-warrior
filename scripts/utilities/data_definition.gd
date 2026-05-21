class_name DataDefinition
extends Node
## 数据定义节点（替代 Unity 项目里的 DataDefination MonoBehaviour）
##
## 挂在任何需要参与存档的节点旁，作为兄弟节点提供：
##   - 唯一 ID（自动生成 GUID，编辑器内可手动覆写）
##   - 持久化策略（read/write 或忽略）
##
## 用法：
##   var def := DataDefinition.new()
##   def.id = "..."          # 可选
##   add_child(def)          # 通常在场景里以子节点形式存在

@export var id: String = ""
@export var persistent_type: int = Enums.PersistentType.READ_WRITE


func _enter_tree() -> void:
	if id.is_empty():
		id = _generate_guid()


static func _generate_guid() -> String:
	# Godot 没有内建 GUID，但 randi 拼接 + 时间戳就足够区分场景内对象
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var t := Time.get_ticks_usec()
	return "%x-%x-%x" % [t, rng.randi(), rng.randi()]
