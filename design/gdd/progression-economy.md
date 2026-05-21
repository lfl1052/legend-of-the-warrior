# 系统 GDD: 进度 & 经济

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-PROGRESSION |
| **系统名称** | 进度 & 经济 |
| **优先级** | 🟡 P2 |
| **状态** | 🟡 部分实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/player/player_progression.gd`, `scripts/resources/player_progression_resource.gd`, `scripts/resources/loot_table_resource.gd`, `scripts/resources/chapter_resource.gd` |

---

## 概述

玩家进度系统维护三种代币（教程经济代币/升级代币/地图代币）、宝箱奖励集合和已解锁槽位。底层由 RuntimeData 加载 JSON 配置文件驱动。

## 核心组件

### PlayerProgression

**文件**: `scripts/player/player_progression.gd`
**继承**: `Node`

**状态**:
| 变量 | 类型 | 设置 |
|------|------|------|
| `tutorial_economy_tokens` | int | ✅ 实现 |
| `upgrade_tokens` | int | ✅ 实现 |
| `map_tokens` | int | ✅ 实现 |
| `opened_chest_rewards` | Dictionary | ✅ 实现 |
| `unlocked_slots` | Dictionary | ✅ 实现 |

**公共 API**:
| 方法 | 说明 |
|------|------|
| `try_apply_chest_rewards(chest_id, table_id)` | 开宝箱：检查是否已开 → 查 loot_table → 发放奖励 |
| `has_unlock_slot(slot) -> bool` | 检查槽位是否解锁 |
| `unlock_slot(slot)` | 解锁槽位 |

**事件通信**:
- `GameEvents.reward_notification.connect(_on_reward_notification)` — 接收奖励
- `GameEvents.raise_reward_notification(reward_id, payload)` — 广播奖励事件

**奖励类型**:
| reward_id | 效果 |
|-----------|------|
| `tutorial-economy-token` | +1 教程经济代币 |
| `upgrade-token` | +1 升级代币 |
| `map-token` | +1 地图代币 |
| `health-refill` | 玩家满血 |
| `power-refill` | 玩家满能量 |
| 其他 (含 `unlock_slot` 字段) | 解锁对应槽位 |

**ISaveable**: 保存/恢复所有代币 `float_data`、已开宝箱 ID、已解锁槽位。

### PlayerProgressionResource

**文件**: `scripts/resources/player_progression_resource.gd`
**继承**: `Resource`

进阶配置的 Resource 封装，通过 `from_dict(RuntimeData.get_player_progression())` 创建。

关键字段:
- `future_unlock_slots`: `@export var future_unlock_slots: Array[StringName]` — 开局即解锁的槽位

### LootTableResource

**文件**: `scripts/resources/loot_table_resource.gd`
**继承**: `Resource`

战利品表定义。配置格式见 `RuntimeData` 的 `loot.json`。

战利品条目结构:
```json
{
  "reward_id": "upgrade-token",
  "amount": 1,
  "weight": 0.5
}
```

查询: `RuntimeData.try_get_loot_table(id: StringName)` 返回 Dictionary。

### ChapterResource

**文件**: `scripts/resources/chapter_resource.gd`
**继承**: `Resource`

章节定义，引用一组 GameSceneResource 组成章节线。

配置格式见 `RuntimeData` 的 `chapters.json`。

## 经济循环

```
玩家探索关卡
    ↓
宝箱（Chest）触发
    ├─ try_apply_chest_rewards(chest_id, table_id)
    │    ├─ 防止重复开箱
    │    └─ RuntimeData.try_get_loot_table(table_id)
    └─ 发放奖励 (upgrade tokens, map tokens 等)
    ↓
存档点 (SavePoint)
    └─ first_activation_reward → power-refill
    ↓
暂停菜单 / ProgressionPanel
    └─ 消耗代币解锁能力槽位
```

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `RuntimeData` | Autoload | 配置加载（loot.json, progression.json） |
| `GameEvents` | Autoload | reward_notification |
| `DataManager` | Autoload | ISaveable 注册/持久化 |
| `Chest` | Node | 宝箱触发入口 |

## 待做

- [ ] `data/loot.json` 未创建
- [ ] `data/progression.json` 未创建
- [ ] `data/chapters.json` 未创建
- [ ] `PlayerProgressionPanel` 完整实现
- [ ] 升阶里程碑的经济平衡数值
