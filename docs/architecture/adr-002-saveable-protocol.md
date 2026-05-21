# ADR-0002: ISaveable 鸭子类型 + `user://SAVE_DATA/data.sav` 存档协议

## Status

Accepted

## Date

2026-05-20

## Last Verified

2026-05-20

## Decision Makers

项目负责人

## Summary

需要让分散在各场景里的角色 / 存档点 / 玩家进度都能写盘和恢复，但又不能强迫所有节点都继承同一基类（GDScript 单继承 + 节点已经继承 Node2D / CharacterBody2D 等）。决定：定义 `ISaveable` 鸭子接口（仅声明 `get_save_id` / `get_save_data` / `load_save_data` 三个方法），由 `DataManager` autoload 维护注册表 + 写入 `user://SAVE_DATA/data.sav`（JSON），可疑文件隔离到 `.bak`。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — `FileAccess` / `JSON` / `DirAccess` 是稳定 API |
| **References Consulted** | `scripts/autoload/data_manager.gd`、`scripts/utilities/i_saveable.gd`、Godot user:// 文件系统 docs |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | 跨平台 user:// 路径在 Linux / Web 行为差异（Web 用 IndexedDB） |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001（依赖 `GameEvents.save_data_requested` / `load_data_requested` 信号） |
| **Enables** | ADR-0003（`scene_to_save` 字段保存当前 GameSceneResource 元数据） |
| **Blocks** | "Continue" 主菜单按钮 epic、SavePoint epic、玩家进度持久化 epic |
| **Ordering Note** | 必须在任何持久化数据 epic 之前固化 |

## Context

### Problem Statement

Unity 项目使用 `ISaveable` 接口 + `DataManager` 单例 + Newtonsoft.Json 写 `Application.persistentDataPath/data.sav`。迁移到 Godot 后需要保留：
- 同样的 schema（`schema_version` / `scene_to_save` / `character_pos` / `float_data`）
- 多场景对象在加载时能恢复"上次离开的状态"
- 损坏存档不能让游戏崩溃

### Current State

- 玩家位置、玩家进度、存档点、敌人血量等都需要持久化
- GDScript 不能多继承，节点已经是 CharacterBody2D / Area2D，不能再 `extends ISaveable`
- 没有内建的 ScriptableObject 等价物用于存放运行时状态

### Constraints

- 必须复用 Unity 端的 schema（`schema_version: int`、`scene_to_save: Dict`、`character_pos: Dict<id, {x,y,z}>`、`float_data: Dict<key, float>`），便于跨平台对照与未来工具链
- Web 平台 `user://` 实际写入 IndexedDB，文件需保持单文件 + 小体积（<1 MB）
- 不能因损坏存档让游戏白屏

### Requirements

- 任意 Node 都能成为 saveable，无需改基类
- 注册 / 注销时机清晰，不会出现僵尸引用
- 写盘 < 50 ms（避免主线程卡顿）
- 损坏存档自动隔离到 `.bak` 并继续以空数据运行

## Decision

**鸭子接口 + 中央注册表**：

1. 定义 `ISaveable extends RefCounted`（仅作类型注释，**不强制继承**），声明 3 个方法：
   - `get_save_id() -> String` — 持久化键（用 `persistence_key_utility` 生成稳定键）
   - `get_save_data(data: Dictionary) -> void` — 把自身状态塞入 data
   - `load_save_data(data: Dictionary) -> void` — 从 data 读回状态
2. `DataManager` autoload 维护 `_saveables: Array[Object]`，节点 `_enter_tree` 调 `register(self)`，`_exit_tree` 调 `unregister(self)`
3. 写盘走 `GameEvents.save_data_requested` 信号驱动；读盘走 `load_data_requested`
4. 存档路径：`user://SAVE_DATA/data.sav`（JSON），损坏自动 copy 到 `data.sav.bak`

### Architecture

```
┌────────────────────────┐    raise_save_data()    ┌──────────────────────┐
│   SavePoint (Area2D)   │ ──────────────────────► │     GameEvents       │
│   trigger_action()     │                         │ save_data_requested  │
└────────────────────────┘                         └──────────────────────┘
                                                              │
                                                              ▼ connect
                                                  ┌──────────────────────────┐
                                                  │     DataManager          │
                                                  │  capture_runtime_state() │
                                                  │  → 遍历 _saveables[]     │
                                                  │  → 各自写入 _data dict   │
                                                  │  → JSON.stringify        │
                                                  │  → FileAccess.WRITE      │
                                                  │      user://SAVE_DATA/   │
                                                  │      data.sav            │
                                                  └──────────────────────────┘
```

### Key Interfaces

```gdscript
# i_saveable.gd（仅作文档锚点，节点不需要 extends）
class_name ISaveable
extends RefCounted

func get_save_id() -> String:        return ""
func get_save_data(_data: Dictionary) -> void:  pass
func load_save_data(_data: Dictionary) -> void: pass

# 任意节点接入存档系统的样板
extends Node2D

func _enter_tree() -> void:
    DataManager.register(self)

func _exit_tree() -> void:
    DataManager.unregister(self)

func get_save_id() -> String:
    return PersistenceKeyUtility.build("save_point", scene_uid, save_id_prefix)

func get_save_data(data: Dictionary) -> void:
    data["float_data"][get_save_id() + "/triggered"] = 1.0

func load_save_data(data: Dictionary) -> void:
    var triggered := data.get("float_data", {}).get(get_save_id() + "/triggered", 0.0)
    if triggered > 0.5:
        _mark_visited()
```

