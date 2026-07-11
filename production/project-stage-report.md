# Project Stage Analysis — Legend of the Warrior

> 历史快照：本报告记录 2026-05-20 当时的 Godot 4.6 项目状态。当前引擎基线已经升级到 Godot 4.7 stable；最新目录与入口以 `docs/project-map.md` 为准。

**Date**: 2026/05/20
**Stage**: **Production**（已固定写入 `production/stage.txt`）
**Stage Confidence**: **CONCERNS** — 代码已达 Production 量级，但 Game Studios 工作流文档（design / docs / production）几乎为零，存在「代码先于文档」错位

**项目概述**：从 Unity 迁移到 Godot 4.6 的 2D 横版动作冒险游戏。引擎 Forward+ renderer，GDScript 静态类型。当前已实现 Player + Enemy AI（状态机）+ Save + Scene Transition + UI/HUD + 双语（中/英）+ MCP Bridge 等系统，单关 demo 可玩。

---

## Completeness Overview

| 维度 | 完成度 | 详情 |
|---|---|---|
| **代码** | ~85% | `scripts/` 64 个 `.gd` 文件，跨 10 个子目录（autoload / player / enemy / ui / save / transition / utilities / general / resources / audio） |
| **场景** | ~30% | 5 个 `.tscn`：`player`、`bee`、`snail`、`warrior_menu`、`level_demo`。仅 1 个可玩关卡 |
| **数据资源** | ~20% | `data/` 仅 2 个 `.tres`（`scene_warrior_menu.tres` / `scene_level_demo.tres`）。`LootTableResource` / `PlayerProgressionResource` / `ChapterResource` / `UiStringResource` 类已写但缺数据实例 |
| **设计文档** | **0%** | `design/` 目录不存在。无 GDD、无 systems-index、无 art-bible |
| **架构文档** | **0%** | `docs/architecture/` 不存在，无 ADR、无 architecture.md、无 control-manifest |
| **生产文档** | ~5% | 仅 `production/stage.txt`（本次新建）；无 epics / stories / sprints / playtests |
| **测试** | ~10% | 仅 1 个端到端冒烟测试 `tests/smoke_test.gd`，无单元测试，无 GUT/GdUnit4 框架 |
| **原型** | 0% | `prototypes/` 不存在（已是 Production，可不补） |
| **引擎登记** | ✅ | `.claude/docs/technical-preferences.md` 已写入 Godot 4.6 + Forward+ + GDScript（本次新建） |

---

## 已识别的 10 个子系统（按 `scripts/` 反推）

| # | 系统 | 关键文件 | 优先级 | 反向文档化建议 |
|---|---|---|---|---|
| 1 | **Autoload 服务层** | `game_events` / `data_manager` / `scene_loader` / `audio_manager` / `language_manager` / `ui_manager` / `runtime_data` | 🔴 P0 | 必做 — 是骨架 |
| 2 | **Player Controller** | `player_controller` / `player_animation` / `player_skill_slash` / `player_heal_skill` / `player_progression` | 🔴 P0 | 必做 — 玩家手感核心 |
| 3 | **Enemy AI 状态机** | `base_state` / `enemy` / `boar(_elite)` / `bee` / `snail` + `*_patrol/chase/skill_state` | 🔴 P0 | 必做 — 多敌人复用模式 |
| 4 | **Save / 持久化** | `data_manager` + `i_saveable` + `save_point` + `persistence_key_utility` | 🟠 P1 | 重要 — 数据契约 |
| 5 | **Encounter / Boss** | `boss_enemy` / `elite_enemy` / `enemy_minion` / `enemy_encounter_*.gd` | 🟠 P1 | 重要 — Boss 战流程 |
| 6 | **场景切换 / 传送** | `scene_loader` + `teleport_point` + `initial_load` + `game_scene_resource` | 🟠 P1 | 重要 |
| 7 | **UI / HUD / 菜单** | `main_menu` / `menu_flow` / `fade_canvas` / `player_stat_bar` / `language_toggle` / `localized_text` / `encounter_bar` / `progression_panel` | 🟡 P2 | 中等 |
| 8 | **进度 & 经济** | `player_progression(_resource)` / `loot_table_resource` / `chapter_resource` | 🟡 P2 | 中等 |
| 9 | **战斗判定** | `character` / `attack` / `physics_check` | 🟡 P2 | 中等 |
| 10 | **MCP 集成（开发期）** | `mcp_bridge_game.gd` + `addons/mcp_bridge` | 🟢 P3 | 可不写 GDD，写一份开发者文档即可 |

