# 系统 GDD: 场景切换 / 传送

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-SCENE-TRANS |
| **系统名称** | 场景切换 / 传送 |
| **优先级** | 🟠 P1 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/autoload/scene_loader.gd`, `scripts/transition/teleport_point.gd`, `scripts/transition/initial_load.gd`, `scripts/resources/game_scene_resource.gd` |

**ADR**: [ADR-003: GameSceneResource .tres 场景资源化](../architecture/adr-003-game-scene-resource.md)

---

## 概述

场景切换系统通过 GameSceneResource（.tres 元数据）承载目标场景路径/类型/显示名，由 SceneLoader autoload 负责异步加载与实际切换，TeleportPoint / InitialLoad / MenuFlow 作为触发入口。

## 核心组件

### GameSceneResource

**文件**: `scripts/resources/game_scene_resource.gd`
**继承**: `Resource`

```gdscript
class_name GameSceneResource extends Resource

@export_file("*.tscn") var scene_path: String
@export var display_name: String
@export var scene_type: int  # Enums.SceneType.LOACTION / MENU

func is_menu() -> bool
func is_location() -> bool
```

**存放位置**: `data/scene_*.tres`（当前有 `scene_warrior_menu.tres`, `scene_level_demo.tres`）

### SceneLoader

**文件**: `scripts/autoload/scene_loader.gd`
**监听信号**: `GameEvents.scene_load_requested`

**加载流程**:

```
scene_load_requested(scene_resource, position, fade)
    ↓
Raise fade_in(0.4s)  ← 可选
    ↓
DataManager.try_capture_runtime_state_for_scene_transition()  ← 场景退出前保存
    ↓
GameEvents.raise_scene_unloaded(...)
    ↓
ResourceLoader.load_threaded_request(scene_path)
    ↓
_process loop: load_threaded_get_status
    ├─ THREAD_LOAD_LOADED → _apply_packed_scene
    ├─ THREAD_LOAD_FAILED → push_error + reset
    └─ THREAD_LOAD_INVALID_RESOURCE → push_error + reset
    ↓
_apply_packed_scene(packed)
    ├─ tree.change_scene_to_packed(packed)
    ├─ current_scene_resource = _pending_scene_resource
    ├─ After 1 process_frame:
    │    └─ _apply_player_position()
    │         └─ find "player" group → set global_position
    ├─ fade_out (可选)
    └─ raise_after_scene_loaded()
```

**关键设计**:
- `_is_loading` 防止并发加载
- 2D 项目: 位置只取 `Vector2(_pending_position.x, _pending_position.y)`
- `current_scene_resource` 跟踪当前场景元数据，用于存档

### TeleportPoint

**文件**: `scripts/transition/teleport_point.gd`
**继承**: `Area2D`

物理传送触发器，属于 `interactable` 组。

```gdscript
@export var scene_to_go: GameSceneResource
@export var position_to_go: Vector2
@export var fade_screen: bool = true
```

`trigger_action()` 直接调用 `GameEvents.raise_scene_load_requested()`。

### InitialLoad

**文件**: `scripts/transition/initial_load.gd`
**继承**: `Node`

启动场景引导，在场景启动时立即跳转到持久化场景。

**功能**:
- `_ready()` 时自动触发 `GameEvents.raise_scene_load_requested()`
- `_has_requested_load` 静态变量防止重复执行（场景自重启时也只会执行一次）

### MenuFlow

**文件**: `scripts/ui/menu_flow.gd`
**继承**: `Node`

主菜单流控：将按钮事件（新游戏/继续）转化为 `scene_load_requested`。

```gdscript
@export var default_level: GameSceneResource
@export var default_spawn_position: Vector2

_on_new_game_started() → 加载 default_level
_on_load_data_requested() → 从存档读取目标场景 → 加载
```

## 触发入口总结

| 入口 | 触发方式 | 用途 |
|------|----------|------|
| TeleportPoint | 交互键 | 关卡内传送门 |
| InitialLoad | 场景 _ready 自动 | 启动场景 → 持久场景 |
| MenuFlow | 按钮事件 | 主菜单新游戏/继续 |
| GameEvents.raise_scene_load_requested() | 任意代码 | 任何场景跳转 |

## 数据流

```
用户交互 / 自动触发
    ↓
入口节点 TeleportPoint / MenuFlow / InitialLoad
    ↓
GameEvents.raise_scene_load_requested(res, pos, fade)
    ↓
SceneLoader._on_scene_load_requested
    ├─ 淡入
    ├─ 保存当前状态
    ├─ 异步加载
    └─ 切换场景 + 放置玩家 + 淡出
    ↓
GameEvents.raise_after_scene_loaded()
    ├─ AudioManager: 清除 FX
    ├─ Camera: 重新定位
    └─ UI: 更新状态
```

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `GameEvents` | Autoload | `scene_load_requested` / `fade_requested` / `after_scene_loaded` |
| `DataManager` | Autoload | 场景切换前保存状态 |
| `FadeCanvas` | UI | 淡入淡出视觉效果 |
| `GameSceneResource` | 资源 | 场景元数据 |

## 设计中禁止的模式

- **禁止** 直接 `change_scene_to_file("res://...")` — 必须经过 SceneLoader + GameSceneResource
- **禁止** 在 `_on_scene_load_requested` 中对等调用多个 `load_threaded_request`

## 数据文件

| 文件 | 内容 |
|------|------|
| `data/scene_warrior_menu.tres` | 主菜单场景元数据 |
| `data/scene_level_demo.tres` | Demo 关卡场景元数据 |
| `data/scene_links.json` | 场景跳转关系（未创建） |
| `data/chapters.json` | 章节定义（未创建） |
