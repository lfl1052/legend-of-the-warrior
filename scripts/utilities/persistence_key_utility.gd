class_name PersistenceKeyUtility
extends RefCounted
## 持久化键解析工具（替代 Unity 项目里的 PersistenceKeyUtility）
##
## 解析顺序：
##   1. 节点旁挂的 DataDefinition.id（最可靠）
##   2. 节点的"场景路径"（fallback，回避场景重启时丢失）
##   3. fallback_prefix + 节点 name

static func resolve_key(node: Node, fallback_prefix: String = "") -> String:
	if node == null:
		return ""

	var def := _find_definition(node)
	if def != null and not def.id.is_empty():
		return def.id

	# 用场景路径作为兜底，对未挂 DataDefinition 的节点也能稳定定位
	var path := str(node.get_path())
	if not path.is_empty():
		return path

	if not fallback_prefix.is_empty():
		return "%s_%s" % [fallback_prefix, node.name]
	return String(node.name)


static func _find_definition(node: Node) -> DataDefinition:
	# 同级 / 子级 / 父级 寻找 DataDefinition
	if node is DataDefinition:
		return node
	for child in node.get_children():
		if child is DataDefinition:
			return child
	if node.get_parent() != null:
		for sibling in node.get_parent().get_children():
			if sibling is DataDefinition:
				return sibling
	return null
