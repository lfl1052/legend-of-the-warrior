# 系统 GDD: Player Controller

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-PLAYER |
| **系统名称** | 玩家控制 |
| **优先级** | 🔴 P0 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-07-15 |
| **源码参考** | `scripts/player/player_controller.gd`, `scripts/player/player_animation.gd`, `scripts/player/player_skill_slash.gd`, `scripts/player/player_heal_skill.gd`, `scripts/player/player_progression.gd` |

---

## 概述

玩家角色控制，从 Unity `PlayerController.cs` 迁移。包含移动、跳跃、蹬墙跳、行走切换、落地表现、下蹲、梯子攀爬、三段连击、滑铲（带无敌帧）、正面格挡、受击/死亡/复活、治疗与技能斩，以及自动化驱动接口（用于调试/教学）。

## 节点结构期望

```
PlayerController (CharacterBody2D)
 ├── Sprite/AnimatedSprite2D              # 视觉表现
 ├── AnimationPlayer                      # 动画状态机
 ├── CollisionShape2D                     # 身体主碰撞，只负责移动阻挡
 ├── HurtBox/CollisionShape2D             # 独立受击框，PlayerHurtBox 层
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
| `run_speed` | 220.0 | 奔跑速度 |
| `walk_speed` | 110.0 | 行走速度 |
| `jump_velocity` | -600.0 | 跳跃初速度 |
| `wall_jump_horizontal_velocity` | 380.0 | 蹬墙跳水平分量 |
| `wall_jump_vertical_velocity` | -560.0 | 蹬墙跳垂直分量 |
| `wall_slide_max_speed` | 140.0 | 贴墙下落最大速度 |
| `slide_speed` | 320.0 | 滑铲速度 |
| `slide_duration` | 0.44s | 滑铲安全超时下限 |
| `slide_distance` | 140.8 | 固定目标距离，沿用原速度×时长的既有手感 |
| `slide_power_cost` | 20.0 | 项目默认消耗；课程笔记未记录原始精确值 |
| `slide_collider_height` / `slide_hurtbox_height` | 24.0 / 20.0 | 滑铲身体框/受击框高度，保持脚底基线 |
| `COMBO_RESET` | 0.70s | 连击计时器超时（脚本常量） |
| `HURT_KNOCKBACK` | 220.0 | 受击后退速度（脚本常量） |
| `coyote_time` / `jump_buffer_time` | 0.12s / 0.12s | 郊狼时间与跳跃缓冲 |
| `ground_acceleration` / `ground_deceleration` | 1400.0 / 3000.0 | 地面起步与停止加速度 |
| `crouch_collider_height` | 28.0 | 下蹲时 Capsule 高度；站立高度为 40.0 |
| `climb_speed` | 120.0 | 梯子纵向移动速度 |
| `ladder_snap_speed` | 480.0 | 攀爬时吸附梯子中心的水平速度 |
| `land_visual_duration` | 0.18s | 落地动画的最大表现窗口，不锁定操作 |
| `block_power_cost` | 15.0 | 每次成功格挡消耗的能量 |

速度、加速度、跳跃窗口和滑铲参数已 `@export`，可在 Inspector 中按角色调整；连击重置和受击击退仍是脚本常量。

## 输入映射

| 动作 | 操作 |
|------|------|
| `move_left` / `move_right` | 水平移动（轴输入） |
| `move_up` / `move_down` | 梯子攀爬；`move_down` 在地面同时用于下蹲 |
| `jump` | 跳跃 / 蹬墙跳 |
| `attack` | 攻击（三段连击） |
| `walk` | 按下时行走模式 |
| `slide` | 滑铲 |
| `heal` | 治疗 |
| `skill_slash` | 技能斩 |
| `block` | 按住时进入正面格挡 |
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
- 蹬墙跳：当 `PhysicsCheck.touch_left` 或 `touch_right` 为 true 且未落地时，触发水平+垂直跳跃（`wall_jump_horizontal_velocity` / `wall_jump_vertical_velocity`）
- 墙滑：角色正在下落、接触墙面且输入方向朝向该墙时，把下落速度限制为 `wall_slide_max_speed`；松开或输入离墙方向后立即恢复普通下落
- 墙滑与墙跳判定分离：只要仍接触墙面即可触发墙跳，不要求当前处于墙滑表现
- 支持 0.12 秒郊狼时间、跳跃缓冲和短按截断上升速度
- 重力使用 ProjectSettings `physics/2d/default_gravity`

### 落地 (Land)
- 由“上一物理帧未接地、当前帧接地”的边沿触发，表现窗口为 `land_visual_duration=0.18s`
- Land 不锁定业务状态；移动、攻击、滑铲、下蹲、格挡和技能等高优先级动作可立即打断
- 仅在接地且没有水平移动时选择 `land`，避免角色已开始移动仍被落地姿态覆盖

### 下蹲 (Crouch)
- 接地按住 `move_down` 进入，空中不能进入；下蹲期间水平速度归零，不提供蹲走
- 身体 Capsule 高度从 40 缩短到 28，并同步下移碰撞体，保持脚底世界坐标不变
- 松开输入时使用物理 Shape Query 检查站立体积；头顶空间不足则继续下蹲，不把角色恢复到地形内部
- 每个玩家实例复制自己的 CapsuleShape，运行时尺寸变化不会污染共享场景资源

### 梯子攀爬 (Climb)
- 玩家进入 `LadderArea` 后，按 `move_up` / `move_down` 激活攀爬；没有梯子区域时纵向输入不改变移动规则
- 攀爬时关闭重力，速度为 `vertical_input × climb_speed`，并以 `ladder_snap_speed` 吸附梯子中心
- 无纵向输入时保持梯子状态并暂停 `climb` 动画；按 `jump` 可跳离，离开区域立即恢复普通重力与移动状态
- Demo 关卡的 `TrainingLadder` 用于安全教学和冒烟装载检查

### 三段连击 (Combo)
- 连续按 `attack`，`combo_index` 在 1→2→3 循环
- 每次攻击重置 `_combo_timer = COMBO_RESET`（0.70s）
- 超时未按下一击则 combo_index 归零
- 动画名: `attack1` / `attack2` / `attack3`，回退 `attack`
- 攻击期间 `velocity.x = 0.0`（地面站定）
- 三段分别使用 `44×32 @ (34,-2)`、`54×36 @ (40,-1)`、`68×44 @ (46,-2)` 判定；伤害与剑招幅度逐段增长
- 攻击查询命中 HurtBox 后解析回角色本体，同一角色的身体框和受击框不会造成重复伤害

### 滑铲 (Slide)
- 地面限定，不可在攻击/受击时触发
- 按稳定朝向计算固定 `slide_distance=140.8px` 目标，以 `slide_speed` 向目标推进
- 开始时消耗 `slide_power_cost=20`；能量不足不进入状态、不扣能量、不触发冷却
- 身体 Capsule 由高 40 缩为 24，HurtBox 由高 34 缩为 20，二者下移保持脚底不变
- 临时清除与 PlayerAttack / Hazard 层的碰撞（无敌帧）
- 到达目标、撞墙、离开地面或安全超时都会统一结束；受击、死亡、复活、新游戏和输入禁用也走同一恢复入口
- 结束时恢复 collision mask、身体框、HurtBox 和水平速度
- 动画: `slide`；音效 ID: `slide`

### 格挡 (Block)
- 接地按住 `block` 进入，格挡期间水平速度归零；攻击、受击、滑铲、施法、下蹲或攀梯时不能进入
- 仅阻止来自当前朝向正面的攻击；背面攻击继续走 `take_damage()` 的统一伤害链
- 每次成功格挡消耗 `block_power_cost=15` 能量并播放格挡音效与命中反馈
- 能量不足时立即退出格挡并正常受伤，避免出现无成本防御或仅有动画没有规则效果

### 受击 (Hurt)
- 收到 `Character.took_damage` 信号
- 状态: `is_hurt = true`，打断攻击/滑铲
- 击退: 从攻击者方向施加 `hurt_knockback` 水平速度 + 40% 跳跃速度
- 动画: `hurt`，播放完毕回调 `on_hurt_animation_finished()`
- PlayerAnimation 桥接节点的 `animation_finished` 信号转发给 controller
- 站立 HurtBox 为 `Capsule(半径10, 高34, y=-2)`；下蹲时高度同步缩为 22 且保持底边不跳动
- 玩家受击后保留全局 `0.5s` 无敌窗口，用于限制多敌同时接触造成的瞬间叠伤

### 死亡与复活
- 血量归零 → `_on_died()` → `is_dead = true` → 播放 `dead` 动画 → `GameEvents.raise_game_over()`
- `revive_at(pos: Vector2)`: 重置所有状态 + 满血 + 位移

### 治疗 (Heal)
- 按 `heal` 键
- 通过 `HealSkill.try_use(self)` 调用；需要 `HealSkill` 节点存在、已解锁治疗、能量达到 95% 且生命未满
- 播放独立 `heal` 施法动画，0.32s 生效帧才恢复 45% 最大生命并结算能量，0.62s 结束回调、0.64s 动画长度
- 攻击、受击、死亡、滑铲、下蹲、格挡、攀梯或其他技能中不能开始；生效帧前被受击/死亡打断时不治疗、不扣能量

### 技能斩 (Skill Slash)
- 按 `skill_slash` 键
- 通过 `SkillSlash.try_use(self)` 调用；需要 `SkillSlash` 节点存在
- 消耗 35 点能量，对朝向前方 `160×80` 范围内的每个目标造成 2 点伤害
- 播放 `skill_slash` 动画（`spell_cast` 序列帧 64–71），0.32s 进入生效帧并结算伤害，0.64s 收招结束
- 前摇和 Active 期间绘制覆盖 `160×80` 逻辑边界的前向弧形斩击轨迹，取消技能时同步清除
- 施法期间锁定移动、普通攻击和滑铲；受击、死亡、复活或禁用玩法输入会取消尚未生效的技能
- 仅在当前状态允许施法时消耗能量；攻击、受击、死亡、滑铲或技能动作中再次输入不会扣除能量

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
| 梯子内攀爬 / 停驻 | `climb`（停驻时暂停动画） |
| 正面格挡 | `block` |
| 下蹲 | `crouch` |
| 蹬墙 | `wall` |
| 上升中 | `jump` |
| 下落中 | `fall` |
| 刚落地且未移动 | `land` |
| 移动中且 walking | `walk` |
| 移动中且 !walking | `run` |
| 静止 | `idle` |
| 攻击中/受击/死亡/滑铲/治疗/技能斩 | 由各方法直接 play，`_update_animation` 跳过 |

动作图集语义契约：`walk` 使用 `char_blue_2` 的 0–7 帧，`wall` 使用 `char_blue_2` 的 24–27 帧，`climb` 使用 `char_blue_2` 的 40–47 帧；`fall` 使用 `char_blue_1` 的 32–37 帧，`land` 使用 38–39 帧，`heal` 使用 64–71 帧，`crouch` 使用 72–74 帧，`block` 使用 80–82 帧。所有映射由视觉契约测试同时校验纹理、vframes 与首末帧。

## 数据流

```
Input.get_axis/just_pressed
    ↓ (或 ai_* 标志)
_read_move_input / _read_jump_pressed / _read_attack_pressed
    ↓
_physics_process (delta)
    ├─ 重力 → move_and_slide
    ├─ 跳跃/蹬墙跳 → velocity.y 更新
    ├─ 下蹲/格挡 → 地面姿态与碰撞体规则
    ├─ LadderArea + 纵轴 → 攀爬/跳离梯子
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
| `LadderArea` | 外部 Area2D | 通知玩家进入/离开可攀爬区域 |
| `GameEvents` | Autoload | 游戏流程信号 + 事件总线 |
| `DataManager` | Autoload | 玩家位置持久化 |

## 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 动画未定义时 `_anim.play("name")` 静默失败 | 低 | 中 | `_play_if_present` 检查 `has_animation` |
| 蹬墙跳碰撞层配置错误 | 中 | 高 | `PhysicsCheck.touch_left/right` 依赖正确碰撞层 |
| 滑铲无敌帧不生效 | 中 | 中 | 滑铲时 collision_mask 临时移除 layer 4/6，需验证 |
| 组合键冲突（攻击+跳跃） | 低 | 低 | `_physics_process` 顺序执行，单个 frame 内按优先级处理 |
