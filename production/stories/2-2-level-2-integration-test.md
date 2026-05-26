# Story 2-2 - 补充 level_2 集成测试证据

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: must-have
**Owner**: godot-gdscript-specialist
**Estimate**: 0.5 day
**Type**: Integration / Test

## 用户故事

作为 QA 维护者，
我需要 level_2 有明确的自动化加载验证，
以便第二关脚手架不是只靠手动 smoke 记录证明可用。

## 验收标准

- [x] `level_2` 可以通过自动化流程 headless 加载。
- [x] 创建 `tests/integration/level_2_load_test.tscn`，或在 `tests/e2e/smoke_test.gd` 中加入 level_2 验证。
- [x] 测试确认 `level_2` 的关键节点存在。
- [x] 相关测试 PASS。

## 实现笔记

- 依赖 Story 2-1，避免红色角色卡死影响加载或短时运行验证。
- 可参考 Sprint 1 的 `tests/e2e/smoke_test.gd` 和 `tests/integration/boss_skill_state_test.tscn`。

## Test Evidence

- `tests/integration/level_2_load_test.tscn` PASS on 2026-05-25 via Godot headless.
- `tests/integration/level_2_load_test.gd` verifies both `res://scenes/levels/level_2.tscn` and `res://scenes/levels/level_demo.tscn`.
- Required nodes covered include Player, Player/Sign, enemies, BossEnemy on level_2, ChestA, BreakableRockA, SavePoint, Teleport nodes, Camera2D, PlayerStatBar, and RewardNotification.

## Completion Notes

- The Sprint 1 missing integration evidence for level_2 is now covered by a dedicated load test scene.
- The test also checks interactable/damageable group wiring for the new Sprint 2 props.

## 关联文件

- `scenes/levels/level_2.tscn`
- `tests/e2e/smoke_test.gd`
- `tests/integration/`

## 后续依赖

- 无。