---

## Gaps Identified

### 1. 工作流目录骨架缺失
缺：`design/gdd/`、`design/art/`、`design/ux/`、`docs/architecture/`、`production/epics/`、`production/sprints/`、`production/stories/`、`production/playtests/`。
→ **建议**：在第一个反向文档化任务时按需创建，不必一次性铺满。

### 2. 没有 systems-index.md
进入正式 production 循环之前，10 个系统应该在 `design/gdd/systems-index.md` 列出，标注 Status。
→ **建议**：用 `/map-systems` 或手写一份。

### 3. 至少应记录的 4 条 ADR
项目实际上已经做了重要架构决策但都没记录：
- **ADR-001**：用 Autoload + `GameEvents` 信号总线作为跨系统通信
- **ADR-002**：存档采用 ISaveable 鸭子类型 + `user://SAVE_DATA/data.sav`
- **ADR-003**：场景元数据用 `GameSceneResource(.tres)` 取代裸字符串路径
- **ADR-004**：Enemy AI 用 `BaseState` 状态机模式（Patrol / Chase / Skill）

### 4. 没有 epics / stories
所以 `/dev-story`、`/sprint-plan`、`/sprint-status` 都跑不起来。
→ **建议**：先把头脑里下一步要做的 5~8 件事口述出来，我帮你转成 epic + story。

### 5. 测试只有冒烟
没有单元测试、没有测试框架、没有 CI 集成。
→ **建议**：装 GUT 或 GdUnit4 二选一，把 `tests/smoke_test.gd` 收编进去做 e2e 子目录。

### 6. 已有但未文档化的"事实"
- 8 个 Autoload（含 `McpBridgeGame`）
- Input Map：move/move_left/move_right/jump/attack/walk/slide
- 双语切换（中文 / English）+ `LocalizedText` 节点
- Forward+ 渲染 / 1920×1080 stretch=expand

→ 这些应该在 `technical-preferences.md`（已做）+ 系统 GDD 里固化。

---

## Recommended Next Steps（优先级排序）

### 🔴 立即（今日）
1. ✅ **Setup engine** — `.claude/docs/technical-preferences.md` 已写入 Godot 4.6
2. ✅ **Pin stage** — `production/stage.txt = Production` 已写入
3. **反向写 3 条核心 ADR**（autoload / save / scene-resource）
   - 命令：`/architecture-decision retrofit autoload-event-bus`

### 🟠 本周
4. **反向写 3 份核心 GDD**：`autoload-services` / `player-controller` / `enemy-ai-state-machine`
   - 命令：`/reverse-document design src/scripts/autoload`
5. **建 `design/gdd/systems-index.md`** — 把 10 个系统列上去
6. **选定测试框架** — GUT 或 GdUnit4，把冒烟测试收编

### 🟡 两周内
7. **补剩余 7 个系统的 GDD**（save / encounter / scene-transition / ui / progression / combat / mcp）
8. **写 `docs/architecture/architecture.md`** + 把 ADR 提到 4~6 条
9. **第一份 sprint-plan** — 列出下一阶段（动画完善 / 关卡 2 / 音效 / 平衡）

### 🟢 持续
10. 之后每完成一个 feature 走标准循环：`/sprint-plan` → `/dev-story` → `/code-review` → `/story-done`

---

## 第一个具体动作

我建议下一步直接让我帮你写出 **3 条 ADR + 1 份 systems-index.md**（约 30 分钟一次性产出）。这样：
- 你就有了基本的架构文档锚点
- 后续 GDD 反向化可以引用 ADR
- `/architecture-review` 跑得起来
- 状态行能显示 Pre-Production 之后的阶段标识

或者，如果你希望跳过文档化、直接进入下一个功能开发，告诉我"下一步要做什么"，我就跳过 ADR 直接帮你拆 epic / story。

---

## 已做 / 待做 清单

- [x] 创建 `.claude/docs/technical-preferences.md`（Godot 4.6 + GDScript + 物理层 + 性能预算 + 命名规范）
- [x] 创建 `production/stage.txt`（Production）
- [x] 创建 `production/project-stage-report.md`（本文件）
- [x] 创建 3 条核心 ADR（ADR-001/002/003）
- [ ] 创建 `design/gdd/systems-index.md`
- [ ] 反向 3 份核心 GDD
- [ ] 选定并安装测试框架
- [ ] 写第一份 sprint-plan
