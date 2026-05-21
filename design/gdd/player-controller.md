# 系统 GDD: Player Controller

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-PLAYER |
| **系统名称** | 玩家控制 |
| **优先级** | 🔴 P0 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/player/player_controller.gd`, `scripts/player/player_animation.gd`, `scripts/player/player_skill_slash.gd`, `scripts/player/player_heal_skill.gd`, `scripts/player/player_progression.gd` |

---

## 概述

玩家角色控制，从 Unity `PlayerController.cs` 迁移。包含移动、跳跃、蹬墙跳、行走切换、三段连击、滑铲（带无敌帧）、受击/死亡/复活、治疗与技能斩，以及自动化驱动接口（用于调试/教学）。

## 节点结构期望

```
PlayerController (CharacterBody2D)
 ├── Sprite/AnimatedSprite2D              # 视觉表现
 ├── AnimationPlayer                      # 动画状态机
 ├── CollisionShape2D                     # 身体主碰撞
 ├── PhysicsCheck                         # 脚下/左右检测
 ├── Character                            # 血量/能量（extends Character）
 ├── AttackPivot
 │    └── Attack                          # 连击命中区（可多个）
 ├── HealSkill                            # 治疗技能
 └── SkillSlash                           # 技能斩
```

## 运动参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `run_speed` | 380.0 | 奔跑速度 |
| `walk_speed` | 160.0 | 行走速度 |
| `jump_velocity` | -600.0 | 跳跃初速度 |
| `wall_jump_x` | 380.0 | 蹬墙跳水平分量 |
| `wall_jump_y` | -560.0 | 蹬墙跳垂直分量 |
| `slide_speed` | 540.0 | 滑铲速度 |
| `slide_duration` | 0.42s | 滑铲持续时间 |
| `combo_reset` | 0.55s | 连击计时器超时 |
| `hurt_knockback` | 220.0 | 受击后退速度 |

所有运动参数均已 `@export`，可在 inspector 中按角色调整。

## 输入映射

| 动作 | 操作 |
|------|------|
| `move_left` / `move_right` | 水平移动（轴输入） |
| `jump` | 跳跃 / 蹬墙跳 |
| `attack` | 攻击（三段连击） |
| `walk` | 按下时行走模式 |
| `slide` | 滑铲 |
| `heal` | 治疗 |
| `skill_slash` | 技能斩 |
| `interact` | 交互 |
| `pause` | 暂停 |
| `move` | 移动（冗余轴） |

## 能力详解

### 移动
- 左/右轴输入，`run_speed` 奔跑
- 按住 `walk` 键切换行走模式（`walk_speed`）
- 朝向随移动方向翻转（Sprite + AttackPivot scale.x）

### 跳跃与蹬墙跳
- 地面跳跃：标准 `jump_velocity`
- 蹬墙跳：当 `PhysicsCheck.touch_left` 或 `touch_right` 为 true 且未落地时，触发水平+垂直跳跃（`wall_jump_x` / `wall_jump_y`）
- 重力使用 ProjectSettings `physics/2d/default_gravity`

### 三段连击 (Combo)
- 连续按 `attack`，`combo_index` 在 1→2→3 循环
- 每次攻击重置 `_combo_timer = COMBO_RESET`（0.55s）
- 超时未按下一击则 combo_index 归零
- 动画名: `attack1` / `attack2` / `attack3`，回退 `attack`
- 攻击期间 `velocity.x = 0.0`（地面站定）

### 滑铲 (Slide)
- 地面限定，不可在攻击/受击时触发
- 速度 `slide_speed` × 朝向方向
- 临时清除与 PlayerAttack / Hazard 层的碰撞（无敌帧）
- 离开地面或计时结束自动恢复碰撞
- 动画: `slide`

### 受击 (Hurt)
- 收到 `Character.took_damage` 信号
- 状态: `is_hurt = true`，打断攻击/滑铲
- 击退: 从攻击者方向施加 `hurt_knockback` 水平速度 + 40% 跳跃速度
- 动画: `hurt`，播放完毕回调 `on_hurt_animation_finished()`
- PlayerAnimation 桥接节点的 `animation_finished` 信号转发给 controller

### 死亡与复活
- 血量归零 → `_on_died()` → `is_dead = true` → 播放 `dead` 动画 → `GameEvents.raise_game_over()`
- `revive_at(pos: Vector2)`: 重置所有状态 + 满血 + 位移

### 治疗 (Heal)
- 按 `heal` 键
- 通过 `HealSkill.try_use(self)` 调用
- 需要 `HealSkill` 节点存在

### 技能斩 (Skill Slash)
- 按 `skill_slash` 键
- 通过 `SkillSlash.try_use(self)` 调用
- 需要 `SkillSlash` 节点存在

## 自动化接口

为 AI 驱动/调试脚本提供的编程接口：

| 方法 | 说明 |
|------|------|
| `enable_automation(enable: bool)` | 开启/关闭自动化模式 |
| `automation_move(value: float)` | 设置水平输入（-1.0 ~ 1.0） |
| `automation_jump()` | 触发一次跳跃 |
| `automation_attack()` | 触发一次攻击 |

开启自动化后，`_read_move_input()` / `_read_jump_pressed()` / `_read_attack_pressed()` 优先检查 `ai_*` 标志而非 Input 映射。

## 持久化

实现 ISaveable 鸭子接口（详见 ADR-002）：

| 方法 | 行为 |
|------|------|
| `get_save_id()` | `PersistenceKeyUtility.resolve_key(self, "player")` |
| `get_save_data(data)` | 记录 `global_position` 到 `data.character_pos` |
| `load_save_data(data)` | 从 `data.character_pos` 恢复位置 |

注册: `_ready()` 中 `DataManager.register(self)`
注销: `_exit_tree()` 中 `DataManager.unregister(self)`

## 动画状态

PlayerController 直接控制 AnimationPlayer（通过 `_update_animation`）：

| 条件 | 动画名 |
|------|--------|
| 蹬墙 | `wall` |
| 上升中 | `jump` |
| 下落中 | `fall` |
| 移动中且 walking | `walk` |
| 移动中且 !walking | `run` |
| 静止 | `idle` |
| 攻击中/受击/死亡/滑铲 | 由各方法直接 play，_update_animation 跳过 |

## 数据流

```
Input.get_axis/just_pressed
    ↓ (或 ai_* 标志)
