# ADR-0003: GameSceneResource(.tres) 取代裸字符串场景路径

## Status

Accepted

## Date

2026-05-20

## Last Verified

2026-05-20

## Decision Makers

项目负责人

## Summary

跨系统传递"目标场景"时如果用裸 `String` 路径（`res://scenes/levels/level_demo.tscn`），路径漂移、本地化名缺失、菜单 / 关卡区分都得在调用点重复处理。决定：把"场景元数据"封装为 `GameSceneResource extends Resource`（`.tres`），声明 `scene_path` / `display_name` / `scene_type`，所有场景跳转 API 接收 `Resource` 而不是 String。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Scripting / Core / UI |
| **Knowledge Risk** | LOW — Godot Resource + ResourceLoader.load_threaded_request 是稳定 API |
| **References Consulted** | `scripts/resources/game_scene_resource.gd`、`scripts/autoload/scene_loader.gd`、Godot `@export_file` / Resource docs |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001（通过 `GameEvents.scene_load_requested` 信号传递） |
| **Enables** | "Continue" 主菜单按钮（保存的 GameSceneResource 元数据可还原显示名）、章节系统（`ChapterResource` 引用一组 GameSceneResource）、传送门（`TeleportPoint.scene_to_go` 直接 `@export Resource`） |
| **Blocks** | 任何"跳到关卡 X" 的功能 |
| **Ordering Note** | 第三条基础 ADR，与 ADR-0001/0002 共同构成基础层 |

## Context

### Problem Statement

Unity 端用 `GameSceneSO`（ScriptableObject）封装场景引用，附带 `sceneName` / `sceneType` / `sceneReference`。如果迁移时退化成裸字符串：
- 菜单 vs 关卡区分要在 SceneLoader 里 `if path.endswith("menu.tscn")`，脆弱
- UI "回到主菜单 / Continue" 显示名要在每次跳转时手动塞
- 传送门、章节、章节链 `SceneLinkResource` 等需要 `@export PackedScene` 或 `@export String`，无法附带元数据

### Current State

- 5 个场景：`player.tscn` / `bee.tscn` / `snail.tscn` / `level_demo.tscn` / `warrior_menu.tscn`
- 2 个场景元数据 `.tres`：`scene_warrior_menu.tres` / `scene_level_demo.tres`
- 传送 / 菜单跳转 / 存档恢复都需要"知道下一个场景是什么"

### Constraints

- 必须支持 `@export` 在 inspector 里拖拽配置（`@export var scene_to_go: Resource`）
- 必须能序列化进存档（schema `scene_to_save: {path, display_name, scene_type}`）
- 必须支持后台异步加载（`ResourceLoader.load_threaded_request`）
- 兼容菜单 / 关卡两种类型（`Enums.SceneType.MENU / LOACTION`，注意保留 Unity 拼写）

### Requirements

- 一个 `.tres` 文件描述一个场景的全部元数据
- SceneLoader 接收 Resource，不接收 String
- 存档可以保存 Resource 元数据并恢复
- 增加新场景只需新增一个 `.tres`，无代码改动

## Decision

**`GameSceneResource extends Resource`**：

```gdscript
class_name GameSceneResource
extends Resource

@export_file("*.tscn") var scene_path: String = ""
@export var display_name: String = ""
@export var scene_type: int = Enums.SceneType.LOACTION  # 保留 Unity 拼写

func is_menu() -> bool:     return scene_type == Enums.SceneType.MENU
func is_location() -> bool: return scene_type == Enums.SceneType.LOACTION
```

所有场景跳转 API：

- `GameEvents.scene_load_requested(scene_resource: Resource, position_to_go: Vector3, fade_screen: bool)`
- `TeleportPoint.scene_to_go: Resource`（@export，inspector 拖 .tres）
- `MenuFlow.default_level: Resource`（@export，主菜单"开始游戏"目标）
- `DataManager.record_scene(scene_resource: Resource)` 写入存档

### Architecture

```
data/scene_warrior_menu.tres   ┐
data/scene_level_demo.tres     │  作为 @export var 拖入 inspector
data/scene_chapter_2.tres      ┘
        │
        ▼ ExtResource("...")
┌──────────────────┐   raise_scene_load_requested(res, pos, fade)
│  TeleportPoint   │ ──────────────────────►─────┐
│  MenuFlow        │                              │
│  ChapterResource │                              ▼
└──────────────────┘                  ┌──────────────────────┐
                                      │     SceneLoader      │
                                      │  scene_path 提取     │
                                      │  load_threaded_*     │
                                      │  change_scene_to_*   │
                                      └──────────────────────┘
                                                  │
                                                  ▼
                                      DataManager.record_scene(res)
                                      → save: { path, display_name, scene_type }
```

### Key Interfaces

```gdscript
# 资源定义
class_name GameSceneResource extends Resource
@export_file("*.tscn") var scene_path: String
@export var display_name: String
@export var scene_type: int  # Enums.SceneType

# 跳转入口（信号）
signal scene_load_requested(scene_resource: Resource, position_to_go: Vector3, fade_screen: bool)

# 调用点
GameEvents.raise_scene_load_requested(scene_warrior_menu, Vector3.ZERO, true)

# 节点字段
@export var scene_to_go: Resource = null  # 拖一个 GameSceneResource 进去
```

### Implementation Guidelines

