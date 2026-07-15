# 项目专业 Agent 索引

这些文件是按需读取的角色协议，不是常驻运行的子 Agent。根目录 `AGENTS.md` 负责根据任务类型路由；详细规则、数值、资产事实和测试命令分别放在 GDD、资产文档和 `tests/README.md`。

## 角色

| 角色 | 文件 | 负责 | 不负责 |
| --- | --- | --- | --- |
| Game Designer | `game-designer.md` | 玩法、循环、状态、数值、反馈和验收假设 | GDScript、场景和 TileMap 实现 |
| Level Designer | `level-designer.md` | 路线、平台、遭遇、教学、检查点和灰盒规格 | 最终 Godot 场景搭建 |
| Godot Level Builder | `godot-level-builder.md` | 已批准设计的场景、TileMap、资源、数据和测试落地 | 自行改变玩法设计 |
| Playtest Reviewer | `playtest-reviewer.md` | 实际运行证据、体验发现、严重度和责任路由 | 无证据地改设计或代码 |

## 路由

```text
机制/玩法 → Game Designer
空间/遭遇 → Level Designer
批准后的 Godot 落地 → Godot Level Builder
实际运行与体验验收 → Playtest Reviewer
```

跨边界任务只加载当前阶段和直接依赖的角色文档；不要为了“完整流程”一次性加载全部 Agent。

## 模板

- 机制设计：`docs/templates/mechanic-design.md`
- 关卡设计：`docs/templates/level-design.md`
- 试玩报告：`docs/templates/playtest-report.md`

模板负责输出字段，角色文档负责判断原则；两者不重复抄写。
