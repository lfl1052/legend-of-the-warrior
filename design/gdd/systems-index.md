# Systems Index — Legend of the Warrior

**日期**: 2026-05-20
**阶段**: Production
**总系统数**: 10

---

## 索引

| # | 系统 ID | 系统名称 | 优先级 | 状态 | GDD 文档 | 源码位置 | 关键文件数 |
|---|---------|----------|--------|------|----------|----------|-----------|
| 1 | SYS-AUTOLOAD | Autoload 服务层 | 🔴 P0 | ✅ 已实现 | ✅ `gdd/autoload-services.md` | `scripts/autoload/` | 7 |
| 2 | SYS-PLAYER | Player Controller | 🔴 P0 | ✅ 已实现 | ✅ `gdd/player-controller.md` | `scripts/player/` | 6 |
| 3 | SYS-ENEMY-AI | Enemy AI 状态机 | 🔴 P0 | ✅ 已实现 | ✅ `gdd/enemy-ai-state-machine.md` | `scripts/enemy/` | 16 |
| 4 | SYS-SAVE | Save / 持久化 | 🟠 P1 | ✅ 已实现 | 📋 待补 | `scripts/player/save_point.gd`, `scripts/utilities/i_saveable.gd`, `scripts/utilities/persistence_key_utility.gd` | 3 |
| 5 | SYS-ENCOUNTER | Encounter / Boss 战 | 🟠 P1 | ✅ 已实现 | 📋 待补 | `scripts/enemy/enemy_encounter_*.gd`, `scripts/enemy/elite_enemy.gd`, `scripts/enemy/boss_enemy.gd` | 5 |
| 6 | SYS-SCENE-TRANS | 场景切换 / 传送 | 🟠 P1 | ✅ 已实现 | 📋 待补 | `scripts/transition/teleport_point.gd`, `scripts/transition/initial_load.gd` | 2 |
| 7 | SYS-UI | UI / HUD / 菜单 | 🟡 P2 | ✅ 已实现 | 📋 待补 | `scripts/ui/` | 12 |
| 8 | SYS-PROGRESSION | 进度 & 经济 | 🟡 P2 | 🟡 部分实现 | 📋 待补 | `scripts/player/player_progression.gd`, `scripts/resources/loot_table_resource.gd`, `scripts/resources/player_progression_resource.gd`, `scripts/resources/chapter_resource.gd` | 4 |
| 9 | SYS-COMBAT | 战斗判定 | 🟡 P2 | ✅ 已实现 | 📋 待补 | `scripts/general/character.gd`, `scripts/general/attack.gd`, `scripts/general/physics_check.gd` | 3 |
| 10 | SYS-MCP | MCP 集成（开发期） | 🟢 P3 | ✅ 已实现 | 📋 待补 | `mcp_bridge_game.gd`, `addons/mcp_bridge/` | N/A |

---

## 优先级定义

| 级别 | 含义 | 目标 |
|------|------|------|
| 🔴 P0 | 核心游戏系统，不工作则游戏不可玩 | 反向文档 + 测试 |
| 🟠 P1 | 重要系统，影响游戏体验完整性 | 反向文档 + 测试 |
| 🟡 P2 | 完善性系统，有最好，没有也不影响核心 loop | 文档 + 后续迭代 |
| 🟢 P3 | 开发期工具，不影响发布 | 开发者文档 |

## 状态图例

| 状态 | 含义 |
|------|------|
| ✅ 已实现 | 代码完整，可运行 |
| 🟡 部分实现 | 核心逻辑存在但缺少关键部分（如数据文件、特定状态） |
| 🔴 规划 | 仅设计阶段，未编码 |
| 📋 待补 | 系统已编码，GDD 文档待反向编写 |

## 文档进度

- **已反向编写**: 10/10 系统（全部完成）
- **待反向编写**: 0/10 系统
- **架构 ADR**: 3 条（ADR-001/002/003）
- **测试框架**: GdUnit4 v6.1.3（`addons/gdUnit4`）
- **单元测试**: 3 份（`tests/unit/test_character.gd`, `test_persistence_key_utility.gd`, `test_game_events.gd`）
- **冒烟测试**: 1 份（`tests/e2e/smoke_test.gd`，e2e 手动运行）

## GDD 反向编写顺序（推荐）

| 顺序 | 系统 | 原因 |
|------|------|------|
| 1 | ✅ SYS-AUTOLOAD | 骨架系统，其他所有系统依赖 |
| 2 | ✅ SYS-PLAYER | 核心手感，最常修改 |
| 3 | ✅ SYS-ENEMY-AI | 多敌人复用模式，需固定架构 |
| 4 | 🆕 SYS-COMBAT | Character/Attack 被 player + enemy 共享 |
| 5 | 🆕 SYS-SAVE | 数据契约，存档点实现 |
| 6 | 🆕 SYS-ENCOUNTER | Boss 战流程 |
| 7 | 🆕 SYS-SCENE-TRANS | 传送 + 初始加载 |
| 8 | 🆕 SYS-UI | HUD/菜单体系 |
| 9 | 🆕 SYS-PROGRESSION | 经济/进度系统 |
| 10 | 🆕 SYS-MCP | 开发期工具 |