- **新场景接入**：先建 `.tscn`，再在 `data/` 建一份 `scene_<name>.tres`，`scene_path` 指向 `.tscn`，`display_name` 写本地化键，`scene_type` 选 MENU / LOACTION
- **inspector 字段统一用 `Resource` 类型**：不要用 `GameSceneResource` 显式类型 hint，因为有循环依赖风险（资源类型解析时机）。在使用点用 `as GameSceneResource` 或直接 `get("scene_path")`
- **存档序列化**：`DataManager.record_scene` 通过 `scene_resource.get("scene_path")` 提取，不强制 ISaveable 接口
- **禁止**：`change_scene_to_file("res://...")` 直连字符串路径；必须经 `GameEvents.raise_scene_load_requested(res, ...)`

## Alternatives Considered

### Alternative 1: 直接 @export PackedScene

- **Description**: `@export var scene_to_go: PackedScene`
- **Pros**: 类型检查严，IDE 自动补全
- **Cons**: 没法附带 display_name / scene_type；切换语言时 UI 拿不到本地化名；存档无法只存元数据（PackedScene 整个实例化才能拿 path）
- **Rejection Reason**: 元数据缺失

### Alternative 2: 裸 String 路径

- **Description**: `@export_file("*.tscn") var scene_path: String`
- **Pros**: 最简单
- **Cons**: 见 Problem Statement
- **Rejection Reason**: 跨系统重复处理元数据

### Alternative 3: Dictionary 字面量

- **Description**: `@export var scene_meta: Dictionary = {"path": "...", "name": "...", "type": 0}`
- **Pros**: 灵活
- **Cons**: 没有类型 / 字段约束；inspector 编辑体验差
- **Rejection Reason**: 维护成本高

## Consequences

### Positive

- 一处定义，多处复用（菜单按钮、传送门、章节、存档元数据）
- inspector 拖拽体验好，新场景接入零代码
- 存档元数据天然完整（path + 显示名 + 类型）
- 与 Unity `GameSceneSO` 一一对应，迁移直观

### Negative

- 多了一层文件（每个 .tscn 通常配一个 .tres）；可接受
- inspector 字段类型只能写 `Resource` 不能写 `GameSceneResource`（循环加载风险），调用点要 `get("scene_path")` 或 `as`
- `Enums.SceneType.LOACTION` 保留 Unity 拼写错误，需要文档注释（已注释）

### Neutral

- ChapterResource / SceneLinkResource 等聚合资源天然引用 GameSceneResource

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `.tres` 与 `.tscn` 路径不一致（人工维护） | Medium | Medium | 提供 dev-only validator skill 检查 scene_path 文件存在；`/code-review` 可加规则 |
| inspector 字段类型 Resource 太宽 | Medium | Low | 调用点 `as GameSceneResource` 或 `is GameSceneResource` 断言 |
| Web 异步加载失败回退 | Low | Medium | SceneLoader 已有 `THREAD_LOAD_FAILED` / `INVALID_RESOURCE` 分支 push_error |
| Enums.SceneType.LOACTION 拼写传播 | Low | Low | 文档注释 + 不重命名（破坏存档兼容） |

## Performance Implications

| Metric | Before（字符串路径） | Expected After（Resource） | Budget |
|--------|--------|---------------|--------|
| CPU（跳转） | < 5 ms | < 5 ms（含 .tres 解析 < 1 ms） | < 50 ms |
| Memory（每个 .tres） | n/a | < 1 KB | < 100 KB（100 场景） |
| Load Time（首次场景） | < 500 ms | < 500 ms | < 2 s |

## Migration Plan

已完成。

1. ✅ 定义 `GameSceneResource`，3 个 `@export` 字段
2. ✅ 建 `data/scene_warrior_menu.tres` / `data/scene_level_demo.tres`
3. ✅ `GameEvents.scene_load_requested` 第一参为 `Resource`
4. ✅ `SceneLoader._on_scene_load_requested` 通过 `get("scene_path")` 提取路径
5. ✅ `TeleportPoint.scene_to_go` / `MenuFlow.default_level` 改为 `@export var ... : Resource`
6. ✅ `DataManager.record_scene` / `try_get_saved_scene_path` 处理 Resource 元数据
7. ✅ 冒烟测试覆盖（菜单 → 关卡 → 回菜单全链路）

**Rollback plan**: 不必回滚；如确需，可在 SceneLoader 内部加 String fallback 分支。

## Validation Criteria

- [x] 全项目 `change_scene_to_file` / `change_scene_to_packed` 仅出现在 SceneLoader
- [x] 所有跳转入口接受 `Resource` 类型
- [x] 存档 `scene_to_save` 字段含 path + display_name + scene_type
- [x] 冒烟测试 `test_menu_new_game_loads_level_demo` + `test_teleport_to_menu_returns_to_main_menu` 通过
- [ ] 加 dev-only validator 检查 `.tres.scene_path` 实际存在

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| Foundational — no GDD requirement yet（待补 `design/gdd/scene-transition.md`）。Enables: 章节系统 / 传送门 / 主菜单 Continue / Hub-and-spoke 关卡组织 |

## Related

- ADR-0001（信号总线）— `scene_load_requested` 信号承载本资源
- ADR-0002（存档协议）— `scene_to_save` schema 字段
- 代码：`scripts/resources/game_scene_resource.gd`、`scripts/autoload/scene_loader.gd`、`scripts/transition/teleport_point.gd`、`scripts/ui/menu_flow.gd`
- 数据：`data/scene_warrior_menu.tres`、`data/scene_level_demo.tres`
