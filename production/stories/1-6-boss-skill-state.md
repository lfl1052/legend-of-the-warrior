# Story 1-6 - BossEnemy 专属 skill_state 实现

**Status**: Complete
**Last Updated**: 2026-05-22
**Completed**: 2026-05-22
**Sprint**: 1
**Priority**: should-have
**Owner**: ai-programmer
**Estimate**: 1.5 days
**Type**: AI / Combat

## 用户故事

作为玩法实现者，我需要 BossEnemy 拥有一个可运行的专属技能状态，使 Boss 能从追击进入技能、释放攻击窗口、再回到追击状态，形成可验证的战斗闭环。

## 验收标准

- [x] 至少 1 个可用 Boss 技能状态。
- [x] `CHASE -> SKILL -> CHASE` 状态切换闭环可自动验证。
- [x] 技能有 windup / active / recovery 三段时序。
- [x] 技能 active 阶段启用 `Attack` 命中框，结束后关闭。
- [x] 附带 1 个集成测试场景。

## 实现笔记

- `BossEnemy` 现在默认装配 `BossChaseState` 与 `BossSkillState`。
- `BossSkillState` 使用 windup / active / recovery 三段式逻辑，并通过 `BossEnemy.set_skill_hitbox_active()` 控制 `SkillAttack`。
- `scenes/enemy/boss_enemy.tscn` 提供可实例化的占位 Boss，包括 `Character`、`PhysicsCheck`、`SkillAttack` 与基本动画名。
- `tests/integration/boss_skill_state_test.tscn` 是自动测试场景；`tests/unit/test_boss_skill_state.gd` 验证状态闭环。

## Test Evidence

- `Godot_v4.6.3-stable_win64.exe --headless --path . --check-only` Exit 0
- `addons\gdUnit4\runtest.cmd --add tests\unit` Exit 0, 43/43 PASS
- `Godot_v4.6.3-stable_win64.exe --headless --path . --scene res://scenes/levels/level_2.tscn --quit-after 20` Exit 0

## 关联文件

- `scripts/enemy/boss_enemy.gd`
- `scripts/enemy/boss_chase_state.gd`
- `scripts/enemy/boss_skill_state.gd`
- `scenes/enemy/boss_enemy.tscn`
- `tests/integration/boss_skill_state_test.tscn`
- `tests/unit/test_boss_skill_state.gd`
