# Legend of the Warrior 项目约束

> 本文件只保存项目独有的长期约束、常见踩坑和文档路由。通用协作、回复格式、工具、安全和 Git 规则由上层运行规范负责，不在此重复。

## 项目基线

- Godot 4.7 stable；GDScript 使用静态类型。
- 2D 横版动作冒险；逻辑视口 `640x360`，默认窗口 `1280x720`，使用整数缩放。
- 项目地图见 `docs/project-map.md`；玩法数据优先使用 Resource、JSON 和稳定内容 ID。
- 原始美术图集位于 `art/imported/`；不把资产路径当作公开业务契约。

## 不可违反的契约

- 跨系统通信使用 `GameEvents` 或职责明确的 Autoload；禁止新增隐式跨层级 `get_node("../../...")` 耦合。
- 游戏规则和状态是唯一真相；场景树、动画和视觉表现不能单独决定业务状态。
- 伤害必须经过现有伤害入口，禁止直接修改其他角色的生命值字段。
- 场景跳转使用 `GameSceneResource` 与 `SceneLoader`，业务逻辑中不新增裸字符串场景路径。
- 输入逻辑使用 Input Map action，不把具体键位写入游戏规则。
- 可持久化对象遵守 `ISaveable`；变更存档字段时处理旧存档兼容和迁移。
- `_process` / `_physics_process` 中不得反复全树扫描、`find_child` 或未缓存节点查找。
- 复杂 `.tscn`、`.tres`、TileSet 和 TileMap 优先通过 Godot 编辑器或项目工具修改，并验证资源引用与 UID。
- 不修改 `.godot/`、导入缓存、测试报告和导出产物；除非任务明确要求，不修改 `addons/godot_ai` 或 `addons/gdUnit4`。

## 按需路由

- 玩法、战斗、成长、奖励、技能或敌人职责：读取 `docs/agents/game-designer.md`，再读取对应 `design/gdd/`。
- 关卡布局、空间引导、遭遇、教学节奏或检查点：读取 `docs/agents/level-designer.md`。
- 已批准设计的 Godot 场景、节点、TileMap、资源或数据落地：读取 `docs/agents/godot-level-builder.md`。
- 实际运行、手感、可读性、截图或试玩验收：读取 `docs/agents/playtest-reviewer.md`。
- 存档、场景切换、UI 或 Autoload 任务：读取对应 `design/gdd/` 文档和现有实现；不加载无关领域规则。
- 详细方法、数值、方案和验收表写在对应文档中，不复制到本文件。

## 验证路由

- 修改脚本、公式、状态机或 Bug：运行相关回归测试；修改脚本或资源后先做 Godot headless import。
- 修改场景或关卡：运行装载、通路和冒烟测试。
- 修改 UI、动画、特效、相机或手感：实际运行并保留代表状态截图或试玩记录。
- 未实际验证的内容必须明确标注风险，不以“脚本能运行”代替完成结论。
- 跨多轮任务的已确认决策、断点和下一步记录到 `production/session-state/active.md`。
