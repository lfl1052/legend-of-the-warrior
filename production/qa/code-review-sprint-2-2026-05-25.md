# Code Review: Sprint 2

**Date**: 2026-05-25
**Scope**: Sprint 2 implementation and tests
**Reviewer**: Codex local review
**Verdict**: APPROVED WITH CONDITIONS

---

## Reviewed Files

- `scripts/general/chest.gd`
- `scripts/general/breakable.gd`
- `scripts/autoload/scene_loader.gd`
- `scripts/autoload/audio_manager.gd`
- `scripts/autoload/game_events.gd`
- `scripts/general/attack.gd`
- `scripts/general/character.gd`
- `scripts/general/physics_check.gd`
- `scripts/enemy/boar_patrol_state.gd`
- `scripts/enemy/snail_patrol_state.gd`
- `scripts/player/player_controller.gd`
- `scripts/utilities/camera_control.gd`
- `scripts/player/sign.gd`
- `scenes/props/chest.tscn`
- `scenes/props/breakable_rock.tscn`
- `scenes/levels/level_demo.tscn`
- `scenes/levels/level_2.tscn`
- `tests/unit/test_chest.gd`
- `tests/unit/test_breakable.gd`
- `tests/unit/test_scene_loader.gd`
- `tests/unit/test_combat_feedback.gd`
- `tests/unit/test_audio_manager.gd`
- `tests/unit/test_physics_check.gd`
- `tests/unit/test_player_dash.gd`
- `tests/integration/level_2_load_test.gd`
- `tests/e2e/smoke_test.gd`

---

## Findings

### Fixed During Review

- **SceneLoader fade/threaded-load race**: `SceneLoader` exposed `_pending_scene_path` before `ResourceLoader.load_threaded_request()` had started. During fade delay, `_process()` could poll a path with no threaded load and trigger `load_threaded_get_status()` warnings/fallback loading. Fixed by adding a queued path phase and only moving the path to `_pending_scene_path` after the threaded request succeeds.
- **Smoke test coverage drift**: `smoke_test.gd` had temporarily bypassed the real New Game button chain by calling `change_scene_to_file()` directly. Restored `NewGameButton.pressed` so smoke covers `MainMenu -> GameEvents -> MenuFlow -> SceneLoader`.
- **Audio smoke shutdown leak**: Sprint 2 BGM playback initially left `AudioStreamWAV` / `AudioStreamPlaybackWAV` leaked at headless smoke exit. Fixed by disabling real audio playback in headless runs while keeping stream assignment testable, and by adding explicit `AudioManager` cleanup coverage.

### Remaining Conditions

- Headless smoke exits cleanly with code 0. It no longer reports the previous SceneLoader threaded-load warning, resource-still-in-use errors, `GDScriptFunctionState` leak warning, or Sprint 2 audio playback leak warnings.
- Manual QA sign-off is still required for level feel, chest/breakable feedback, combat feedback, dash feel, and final audio mix feel.

---

## ADR / Architecture Check

- ADR-0001 Event Bus: compliant for scene flow and reward notifications.
- ADR-0002 Saveable protocol: chest and breakable props follow `get_save_id()`, `get_save_data()`, `load_save_data()`, register/unregister lifecycle.
- ADR-0003 GameSceneResource: main menu and teleport scene flow continue to route through `GameSceneResource`; tests also validate scene resource paths.
- Combat feedback and audio triggers continue to route through `GameEvents` instead of direct cross-system references.

---

## Verification

- `addons\gdUnit4\runtest.cmd --add tests/unit` - PASS, 64/64 tests.
- `godot --headless --verbose --log-file integration_level_2_2026-05-25.log --path . --scene res://tests/integration/level_2_load_test.tscn` - PASS.
- `godot --headless --verbose --path . --scene res://tests/e2e/smoke_test.tscn` - PASS, 5/5 steps.

---

## Approval

Approved for Sprint 2 QA hand-off with the conditions above. Merge remains pending until user-approved staging/commit and any desired manual QA pass.
