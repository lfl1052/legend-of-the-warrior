# 系统 GDD: Enemy AI 状态机

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-ENEMY-AI |
| **系统名称** | 敌人 AI 状态机 |
| **优先级** | 🔴 P0 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/enemy/` 共 16 个 `.gd` 文件 |

---

## 概述

从 Unity 项目迁移的敌人 AI 系统，采用状态机模式（BaseState 基类 + 子类实现 Patrol / Chase / Skill 三种状态）。支持三种敌人类型（Bee / Boar / Snail），每种定义自己的行为分支与切换逻辑。Elite/Boss 变体在基础敌人上叠加特殊技能。

## 架构

```
BaseState (RefCounted)
 ├── on_enter(enemy: Node)
 ├── logic_update(delta)
 ├── physics_update(delta)
 └── on_exit()

Enemy (EnemyCombatant → CharacterBody2D)
 ├── patrol_state: BaseState     # 子类装配
 ├── chase_state: BaseState      # 子类装配
 ├── skill_state: BaseState      # 子类装配
 ├── switch_state(new_state)
 └── found_player() → bool
```

## 状态定义

### PATROL（巡逻）
- 行为: 在 `spawn_point` 附近巡逻，或返回出场点
- 切换条件: `found_player()` 返回 true → CHASE
- `get_new_patrol_point()`: 子类覆写，默认返回 `spawn_point`

### CHASE（追击）
- 行为: 朝向玩家移动，进入攻击范围后触发 SKILL
- 切换条件:
  - 进入攻击范围 → SKILL
  - `lost_time_counter` ≤ 0（超时未追踪到玩家）→ PATROL

### SKILL（技能）
- 行为: 执行专属技能动作（冲锋/范围攻击等）
- 切换条件: 技能完成后回到 CHASE 或 PATROL

## 敌人类型

### Bee（蜜蜂）

| 属性 | 值 |
|------|-----|
| **文件** | `bee.gd`, `bee_patrol_state.gd`, `bee_chase_state.gd` |
| **移动** | 飞行（无视重力），水平 + 垂直追踪 |
| **巡逻** | 在出场点周围徘徊 |
| **追击** | 朝玩家位置线性移动 |
| **技能** | （未定义） |

### Boar（野猪）

| 属性 | 值 |
|------|-----|
| **文件** | `boar.gd`, `boar_patrol_state.gd`, `boar_chase_state.gd`, `boar_elite.gd`, `boar_elite_skill_state.gd` |
| **移动** | 地面行走，受重力影响 |
| **巡逻** | 在巡逻点之间往返行走 |
| **追击** | 加速冲向玩家 |
| **技能** | 冲刺攻击（仅 Elite 变体） |

### Snail（蜗牛）

| 属性 | 值 |
|------|-----|
| **文件** | `snail.gd`, `snail_patrol_state.gd`, `snail_skill_state.gd` |
| **移动** | 慢速地面 |
| **巡逻** | 缓慢移动 |
| **追击** | （无追击逻辑） |
| **技能** | 范围攻击（如喷吐） |

## 类层次

```
CharacterBody2D
 └── EnemyCombatant           # 战斗属性: 血量/受伤/死亡
      ├── Enemy               # 状态机: Patrol/Chase/Skill + found_player
      │    ├── EnemyMinion    # 小兵（可被 Encounter 管理）
      │    ├── Bee
      │    ├── Boar
      │    ├── BoarElite
      │    └── Snail
      ├── EliteEnemy          # 精英模板
      ├── BossEnemy           # Boss 模板
      └── EnemyEncounterCombatant  # Encounter 战斗专用
