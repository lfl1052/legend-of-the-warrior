# Codex 项目指南

## 项目定位

- 本项目是使用 Godot 4.7 stable 开发的 2D 横版动作冒险游戏。
- 目标平台以 Windows / Linux PC 为主；逻辑视口为 640×360，默认窗口为 1280×720，使用整数缩放。
- 主要体验是移动、跳跃、蹬墙、滑铲、近战攻击、技能、探索、奖励和 Boss 战。
- 开始任务前先阅读 `docs/project-map.md`；涉及玩法、关卡、UI 或成长时，再阅读 `design/gdd/` 中对应文档。

## 协作方式

- 始终使用简体中文交流。
- 默认先调查再修改：说明当前实现、目标差异、拟修改文件和验证方式。
- 用户明确要求实现功能时，可在已确认范围内修改；若需求会改变玩家体验、存档契约、关卡结构或多个系统边界，先列出方案和影响再动手。
- 当前工作区可能包含用户未提交的修改。不得覆盖、恢复、删除或格式化无关改动。
- 未经用户明确要求，不执行提交、推送、变基、重置、清理或批量恢复。
- 不把对话当作长期状态。需要持续多轮的任务，应把已确认决策记录到对应 GDD、ADR、Story 或 `production/session-state/active.md`。

## 架构约束

- GDScript 强制使用静态类型：变量、参数和返回值应有明确类型。
- 跨系统通信使用 `GameEvents` 或职责明确的 Autoload；禁止用跨层级 `get_node("../../...")` 建立隐式耦合。
- 可持久化对象遵守现有 ISaveable 协议，并考虑旧存档兼容与迁移。
- 场景跳转和场景引用使用 `GameSceneResource` 与 `SceneLoader`；禁止在业务逻辑中散落裸字符串场景路径。
- 输入规则基于 Input Map action；游戏逻辑不得直接依赖具体键位。
- 游戏规则、AI 状态、成长和奖励应与渲染表现分离；场景树和动画不是业务状态的唯一真相。
- 玩法数值优先放在 Resource、JSON 或现有数据结构中，避免在多处硬编码。
- 不在 `_process` 或 `_physics_process` 中反复执行 `find_child`、全树扫描或未缓存的节点查找。
- 角色伤害通过既有伤害入口处理，不直接修改其他角色的生命值字段。

## 场景、资产与数据

- 复杂 `.tscn`、`.tres`、TileSet 和 TileMap 修改优先通过 Godot 编辑器或已验证的项目工具完成；直接文本修改前必须确认资源引用和 UID 不会损坏。
- 不修改 `.godot/`、导入缓存、测试报告或导出产物。
- 未经任务明确要求，不修改 `addons/godot_ai` 和 `addons/gdUnit4`。
- 游戏逻辑优先引用稳定内容 ID，不把资产文件路径当作公开业务契约。
- 新增像素资产时保持统一脚底基线、朝向、锚点、帧尺寸和碰撞约定，并在游戏实际缩放下检查。
- UI 应保护主要游玩区域；常驻 HUD 只展示立即可操作的信息，文字密集内容进入暂停页或独立面板。

## 游戏设计闭环

每个玩法任务都要同时说明：

1. 玩家幻想和希望玩家做出的决策。
2. 玩家动作、输入 action 和状态变化。
3. 关卡如何引入、确认、组合、施压和测试该玩法。
4. 成功、失败、奖励和重试方式。
5. HUD、提示、音效、动画和受击反馈。
6. 数据、场景、脚本、资产和存档的影响。
7. 自动化测试、实际试玩和截图证据。

不要把“脚本能够运行”视为玩法完成。手感、可读性和失败恢复必须通过实际运行验证。

## 专业角色路由

项目内的角色说明位于 `docs/agents/`。这些文件是项目级专业工作协议，不代表模型可以绕过本文件的权限、Git 和修改范围约束。

- 玩法机制、战斗循环、成长、奖励、技能、敌人职责或数值设计：先阅读 `docs/agents/game-designer.md`。
- 关卡结构、平台布局、遭遇、教学节奏、检查点、秘密区域或空间引导：先阅读 `docs/agents/level-designer.md`。
- 已批准设计的 Godot 场景、TileMap、节点、资源和数据落地：先阅读 `docs/agents/godot-level-builder.md`。
- 实际运行、截图、试玩、可读性、手感、失败恢复和体验验收：先阅读 `docs/agents/playtest-reviewer.md`。

复杂任务按以下顺序交接：

```text
Game Designer
→ Level Designer（涉及空间时）
→ Godot Level Builder
→ Playtest Reviewer
→ 将发现反馈到 GDD / Story
```

同一轮可以连续承担多个阶段，但必须明确当前角色、输入文档、输出物和阶段边界。设计未批准时，不进入实现；实现未经实际验证时，不宣称完成。

角色索引和调用示例见 `docs/agents/README.md`。标准交付物使用：

- `docs/templates/mechanic-design.md`
- `docs/templates/level-design.md`
- `docs/templates/playtest-report.md`

## 验证要求

- 修改脚本或资源后，先执行 Godot headless import，确认没有解析错误和缺失资源。
- 逻辑、公式、状态机和 Bug 修复必须添加或更新确定性的回归测试。
- 关卡修改必须运行相关装载测试、通路测试和冒烟测试。
- UI、动画、特效、相机、TileMap 和战斗手感必须实际运行，并提供代表状态截图或清晰的人工验证记录。
- 不通过删除、跳过或放宽失败测试来制造“通过”。
- 完成任务时汇报：修改文件、行为变化、测试命令与结果、截图/试玩结果、未验证风险。

常用验证入口见 `tests/README.md`。推荐基线顺序：

```powershell
& 'E:\Godot\Godot.exe' --headless --path . --quit --import
cmd /c addons\gdUnit4\runtest.cmd --godot_binary "E:\Godot\Godot.exe" --add tests/unit
& 'E:\Godot\Godot.exe' --path . 'res://tests/integration/level_2_load_test.tscn'
& 'E:\Godot\Godot.exe' --path . 'res://tests/integration/level_2_traversal_test.tscn'
& 'E:\Godot\Godot.exe' --path . 'res://tests/e2e/smoke_test.tscn'
```

根据任务范围选择相关测试；完整回归或发版前再运行全部检查。

## AI 技术边界

- Codex 在本项目中主要作为开发 Agent：读取代码和 GDD、修改脚本与场景、运行测试、控制编辑器并检查结果。
- `AGENTS.md` 保存长期稳定规则；具体功能目标、范围、取舍和验收标准仍由每次对话 Prompt 提供。
- 当前游戏运行时不需要 LangChain、向量数据库、RAG 或模型微调。除非用户明确要求开发游戏内 AI 对话、知识检索或外部模型功能，否则不要引入这些依赖。
- `addons/godot_ai` 是开发期 MCP 集成，不等同于游戏内生成式 AI 功能；发布前应复核是否需要保留或禁用。

## 任务 Prompt 最小信息

用户的具体任务应尽量包含：

- 目标：希望玩家获得什么体验。
- 范围：允许修改哪些系统、关卡和文件类型。
- 非目标：明确本次不做什么。
- 规则：状态、数值、失败、奖励和边界条件。
- 验收：自动化测试、试玩路径、截图状态和性能要求。

可复用示例见 `docs/codex-development-workflow.md`。
