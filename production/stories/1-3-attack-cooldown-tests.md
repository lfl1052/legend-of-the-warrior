# Story 1-3 — Attack 攻击冷却逻辑单元测试

**Status**: Complete
**Sprint**: 1
**Priority**: must-have
**Owner**: godot-gdscript-specialist
**Estimate**: 0.5 day
**Completed**: 2026-05-21

## 用户故事

作为 **战斗系统的维护者**，
我需要 **Attack 节点的两种命中模式（one-shot / repeat）和退出冷却清除路径都有测试覆盖**，
以便 **未来调玩家攻击节奏或敌人 attack_rate 时不至于回归玩家"对一个目标连续多次扣血"或"敌人不停打"的旧 bug**。

## 验收标准

- [x] `test_attack_one_shot_hits_target_only_once` — `per_target_one_hit=true` 模式下 5 次重叠仅命中一次
- [x] `test_attack_repeat_respects_attack_rate` — `attack_rate=10.0` 时连续两次调用第二次被冷却拦截
- [x] `test_attack_target_exit_clears_cooldown` — `_on_target_exited()` 后冷却被清空，再次命中可以生效
- [x] 测试不依赖 Area2D 物理回调，直接驱动内部 `_try_apply_damage()` / `_on_target_exited()`
- [x] 用例命名遵循 `test_[system]_[scenario]_[expected_result]`，AAA 三段式

## 实现笔记

- **避开物理时序**：Attack 是 Area2D，正常通路要靠 `area_entered/body_entered` 信号触发命中。但 GdUnit4 单元测试不便等物理 tick，直接调用内部方法 `_try_apply_damage(target)` / `_on_target_exited(target)` 来验证状态机逻辑，命中判定与物理调度解耦。
- **TestTarget**：内嵌 `class TestTarget extends Node2D`，仅实现 `take_damage(_attacker)` 累加 `hit_count`，最小化 mock 表面积。
- **冷却存储**：`_cooldowns` 字典在 one-shot 模式下值为 `INF`（永久冷却），在 repeat 模式下值为时间戳；`_on_target_exited()` 把对应 entry 移除即可解锁。

## 关联文件

- 创建：`tests/unit/test_attack.gd`
- 引用代码：`scripts/general/attack.gd`

## 后续依赖

- **Story 1-9** GdUnit4 升级后 CLI 可批量运行
