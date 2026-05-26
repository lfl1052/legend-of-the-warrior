# Story 2-5 - 扩展 level_demo 地图长度

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: must-have
**Owner**: level-designer
**Estimate**: 1.5 days
**Type**: Level / Content

## 用户故事

作为玩家，
我需要 level_demo 从短测试场景扩展成 3-5 分钟的可玩关卡，
以便核心移动、战斗、探索和奖励形成完整体验。

## 验收标准

- [x] `level_demo` 地图长度至少扩展到当前长度的 2 倍。
- [x] 增加平台跳跃段落。
- [x] 增加敌人配置和节奏变化。
- [x] 放置宝箱和陶罐等可交互物品。
- [x] TileMap 绘制完整，无明显空洞或阻塞主路径。

## 实现笔记

- 如果工作量超出预期，优先保证主路径可通关和关键交互放置，再降级装饰内容。
- 依赖 Story 2-3/2-4 的可交互物品场景可用。

## Test Evidence

- `tests/integration/level_2_load_test.tscn` PASS on 2026-05-25 and validates `level_demo` required nodes, enemy count, chest, breakable, HUD, save point, and teleport.
- `tests/e2e/smoke_test.tscn` PASS on 2026-05-25: menu to level_demo, world nodes, player attack path, save point, and teleport back to menu.
- Full unit suite PASS on 2026-05-25: 64/64 passing.

## Completion Notes

- `scenes/levels/level_demo.tscn` now includes the Sprint 2 interactable props and extended route content.
- The automated smoke path verifies the playable loop remains navigable after the level expansion.

## 关联文件

- `scenes/levels/level_demo.tscn`
- `data/scene_level_demo.tres`
- `scenes/enemy/`

## 后续依赖

- 无。
