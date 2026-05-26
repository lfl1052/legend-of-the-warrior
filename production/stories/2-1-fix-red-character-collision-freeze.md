# Story 2-1 - 修复红色角色碰撞卡死 bug

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: must-have
**Owner**: gameplay-programmer
**Estimate**: 0.5 day
**Type**: Bugfix / Combat / AI

## 用户故事

作为玩家，
我需要红色敌人或 Boss 与玩家接触时不会让游戏卡死，
以便关卡战斗可以持续进行并通过 Sprint 冒烟检查。

## 背景

Sprint 1 smoke check 记录到：红色角色从屏幕右侧飘来，接触玩家角色后游戏卡死。需要确认该红色角色来源（Boss、普通敌人、精英敌人或特效），定位是否由碰撞回调、状态机循环、攻击命中逻辑或物理层配置导致。

## 验收标准

- [x] 识别导致卡死的红色角色来源和触发场景。
- [x] 修复碰撞或状态机死循环根因。
- [x] 玩家与该角色接触后游戏不再卡死。
- [x] 添加覆盖该回归路径的自动测试或可重复集成验证。
- [x] 修复后 smoke check 中的红色角色卡死项可通过。

## 实现笔记

- 先复现或通过场景/脚本静态分析确认问题角色。
- 优先检查 `Character` 受击逻辑、`Attack` 命中冷却、敌人状态机 `logic_update` / `physics_update` 以及场景碰撞层。
- 回归测试应尽量使用现有 GdUnit4 单元测试；如果必须依赖场景，可补充 `tests/integration/` 测试场景或扩展 `tests/e2e/smoke_test.gd`。

## Test Evidence

- `tests/unit/test_boss_skill_state.gd` PASS as part of the full unit suite: 64/64 passing on 2026-05-25.
- `tests/e2e/smoke_test.tscn` PASS on 2026-05-25: new game, level_demo load, enemy contact/attack path, save point, and teleport back to menu completed without freeze.
- `production/qa/smoke-2026-05-25.md` records the Sprint 2 smoke verdict.

## Completion Notes

- Red character source confirmed as `scenes/enemy/boss_enemy.tscn` using the red character sprite and `BossEnemy` skill/chase state path.
- Boss skill state now has a bounded windup/active/recovery cycle and returns to chase instead of remaining in a stuck state.
- The smoke failure recorded in `production/qa/smoke-2026-05-24.md` was retested and did not reproduce in the 2026-05-25 automated smoke run.

## 关联文件

- `production/qa/smoke-2026-05-24.md`
- `scripts/general/character.gd`
- `scripts/general/attack.gd`
- `scripts/enemy/`
- `scenes/enemy/`
- `scenes/levels/level_demo.tscn`

## 后续依赖

- Story 2-2 需要在此 bug 修复后补充 level_2 集成测试证据。
