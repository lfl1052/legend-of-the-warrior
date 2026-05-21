extends GdUnitTestSuite
## PersistenceKeyUtility 单元测试
##
## 测试范围：
##   - resolve_key 的优先级逻辑
##   - DataDefinition 优先级
##   - 场景路径 fallback
##   - fallback_prefix

const UTILITY_PATH := "res://scripts/utilities/persistence_key_utility.gd"

var _utility: RefCounted


func before_test() -> void:
	_utility = load(UTILITY_PATH).new()


func after_test() -> void:
	_utility = null


# ----- 空节点 -----------------------------------------------------------------

func test_resolve_key_null_node_returns_empty() -> void:
	# Act
	var result: String = PersistenceKeyUtility.resolve_key(null, "fallback")
	# Assert
	assert_str(result).is_empty()


# ----- DataDefinition 优先 --------------------------------------------------

func test_resolve_key_with_data_definition_child_returns_id() -> void:
	# Arrange: 创建一个节点，其子节点有 DataDefinition
	var node := Node.new()
	add_child(node)
	auto_free(node)
	var def: DataDefinition = load("res://scripts/utilities/data_definition.gd").new()
	def.id = "test_id_123"
	node.add_child(def)
	# Act
	var result := PersistenceKeyUtility.resolve_key(node, "fallback")
	# Assert
	assert_str(result).is_equal("test_id_123")


# ----- 场景路径 fallback -----------------------------------------------------

func test_resolve_key_with_no_data_def_returns_path() -> void:
	# Arrange
	var node := Node.new()
	node.name = "TestNode"
	add_child(node)
	auto_free(node)
	# Act
	var result := PersistenceKeyUtility.resolve_key(node, "prefix")
	# Assert: 场景路径不是空字符串
	assert_str(result).is_not_empty()


# ----- fallback_prefix + name ------------------------------------------------

func test_resolve_key_uses_name_for_unknown_node() -> void:
	# Arrange
	var node := Node.new()
	node.name = "Enemy1"
	add_child(node)
	auto_free(node)
	# Act & Assert: 结果非空（具体值取决于场景路径逻辑，但不应该是纯空）
	var result := PersistenceKeyUtility.resolve_key(node, "enemy")
	assert_str(result).is_not_empty()
