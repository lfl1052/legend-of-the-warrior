extends GdUnitTestSuite
## PlayerProgression 代币 / 解锁逻辑单元测试
##
## 测试范围：
##   - 宝箱奖励正确累加（依赖 loot.json 的 tutorial_chest_basic 条目）
##   - 重复开同一宝箱不再发放（chest_id 去重）
##   - unlock_slot 幂等（重复调用不重复 emit unlock_changed）
##
## 依赖：RuntimeData 已加载 res://data/loot.json 与 progression.json。

const PLAYER_PROGRESSION_SCRIPT := preload("res://scripts/player/player_progression.gd")

var _progression: Node


func before_test() -> void:
	# 把 DataManager 路径重定向到测试目录，避免 register/unregister 影响真实存档
	DataManager.override_save_paths_for_test("user://TEST_PROGRESSION/")
	_progression = auto_free(PLAYER_PROGRESSION_SCRIPT.new())
	_progression.save_id = "test_player_progression"
	add_child(_progression)
	# _ready 在 add_child 后触发：连接 GameEvents、注册 DataManager、加载 progression 配置


func after_test() -> void:
	_progression = null
	DataManager.clear_test_overrides()


# ----- 宝箱奖励正确累加 -------------------------------------------------------

func test_player_progression_chest_reward_adds_tokens() -> void:
	# Arrange
	# tutorial_chest_basic = 1 个 tutorial-economy-token
	# Act
	_progression.try_apply_chest_rewards("test_chest_basic_001", &"tutorial_chest_basic")
	# Assert
	assert_int(_progression.tutorial_economy_tokens).is_equal(1)


# ----- 重复开同一宝箱不发放 ---------------------------------------------------

func test_player_progression_repeated_chest_does_not_double_reward() -> void:
	# Arrange：先开一次
	_progression.try_apply_chest_rewards("test_chest_dup_001", &"tutorial_chest_basic")
	assert_int(_progression.tutorial_economy_tokens).is_equal(1)
	# Act：用同一个 chest_id 再开一次
	_progression.try_apply_chest_rewards("test_chest_dup_001", &"tutorial_chest_basic")
	# Assert：代币数不变
	assert_int(_progression.tutorial_economy_tokens).is_equal(1)


# ----- 解锁槽位幂等 -----------------------------------------------------------

func test_player_progression_unlock_slot_is_idempotent() -> void:
	# Arrange：监听 unlock_changed 信号，统计 emit 次数
	var emit_count: int = 0
	var on_changed := func(_slot: StringName) -> void: emit_count += 1
	_progression.unlock_changed.connect(on_changed)
	# Act：解锁同一槽位两次
	_progression.unlock_slot(&"heal")
	_progression.unlock_slot(&"heal")
	# Assert：信号只触发一次，槽位记录稳定
	assert_int(emit_count).is_equal(1)
	assert_bool(_progression.has_unlock_slot(&"heal")).is_true()
	# 解锁不同槽位应能正常触发
	_progression.unlock_slot(&"map")
	assert_int(emit_count).is_equal(2)
	assert_bool(_progression.has_unlock_slot(&"map")).is_true()
	_progression.unlock_changed.disconnect(on_changed)
