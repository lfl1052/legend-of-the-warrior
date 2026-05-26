# Story 2-10 - 背景音乐系统

**Status**: Complete
**Last Updated**: 2026-05-25
**Sprint**: 2
**Priority**: nice-to-have
**Owner**: audio-programmer
**Estimate**: 0.5 day
**Type**: Audio / Scene Transition

## 用户故事

作为玩家，
我需要菜单和关卡有循环播放的背景音乐，
以便游戏氛围更完整。

## 验收标准

- [x] `AudioManager` 支持循环播放背景音乐。
- [x] 至少 1 首占位 BGM 可播放。
- [x] 场景切换时 BGM 可淡入淡出或平滑切换。
- [x] 音量配置与音效配置不冲突。

## 实现笔记

- 依赖 Story 2-8 的基础音效/音频配置梳理。
- 优先使用现有 `AudioManager.play_bgm` 路径，补齐缺口而不是重写。

## Test Evidence

- `tests/unit/test_audio_manager.gd` PASS on 2026-05-25: verifies `demo_theme` BGM stream exists, uses separate BGM volume, loop-capable stream setup, fade-duration start behavior, and cleanup paths.
- `tests/unit/test_game_events.gd` PASS on 2026-05-25: verifies BGM event surface.
- `tests/e2e/smoke_test.tscn` PASS on 2026-05-25: menu to level scene flow runs with scene-load BGM hook enabled.
- Full unit suite PASS on 2026-05-25: 64/64 passing after Sprint 2 2-6 through 2-10 implementation.

## Completion Notes

- `AudioManager` now provides generated looping placeholder BGM id `demo_theme`.
- `SceneLoader` requests `demo_theme` after scene load through `GameEvents.raise_play_bgm_id(&"demo_theme", 0.2)`.
- New BGM requests can start from silence and tween to configured BGM volume; repeated requests for the same playing stream are ignored to avoid hard restarts.
- BGM volume is configured independently from SFX volume.

## 关联文件

- `scripts/autoload/audio_manager.gd`
- `scripts/general/audio_definition.gd`
- `scripts/transition/`

## 后续依赖

- 无。
