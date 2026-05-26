# Story 2-4 - 可交互物品系统：可破坏物（陶罐）

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: must-have
**Owner**: gameplay-programmer
**Estimate**: 1.0 day
**Type**: Gameplay / Combat

## 用户故事

作为玩家，
我需要攻击陶罐等可破坏物并获得掉落反馈，
以便战斗和探索空间更有互动性。

## 验收标准

- [x] 新增 `scripts/general/breakable.gd` 或等效可破坏物组件。
- [x] 可破坏物受击后破碎或进入已破坏状态。
- [x] 可破坏物支持掉落物品或触发奖励表。
- [x] 至少创建 1 个陶罐场景。
- [x] 单元测试覆盖受击破碎与重复破坏不重复掉落。

## 实现笔记

- 依赖 Story 2-3 的奖励/一次性标记约定。
- 优先复用 `Attack` / `Character` 可测试接口，避免新增平行伤害系统。
- 可使用占位美术，后续 Sprint 替换陶罐资源。

## Test Evidence

- `tests/unit/test_breakable.gd` PASS on 2026-05-25: damage, broken state, reward-once behavior, and save/load restore covered.
- Sprint prop unit set PASS on 2026-05-25: `test_chest.gd`, `test_breakable.gd`, and `test_attack.gd` passed 8/8.
- `tests/integration/level_2_load_test.tscn` PASS on 2026-05-25 and verifies `BreakableRockA` in both `level_2` and `level_demo`.

## Completion Notes

- Added `scripts/general/breakable.gd` and reusable prop scene `scenes/props/breakable_rock.tscn`.
- Placed stable-id breakable instances in `scenes/levels/level_demo.tscn` and `scenes/levels/level_2.tscn`.
- Breakable objects use the existing player attack collision path, avoiding a parallel damage system.

## 关联文件

- `scripts/general/breakable.gd`
- `scripts/general/attack.gd`
- `scripts/general/character.gd`
- `data/loot.json`

## 后续依赖

- Story 2-5 会在 level_demo 中放置陶罐。
