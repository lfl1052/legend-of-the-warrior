# Story 2-8 - 基础音效系统

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: should-have
**Owner**: audio-programmer
**Estimate**: 1.0 day
**Type**: Audio / Integration

## 用户故事

作为玩家，
我需要攻击、受击、跳跃和开宝箱等动作有基础音效，
以便游戏反馈更完整。

## 验收标准

- [x] `AudioManager` 支持播放短促音效。
- [x] 至少接入攻击、受击、跳跃、开宝箱四类触发点。
- [x] 至少提供 5 个占位音效资源或可生成的占位音效。
- [x] 音效音量可配置。
- [x] 自动测试或手动验证记录覆盖事件触发和音量配置。

## 实现笔记

- 复用现有 `AudioManager` 和 `AudioDefinition`，避免新增平行音频入口。
- 占位资源可以后续替换，接口需要保持稳定。

## Test Evidence

- `tests/unit/test_audio_manager.gd` PASS on 2026-05-25: 6/6 tests covering placeholder SFX IDs, SFX volume, BGM volume separation, BGM fade start, stop cleanup, and late-event shutdown handling.
- `tests/unit/test_game_events.gd` PASS on 2026-05-25: verifies `play_sfx`, `play_fx`, `play_bgm`, and `play_bgm_id` signals are available.
- Full unit suite PASS on 2026-05-25: 64/64 passing after Sprint 2 2-6 through 2-10 implementation.
- `tests/e2e/smoke_test.tscn` PASS on 2026-05-25: core attack/save/teleport flow remains stable with audio autoload enabled.

## Completion Notes

- `AudioManager` now provides generated placeholder SFX ids: `attack`, `hurt`, `jump`, `chest_open`, and `breakable_break`.
- Trigger points are wired through `GameEvents.raise_play_sfx()` in attack feedback, character damage, player jump/dash, chest open, and breakable break paths.
- `set_fx_volume()` configures SFX pool volume separately from BGM volume.
- Headless test runs keep stream assignment testable while disabling actual playback to avoid audio backend leaks during automated shutdown.

## 关联文件

- `scripts/autoload/audio_manager.gd`
- `scripts/general/audio_definition.gd`
- `scripts/autoload/game_events.gd`

## 后续依赖

- Story 2-10 背景音乐系统依赖本 story。