_read_move_input / _read_jump_pressed / _read_attack_pressed
    ↓
_physics_process (delta)
    ├─ 重力 → move_and_slide
    ├─ 跳跃/蹬墙跳 → velocity.y 更新
    ├─ 攻击 → _begin_attack → combo_index
    ├─ 滑铲 → _begin_slide → 临时碰撞层
    ├─ 治疗 → HealSkill.try_use
    └─ 技能斩 → SkillSlash.try_use
    ↓
_update_animation (朝向 + 动画状态)
    ↓
move_and_slide → 物理引擎
```

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `Character` | 子节点 | 血量/能量管理，信号 `died`/`took_damage` |
| `PhysicsCheck` | 子节点 | 地面/墙壁碰撞检测 |
| `Attack` | 子节点 | 连击命中判定 |
| `HealSkill` | 子节点 | 治疗逻辑 |
| `SkillSlash` | 子节点 | 技能斩逻辑 |
| `GameEvents` | Autoload | 游戏流程信号 + 事件总线 |
| `DataManager` | Autoload | 玩家位置持久化 |

## 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 动画未定义时 `_anim.play("name")` 静默失败 | 低 | 中 | `_play_if_present` 检查 `has_animation` |
| 蹬墙跳碰撞层配置错误 | 中 | 高 | `PhysicsCheck.touch_left/right` 依赖正确碰撞层 |
| 滑铲无敌帧不生效 | 中 | 中 | 滑铲时 collision_mask 临时移除 layer 4/6，需验证 |
| 组合键冲突（攻击+跳跃） | 低 | 低 | `_physics_process` 顺序执行，单个 frame 内按优先级处理 |
