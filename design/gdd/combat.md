# 系统 GDD: 战斗判定

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-COMBAT |
| **系统名称** | 战斗判定 |
| **优先级** | 🟡 P2 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/general/character.gd`, `scripts/general/attack.gd`, `scripts/general/physics_check.gd` |

---

## 概述

被 Player 和 Enemy 共享的底层战斗系统，包含角色属性（血量/能量/无敌帧）、攻击判定体、物理检测组件三个核心类。

## 核心类

### Character

**文件**: `scripts/general/character.gd`
**继承**: `Node`

作为玩家/敌人的子节点存在，管理血量和能量。

**属性**:
| 属性 | 默认值 | 说明 |
|------|--------|------|
| `max_health` | 5.0 | 最大生命 |
| `max_power` | 100.0 | 最大能量 |
| `power_recover_speed` | 8.0 | 能量恢复速率/秒 |
| `invulnerable_duration` | 0.5s | 受击无敌时间 |

**信号**:
| 信号 | 参数 | 触发时机 |
|------|------|----------|
| `health_changed` | 无 | 任何血量变化 |
| `took_damage` | `attacker: Node` | 受到伤害时 |
| `died` | 无 | 血量归零时 |

**所有信号同时通过 GameEvents 广播**:
- `GameEvents.raise_character_took_damage(self, attacker)`
- `GameEvents.raise_character_health_changed(self)`
- `GameEvents.raise_character_died(self)`

**公共接口**:
| 方法 | 说明 |
|------|------|
| `take_damage(attacker, amount=1.0)` | 造成伤害，触发无敌帧 |
| `heal(amount)` | 回复血量 |
| `consume_power(amount) -> bool` | 消耗能量，不足返回 false |
| `reset_to_full()` | 满血满能量重置 |
| `is_dead() -> bool` | 血量 ≤ 0 |
| `get_health_ratio() -> float` | 血量比例 |
| `get_power_ratio() -> float` | 能量比例 |

**ISaveable**: 保存/恢复 `current_health` 和 `current_power`（以 `float_data` 形式）。

### Attack

**文件**: `scripts/general/attack.gd`
**继承**: `Area2D`

攻击判定体，支持两种模式：

| 模式 | `per_target_one_hit` | 用途 | 冷却 |
|------|---------------------|------|------|
| One-shot | `true` | 玩家连击 | 每目标终身一次（combo 切换时重置） |
| Repeat | `false` | 敌人持续攻击 | 每 `attack_rate` 秒可再次命中 |

**属性**:
| 属性 | 默认值 | 说明 |
|------|--------|------|
| `damage` | 1 | 伤害值 |
| `attack_range` | 0.25 | 攻击范围（未使用，预留） |
| `attack_rate` | 1.0 | Repeat 模式攻击频率 |
| `per_target_one_hit` | `false` | 模式选择 |

**判定流程**:
1. 目标进入 Area2D（`body_entered` / `area_entered`）→ `_try_apply_damage`
2. 检查: `has_method("take_damage")` 或 `is_in_group("damageable")`
3. 冷却判定后: `target.call("take_damage", get_parent())`
4. Repeat 模式: `_physics_process` 每帧扫描 `get_overlapping_bodies/areas`

### PhysicsCheck

**文件**: `scripts/general/physics_check.gd`
**继承**: `Node2D`

物理环境检测组件，每物理帧更新三个方向的碰撞状态。

**检测点**:
| 方向 | 变量 | 用途 |
|------|------|------|
| 底部 | `is_ground` | 落地判定 |
| 左侧 | `touch_left` | 蹬墙跳 / 贴墙检测 |
| 右侧 | `touch_right` | 蹬墙跳 / 贴墙检测 |

**实现**: 使用 `PhysicsServer2D.intersect_shape` + `CircleShape2D` 检测，自动从父节点的 `CollisionShape2D` 推导偏移。

**可配置属性**:
- `ground_layer` / `wall_layer`: 检测的碰撞层 mask
- `check_radius`: 检测球半径（默认 0.2）
- `bottom_offset` / `left_offset` / `right_offset`: 手动覆盖偏移
- `auto_derive_offsets`: 自动推导（默认 true）

## 数据流

```
Attack Area2D 进入 / _physics_process 扫描
    ↓ target.has_method("take_damage")
Character.take_damage(attacker, amount)
    ├─ 无敌帧判定 (is_invulnerable)
    ├─ current_health 扣减
    ├─ 发出信号: took_damage / health_changed / died
    ├─ 广播 GameEvents
    └─ 回写 data.float_data（ISaveable）
```

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `GameEvents` | Autoload | 广播角色事件 |
| `DataManager` | Autoload | ISaveable 注册 |
| `PersistenceKeyUtility` | 工具 | 存档键解析 |

## 设计决策

- Character 是纯逻辑节点（Node），不是 Node2D — 碰撞/视觉由父节点管理
- Attack 使用 Area2D 的原生信号（body_entered/area_entered）而非自定义物理查询
- PhysicsCheck 每物理帧都查询，是项目最频繁的物理查询点

## 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| PhysicsCheck 每帧 intersect_shape 性能 | 低 | 低 | 仅 3 个点 + 最多 1 个结果 |
| Attack 的 _cooldowns 字典内存泄漏 | 低 | 低 | target 退出时 `_on_target_exited` 清理 |
| take_damage 的 amount 参数未使用（默认 1.0） | 中 | 低 | Enemy 的 take_damage 调用链已支持自定义 amount |
