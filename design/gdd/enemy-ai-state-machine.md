# 系统 GDD: Enemy AI 状态机

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-ENEMY-AI |
| **系统名称** | 敌人 AI 状态机 |
| **优先级** | 🔴 P0 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-07-15 |
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
- 行为: 执行专属技能动作；当前普通敌人中蜗牛使用缩壳防御，蜜蜂攻击作为 Chase 内部子阶段，普通野猪没有独立 Skill
- 切换条件: 技能完成后回到 CHASE 或 PATROL

## 敌人类型

### Bee（蜜蜂）

| 属性 | 值 |
|------|-----|
| **文件** | `bee.gd`, `bee_patrol_state.gd`, `bee_chase_state.gd` |
| **移动** | 飞行（无视重力），水平 + 垂直追踪 |
| **巡逻** | 在出场点周围徘徊 |
| **追击** | 朝玩家上方悬停点二维移动 |
| **攻击** | Chase 内执行 Startup → Active → Retreat；只有 Active 开启 AttackBox |

### Boar（野猪）

| 属性 | 值 |
|------|-----|
| **文件** | `boar.gd`, `boar_patrol_state.gd`, `boar_chase_state.gd`, `boar_elite.gd`, `boar_elite_skill_state.gd`, `scenes/enemy/boar.tscn` |
| **移动** | 地面行走，受重力影响 |
| **巡逻** | 在巡逻点之间往返行走 |
| **追击** | 加速冲向玩家 |
| **攻击** | 普通型仅在实际移动时开启前向接触攻击区；墙/边缘等待、受击时关闭；Elite 变体另有冲刺技能 |

### Snail（蜗牛）

| 属性 | 值 |
|------|-----|
| **文件** | `snail.gd`, `snail_patrol_state.gd`, `snail_skill_state.gd` |
| **移动** | 慢速地面 |
| **巡逻** | 缓慢移动 |
| **追击** | （无追击逻辑） |
| **攻击** | 前向接触攻击区随实际 CollisionShape 朝向翻转；等待、受击和缩壳阶段关闭 |
| **技能** | Hide → 壳内等待 → Unhide；壳内无敌 |

## 课程动作与动画契约

| 敌人 | 课程行为目标 | 当前 Godot 规则 | 原图集映射 |
|------|--------------|------------------|------------|
| Boar | Walk 巡逻、墙前 Idle 等待、Run 追击、Hurt/Dead | 墙或边缘前等待 0.4s；等待播放 Idle，恢复后 Walk；追击与受击恢复使用 Run；接触攻击走统一 Attack 入口 | Idle 4 帧、Walk 6 帧、Run 6 帧、Hit/Vanish 4 帧 |
| Snail | 慢速巡逻、正面发现后缩壳、防御结束后伸出 | 前方感知与背刺盲区；Hide/Waiting/Unhide 三阶段；接触攻击区随朝向翻转 | Walk 0–7；Hide 0–3；闭壳保持 3；Unhide 4–7；Dead 0–7 |
| Bee | 随机飞行、追到玩家上方、间隔攻击 | 固定出生中心巡逻；追击悬停；0.35s Startup、0.12s Active、0.55s Retreat；受击或离开状态关闭命中盒 | Fly 0–3；Attack 0–3；Hurt 0–3；Dead/vanish 0–3 |

所有伤害继续经过 `Attack → HurtBox → target.take_damage()`；动画表示状态结果，不负责开启 AI 状态。Bee 使用 Startup/Active/Retreat 窗口，Boar/Snail 的接触攻击由移动/等待/缩壳等规则状态显式启停。

正式玩家和敌人场景均把身体碰撞与 HurtBox 分离：身体层继续用于地形和感知，PlayerHurtBox / EnemyHurtBox 层只用于战斗命中。普通敌人受击无敌为 `0.18s`，Boss 为 `0.22s`，允许三连击逐段命中；玩家仍使用 `0.5s` 全局保护窗口。Boss 半径 72 的范围技在 Windup/Active 阶段绘制同半径圆形预警。

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
- `found_player() -> bool`: 使用缓存的 `CircleShape2D` / `PhysicsShapeQueryParameters2D` 产生候选玩家，再用 `can_see_target()` 射线确认 World 碰撞未遮挡；通过后设置 `attacker` 并重置 `lost_time_counter`
- `_update_target_tracking(delta)`: 仅由 Enemy 基类在 Chase 中维护目标记忆；仍在范围且视线清晰时刷新计时，失去目标时每帧只递减一次，归零后清除 `attacker`

**生命周期**:
- `_ready()`: `super._ready()` → 记 `spawn_point` → 初始化感知查询 → `_setup_states()` → `switch_state(PATROL)`
- `_process(delta)`: 统一更新 Chase 目标记忆 → `_active_state.logic_update(delta)`
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
| state 对象在场景切换后 zombie 引用 | 低 | 中 | `on_exit` 清 `current_enemy = null` |
| 正式敌人场景的动画与碰撞基线漂移 | 中 | 中 | 使用角色视觉契约测试并保留 Windows/OpenGL 代表截图 |
| 攻击动画播放但 AttackBox 未监测 | 中 | 高 | 课程动作测试同时验证 monitoring、实际玩家扣血与窗口关闭 |

## Encounter 完成证据

- [x] Level 2 Boss 使用稳定 encounter ID 聚合成员死亡，并通过 Loot JSON、PlayerProgression 与通知 UI 发放一次性战利品。
- [x] `test_encounter_reward_controller.gd` 覆盖清场奖励与重复死亡信号去重；`level_2_boss_reward.png` 覆盖实际奖励状态。
