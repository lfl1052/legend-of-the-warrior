# 系统 GDD: Encounter / Boss 战

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-ENCOUNTER |
| **系统名称** | Encounter / Boss 战 |
| **优先级** | 🟠 P1 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-07-16 |
| **源码参考** | `scripts/enemy/enemy_encounter_contracts.gd`, `scripts/enemy/enemy_encounter_combatant.gd`, `scripts/enemy/encounter_reward_controller.gd`, `scripts/enemy/boss_enemy.gd`, `scripts/enemy/boss_arena_lock.gd` |

---

## 概述

将一组敌人组织为一个 Encounter 战斗单元，统一管理战斗区域、战斗状态、战利品分配。支持普通小兵（Minion）、精英（Elite）和 Boss 三种角色。

## 类层次

```
EnemyCombatant (CharacterBody2D)
 ├── EnemyMinion          # 普通小兵，可被 Encounter 管理激活/关闭
 ├── EliteEnemy           # 精英模板，自带特殊技能状态
 ├── BossEnemy            # Boss 模板
 └── EnemyEncounterCombatant  # Encounter 管理的战斗者
```

### EnemyMinion

普通敌人变体，可被 Encounter 管理器批量控制。通常在进入 Encounter 区域前处于"休眠"状态。

### EliteEnemy

精英敌人，在 Enemy 基础上叠加特殊技能状态（如 BoarElite 的冲刺）。通过 `_setup_states()` 中装配额外的 `skill_state`。

### BossEnemy

Boss 级敌人，拥有独立的战斗阶段和技能循环。是 Encounter 系统管理的最高难度目标。

`phase_thresholds = [0.66, 0.33]` 仍是规则真相。进入第二、第三阶段时，Boss 按自身 Inspector 基础参数应用倍率：冲击波冷却缩短为 `0.77x / 0.61x`、蓄力缩短为 `0.75x / 0.55x`、追击速度提升为 `1.14x / 1.28x`；范围扩大为 `1.28x / 1.56x`，第三阶段伤害提高到 3。所有范围变化同时写入 `SkillAttack` 圆形碰撞与预警圈，避免 HUD 阶段和实际判定分离。

首次发现玩家或受到伤害时，`BossEnemy.arena_engaged` 驱动 `BossArenaLock` 关闭 Level 2 的入口/出口 `StaticBody2D` 门锁；Boss 死亡的 `arena_completed` 重新开启碰撞与视觉门线。门锁不修改玩家坐标或移动参数。

### EnemyEncounterCombatant

Encounter 专属战斗者，追踪与 Encounter 管理器的绑定关系。

## Encounter 流程

```
Boss 发现玩家或首次受到伤害
    ↓
Boss / ArenaLock 激活
    ├─ `BossArenaLock` 启用入口与出口 StaticBody2D
    ├─ `BossEnemy.arena_engaged`
    ├─ GameEvents.raise_encounter_focus_changed(self)
    └─ HUD 切换到 Encounter 模式
    ↓
战斗进行中
    ├─ GameEvents.raise_encounter_phase_changed(self, phase)
    ├─ GameEvents.raise_encounter_poise_changed(self, ratio)
    └─ GameEvents.raise_encounter_skill_cooldown_changed(self, skill_id, ratio)
    ↓
所有敌人击败
    └─ 发放战利品 / 解锁区域 / 继续推进
```

## Encounter 信号

| 信号 | 来源 | 接收者 |
|------|------|--------|
| `encounter_focus_changed` | Encounter 管理器 | HUD 状态切换 |
| `encounter_phase_changed` | Boss/Elite 阶段变化 | HUD 阶段显示 |
| `encounter_poise_changed` | 韧性值变化 | HUD 韧性条 |
| `encounter_skill_cooldown_changed` | 技能冷却 | HUD 冷却显示 |

## 关联 UI

| UI 组件 | 文件 | 说明 |
|---------|------|------|
| `EnemyEncounterBar` | `scripts/ui/enemy_encounter_bar.gd` | Encounter 专属 HP/韧性条 |
| `EnemyEncounterHUDState` | `scripts/ui/enemy_encounter_hud_state.gd` | Encounter HUD 状态机 |

## 数据流

```
Area2D body_entered (玩家进入)
    ↓
Encounter 激活信号
    ↓
EnemyMinion._on_encounter_activated()
    ├─ 启用 AI / 状态机
    └─ 切换到 PATROL / CHASE
    ↓
玩家击败所有小兵 / Boss
    ↓
Encounter 完成信号
    ├─ GameEvents.raise_reward_notification(reward_id)
    └─ 区域解锁
```

## 完成状态

- [x] BossEnemy 专用 skill_state 实现
- [x] 多阶段 Boss 战：阶段影响冲击波范围、伤害、蓄力、冷却与追击节奏
- [x] Encounter 区域锁定：Level 2 的入口/出口物理门锁随 Boss 信号开闭
- [x] 战利品表与 Encounter 绑定；稳定 ID 与 PlayerProgression 存档负责防重复
