# Story 2-3 - 可交互物品系统：宝箱

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: must-have
**Owner**: gameplay-programmer
**Estimate**: 1.5 days
**Type**: Gameplay / Persistence

## 用户故事

作为玩家，
我需要在关卡中打开宝箱并领取一次性奖励，
以便探索有明确反馈和可保存的收益。

## 验收标准

- [x] `scripts/general/chest.gd` 支持打开动画或打开状态反馈。
- [x] 宝箱触发 `PlayerProgression.try_apply_chest_rewards(chest_id, table_id)` 发放掉落。
- [x] 同一宝箱重复交互不会重复发放奖励。
- [x] 至少创建 1 个可放入关卡的宝箱场景。
- [x] 单元测试覆盖奖励发放和一次性标记路径。

## 实现笔记

- 复用现有 `PlayerProgression` 宝箱奖励和 `ISaveable`/`DataManager` 约定。
- 优先保持 `chest_id` 稳定，避免保存键漂移。
- 可以先用占位美术，后续 Sprint 替换资源。

## Test Evidence

- `tests/unit/test_chest.gd` PASS on 2026-05-25: 3/3 chest tests passing.
- Full unit suite PASS on 2026-05-25: 64/64 passing.
- `tests/integration/level_2_load_test.tscn` PASS on 2026-05-25 and verifies `ChestA` in both `level_2` and `level_demo`.

## Completion Notes

- Added reusable prop scene `scenes/props/chest.tscn`.
- Placed stable-id chest instances in `scenes/levels/level_demo.tscn` and `scenes/levels/level_2.tscn`.
- `scripts/general/chest.gd` uses stable scene path fallback when no `DataDefinition` is present and no longer creates random runtime save IDs.

## 关联文件

- `scripts/general/chest.gd`
- `scripts/player/player_progression.gd`
- `data/loot.json`
- `tests/unit/test_player_progression.gd`

## 后续依赖

- Story 2-4 可破坏物会复用掉落和一次性奖励思路。
- Story 2-5 会在 level_demo 中放置宝箱。