### Implementation Guidelines

- **稳定键**：所有 `save_id` 走 `PersistenceKeyUtility.build()`，**禁止**用 `get_path()`（场景重组会失效）
- **类型存放**：位置走 `record_character_position`；任意 float 走 `record_float`；不要直接动 `_data` dict
- **schema 升级**：当前 `CURRENT_SCHEMA_VERSION = 1`；升级时先在 `data_manager.gd` 加 `_migrate_v1_to_v2(data)` 再升 version
- **写时机**：玩家踩到存档点 / 主菜单"返回主界面" / Application quit 前
- **读时机**：主菜单 "Continue" 按钮 / `_ready` 时（由 `GameEvents.load_data_requested` 触发）

## Alternatives Considered

### Alternative 1: 用基类 SaveableNode2D + SaveableArea2D

- **Description**: 给每种父类做一个 saveable 子类
- **Pros**: 类型检查更严
- **Cons**: 需要为 Node2D / CharacterBody2D / Area2D / Control 各做一个，组合爆炸；玩家用第三方插件节点时不能接入
- **Rejection Reason**: GDScript 单继承不友好

### Alternative 2: ConfigFile 替代 JSON

- **Description**: 用 Godot 的 `ConfigFile` 读写 ini 风格存档
- **Pros**: 类型保留更精确（Variant）
- **Cons**: 与 Unity Newtonsoft.Json 端 schema 不兼容；嵌套字典支持差；不适合工具链跨平台分析
- **Rejection Reason**: 跨平台对照成本高

### Alternative 3: 每个 saveable 自己写自己的文件

- **Description**: 每个对象自己 `save_<id>.json`
- **Pros**: 损坏只影响一个对象
- **Cons**: 文件数爆炸；Web 平台 IndexedDB 多文件读写慢；schema_version 不统一
- **Rejection Reason**: 维护成本远高于单文件 + 隔离机制

## Consequences

### Positive

- 节点无需改继承链，加 3 个方法 + 注册即可
- schema 与 Unity 项目对齐，工具链可复用
- 单文件、单 schema_version，升级路径清晰
- 损坏存档不会让游戏崩溃（隔离 + 空数据回退）

### Negative

- 鸭子类型缺少编译期检查；`has_method("get_save_data")` 检查只能运行时
- 单文件意味着任意 saveable 写错 key 都会污染共享 dict（已通过 `record_*` 帮助方法收敛）
- 没有加密 / 校验和，存档可被篡改（Polish 阶段决定是否加 HMAC）

### Neutral

- 所有 saveable 共享一个 dict，便于跨对象引用（如玩家位置可被存档点读到）

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Web 平台 user:// 行为差异 | Medium | Medium | Web build 时显式 `OS.has_feature("web")` 分支，必要时改用 `JavaScriptBridge` 持久化到 localStorage |
| schema_version 升级遗漏迁移 | Medium | High | 每次改 schema 必须写 `_migrate_vN_to_vN+1`；测试覆盖 |
| 玩家篡改 data.sav 作弊 | Low | Low | 单机游戏，不阻止 |
| `_saveables` 漏 unregister 导致僵尸引用 | Medium | Low | DataManager 在写盘时 `is_instance_valid` 过滤；单元测试覆盖 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU（save 调用） | n/a | < 10 ms（10 saveable 全场景） | < 50 ms |
| CPU（load 调用） | n/a | < 15 ms（含 JSON parse） | < 100 ms |
| Memory（_data） | n/a | < 50 KB | < 1 MB |
| 文件大小（data.sav） | n/a | 5–20 KB | < 1 MB |

## Migration Plan

已完成。

1. ✅ 定义 `ISaveable`（仅作接口注释）
2. ✅ DataManager 实现 `register`/`unregister`/`save`/`load_from_disk`
3. ✅ schema 与 Unity 对齐：`schema_version` / `scene_to_save` / `character_pos` / `float_data`
4. ✅ `has_saved_game()` 用于主菜单"Continue"按钮可见性
5. ✅ 损坏存档隔离到 `data.sav.bak`
6. ✅ 冒烟测试覆盖（SavePoint 触发后 `has_saved_game() == true`）

**Rollback plan**: 删除 `user://SAVE_DATA/`；ISaveable 协议保留即可，DataManager 可被换成新实现而不影响调用点。

## Validation Criteria

- [x] 任意节点可在 3 行内接入存档（register + 3 方法）
- [x] 写盘 < 50 ms（冒烟测试无明显卡顿）
- [x] 损坏 JSON 自动隔离 + 回退空数据 + 不崩溃
- [x] schema_version 字段存在，未来可迁移
- [ ] 单元测试覆盖 `record_float` / `record_character_position` 往返
- [ ] Web 平台手动验证

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| Foundational — no GDD requirement yet（待补 `design/gdd/save-system.md`）。Enables: SavePoint epic / Continue 按钮 / 玩家进度持久化 / 关卡间状态保留 |

## Related

- ADR-0001（信号总线）— 触发存档的 `save_data_requested` 信号
- ADR-0003（场景资源）— `scene_to_save` 字段保存当前 GameSceneResource 元数据
- 代码：`scripts/autoload/data_manager.gd`、`scripts/utilities/i_saveable.gd`、`scripts/utilities/persistence_key_utility.gd`、`scripts/player/save_point.gd`
- 测试：`tests/smoke_test.gd::test_save_point_writes_save_file_to_disk`
