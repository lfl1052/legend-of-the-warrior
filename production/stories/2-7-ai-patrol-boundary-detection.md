# Story 2-7 - AI 行为优化：巡逻边界检测

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: should-have
**Owner**: ai-programmer
**Estimate**: 0.5 day
**Type**: AI / Physics

## 用户故事

作为关卡设计者，
我需要地面敌人巡逻时能检测边缘和墙壁，
以便敌人不会掉出平台或卡进墙体。

## 验收标准

- [x] 敌人巡逻时能正确检测平台边缘。
- [x] 敌人巡逻时能正确检测墙壁。
- [x] 遇到边缘或墙壁时改变方向或停顿，不会掉落/卡墙。
- [x] `PhysicsCheck` 相关逻辑有测试覆盖或集成验证。

## 实现笔记

- 优先检查 `PhysicsCheck`、`boar_patrol_state.gd`、`snail_patrol_state.gd` 和场景 RayCast/Shape 配置。
- 避免把关卡坐标硬编码进 AI 状态。

## Test Evidence

- `tests/unit/test_physics_check.gd` PASS on 2026-05-25: covers wall detection, missing-front-ground detection, and continue-forward path.
- `tests/integration/level_2_load_test.tscn` PASS on 2026-05-25: verifies level scenes still load with required enemies and gameplay nodes.
- `tests/e2e/smoke_test.tscn` PASS on 2026-05-25: verifies the main level flow remains stable with updated enemy patrol logic.
- Full unit suite PASS on 2026-05-25: 64/64 passing after Sprint 2 2-6 through 2-10 implementation.

## Completion Notes

- `PhysicsCheck` now exposes `has_ground_ahead()`, `touches_wall_in_direction()`, and `should_turn_for_patrol()`.
- Snail and boar patrol states use the shared `PhysicsCheck.should_turn_for_patrol()` path instead of local wall-only checks.
- No level-coordinate hardcoding was introduced.

## 关联文件

- `scripts/general/physics_check.gd`
- `scripts/enemy/boar_patrol_state.gd`
- `scripts/enemy/snail_patrol_state.gd`
- `scripts/enemy/bee_patrol_state.gd`

## 后续依赖

- 无。
