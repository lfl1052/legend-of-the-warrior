# 《勇士传说》Unity 2022 教程合集研究与 Godot 4.7 制作参考

## 文档目的

本文整理 M_Studio 的 B 站合集《勇士传说》Unity 2022 版教程，并把教程中的游戏制作目标转换为本项目可执行的 Godot 4.7 方案。

- 合集地址：[《勇士传说》Unity2022版教程](https://www.bilibili.com/video/BV1mL411o77x)
- UP 主：M_Studio
- 合集 ID：`1187255`
- 视频数量：39
- 总时长：约 12 小时 37 分 33 秒
- 原教程技术栈：Unity 2022.2、C#、Tilemap、New Input System、Animator、Cinemachine、ScriptableObject
- 本项目技术栈：Godot 4.7 stable、静态类型 GDScript、TileMapLayer、Input Map、AnimationPlayer/AnimationTree、Camera2D、Resource、Autoload

这份文档不是 Unity API 的逐句翻译。它记录的是：教程要解决的玩家体验和系统问题、Godot 对应方案、当前项目状态及后续制作约束。

## 资料可信度与使用边界

本次已通过 B 站公开接口核对合集元数据、39 集顺序、标题、时长、视频简介和作者补充说明。合集当前没有公开字幕，也没有官方逐集文字稿，因此：

- 系统范围、制作顺序和显式技术点可以作为可靠参考。
- Unity 编辑器中的具体按钮、参数和逐行代码不能直接视为 Godot 实现规范。
- 涉及动画时序、镜头幅度、碰撞形状和最终画面效果时，仍需回看对应视频画面，并在 Godot 实际运行中验证。
- 本项目已有架构、GDD、ADR、测试和存档契约优先于教程示例。
- 教程中的机械 Sprite 切割方法不适用于所有原图集。不规则 atlas 必须先建立人工语义区域，不能把透明像素连通块自动认定为完整素材。

## 合集整体结构

教程可以归纳为九个制作阶段：

1. 开发环境与素材管线：第 1–4 集。
2. 玩家基础控制与物理：第 5–9 集。
3. 玩家动画、属性和战斗：第 10–15 集。
4. 敌人与有限状态机：第 16–20 集。
5. HUD、相机和音频反馈：第 21–24 集。
6. 环境伤害和互动：第 25–27 集。
7. 场景管理、加载和主菜单：第 28–32 集。
8. 存档、结束和暂停流程：第 33–38 集。
9. 构建与发布：第 39 集。

## Unity → Godot 4.7 对照

| Unity 概念 | Godot 4.7 对应 | 本项目入口 |
| --- | --- | --- |
| Sprite Editor / Slice | 原 atlas、`AtlasTexture.region`、SpriteFrames 区域 | `data/editor_asset_catalog.json`、`scenes/editor_library/` |
| Tilemap | 多个 `TileMapLayer` | Background / Geometry / Water / Foreground |
| Rule Tile | TileSet Terrain Set / Terrain Connect | `data/forest_tileset.tres` |
| Animated Tile | `TileSetAtlasSource` 动画 | `data/tilesets/forest_water_tileset.tres` |
| Rigidbody2D | `CharacterBody2D` 或 `RigidBody2D` | 玩家和敌人场景 |
| Collider2D | `CollisionShape2D` / `CollisionPolygon2D` | 角色、地形和交互场景 |
| Trigger | `Area2D` | 攻击、感知、交互、传送和伤害区 |
| New Input System | Input Map action | `project.godot`、`player_controller.gd` |
| Animator / Animation Clip | `AnimationPlayer`、SpriteFrames | 玩家和敌人场景 |
| Blend Tree | `AnimationTree` 或显式状态参数映射 | 当前玩家动画状态映射 |
| Gizmos | `_draw()`、调试形状和编辑器可视节点 | PhysicsCheck 与测试场景 |
| UnityEvent | Signal、`GameEvents` | `scripts/autoload/game_events.gd` |
| ScriptableObject | 自定义 `Resource` | `scripts/resources/`、`data/*.tres` |
| Coroutine | `await`、SceneTreeTimer、Tween | 场景加载、受击和 UI 流程 |
| Cinemachine | `Camera2D` + 相机控制脚本 | `scripts/utilities/camera_control.gd` |
| AudioSource | `AudioStreamPlayer` / 2D 版本 | `scripts/autoload/audio_manager.gd` |
| SceneManager | `GameSceneResource` + `SceneLoader` | `scripts/autoload/scene_loader.gd` |
| Canvas / TextMesh Pro | `Control`、Label、Theme | `scripts/ui/`、UI 场景 |
| PlayerPrefs / 序列化 | `DataManager` + ISaveable | `scripts/autoload/data_manager.gd` |
| Addressables | 稳定资源 ID、ResourceLoader、线程加载 | `GameSceneResource`、`SceneLoader` |
| Post Processing / 2D Light | `WorldEnvironment`、CanvasModulate、Light2D | 按关卡表现需求使用 |

## 逐集索引与项目映射

状态含义：

- **已具备**：项目已有对应实现和基本测试。
- **部分具备**：已有基础，但体验、内容或验证未完整覆盖。
- **待实现**：教程涉及，项目尚无可靠实现。
- **非当前目标**：不属于当前 Windows/Linux PC 范围。

| # | 视频 | 教程核心 | Godot / 当前项目映射 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | [安装 Unity 和代码编辑器](https://www.bilibili.com/video/BV1mL411o77x) | 引擎、IDE、代码补全和项目创建 | Godot 4.7 stable 已锁定；使用 Godot 编辑器和 GDScript | 已具备 |
| 2 | [素材导入和整理](https://www.bilibili.com/video/BV1tm4y16728) | 导入素材、目录和编辑器布局 | `art/imported` 原图集优先，catalog 和生成工具管理编辑器素材 | 已具备，但语义区域仍需持续人工审计 |
| 3 | [场景绘制和叠层设置 Tilemap](https://www.bilibili.com/video/BV1NL411X7V2) | Tilemap、切图、叠层、相机尺寸 | 四层 TileMapLayer、640×360 逻辑视口、整数缩放 | 已具备 |
| 4 | [规则瓦片和动态瓦片](https://www.bilibili.com/video/BV1FM4y1174A) | Rule Tile、Animated Tile、瀑布 | Terrain Connect、动态水体 TileSet | 已具备；瀑布仍可扩展 |
| 5 | [人物及基本组件](https://www.bilibili.com/video/BV1Fs4y127A4) | 人物切图、刚体和碰撞体 | `CharacterBody2D`、玩家碰撞与视觉基线 | 已具备 |
| 6 | [新输入系统](https://www.bilibili.com/video/BV17h4y1W7Z2) | 输入配置和 Player Controller | Input Map action + `player_controller.gd` | 已具备 |
| 7 | [人物移动和翻转](https://www.bilibili.com/video/BV1zo4y1L7N8) | 水平移动和朝向 | 速度、朝向、动画映射 | 已具备 |
| 8 | [人物跳跃](https://www.bilibili.com/video/BV1gh411j73Q) | 刚体跳跃 | 跳跃、土狼时间、跳跃缓冲和松键减速 | 已具备并超出教程基础 |
| 9 | [物理环境监测和 Gizmos](https://www.bilibili.com/video/BV1Cg4y1575P) | 地面、墙体和前方检测 | `physics_check.gd`、墙面和悬崖检测 | 已具备 |
| 10 | [人物基本动画](https://www.bilibili.com/video/BV1Rz4y1t7wp) | Animator、Clip、参数切换 | AnimationPlayer 和原 sheet 帧映射 | 已具备 |
| 11 | [跳跃动画 Blend Tree](https://www.bilibili.com/video/BV11M4y1e7kD) | 上升、下落、落地动画混合 | 速度/状态驱动的跳跃动画映射 | 部分具备；仍需逐状态视觉验收 |
| 12 | [人物属性和伤害](https://www.bilibili.com/video/BV14u4y1d7yE) | 属性、碰撞与伤害计算 | `character.gd`、统一伤害入口 | 已具备 |
| 13 | [受伤和死亡](https://www.bilibili.com/video/BV1Fk4y1H7TQ) | 受伤动画、死亡逻辑、事件 | 无敌帧、受击、死亡、复活和反馈事件 | 已具备 |
| 14 | [三段攻击动画](https://www.bilibili.com/video/BV1Ju41187CY) | 连击动画切换 | 三段攻击和输入缓存 | 已具备 |
| 15 | [攻击判定](https://www.bilibili.com/video/BV1bM4y177Ap) | 动画期间启停攻击范围 | `attack.gd` 与攻击时序 | 已具备 |
| 16 | [野猪基础移动和动画](https://www.bilibili.com/video/BV1oz4y1E7aJ) | 巡逻、墙面碰撞和动画 | Boar 脚本及敌人基础层 | 部分具备，正式内容接入需复核 |
| 17 | [野猪撞墙和等待](https://www.bilibili.com/video/BV1Lk4y1N7ZD) | 朝向检测、撞墙、等待计时 | PhysicsCheck、Patrol 状态与计时 | 部分具备 |
| 18 | [野猪受伤和死亡](https://www.bilibili.com/video/BV1Ah4y1C7JB) | 敌人受击和死亡动画 | `enemy_combatant.gd` | 基础已具备，Boar 表现待验收 |
| 19 | [有限状态机和抽象类多态](https://www.bilibili.com/video/BV1xp4y137Xr) | 状态模式和敌人公共基类 | `base_state.gd`、Patrol/Chase/Skill | 已具备 |
| 20 | [追击状态转换](https://www.bilibili.com/video/BV1kP411x7UW) | 感知、追击、丢失目标和返回 | 敌人感知与状态切换 | 已具备 |
| 21 | [创建人物状态栏](https://www.bilibili.com/video/BV1Lu411E7MQ) | 血量 UI 结构 | HUD 和 `player_stat_bar.gd` | 已具备 |
| 22 | [血量更新逻辑](https://www.bilibili.com/video/BV1Uh4y1N7pT) | 属性事件驱动 UI | GameEvents / 信号更新 HUD | 已具备 |
| 23 | [摄像机跟随和攻击抖动](https://www.bilibili.com/video/BV1i94y1W75i) | 跟随、边界和打击震动 | Camera2D 控制和战斗反馈 | 部分具备；抖动强度需实际试玩校准 |
| 24 | [音源设置和音效](https://www.bilibili.com/video/BV1WK4y1F7nH) | BGM、SFX 和播放接口 | `audio_manager.gd` | 逻辑已具备，正式音频资产仍是缺口 |
| 25 | [水和荆棘逻辑](https://www.bilibili.com/video/BV1mw411Y7pM) | 环境区域、伤害与反馈 | 动态水体已有；环境伤害区需按关卡设计接入 | 部分具备 |
| 26 | [人物可互动标识](https://www.bilibili.com/video/BV13w411c7zU) | 进入交互范围时显示提示 | `sign.gd`、交互探测和 UI 提示 | 已具备基础 |
| 27 | [场景互动逻辑](https://www.bilibili.com/video/BV1p94y1b7ka) | 宝箱、物品、触发和奖励 | Chest、Breakable、CollectibleReward | 已具备 |
| 28 | [场景管理和切换](https://www.bilibili.com/video/BV1mu4y1E7de) | 场景引用、传送和切换流程 | `GameSceneResource`、`SceneLoader` | 已具备 |
| 29 | [场景加载后的执行逻辑](https://www.bilibili.com/video/BV15C4y1S7Tc) | 出生点、加载完成和场景初始化 | SceneLoader、场景入口与运行时初始化 | 已具备基础 |
| 30 | [场景淡入淡出](https://www.bilibili.com/video/BV11N411u7q9) | 切换遮罩和异步时序 | `fade_canvas.gd` + SceneLoader | 已具备 |
| 31 | [主场景制作](https://www.bilibili.com/video/BV1MC4y127aV) | 主菜单和 UI 结构 | `warrior_menu.tscn`、MenuFlow | 已具备 |
| 32 | [新的冒险](https://www.bilibili.com/video/BV1sw41187WH) | 新游戏初始化和状态重置 | 新游戏流程、存档隔离和角色初始化 | 已具备 |
| 33 | [存储点和画面效果](https://www.bilibili.com/video/BV11u4y1K7p8) | 存档点、恢复和视觉提示 | `save_point.gd` | 已具备 |
| 34 | [数据结构及坐标保存加载](https://www.bilibili.com/video/BV1a5411B7XD) | 数据模型、场景 ID 和坐标 | DataManager、ISaveable、稳定内容 ID | 已具备并增加旧存档兼容要求 |
| 35 | [人物数值及场景保存加载](https://www.bilibili.com/video/BV1k94y1T7hB) | 玩家状态和场景持久化 | 玩家成长、存档协议、场景状态 | 已具备基础 |
| 36 | [游戏结束面板](https://www.bilibili.com/video/BV1RN4y1p7xm) | 失败/完成 UI 和重试 | 当前死亡、复活和菜单流程已有；完整结束面板需按章节设计确认 | 部分具备 |
| 37 | [移动设备屏幕操控](https://www.bilibili.com/video/BV1Li4y1p72V) | 触屏输入 | 当前目标平台为 Windows/Linux PC | 非当前目标 |
| 38 | [暂停面板和声音控制](https://www.bilibili.com/video/BV1mC411B7a2) | 暂停、音量和 UI 状态 | UIManager、暂停页、AudioManager | 已具备基础 |
| 39 | [打包生成游戏](https://www.bilibili.com/video/BV1uZ421U7Qz) | 构建配置和最终导出 | Godot ExportPreset、发布检查和平台构建 | 待发布阶段验证 |

## 对当前项目最重要的制作结论

### 1. 教程是功能覆盖清单，不是必须复制的架构

教程使用 ScriptableObject 作为中间事件键。本项目已经使用 `GameEvents`、职责明确的 Autoload 和自定义 Resource，不应为了贴近教程重新引入一套重复事件架构。

### 2. 素材整理必须先理解原图语义

教程早期展示的规则切图只适用于规则 sheet。本项目的 `Hive.png`、`Forest-2.png`、`Buildings.png` 和 `Props-Rocks.png` 存在不规则排版：

- 相邻但不同用途的素材可能像素相连。
- 一个完整物件可能由多个互不相连的透明区域组成。
- 技术连通块只能作为候选，不是完整素材定义。
- 正式 Scene Paint 必须满足 `editor_ready=true`，并区分 `standalone` 与 `kit_piece`。

这条规则优先于教程中的自动切割演示。

### 3. 关卡绘制必须区分连续地形和视觉摆件

- Geometry Terrain 承担可站立地面、墙体和平台碰撞。
- Background、Water、Foreground 和 Scene Paint 默认只负责表现。
- 岩石堆、矿石堆和矿洞入口不能通过临时添加碰撞冒充完整矿区 Terrain。
- 当前没有专用矿区 Geometry Terrain，正式矿区仍存在资产缺口。

### 4. 动画不能成为业务状态的唯一真相

教程大量通过 Animator 参数和动画事件驱动逻辑。本项目应保持：

- 角色状态、伤害、攻击窗口和死亡规则由脚本状态控制。
- AnimationPlayer/SpriteFrames 只表现已经确定的状态。
- 攻击判定可以与动画时序同步，但不能只依赖某个动画帧是否播放来保存业务状态。

### 5. 敌人 FSM 应共享协议而非复制脚本

教程从野猪逐步引入状态模式。本项目已有公共 Enemy、BaseState、Patrol、Chase 和 Skill 结构。新增敌人应复用感知、伤害和状态协议，只把差异留在角色专属状态与数据中。

### 6. 场景切换和存档需要稳定 ID

Unity 教程后段才引入场景和坐标保存。本项目从一开始就要求：

- 场景引用通过 `GameSceneResource` 和 `SceneLoader`。
- 可持久化对象遵守 ISaveable。
- 内容使用稳定 ID，不把文件路径和节点临时名称当作长期存档键。
- 修改数据结构时考虑旧存档迁移。

### 7. 完成标准必须包含实际体验

教程展示“功能能够运行”，本项目的完成门槛更高：

- 自动化测试证明逻辑和资源契约。
- 实际运行证明手感、可读性、镜头、动画和失败恢复。
- 关卡修改需要装载、通路、冒烟和代表状态截图。
- 不因教程里有实现就默认它适合当前项目的战斗节奏与关卡结构。

## 后续制作建议顺序

结合教程覆盖和当前项目状态，推荐继续按以下顺序推进：

1. 完成人工素材区域表，优先处理 Forest-2、Hive 和 Buildings 组合语义。
2. 建立专用矿区 Geometry Terrain，消除森林地面作为矿区灰盒的问题。
3. 使用经过语义审核的素材重新设计一段正式森林→矿区过渡关卡。
4. 完成 Boar 正式场景、状态表现和关卡遭遇验证。
5. 补齐水体/荆棘等环境伤害的设计、反馈和测试。
6. 实际校准相机跟随、攻击震动、受击反馈和音效同步。
7. 完成章节结束、失败重试和游戏结束面板闭环。
8. 发布阶段再处理 Windows/Linux 导出、构建验证和发布检查清单。

## 每次参考本合集时的检查清单

- 本集解决的是玩家体验问题，还是 Unity 编辑器特有操作？
- Godot 中已有等价架构吗？是否会产生重复系统？
- 教程示例是否依赖规则图集，而当前素材实际是不规则 atlas？
- 逻辑是否应该由状态脚本负责，而不是动画或场景树负责？
- 是否影响输入 action、存档契约、场景 ID 或跨系统事件？
- 是否需要更新 GDD、ADR、Story 或测试？
- 是否已经通过实际运行和截图，而不只是脚本解析成功？

## 相关项目文档

- `docs/project-map.md`
- `docs/art-asset-library.md`
- `docs/reference/tilemap-rule-and-layering-workflow.md`
- `design/gdd/forest-chapter-redesign.md`
- `design/gdd/pixel-art-and-collision-standard.md`
- `docs/agents/game-designer.md`
- `docs/agents/level-designer.md`
- `docs/agents/godot-level-builder.md`
- `docs/agents/playtest-reviewer.md`
