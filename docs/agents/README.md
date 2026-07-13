# 项目专业 Agent 索引

这些角色文件把游戏开发任务拆成设计、空间实现和验证阶段。它们由根目录 `AGENTS.md` 路由，具体任务仍由当次对话提供目标、范围、非目标和验收标准。

## 角色

| 角色 | 文件 | 主要产出 | 不负责 |
| --- | --- | --- | --- |
| Game Designer | `game-designer.md` | 玩法规则、循环、数值、状态、反馈和验收假设 | GDScript 与场景实现 |
| Level Designer | `level-designer.md` | 关卡灰盒、路线、遭遇、节奏、检查点和地编规格 | 在 Godot 中直接搭建关卡 |
| Godot Level Builder | `godot-level-builder.md` | 把已批准设计落地为场景、TileMap、数据和测试 | 自行改变玩法设计 |
| Playtest Reviewer | `playtest-reviewer.md` | 基于实际运行证据的体验发现、严重度和责任归属 | 无证据地改设计或代码 |

## 推荐流程

```text
用户目标
→ 读取项目现状和 GDD
→ Game Designer 明确玩法
→ Level Designer 明确空间和遭遇
→ 用户批准设计
→ Godot Level Builder 实现
→ 自动化测试
→ Playtest Reviewer 实际试玩
→ 发现回流到 GDD、Story 或 Bug
```

## 调用示例

### 玩法设计

```text
请按 docs/agents/game-designer.md 工作。
为玩家设计一个空中下劈技能，先提供方案和机制文档，不修改代码。
```

### 关卡设计

```text
请按 docs/agents/level-designer.md 工作。
为 level_2 的 Combine 区域设计 Snail + Bee 地空组合遭遇，输出灰盒图和遭遇表。
```

### Godot 地编实现

```text
请按 docs/agents/godot-level-builder.md 工作。
把已批准的 level_2 Combine 设计实现到 Godot，并运行装载、通路和截图验证。
```

### 试玩评审

```text
请按 docs/agents/playtest-reviewer.md 工作。
实际运行 level_2，验证出生、组合战、Boss 前检查点和出口，按严重度输出发现。
```

## 交付物模板

- 玩法机制：`docs/templates/mechanic-design.md`
- 关卡设计：`docs/templates/level-design.md`
- 试玩报告：`docs/templates/playtest-report.md`

模板是最低信息要求，可以按任务缩减不适用部分，但不得省略会影响实现或验收的关键决策。
