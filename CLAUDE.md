# Legend of the Warrior — Game Studio Agent Architecture

2D side-scrolling action adventure，从 Unity 迁移到 Godot。
通过 Claude Code Game Studios 的 48 个 Agent + 70+ 工作流进行开发管理。

## Technology Stack

- **Engine**: Godot 4.6 (Forward+ rendering)
- **Language**: GDScript（全项目强制静态类型标注 `: Type` + `-> ReturnType`）
- **Physics**: Godot 内置 2D 物理 (CharacterBody2D / StaticBody2D / Area2D)
- **Testing**: GdUnit4 v6.1.3
- **Platform**: PC (Windows / Linux), 1920×1080, stretch=expand
- **VCS**: Git with conventional commits

## Technical Preferences

@.claude/docs/technical-preferences.md

## Project Structure

```
scripts/           # 所有游戏脚本
  autoload/        # 8 个全局单例 (GameEvents, DataManager, SceneLoader, ...)
  enemy/           # AI 状态机 + 敌人变体 (Bee, Snail, Boar, Boss)
  general/         # 共享组件 (Character, Attack, PhysicsCheck, Chest)
  player/          # 玩家控制 / 动画 / 技能 / 存档点
  resources/       # 自定义 .tres Resource 类
  tools/           # 开发工具 (scene_resource_validator)
  transition/      # 场景过渡
  ui/              # UI 脚本 (主菜单, HUD, 本地化, ...)
scenes/            # .tscn 场景文件
  enemy/           # bee, snail, boss_enemy
  levels/          # warrior_menu, level_demo, level_2
  player/          # player
data/              # 运行时 JSON + .tres Resource 文件
  chapters.json, loot.json, progression.json, scene_links.json, ui_strings.json
tests/
  unit/            # GdUnit4 单元测试 (7 个文件, 43+ 用例)
  e2e/             # 冒烟测试 (smoke_test.tscn)
  integration/     # 集成测试场景
design/gdd/        # 游戏设计文档 (11 份)
docs/architecture/ # ADR 架构决策记录
production/        # Sprint 管理
art/               # 美术资源
addons/            # Godot 插件 (gdUnit4, mcp_bridge)
```

## Architecture Patterns

### Event Bus (ADR-001)
所有跨系统通信通过 `GameEvents` 信号总线。系统通过 `GameEvents.xxx.connect(callback)` 订阅事件。
禁止直接 `get_node("../../...")` 跨系统引用。

### ISaveable Protocol (ADR-002)
需要持久化的节点实现三个方法：`get_save_id()`, `get_save_data()`, `load_save_data()`。
节点在 `_ready()` 中通过 `DataManager.register(self)` 自注册。

### GameSceneResource (ADR-003)
场景引用使用 `.tres` Resource 文件，禁止裸字符串路径。
字段：`scene_path`, `display_name`, `scene_type`。

### Enemy AI State Machine
`BaseState` (RefCounted) → `on_enter/logic_update/physics_update/on_exit`
状态：PATROL ↔ CHASE ↔ SKILL
Boss 技能有 3 阶段子状态机：WINDUP → ACTIVE → RECOVERY

### Autoload Singletons (8 个)
GameEvents, RuntimeData, DataManager, SceneLoader, AudioManager, LanguageManager, UIManager, McpBridgeGame

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: Question -> Options -> Decision -> Draft -> Approval

- Agents MUST ask before using Write/Edit tools on existing files
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md

## MCP Integration

本项目已配置 Godot MCP Server，提供编辑器实时控制能力：
- `mcp__godot-mcp__*` 工具集：场景树操作、节点创建/修改、脚本管理、截图、运行控制
- `McpBridgeGame` autoload：开发期 TCP bridge (127.0.0.1:9501)

## Sprint Status

@production/sprint-status.yaml
