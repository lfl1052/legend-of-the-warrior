# 系统 GDD: Save / 持久化

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-SAVE |
| **系统名称** | 存档 / 持久化 |
| **优先级** | 🟠 P1 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/autoload/data_manager.gd`, `scripts/utilities/i_saveable.gd`, `scripts/utilities/persistence_key_utility.gd`, `scripts/player/save_point.gd` |

**ADR**: [ADR-002: ISaveable 鸭子类型 + 存档协议](../architecture/adr-002-saveable-protocol.md)

---

## 概述

ISaveable 鸭子接口 + DataManager 中央注册表 + user://SAVE_DATA/data.sav JSON 单文件存档。存档点（SavePoint）在游戏中触发，DataManager 遍历所有注册的 ISaveable 对象采集状态并写入 JSON。

## 核心组件

### ISaveable（鸭子接口）

**文件**: `scripts/utilities/i_saveable.gd`

```gdscript
class_name ISaveable extends RefCounted  # 仅作文档锚点，节点不需要 extends

func get_save_id() -> String:        return ""
func get_save_data(_data: Dictionary) -> void:  pass
func load_save_data(_data: Dictionary) -> void: pass
```

**接入方式**:
1. 在 `_enter_tree()` 调用 `DataManager.register(self)`
2. 在 `_exit_tree()` 调用 `DataManager.unregister(self)`
3. 实现三个方法（`get_save_id` / `get_save_data` / `load_save_data`）

### PersistenceKeyUtility

**文件**: `scripts/utilities/persistence_key_utility.gd`

生成稳定的存档键，避免 `get_path()` 在场景重组后失效。

**解析顺序**:
1. 节点旁挂的 `DataDefinition.id`（最可靠）
2. 节点场景路径 `node.get_path()`
3. `fallback_prefix + node.name`

### SavePoint

**文件**: `scripts/player/save_point.gd`
**继承**: `Node2D`

**功能**:
- 属于 `interactable` 组
- `trigger_action()`: 标记已激活 → `GameEvents.raise_save_data()` → 播放动画 → 广播奖励
- 首次激活发出 `first_activation` 信号 + 奖励事件（`first_activation_reward`，默认 `power-refill`）
- 呼吸脉冲动画（`loop_pulse` + `pulse_period`）
- ISaveable: 保存/恢复 `_activated` 状态

## 存档数据格式（Schema v1）

```json
{
  "schema_version": 1,
  "scene_to_save": {
    "path": "res://scenes/levels/level_demo.tscn",
    "display_name": "Demo Level",
    "scene_type": 0
  },
  "character_pos": {
    "player": {"x": 100.5, "y": 250.0, "z": 0.0}
  },
  "float_data": {
    "player_progression_tut": 1.0,
    "player_progression_up": 0.0,
    "player_progression_map": 0.0,
    "player_progression_chest_chest_01": 1.0,
    "save_point_01_done": 1.0,
    "enemy_snail_01_dead": 1.0,
    "character_health": 5.0,
    "character_power": 80.5
  }
}
```

**注意**: `float_data` 是万能的存档字段，几乎所有 ISaveable 都把状态编码为 `float` 塞进去。

## 写盘流程

```
GameEvents.save_data_requested
    ↓
DataManager.save()
    ├─ capture_runtime_state()
    │    └─ 遍历 _saveables[]
    │         ├─ is_instance_valid() 过滤僵尸引用
    │         └─ saveable.call("get_save_data", _data)
    ├─ _data["schema_version"] = 1
    ├─ JSON.stringify(_data)
    └─ FileAccess.open(user://SAVE_DATA/data.sav, WRITE)
```

## 读盘流程

```
GameEvents.load_data_requested
    ↓
DataManager.load_from_disk()
    ├─ FileAccess.file_exists(SAVE_FILE) ?
    ├─ JSON.parse_string(raw)
    │    └─ 格式错误 → _quarantine_corrupted() → 空数据回退
    └─ 遍历 _saveables[]
         └─ saveable.call("load_save_data", _data)
```

## 已实现 ISaveable 的节点

| 节点 | 保存内容 | 存档键 |
|------|----------|--------|
| `PlayerController` | 位置 | `PersistenceKeyUtility.resolve_key(self, "player")` |
| `Character` | 血量/能量 | `resolve_key(parent, "character")` + `_health` / `_power` |
| `SavePoint` | 是否已激活 | `resolve_key(self, "save_point")` + `_done` |
| `EnemyCombatant` | 是否已死亡 | `resolve_key(self, "enemy")` + `_dead` |
| `PlayerProgression` | 代币/解锁/宝箱 | `player_progression` + 各子键 |

## 数据访问帮助方法

| 方法 | 说明 |
|------|------|
| `record_character_position(id, pos)` | 记录位置到 `character_pos` |
| `record_float(key, value)` | 记录浮点到 `float_data` |
| `record_scene(scene_resource)` | 记录当前场景元数据 |
| `has_saved_game() -> bool` | 检查存档文件是否存在 |

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `GameEvents` | Autoload | `save_data_requested` / `load_data_requested` |
| `PersistenceKeyUtility` | 工具 | 稳定键生成 |
| `DataDefinition` | 资源 | 可选的 ID 节点 |

## 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| Web 平台 IndexedDB 行为差异 | 中 | 中 | `OS.has_feature("web")` 分支 |
| schema 升级遗漏迁移函数 | 中 | 高 | 改 schema 必须写 `_migrate_vN_to_vN+1` |
| `_saveables` 漏 unregister | 中 | 低 | 写盘时 `is_instance_valid` 过滤 |
| `float_data` 键冲突 | 低 | 中 | `PersistenceKeyUtility` + 命名约定 |

## 待做

- [ ] 单元测试: `record_float` / `record_character_position` 往返测试
- [ ] Web 平台手动验证 IndexedDB 行为
