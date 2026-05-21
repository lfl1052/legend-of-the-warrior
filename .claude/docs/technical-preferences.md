# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (静态类型强制 — `: Type` 标注 + `-> ReturnType`)
- **Rendering**: Forward+
- **Physics**: Godot 内置 2D 物理 (CharacterBody2D / StaticBody2D / Area2D)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows / Linux 主), Web (后续考虑)
- **Input Methods**: Keyboard/Mouse (Mixed) — 后续可加 Gamepad
- **Primary Input**: Keyboard (WASD + Space/J/K)
- **Gamepad Support**: None（计划：Partial）
- **Touch Support**: None
- **Platform Notes**: 1920x1080 viewport，stretch=expand，aspect=expand；菜单和 HUD 使用 Anchor + CanvasLayer 适配缩放

### Input Map (project.godot)

| 动作 | 键 |
|---|---|
| `move_left` / `move_right` | A / D ， 方向键左右 |
| `jump` | Space |
| `attack` | J |
| `walk` | Shift |
| `slide` | K |

## Naming Conventions

- **Classes**: PascalCase (`PlayerController`, `EnemyEncounterCombatant`)
- **Variables**: snake_case (`current_health`, `max_speed`)
- **Signals/Events**: snake_case 过去时 / 名词 (`new_game_started`, `player_died`)
- **Files**: snake_case (`player_controller.gd`, `enemy_encounter_bar.gd`)
- **Scenes**: snake_case (`player.tscn`, `level_demo.tscn`)
- **Constants**: SCREAMING_SNAKE_CASE (`MAX_HEALTH`, `STEP_TIMEOUT`)
- **Resources (.tres)**: `<purpose>_<noun>.tres` (`scene_warrior_menu.tres`, `chapter_forest.tres`)

## Collision Layers (project-wide)

| Bit | Layer | 用途 |
|---|---|
| 1 | World | 地面 / 墙体 (StaticBody2D) |
| 2 | Player | PlayerController body |
| 3 | Enemy | Enemy body |
| 4 | PlayerAttack | 玩家攻击判定 (Area2D) |
| 5 | EnemyAttack | 敌人攻击判定 |
| 6 | Interactable | 存档点 / 传送门 / 标牌 / 宝箱 |
| 7 | Hazard | 尖刺 / 虚空跌落 |
| 8 | OneWayPlatform | 单向跳跃平台 |

## Performance Budgets

- **Target Framerate**: 60 FPS @ 1920×1080
- **Frame Budget**: 16.6 ms（CPU+GPU 总），其中 gameplay <8 ms
- **Draw Calls**: <300 / frame
- **Memory Ceiling**: <512 MB RAM (PC), <128 MB VRAM
- **Physics Ticks**: 60 Hz

## Testing

- **Framework**: GdUnit4 v4.4.3（`addons/gdUnit4`），与 Godot 4.6.1 存在已知兼容问题，详见 `tests/README.md` 与 Story 1-9 跟踪
- **Minimum Coverage**: 关键系统（存档 / 战斗 / 状态机）目标 70%；UI 与表现层不强制
- **Required Tests**:
  - 存档：has_saved_game / load_data / save_data 往返
  - 战斗：take_damage / die / 攻击命中判定
  - 状态机：状态切换不漏 transition、不重复 enter/exit
  - 经济（lot table）：drop_chance 不会越界
- **Smoke Test**: `tests/e2e/smoke_test.tscn` — 启动菜单 → 加载关卡 → 玩家自动化攻击 → 存档点写盘 → 回菜单 (5 步)

## Forbidden Patterns

- ❌ 裸字符串拼场景路径 — 必须走 `GameSceneResource(.tres)` + `SceneLoader`
- ❌ 跨系统直接 `get_node("../../...")` — 用 `GameEvents` 信号或 autoload 单例
- ❌ 在 `_process` / `_physics_process` 里 `find_child` / `get_tree().get_nodes_in_group` — 缓存到 `@onready`
- ❌ GDScript 不写类型标注 — 全项目强制 `: Type` 与 `-> ReturnType`
- ❌ 直接修改其他角色的 health — 走 `take_damage(amount)` 入口

## Allowed Libraries / Addons

- `addons/mcp_bridge`（开发期 MCP 集成，发布前需关闭）
- 未来可加：`gut` 或 `gdunit4`（测试），`dialogic`（如做对话）

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- ADR 待补 — 建议优先：
  - ADR-001: Autoload + GameEvents 信号总线作为跨系统通信
  - ADR-002: ISaveable 鸭子类型 + `user://SAVE_DATA/data.sav` 存档协议
  - ADR-003: GameSceneResource(.tres) 取代裸字符串场景路径
  - ADR-004: Enemy AI 使用 BaseState 状态机模式（Patrol/Chase/Skill）

## Engine Specialists

- **Primary**: `godot-specialist`
- **Language/Code Specialist**: `godot-gdscript-specialist`（GDScript 静态类型 / 信号 / 协程）
- **Shader Specialist**: `godot-shader-specialist`（Godot shading lang / 粒子 / 后期）
- **UI Specialist**: `godot-specialist`（Control 节点 / Theme / CanvasLayer）
- **Additional Specialists**: `godot-csharp-specialist`（不使用，C# 项目可忽略）, `godot-gdextension-specialist`（不使用）
- **Routing Notes**:
  - 项目零 C#，所有 `.cs` 路由忽略
  - 测试由 `qa-tester` + `godot-gdscript-specialist` 协作

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `*.gd` Game code | `godot-gdscript-specialist` |
| `*.gdshader` Shader / material files | `godot-shader-specialist` |
| `*.tscn` UI / Control 场景 | `godot-specialist` |
| `*.tscn` 关卡 / 角色场景 | `godot-specialist` |
| `*.tres` Resource 文件 | `godot-specialist` |
| Native extension / plugin files | `godot-gdextension-specialist`（项目暂未使用） |
| General architecture review | `godot-specialist` |
