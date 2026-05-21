# Story 1-4 — PlayerProgression 代币 / 解锁单元测试

**Status**: Complete
**Sprint**: 1
**Priority**: must-have
**Owner**: godot-gdscript-specialist
**Estimate**: 0.5 day
**Completed**: 2026-05-21

## 用户故事

作为 **玩家成长系统的维护者**，
我需要 **PlayerProgression 的宝箱奖励、去重、unlock_slot 幂等三条路径都有测试覆盖**，
以便 **未来调奖励配置或新增 reward_id 时不至于回归"重复开宝箱多次发放"或"unlock_changed 信号重复触发"的旧 bug**。

## 验收标准

- [x] `test_player_progression_chest_reward_adds_tokens` — 调 `try_apply_chest_rewards("test_chest_basic_001", &"tutorial_chest_basic")` 后 `tutorial_economy_tokens=1`（依赖 loot.json 的 tutorial_chest_basic 条目 1 个 tutorial-economy-token）
- [x] `test_player_progression_repeated_chest_does_not_double_reward` — 同一 chest_id 调用两次，代币数仍为 1（chest_id 去重生效）
- [x] `test_player_progression_unlock_slot_is_idempotent` — `unlock_slot(&"heal")` 连调两次只 emit 一次 `unlock_changed`；调用 `unlock_slot(&"map")` 后 emit 第二次
- [x] 测试通过 `DataManager.override_save_paths_for_test("user://TEST_PROGRESSION/")` 隔离，不污染真实存档
- [x] 用例命名遵循 `test_[system]_[scenario]_[expected_result]`，AAA 三段式

## 实现笔记

- **autoload 注册副作用**：PlayerProgression `_ready` 会调用 `DataManager.register(self)`，若直接用真实 DataManager 单例，存档目录会被测试污染。Story 1-2 引入的 `override_save_paths_for_test` 钩子在 `before_test` 重定向到 `user://TEST_PROGRESSION/`。
- **不用 class_name**：PlayerProgression 没有 class_name，测试用 `preload("res://scripts/player/player_progression.gd")` 拿到脚本类，再 `.new()` 实例化。
- **数据驱动**：奖励数额来自 `data/loot.json`，由 RuntimeData 在 PlayerProgression `_ready` 时加载，因此测试隐式依赖 Story 1-1 的 loot.json 与 progression.json。

## 关联文件

- 创建：`tests/unit/test_player_progression.gd`
- 引用代码：`scripts/player/player_progression.gd`、`scripts/autoload/data_manager.gd`、`scripts/autoload/runtime_data.gd`
- 数据：`data/loot.json` (tutorial_chest_basic)、`data/progression.json`

## 后续依赖

- **Story 1-9** GdUnit4 升级后 CLI 可批量运行
- 后续若新增 reward_id 类型，应在本 suite 加一条覆盖用例
