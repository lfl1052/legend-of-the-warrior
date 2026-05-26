# Story 2-9 - 玩家技能：冲刺/闪避

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: nice-to-have
**Owner**: gameplay-programmer
**Estimate**: 1.5 days
**Type**: Gameplay / Player Controller

## 用户故事

作为玩家，
我需要按键触发短距离冲刺或闪避，
以便战斗中有主动规避和位移选择。

## 验收标准

- [x] 玩家按 K 键触发冲刺/闪避。
- [x] 冲刺为短距离快速移动。
- [x] 冲刺期间有短暂无敌帧。
- [x] 冲刺有冷却时间，不能无限连发。
- [x] 动画或占位视觉反馈可用。

## 实现笔记

- 复用玩家控制器已有的无敌帧/碰撞层处理思路。
- Nice to Have，不应挤占 Must Have 修复和地图扩展。

## Test Evidence

- `tests/unit/test_player_dash.gd` PASS on 2026-05-25: covers fast dash movement, temporary invulnerability, and cooldown blocking immediate reuse.
- Full unit suite PASS on 2026-05-25: 64/64 passing after Sprint 2 2-6 through 2-10 implementation.
- `tests/e2e/smoke_test.tscn` PASS on 2026-05-25: core player control flow remains stable after dash cooldown changes.

## Completion Notes

- Player slide/dash now requires `can_dash()` and starts a configurable `slide_cooldown`.
- `_begin_slide()` preserves short fast movement, temporary invulnerability, slide animation when present, and placeholder SFX feedback.
- `prepare_for_new_game_session()` resets dash cooldown for a clean new run.

## 关联文件

- `scripts/player/player_controller.gd`
- `scripts/player/player_animation.gd`
- `scripts/general/character.gd`

## 后续依赖

- 无。
