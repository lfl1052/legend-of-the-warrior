# Story 2-6 - 战斗手感：攻击反馈强化

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: should-have
**Owner**: gameplay-programmer
**Estimate**: 1.0 day
**Type**: Visual / Feel

## 用户故事

作为玩家，
我需要攻击命中时有清晰的震动、顿帧和特效反馈，
以便战斗命中感更明确。

## 验收标准

- [x] 攻击命中时触发可配置的 camera shake。
- [x] 攻击命中时触发短暂 hitstop。
- [x] 攻击命中时触发粒子或占位特效。
- [x] 反馈强度可配置，默认值适合 demo 关卡。
- [x] 验证记录说明命中反馈已接入；人工手感 spot-check 仍建议在 release-candidate 前完成。

## 实现笔记

- 优先复用 `GameEvents` 做跨系统通知，避免攻击组件直接引用 Camera。
- Visual/Feel story 需要手动验证证据；自动测试可覆盖事件发射和配置边界。

## Test Evidence

- `tests/unit/test_combat_feedback.gd` PASS on 2026-05-25: verifies attack hit emits configurable combat feedback payload.
- `tests/unit/test_game_events.gd` PASS on 2026-05-25: verifies `combat_hit_feedback_requested` and camera shake/audio feedback signals exist and emit payloads.
- `tests/e2e/smoke_test.tscn` PASS on 2026-05-25: verifies the core attack path damages an enemy without blocking control flow.
- Full unit suite PASS on 2026-05-25: 64/64 passing after Sprint 2 2-6 through 2-10 implementation.

## Completion Notes

- `Attack` now raises `GameEvents.raise_combat_hit_feedback()` after a successful damage application.
- `GameEvents` fans combat feedback out to camera shake, placeholder SFX, hitstop, and a short-lived placeholder particle burst.
- `CameraControl` consumes configurable shake strength and duration.
- Subjective feel still needs one visible-editor/player spot-check before a release candidate because headless automation cannot judge camera shake strength or hitstop feel.

## 关联文件

- `scripts/general/attack.gd`
- `scripts/utilities/camera_control.gd`
- `scripts/autoload/game_events.gd`

## 后续依赖

- 无。