```

### Enemy（核心）

**文件**: `scripts/enemy/enemy.gd`

核心状态机控制器，`extends EnemyCombatant`。

**导出属性**:
| 属性 | 默认值 | 说明 |
|------|--------|------|
| `normal_speed` | 80.0 | 巡逻速度 |
| `chase_speed` | 160.0 | 追击速度 |
| `lost_time` | 1.5s | 丢失目标后放弃追击的超时 |
| `check_distance` | 4.5 | 玩家检测半径 |
| `attack_layer_mask` | 1 << 1 | 检测碰撞层（Player 层） |
| `requires_line_of_sight` | true | 范围检测后是否验证世界遮挡 |
| `line_of_sight_mask` | World + Player | 视线射线可命中的层 |

**状态机方法**:
- `_setup_states()`: 子类覆写，装配 `patrol_state` / `chase_state` / `skill_state`
- `switch_state(new_state: int)`: 调用当前状态的 `on_exit()` → 新状态的 `on_enter(self)`
- `found_player() -> bool`: 先使用 `CircleShape2D` 重叠检测产生候选玩家，再用 `can_see_target()` 射线确认 World 碰撞未遮挡；通过后设置 `attacker` 并重置 `lost_time_counter`

**生命周期**:
- `_ready()`: `super._ready()` → 记 `spawn_point` → `_setup_states()` → `switch_state(PATROL)`
- `_process(delta)`: `_active_state.logic_update(delta)` + `lost_time_counter` 递减
- `_physics_process(delta)`: `super._physics_process(delta)` + `_active_state.physics_update(delta)` + `move_and_slide()`

### EnemyCombatant（战斗基类）

**文件**: `scripts/enemy/enemy_combatant.gd`

继承 `CharacterBody2D`，提供血量/受伤/死亡/击退等战斗属性。被 `Enemy`、`EliteEnemy`、`BossEnemy` 等继承。

## Encounter 系统

**文件**:
- `scripts/enemy/enemy_encounter_contracts.gd` — Encounter 契约定义
- `scripts/enemy/enemy_encounter_combatant.gd` — Encounter 战斗者

一组敌人被组织为一个 Encounter 单位，统一管理激活区域、战斗状态、战利品分配。与 UI 的 `EnemyEncounterBar` / `EnemyEncounterHUDState` 配合显示 Encounter 专属 HUD。

## 数据流

```
_process / _physics_process
    ↓
_active_state.logic_update(delta)
    ├─ found_player() → switch_state(CHASE)
    └─ 巡逻点更新 / 技能判定
_active_state.physics_update(delta)
    ├─ 移动（horizontal/vertical）
    ├─ 朝向（face_direction）
    └─ 攻击判定
    ↓
EnemyCombatant 处理受伤/死亡
    ├─ Character.took_damage → is_hurt
    └─ character_died → is_dead → 清除状态机
```

## 接口契约

```
BaseState:
  on_enter(enemy: Node)       # 注入 current_enemy
  logic_update(delta)         # 逻辑帧（寻找玩家、决策）
  physics_update(delta)       # 物理帧（移动、攻击）
  on_exit()                   # 清理

Enemy (暴露给状态子类):
  spawn_point: Vector2        # 出场点
  current_speed: float        # 当前速度
  normal_speed / chase_speed  # 速度配置
  physics_check: PhysicsCheck # 碰撞检测
  found_player() → bool       # 检测玩家
  face_direction(dir_x)       # 转向
  switch_state(new_state)     # 切换状态
  attacker                    # 当前目标玩家
```

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `Character` | 基类 | 血量/能量，`took_damage` / `died` 信号 |
| `PhysicsCheck` | 子节点 | 地面/墙壁/边缘检测 |
| `GameEvents` | Autoload | `character_died` / `character_took_damage` |
| `Enums.NPCState` | 枚举 | PATROL / CHASE / SKILL |
| `BaseState` | 资源 | 状态基类 |

## 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| _setup_states 未实现（默认空） | 中 | 高 | `switch_state` 中 null state 不调用 on_enter/on_exit，但 `_active_state` 为 null 时 `process` 跳过 |
| found_player 的 CircleShape2D 每次都 new | 中 | 低 | 可缓存 shape 和 query 对象优化 GC |
| state 对象在场景切换后 zombie 引用 | 低 | 中 | `on_exit` 清 `current_enemy = null` |
| Elite/Boss 缺少独立状态实现 | 中 | 中 | 当前 BoarElite 有自己的 skill_state，BossEnemy 尚未实现特殊状态 |

## 待做

- [ ] BossEnemy 的专用 skill_state
- [ ] found_player() 的 PhysicsShapeQueryParameters2D 缓存优化
- [ ] Encounter 完整流程（激活 → 战斗 → 战利品）
