# 《勇士传说》Unity 中文课堂课程研究与 Godot 4.7 制作参考

## 文档目的

本文以 M_Studio 在 Unity 中文课堂发布的《勇士传说》横版卷轴动作类游戏开发教程为主来源，并把课程中的游戏制作目标转换为本项目可执行的 Godot 4.7 方案。B 站合集降级为公开视频、简介与作者评论的交叉核验来源。

- 主课程：[《勇士传说》横版卷轴动作类游戏开发教程](https://learn.u3d.cn/tutorial/2DAdventure?chapterId=64096e626391b600208067da&sectionId=640975324b7731001f66a5f5)
- 主课程平台：Unity 中文课堂
- 讲师：M_Studio
- 课程规模：9 章、50 个课时，另有 9 个章节摘要
- 交叉来源：[B 站《勇士传说》Unity2022版教程](https://www.bilibili.com/video/BV1mL411o77x)，合集 ID `1187255`，39 集，总时长约 `12:37:33`
- 原教程技术栈：Unity 2022.2、C#、Tilemap、New Input System、Animator、Cinemachine、ScriptableObject
- 本项目技术栈：Godot 4.7 stable、静态类型 GDScript、TileMapLayer、Input Map、AnimationPlayer/AnimationTree、Camera2D、Resource、Autoload

这份文档不是 Unity API 的逐句翻译。它记录的是：教程要解决的玩家体验和系统问题、Godot 对应方案、当前项目状态及后续制作约束。

## 资料可信度与使用边界

本次已在登录状态的 Google Chrome 中直接打开 Unity 中文课堂课程页，核对 9 章、50 个课时的目录、课时页面、播放器和课时下方的讨论/笔记/资料区域；同时保留此前通过 B 站公开接口与评论区得到的交叉证据。资料使用边界如下：

- 中文课堂课时正文、播放器画面和课时下方明确提示是本轮主要证据；只有实际阅读或观看后才标为“已整理”。
- B 站标题、简介、评论和前 5 集音轨转写只作为交叉核验，不再以 B 站 39 集批量转写作为主工作流。
- 系统范围、制作顺序和页面显式技术点可以作为可靠参考；未经观看的课时不能仅凭标题补写参数。
- Unity 编辑器中的具体按钮、参数和逐行代码不能直接视为 Godot 实现规范，必须转换为项目已有架构下的实现目标。
- 涉及动画时序、镜头幅度、碰撞形状和最终画面效果时，仍需回看对应视频画面，并在 Godot 实际运行中验证。
- 本项目已有架构、GDD、ADR、测试和存档契约优先于教程示例。
- 教程中的机械 Sprite 切割方法不适用于所有原图集。不规则 atlas 必须先建立人工语义区域，不能把透明像素连通块自动认定为完整素材。

## Chrome 核验记录

本轮于 2026-07-14 使用 Google Chrome 直接打开 Unity 中文课堂课程页。页面标题为《勇士传说》横版卷轴动作类游戏开发教程，目录明确列出 9 章、50 个课时；相比 B 站 39 集版本，中文课堂额外提供 11 个标记为“独有”的课时，因此改为主来源。

- 中文课堂页面当前可读取课时标题、所属章节、播放器实际时长、课时正文提示，以及讨论/笔记/资料区域。
- 页面视频使用 `blob:` 媒体地址，未发现普通 HTML `<track>` 字幕；后续以实际播放观察、课时页面文字和可验证的媒体信息整理，不把标题推断写成正文事实。
- “章节 7 / 6.主场景制作”视频已完整核验，实际时长约 `23:59`；页面提示的 Canvas Scaler 固定参考分辨率示例 `1920×1080` 已与视频内容一并记录在第 40 课笔记中。

B 站交叉核验记录如下：

- 合集 ID `1187255`，共 39 集，7 个官方分组，总时长 `12:37:33`。
- 39 集均核对了标题、BVID、CID、时长、分组和作者简介；39 个详情请求均成功。
- 视频页为 3840×2160 的 4K 教程录制，这只是视频清晰度，不是游戏画布规格。
- 页面字幕对象最多只有语言占位，39 集均没有可用的公开 `subtitle_url`；不能把自动生成的逐字稿当作证据。
- B 站公开 AI 总结接口返回无权限，因此本文不会虚构视频内未在标题、简介或项目资料中出现的精确数值。

本轮进一步用 Chrome 播放器实际观察了首集正文和评论区，并下载公开可播放音轨做本地语音识别抽样。首集前 90 秒的识别内容确认作者实际讲解了：访问 `unity.cn`、进入 Unity 下载页、注册/登录 Unity ID、准备 Windows 电脑并选择 Unity 版本；这比标题和简介提供了更具体的操作顺序。播放器画面同时显示逐句中文字幕，但该字幕没有作为公开 `subtitle_url` 返回，因此正文整理采用“播放器画面/音轨转写 + 页面评论”证据，不把模型转写当作逐字稿。

### 作者评论中的实操答疑

Chrome 评论区可见的 UP 主回复补充了几个容易踩坑的设置：

- Game 窗口像素大小忽大忽小时，作者判断是 Game 窗口的 `Scale` 被调大，应保持最小；这说明编辑器预览缩放不应被误认为像素素材或屏幕 DPI 问题。
- Sprite 切图后坐标轴跑到头顶时，作者要求把 Scene 窗口左上角的 `Center` 改为 `Pivot`。
- 有用户反馈人物素材现在可能收费，作者没有提供新的免费镜像；素材许可证不能因为教程曾经使用就默认可再分发。
- 作者对“视图有但 Game 窗口没有”的答疑指出，默认 Main Camera 的 Z 为 `-10`；评论中的用户曾把它改为 `0`，导致摄像机位置不正确。
- 首集置顶评论把课程受众、最终效果和技术栈列得更完整：面向有无基础的游戏开发学习者，覆盖 2D 物理、Animator、Cinemachine、Post Processing、2D Light、Addressables、UI、TextMesh Pro、New Input System，以及 C# 面向对象、抽象类、接口、继承多态、事件、ScriptableObject、协程和序列化；项目流程以 ScriptableObject 作为中间键驱动事件。
- 第 1 集作者答疑要求学习阶段使用 Unity `2022.3`，不要自行换到 2023；安装目录优先使用 C 盘根目录并避开中文路径，同时保证 C 盘空间充足。
- 第 1 集作者多次把 Hub/编辑器安装失败归因于杀毒软件或电脑管家；Windows 初学阶段建议先用 Visual Studio。若使用 VS Code，需要先通过 Package Manager 安装对应支持，再在 External Script Editor 菜单中选择 VS Code。
- 第 6 集作者答疑要求顶层 Input Action 使用 `Vector2`；创建 Action Asset 后，还要点击黄色提示下的 `Assign as...`，将它指定为项目当前使用的输入配置。`PlayerController` 空引用问题通常来自变量漏赋值。
- 第 9 集作者再次强调 Sprite 切割时 Pivot 设为 `Bottom`，Scene 窗口显示从 `Center` 切到 `Pivot`；角色落地后应恢复带摩擦力的物理材质，而非始终使用零摩擦。
- 第 16 集作者答疑指出敌人翻转后的检测方向必须乘 `localScale.x`；Animator/Animation 拼写混淆、Awake 中未初始化引用也是该阶段常见报错来源。
- 第 17 集评论要求把地面 `Composite Collider 2D` 的类型改为 `Geometry`，并确认 Scene 窗口右上角 Gizmos 已开启。
- 第 18 集持续受击通常来自 Attack Area 没有按时关闭，或攻击脚本挂错节点；不能用重启编辑器掩盖攻击区域生命周期错误。
- 第 19–20 集作者多次要求在 Awake 中 `new` 状态实例；地面检测不能宽到跨过悬崖空隙，`isGround=false` 时不要继续执行落地物理判断。Play 模式中临时修改的场景不会保存，正式编辑必须退出运行模式。
- 第 23 集相机显示/边界异常时，作者要求先检查摄像机范围碰撞体；报错后的行号应直接用于定位未赋值变量，避免凭画面猜代码问题。
- 第 24 集作者建议多音效并发使用对象池创建多个 AudioSource；音效重复播放时先检查是否每帧重复触发，并可输出 `this.name` 确认脚本实际挂载对象。
- 第 26 集交互提示异常时要检查图片 Pixels Per Unit，以及地面 Tilemap 是否标记为 Ground；物体未启用时 Animator 不运行。作者也明确部分课程素材属于付费课程，不能当作公开素材包。
- 第 28 集使用 Addressables 管理场景后，场景内对象的修改需要重新 Build 才会生效；第二场景也必须正确标记 Ground。
- 第 30 集淡入淡出相关代码仍基于 New Input System，不能混回 Old Input Manager；涉及 UI 组件时需引用 `UnityEngine.UI` 命名空间。
- 第 31 集主场景故障排查仍先确认地面 Ground 标记和 Composite Collider；追踪 ScriptableObject Event 来源时，可在编辑器中搜索 Event 名称，或在每次 RaiseEvent 时记录广播类。
- 第 32 集新场景要删除多余 Main Camera，避免两个 Audio Listener；场景加载完成后应重置残留力，新游戏开始时把 `currentHealth` 初始化为 `maxHealth`。
- 第 33 集为避免 Save Point 的 Sign Sprite 与 Rock 排序穿帮，作者要求在根物体添加 Sorting Group，把根与子物体作为一个整体排序。
- 第 34 集 DataManager/SaveManager 需要 `DefaultExecutionOrder(-100)`，保证先于其他脚本和 ISaveable 注册执行；否则会出现尚未初始化就注册事件或读取数据的问题。

这些评论是作者/用户在页面上的补充，不等价于视频正文；若与当前 Godot 项目架构冲突，仍以项目 GDD、ADR 和存档契约为准。

证据等级：

- **页面明确**：合集页、标题、分组、简介或作者补充中直接出现的内容。
- **教程目标**：由标题和系列上下文确认的制作目标，但不声称拥有逐字操作参数。
- **项目映射**：根据当前 Godot 4.7 项目文件给出的落地方案，不代表 Unity 原教程原话。

### 中文课堂章节结构

| 章节 | 课时数 | 内容范围 | 项目侧关注点 |
| --- | ---: | --- | --- |
| 1. 基础设置 | 5 | 欢迎、安装、素材、场景、规则/动态瓦片 | 素材许可证、导入参数、TileSet 与分层 |
| 2. Player 人物创建 | 13 | 组件、输入、移动、跳跃、检测、动画、属性、伤害与攻击 | Input Map、CharacterBody2D、动画表现与伤害入口 |
| 3. 敌人的制作 | 9 | 野猪、FSM、追击、蜗牛、蜜蜂 | 公共 Enemy 协议、状态机与敌人差异 |
| 4. UGUI - 人物状态栏 | 2 | 状态栏与血量更新 | HUD 信息层级与 GameEvents |
| 5. Player 人物特殊动作 | 2 | 滑墙/蹬墙跳、滑铲 | 玩家状态、输入窗口、碰撞与手感 |
| 6. 常用功能及机制 | 3 | 相机、音频、水与荆棘 | Camera2D、AudioManager、环境伤害 |
| 7. 场景转换 | 7 | 互动标识、场景切换、淡入淡出、主场景与新游戏 | SceneLoader、GameSceneResource 与 UI 流程 |
| 8. 数据保存和加载 | 5 | 存储点、坐标/数值/场景、结束面板、序列化文件 | ISaveable、稳定 ID、迁移与失败恢复 |
| 9. 收尾及打包 | 4 | 移动端、暂停/声音、构建、完整代码 | PC 发布检查；移动端当前非目标 |

### 50 课正文阅读与整理进度

本节用于长时间任务的实时记录。“已整理”表示对应正文已经进入下方具体笔记；“页面提示已记录”表示只记录了课时页明确文字，不能视为视频已看完。B 站前 5 集与中文课堂第 2–6 课内容相同，按用户确认不重复观看；后续从第 7 课“创建及配置新输入系统”开始，以中文课堂视频为主线继续整理。

| 总序 | 章节/课时 | 状态 | 当前记录 |
| ---: | --- | --- | --- |
| 1 | 1-1 欢迎 | 跳过 | 课程导览，不影响项目制作；按用户要求不回看前置内容 |
| 2 | 1-2 安装 Unity 引擎和代码编辑器 | 已整理 | B 站第 1 集完整音轨；同源内容不重复观看 |
| 3 | 1-3 素材导入和整理 | 已整理 | B 站第 2 集完整音轨；素材、切片和 Pivot 已记录 |
| 4 | 1-4 场景绘制和叠层设置 | 已整理 | B 站第 3 集完整音轨；Tilemap、相机和叠层已记录 |
| 5 | 1-5 有规则和动态瓦片 | 已整理 | B 站第 4 集完整音轨；Rule/Animated Tile 已记录 |
| 6 | 2-1 设置人物及基本组件 | 已整理 | B 站第 5 集完整音轨；刚体、碰撞体和约束已记录 |
| 7 | 2-2 创建及配置新输入系统 | 视频画面已核验 | `27:26`；代码模板、Input System、Action 配置、PlayerInput、生命周期与 Vector2 读取已记录 |
| 8 | 2-3 实现移动和翻转 | 视频画面已核验 | `17:46`；刚体速度、变量获取、FixedUpdate、运行时数值与两种翻转方案已记录 |
| 9 | 2-4 实现人物跳跃 | 视频画面已核验 | `14:14`；跳跃 Action、输入 started 回调、AddForce/Impulse、Gravity Scale 与落地限制已记录 |
| 10 | 2-5 物理环境监测及绘制 | 视频画面已核验 | `17:29`；脚底圆形检测、Ground Layer、Gizmos、检测参数和 Physics Material 2D 已记录 |
| 11 | 2-6 创建人物基本动画 | 视频画面已核验 | `23:23`；Animator Controller、Idle/Run/Walk Clip、Samples、`PlayerAnimation` 与 `velocityX` 条件已记录 |
| 12 | 2-7 人物行走设定 | 视频画面已核验 | `07:08`；WalkButton 按下/松开回调、跑速缓存、半速强制行走与接地限制已记录 |
| 13 | 2-8 创建人物跳跃动画 | 视频画面已核验 | `14:26`；多段空中/落地动画、`velocityY` Blend Tree、`isGround` 与落地打断已记录 |
| 14 | 2-9 实现人物下蹲逻辑和动画 | 视频画面已核验 | `15:05`；下蹲子状态机、`isCrouch`、碰撞体 offset/size 切换与移动锁定缺口已记录 |
| 15 | 2-10 人物属性及伤害计算 | 视频画面已核验 | `21:53`；野猪木桩、双碰撞体、`Character`/`Attack`、伤害扣减、受伤无敌与生命归零已记录 |
| 16 | 2-11 受伤和死亡的逻辑和动画 | 视频画面已核验 | `25:49`；受伤表现、UnityEvent、击退、死亡输入禁用、Animator Behavior 与死亡 Layer 补充已记录 |
| 17 | 2-12 三段攻击动画的实现 | 视频画面已核验 | `14:56`；三段 Clip/子状态机、Combo 参数、Exit Time、攻击输入与连段重置已记录 |
| 18 | 2-13 实装攻击判定 | 视频画面已核验 | `17:07`；攻击触发区、伤害组件、攻击期间移动锁定、状态退出回调与原地连续命中缺口已记录 |
| 19 | 3-1 野猪：基本的移动逻辑和动画 | 视频画面已核验 | `16:35`；敌人 prefab、Idle/Walk、Enemy 公共速度与朝向移动已记录 |
| 20 | 3-2 野猪：撞墙判定和等候计时 | 视频画面已核验 | `17:24`；三点物理检测、碰撞体推导、撞墙转身、等待计时与朝向缩放补充已记录 |
| 21 | 3-3 野猪：受伤及死亡的逻辑和动画 | 视频画面已核验 | `23:45`；Hurt/Dead 动画、方向击退协程、死亡 Layer 与动画结束销毁已记录 |
| 22 | 3-4 有限状态机、抽象类与多态 | 视频画面已核验 | `18:54`；Enemy/Boar 继承、BaseState 抽象接口、Patrol/Chase 装配与状态生命周期已记录 |
| 23 | 3-5 追击状态的转换 | 视频画面已核验 | `26:08`；玩家检测、Patrol↔Chase、丢失目标计时与页面修正已记录 |
| 24 | 3-6 蜗牛：基本的移动逻辑和动画 | 视频画面已核验 | `18:47`；Snail prefab、基础动画、Patrol 状态、物理检测与死亡动画缺口已记录 |
| 25 | 3-7 蜗牛：特殊技能状态的实现 | 视频画面已核验 | `15:38`；缩壳动画/Skill 状态、发现玩家触发、持续计时与返回巡逻已记录 |
| 26 | 3-8 蜜蜂：基本的移动逻辑和动画 | 视频画面已核验 | `22:08`；飞行 prefab、范围检测、随机巡逻点与 BeePatrolState 已记录 |
| 27 | 3-9 蜜蜂：追击和攻击的实现 | 视频画面已核验 | `20:59`；追击、攻击范围、频率计时、攻击动画与最终运行测试已记录 |
| 28 | 4-1 创建人物状态栏 | 视频画面已核验 | `18:16`；Canvas、状态栏素材切片、锚点、头像、生命/延迟/能量层已记录 |
| 29 | 4-2 血量更新逻辑的实现 | 视频画面已核验 | `20:18`；PlayerStatBar、CharacterEventSO、事件监听、填充比例与延迟血条已记录 |
| 30 | 5-1 滑墙及蹬墙跳的实现 | 视频画面已核验 | `21:27`；墙面动画、物理材质切换、滑落限速、墙检测与蹬墙跳已记录 |
| 31 | 5-2 滑铲的逻辑和动画的实现 | 视频画面已核验 | `29:24`；滑铲动画、输入、协程位移、中断条件、碰撞层与能量反馈已记录 |
| 32 | 6-1 摄像机跟随及攻击抖动实现 | 视频画面已核验 | `20:47`；Cinemachine 跟随、Pixel Perfect、边界替换与 Impulse 抖动已记录 |
| 33 | 6-2 音源设置和音效播放 | 视频画面已核验 | `23:00`；AudioSource、Audio Mixer、事件通道、AudioManager 与运行测试已记录 |
| 34 | 6-3 水和荆棘的逻辑实现 | 视频画面已核验 | `07:20`；水体触发、Character 死亡入口、荆棘 Attack 伤害与运行验证已记录 |
| 35 | 7-1 人物可互动标识 | 视频画面已核验 | `27:16`；提示素材、玩家检测区、Sign 动画、朝向修正与范围显隐已记录 |
| 36 | 7-2 场景互动的逻辑实现 | 视频画面已核验 | `18:41`；IInteractable、输入回调、目标缓存、Chest 打开与重复触发控制已记录 |
| 37 | 7-3 场景管理和切换 | 视频画面已核验 | `28:15`；Addressables、GameSceneSO、持久场景、加载事件与卸载/加载协程已记录 |
| 38 | 7-4 场景加载后的执行逻辑 | 视频画面已核验 | `18:15`；Completed 回调、出生坐标、玩家启停、AfterSceneLoaded 与交互修正已记录 |
| 39 | 7-5 场景淡入淡出效果 | 视频画面已核验 | `17:48`；全屏 Image、DOTween、FadeEventSO、FadeCanvas 与加载时序已记录 |
| 40 | 7-6 主场景制作 | 视频画面已核验 | `23:59`；动态森林背景、标题、菜单区、按钮导航和加载期间输入启停已记录 |
| 41 | 7-7 实现“新的冒险”逻辑 | 视频画面已核验 | `16:36`；新游戏事件、默认场景、角色初始化、默认焦点和退出逻辑已记录 |
| 42 | 8-1 存储点及画面效果 | 视频画面已核验 | `20:43`；存储点状态、互动激活、后处理反馈和 Sort Group 已记录 |
| 43 | 8-2 数据结构及坐标保存加载 | 视频画面已核验 | `30:16`；Data、ISaveable、稳定 ID、注册表和角色坐标往返已记录 |
| 44 | 8-3 人物数值及场景的保存加载 | 视频画面已核验 | `16:36`；生命/能量、当前场景、继续游戏和加载后 UI 刷新已记录 |
| 45 | 8-4 制作游戏结束面板 | 视频画面已核验 | `20:52`；Game Over 面板、死亡事件、重试、回菜单和默认焦点已记录 |
| 46 | 8-5 序列化保存数据文件 | 视频画面已核验 | `18:03`；Newtonsoft.Json、持久目录、读写顺序和 Vector3 包装已记录 |
| 47 | 9-1 实现移动设备屏幕操控 | 视频画面已核验 | `11:29`；虚拟摇杆、动作按钮、Input action、显隐与真机验证已记录；PC 非当前目标 |
| 48 | 9-2 暂停面板及声音控制 | 视频画面已核验 | `19:21`；暂停面板、Time Scale、Audio Mixer、音量同步和按钮焦点已记录 |
| 49 | 9-3 打包生成游戏 | 视频画面已核验 | `13:54`；Addressables Build、Player Settings、场景列表、平台包与独立运行已记录 |
| 50 | 9-4 全部代码文件 | 资料页已核验 | 无视频；版权限制、夸克/迅雷参考代码入口和使用边界已记录 |

### 第 1 集：安装 Unity 和代码编辑器

正文操作顺序：

1. 访问 `unity.cn`，在下载页先创建或登录 Unity ID；作者使用 Windows 电脑演示，也提到低配置设备可使用 Unity 云桌面。
2. 录制时 Windows 最新版本为 `2022.2.6`，Mac 演示使用 `2022.2.7`。作者区分了 LTS 与 Technical Stream：LTS 至少提供两年稳定更新；教程选择 2022.2 Technical Stream，并要求关注 Release Notes、补丁修复和已知问题。结合后来作者评论，当前复现教程应固定在 `2022.3`，不要在学习中途自行跨到 2023 新版本。
3. 通过 Unity Hub 安装和管理编辑器、许可证与项目。首次使用时激活个人免费许可证；Hub 界面可切换为简体中文，但作者不建议把 Unity 编辑器本体长期切成中文，因为教程、公司环境和新工具文档多数使用英文。
4. Hub 偏好设置分别配置项目默认目录、编辑器安装目录和资产下载目录。作者建议初学者暂时不使用 Plastic SCM：网络不稳定会引入问题，也可能与项目文件产生冲突。
5. 安装编辑器时默认勾选 Visual Studio Community 2022。Android 等平台构建模块可以等真正需要打包时再添加；离线英文文档和中文语言包按需安装，本次演示只保留 Visual Studio。
6. 新建项目时选择 `2D URP` 模板，以直接获得 Universal Render Pipeline 配置；不要勾选右下角的版本管理/政策选项。项目统一放入专用项目目录，示例项目名为 `2D Adventure`。
7. 在 `Edit > Preferences > External Tools` 确认 Script Editor 已指向 Visual Studio 2022。新建一个 C# Script 并双击打开：`MonoBehaviour` 获得语法高亮、顶部出现 CodeLens 引用、代码补全和调试可用，才算 IDE 配置成功。
8. 若 IDE 没有正确连接，先关闭编辑器，再在 Project 空白处右键执行 `Open C# Project`，重新生成/加载解决方案与引用。
9. Mac 需要按 CPU 选择 Apple Silicon 或 Intel 编辑器。使用 VS Code/Rider 时，在 Package Manager 的 `In Project` 中确认对应 Editor Integration；缺失 VS Code 支持时切到 `Unity Registry` 搜索并安装。VS Code 还需要 .NET SDK，Mac 需要 Mono 和 C# 扩展；Rider 功能完整但通常收费，学生可申请许可证。
10. 作者最后再次要求安装编辑器、IDE 和创建项目时关闭第三方杀毒软件与电脑管家，并强调安装路径避开中文、保证系统盘空间充足。

Godot 项目采用的结论：锁定 Godot 4.7 stable；任务开始前先验证 GDScript 语言服务器、静态类型提示和代码补全；项目路径保持 ASCII；版本控制由 Git 管理，不引入 Unity Plastic SCM；Unity Hub、URP、C# Editor Integration 和个人许可证步骤不迁移到 Godot。

### 第 2 集：素材导入和整理

正文操作顺序：

1. 作者先区分 Hierarchy（当前场景对象）、Project（项目文件）、Inspector（所选对象设置）、Scene（编辑视图）和 Game（实际运行画面），并演示拖拽窗口、单/双栏 Project 视图、恢复 Default Layout 与保存自定义 Layout。
2. Scene 左侧工具用于移动对象和调整 Transform；Gizmos 可以在右上角开关并调小图标。Scene 的鼠标滚轮缩放只影响编辑观察，不改变 Game 中的实际尺寸。
3. 教程选用两套当时免费的 itch.io 素材：Legacy Fantasy High Forest 负责主要环境，Generic Character 负责玩家。环境包自身也带角色动画，但 Generic Character 提供多种颜色、更丰富动作和三段攻击，因此被选为玩家素材。
4. 中文课堂整理包删减了重复/不用内容、修改了部分动画并添加 UI 按钮，但这些都不是项目必需项；从原作者页面下载的原始包同样可以完成教程。结合当前作者评论，整理包或原素材现在可能收费，必须单独核验许可证。
5. 在 Preferences 的 Scene View 中启用 `Create Objects at Origin`，使新对象默认创建在 `(0,0,0)`。作者还建议设置明显的 Play Mode Tint，因为运行模式中对 Transform 等属性的修改在停止后不会保存。
6. 本教程环境网格为 `16×16`：纹理 `Pixels Per Unit=16`、`Filter Mode=Point`、`Compression=None`，然后点击 Apply。Point 保持像素硬边，None 避免压缩破坏像素颜色。
7. 人物图集设置为 `Sprite Mode=Multiple`，同样使用 PPU 16、Point 和无压缩。不能用 Automatic Slice：自动边界会让每帧脚底高度不同，破坏动画对齐。
8. Generic Character 图集按 `Grid by Cell Count` 切片：横向 8 列、纵向 11 行，即 `8×11`；Pivot 选择 `Bottom`，让所有帧以脚底中心作为定位基线。
9. 切片后先在 Sprite Editor 右上角 Apply，再回到 Inspector Apply。场景和资源名后出现未保存标记时，用 Windows `Ctrl+S` / macOS `Command+S` 保存。
10. 展开切好的图集后，可把单帧拖到 Hierarchy 生成角色对象；后续视频再基于这些帧绘制场景、制作动画和角色逻辑。

Godot 项目采用的结论：原始 sheet/atlas 保留在 `art/imported/`；环境按 16 px TileSet 网格配置并使用 Nearest 过滤；Generic Character 按稳定帧区域建立 SpriteFrames/AtlasTexture，统一脚底锚点；不规则 atlas 不能套用 Automatic Slice；中文课堂整理包和 UI 按钮在许可证确认前不导入项目。

### 第 3 集：场景绘制和叠层设置 Tilemap

正文操作顺序：

1. 选择 `Forest-1` 和 `Forest-2`，设置 `Sprite Mode=Multiple`、`Pixels Per Unit=16`、`Filter Mode=Point`、`Compression=None`。地图素材按 `Grid by Cell Size=16×16` 切片。
2. Tile 与角色的 Pivot 规则不同：角色帧使用 `Bottom`，Tile 必须重新切为 `Center`，否则笔刷鼠标位置会落在 Tile 底边，绘制结果偏离网格。
3. 通过 `Window > 2D > Tile Palette` 打开面板，创建名为 `Forest1` 的 Palette。教程在项目内建立 Tilemap/Palettes/Tiles 分类目录，再把切好的 Forest-1 拖入 Palette 生成独立 Tile 资源。
4. 在 Hierarchy 创建 `2D Object > Tilemap > Rectangular`，得到 Grid 与默认 Tilemap。保存场景后，Tile Palette 才会把该 Tilemap 显示为可绘制目标。
5. Game 窗口顶部的 Scale 滑条只改变预览缩放，不是游戏真实比例；应选择固定的 16:9/1080p 等参考分辨率，再通过 Main Camera 调整实际取景。教程把 Orthographic Camera Size 设置为 `6`。
6. SpriteRenderer/TilemapRenderer 使用 Sorting Layer 和 Order in Layer 控制遮挡。作者建立 `Back`、`Middle`、`Front` 三层，把玩家放在 Middle；Unity Sorting Layer 列表中越靠下越显示在前，层内 `Order in Layer` 数值越大越靠前。
7. Tile Palette 提供笔刷、矩形、填充和橡皮；矩形工具绘制时按住 `Shift` 可快速擦除。Preferences 的 Tile Palette 配置还能加入 X/Y 镜像和左右旋转按钮，添加后要滚到底部保存。
8. 教程把中间可站立地形命名为 `Platform`，复制并创建 `Back1–3`、`Front1–3`。Back/Front 分别进入对应 Sorting Layer，数字通过 Order in Layer 排序；Back3 最接近平台，Back1 最远。
9. Tile Palette 下拉框选择当前绘制目标；Scene 右下角 `Focus On > Tilemap` 只突出当前 Tilemap，防止画错层，完成检查后切回 None 查看整体叠层。
10. 作者要求参考原素材展示图来拆分平台、近景草丛、树、远景树、浅色背景和天空，再按层绘制；最后可修改 Camera Environment 的 Solid Color，并给角色对象改名为 Player。

Godot 项目采用的结论：`Forest-1.png`/`Forest-2.png` 仍以 16 px 中心网格进入 TileSet；教程的七张 Tilemap 不直接照搬，当前项目按职责使用 Background/Geometry/Water/Foreground TileMapLayer，只有 Geometry 承担碰撞；Unity Camera Size `6` 不迁移，画面以 `640×360` 逻辑视口验收；图层选择和可见性用于避免把装饰画进 Geometry。

### 第 4 集：规则瓦片和动态瓦片

正文操作顺序：

1. Forest-1 左上角的 `4×4` 地块用于构造可无限延展的平台。教程创建 `Tiles/RuleTile/Ground1`，并在 Sprite Editor 中给参与规则的 Tile 重命名，方便在 Rule Tile Inspector 中搜索。
2. 每条 Rule 通过九宫格指定相邻格必须有 Tile、必须为空或忽略；例如平台左边缘要求左/上为空、右/下有 Tile。规则越严谨，特殊边角越不容易被通用规则抢占。
3. 平台顶面中间三张设为 `Output=Random`，随机数量为 3；左右侧面各在两张中随机，底边中间在三张中随机。地块内部在无石头、两块石头、三块石头和深色石头四张之间随机。
4. Rule 的排列顺序就是优先级。内部填充和内外角规则需要拖到更高位置，才能优先于“上下左右都有 Tile”的通用中心规则。Noise 控制随机图案变化，可按视觉需要调整。
5. 把 Ground1 拖入 Tile Palette 后，用矩形笔刷即可自动生成边缘、中心和随机细节。若平台台阶的内外角缺图，需要为左/右上角、左/右内角分别补充规则，并提高它们的优先级。
6. 无草石头地面可复制 Ground1 为 `Ground2`，替换对应图片与四个内角；作者把它作为课后练习。草丛同样可以建立 Rule Tile，用于前后景装饰。
7. 瀑布原图是 `3×4` 帧区域，按左、中、右创建三个 Animated Tile；每个 Tile 使用纵向 4 帧，因此总共整理并命名 12 张 Sprite。
8. Waterfall Left 完成后复制为 Middle 和 Right，再替换帧。教程演示把动画速度设为 `7`，并建议 Minimum/Maximum Speed 使用相同数值，避免相邻瀑布列因随机速度而不同步。
9. 三个瀑布 Tile 放进 Palette 后，用矩形工具并排绘制到背景 Tilemap，运行验证水流向下循环。装饰性 Rule Tile 与 Animated Tile 仍需按前一集的 Sorting Layer/Order 绘制到正确层。

Godot 项目采用的结论：Ground1/Ground2 邻接规则映射为 TileSet Terrain Set/Terrain Connect；内外角和中心变体必须检查 Terrain peering bit 与替代图权重；瀑布/水体使用 TileSetAtlasSource 动画，三个相邻列保持同一速度和相位策略。教程的 Unity Speed `7` 只作为视觉参考，当前项目继续使用已验证的水体帧率，实际效果按 640×360 运行画面校准。

### 第 5 集：人物及基本组件

正文操作顺序：

1. Player 先添加 `Rigidbody2D`，默认 `Gravity Scale=1`。教程展示项目 Physics 2D 重力 Y 为 `-9.81`，Simulation Mode 使用 Fixed Update，固定步长为 `0.02s`；Gravity Scale 会乘以项目重力。
2. Player 添加 `Capsule Collider 2D`，通过 Edit Collider 调整。演示把纵向偏移整理为约 `0.9`、胶囊高度设为 `1.9`，并让碰撞体底端与角色脚底基线对齐；横向宽度和偏移按具体 Sprite 调整。
3. Hierarchy 选中对象后按 `F` 可让 Scene 聚焦该对象，便于编辑大型地图中的角色或 Tilemap。
4. 可站立平台添加 `Tilemap Collider 2D`。默认每格生成独立碰撞且边缘会依据像素轮廓形成不规则形状；勾选 `Used by Composite`，再添加 `Composite Collider 2D`，把连续 Tile 合并为整体碰撞。
5. Composite Collider 会自动给 Tilemap 添加 Rigidbody2D；必须把 Body Type 从 Dynamic 改为 `Static`，否则整张地图会受重力掉落。
6. Player 的 Rigidbody2D Constraints 冻结 Z Rotation，避免移动、撞墙或碰到 NPC 时角色侧翻。演示修改后把 Transform Z Rotation 恢复为 `0`。
7. 只有真正承担地面/墙体物理的 Tilemap 添加 Tilemap/Composite Collider；背景草、远景和纯装饰层不添加碰撞。
8. Rigidbody2D 的 Mass 决定物体质量关系；角色动作较多时，作者把 Collision Detection 从离散检测改为 `Continuous`，以减少快速移动、滑铲或墙面动作时穿透。
9. 组件右上角问号可打开与当前 Unity 版本匹配的离线/在线手册；作者建议按 `2022.2` 版本阅读，并可切中文或使用浏览器翻译辅助理解参数。

Godot 项目采用的结论：玩家继续使用 `CharacterBody2D`，不照搬 Unity 动态 Rigidbody2D；身体 `CollisionShape2D` 仍以脚底为根节点基线，底部误差不超过 1 个逻辑像素；只有 Geometry TileMapLayer 具有 World 碰撞，Background/Water/Foreground 不添加；连续地形使用 TileSet 中整理过的平整碰撞形状，避免像素轮廓造成墙面卡顿；快速攻击和交互通过独立 Area2D/ShapeCast/RayCast 检测。

### 中文课堂第 7 课：创建及配置新输入系统

- 课程位置：章节 2 / 第 2 课；`chapterId=6409490c700410001fd872dd`，`sectionId=640949fc4b7731001f66a592`。
- 播放器实际时长：约 `27:26`（`1646.17s`）。
- 本轮证据：中文课堂课时页按视频内容给出的分段说明与时间点、播放器实际媒体信息；精确画面仍按下列时间点继续核验。

课时内容时间线：

1. `00:05` 开始建立人物控制代码。先在项目中创建专门存放代码的目录，再建立玩家代码子目录，创建并命名 C# 控制脚本。
2. `01:08` 把控制脚本挂到 Player，使该脚本成为人物移动、跳跃等行为的入口。文件名、类名和变量名使用一致的驼峰命名，便于编译器定位拼写与引用问题。
3. `03:47` 讲解 Unity 默认代码模板、命名空间和类名关系，并建议不熟悉 C# 的学习者先看 Unity 官方 C# 基础视频。这里的目的不是背模板，而是理解脚本类型、组件生命周期和类名/文件名契约。
4. `06:54` 转入 Unity New Input System。课程目标是用输入动作描述玩家意图，避免人物逻辑直接依赖某个键盘按键。
5. `09:17` 展示两种创建 Input Actions 配置文件的方法；无论从 Project 创建资源还是借助组件生成，最终都应得到一个统一的输入动作配置资源。
6. `12:58` 说明输入方案可以声明 Gamepad 等设备类型，使同一组动作适配键盘或不同手柄，而不需要在移动代码中分别判断设备。
7. `13:43` 添加并命名输入设备/动作配置；命名需要表达玩家意图，后续代码通过动作名访问，不把具体键名写入角色脚本。
8. `14:03` 配置 Gamepad 控制方案；课时页将其描述为加入最高层级的手柄设备。画面核验时重点确认 Control Scheme、Binding 和设备要求之间的关系。
9. `15:34` 使用 `Player Input` 组件生成或关联默认 Input Action 配置表。B 站作者答疑同时要求：顶层移动 Action 使用 `Vector2`，创建 Action Asset 后还要执行黄色提示中的 `Assign as...`，把它设为项目当前输入配置。
10. `20:34` 解释 `Awake` 比 `Start` 更早执行，输入包装对象和脚本引用应在首次读取输入前完成初始化。
11. `21:01` 创建 Input Control 实例，并在组件启用/禁用阶段同步调用输入系统的启用与关闭方法，避免对象失活后仍继续响应输入。
12. `22:35` 从 Input Action 读取 `Vector2`，用变量保存输入信息；横向分量供移动与翻转，纵向分量可供下蹲、攀爬或组合输入使用。

素材与设置影响：本课不新增图片素材；新增的是输入动作资源、Player 上的输入组件和控制脚本。输入配置是项目级数据，动作名会被多个系统消费，不能在后续课程中随意改名。

Godot 项目采用的结论：使用 `project.godot` 的 Input Map action 表达移动、跳跃、下蹲、攻击和技能；`scripts/player/player_controller.gd` 只读取 action，不判断具体按键。二维移动输入通过动作组合形成 `Vector2` 或按职责拆成轴值；输入启停随玩家可控状态和暂停状态管理，不照搬 Unity 的 PlayerInput/Input Control 生命周期类。新增动作前必须检查现有 Input Map 名称和自动化输入接口，避免破坏测试。

### 中文课堂第 8 课：实现移动和翻转

- 课程位置：章节 2 / 第 3 课；`chapterId=6409490c700410001fd872dd`，`sectionId=64094b6b358e970020afe7b0`。
- 播放器实际时长：约 `17:46`（`1065.73s`）。
- 页面补充：课程专门链接 Unity 手册解释“使用速度驱动刚体时，为什么不在 `FixedUpdate` 中再乘 `Time.fixedDeltaTime`”。

课时内容时间线：

1. `00:16` 强调 Player 挂载 Rigidbody2D 后，应由物理刚体驱动坐标，而不是一边直接改 Transform、一边又让物理系统求解。
2. `01:13` 使用速度驱动物体，创建 `speed` 变量并输入数值。速度是单位时间内的位移，不应把它和一次性的位移量混为一谈。
3. `02:45` 在 `FixedUpdate` 调用 `Move`，获取刚体组件并修改其速度。课时页明确提示：直接设置 Rigidbody 速度时不再额外乘 `Time.fixedDeltaTime`，依据应以对应 Unity 版本的 Rigidbody2D 手册为准。
4. `04:26` 变量当前只在 `PlayerController` 内部访问；变量的可见范围和组件引用关系要明确，避免后续脚本随意跨组件读取内部状态。
5. `05:11` 获取自身 Rigidbody2D 的当前速度，在保留纵向速度的同时修改横向速度。移动代码不能每帧把重力、跳跃或击退产生的 Y 速度清零。
6. `08:08` 说明 Play 模式中临时修改 Inspector 数值不会持久保存。需要正式调参时先退出运行模式，再写回场景、Prefab 或数据资源。
7. `08:52` 用手柄测试横向移动和下降速度，确认输入读取、速度赋值与物理重力同时生效。
8. `09:43` 展示两种人物反转方式：修改 Transform 的 `localScale.x`，或设置 SpriteRenderer 的 `flipX`。
9. `13:12` 使用临时变量记录手柄输入方向，据此决定是否反转；输入为 `0` 时应保持当前朝向，而不是在无输入时重置方向。
10. `13:18` 引入 `faceDirection`，默认取 Transform `localScale.x`，把“当前面向”从临时按键状态中分离出来。
11. `13:58` 演示把 `float` 强制转换为 `int`，小数部分会被截断。朝向值应最终归一为 `-1` 或 `1`，不能让摇杆细微浮点值直接成为缩放倍率。
12. `15:38` 说明用 `localScale` 翻转时需要检查图片锚点与原始缩放值；若角色初始缩放不是 `1`，直接写死正负一会破坏既有比例。

讨论区交叉证据：用户指出本项目类型的角色不能简单使用 SpriteRenderer `flipX`，因为它只翻转图片；若武器、特效、挂点和其他需要跟随朝向的子节点都在角色层级内，应使用 Transform `localScale` 翻转整个层级。这条讨论目前不是讲师回复，但其技术影响明确，实施时要用实际节点树验证。碰撞体是否应该随视觉一起镜像则需单独决定，不能因为处在同一层级就默认翻转。

素材与设置影响：本课不新增图片素材；主要修改 PlayerController 的移动变量、Rigidbody2D 引用和朝向逻辑。玩家 Sprite 的 Pivot/脚底基线会直接影响翻转后是否左右跳动，武器挂点、攻击 Area 和检测射线也必须使用同一朝向真相。

Godot 项目采用的结论：玩家继续通过 `CharacterBody2D.velocity` 与 `move_and_slide()` 运动；控制代码只修改职责内的速度分量，保留重力、跳跃、击退等系统产生的其他分量。Godot 物理移动使用引擎既有 delta 语义，不照搬 Unity `FixedUpdate` 写法。朝向保存为稳定的 `-1/1` 状态；优先翻转专门的 `VisualRoot`，并让武器挂点、攻击方向和检测方向读取同一朝向值，避免镜像 CharacterBody2D 根节点后碰撞形状或物理位置产生副作用。运行时调参不视为正式配置，最终数值写入现有脚本常量、Resource 或数据结构并通过试玩校准。

### 中文课堂第 9 课：实现人物跳跃

- 课程位置：章节 2 / 第 4 课；`chapterId=6409490c700410001fd872dd`，`sectionId=64094e246391b60020806788`。
- 播放器实际时长：约 `14:14`（`854.20s`）。
- 本课重点：在 Input Actions 中增加跳跃动作，通过按下瞬间触发跳跃函数，并用 Rigidbody2D 瞬时力产生纵向速度。

课时内容时间线：

1. `00:01` 开始实现人物跳跃，先明确跳跃需要“输入动作、触发时机、纵向物理变化、可跳条件”四个部分。
2. `01:04` 编辑输入配置，添加 Jump 按键/Action，并在 PlayerController 中增加跳跃处理方法。具体键位属于 Input Action 的 Binding，不写死在人物脚本里。
3. `02:21` 通过给 Rigidbody2D 的纵轴施加力产生跳跃；横向移动与纵向跳跃分别修改各自负责的速度/受力分量。
4. `04:00` 打开 Unity Scripting API，搜索 Rigidbody2D 方法。作者用官方手册确认可调用函数、参数和适用版本，而不是只凭代码补全猜用法。
5. `04:44` 查看 Rigidbody2D 的公开变量与样例代码，分辨速度、力、质量、重力倍率等属性的职责。
6. `06:26` 按手册方式编写跳跃代码，并检查按键状态与执行时机。跳跃只应在按钮按下瞬间触发，不能在按住期间每个物理帧持续叠加力。
7. `08:00` 把跳跃函数注册到 Input Action 的 `started` 事件。课时页文字容易被误读为 MonoBehaviour `Start()`；讨论区明确说明这里是“按键按下瞬间”的 `started` 回调。
8. `08:39` 使用 IDE 快速修复生成跳跃函数的签名，再补入实际跳跃逻辑。自动生成只解决方法契约，不等于逻辑已经正确。
9. `11:20` 使用 Force Mode 的瞬时力/Impulse 实现跳跃，使一次输入立即改变纵向运动，而不是持续施力。
10. `12:02` 把 Unity Rigidbody2D 的 `Gravity Scale` 调到 `4`，以更快回落并测试更舒适的手感。该数值是 Unity 示例参数，不直接迁移到 Godot。
11. `12:49` 限制跳跃，禁止角色在空中重复跳跃；本课先建立最基本的“仅落地可跳”约束。
12. `13:32` 再次要求养成查看代码手册的习惯，把 API 的真实语义与要实现的功能对应起来。

讨论区交叉证据：本课讨论明确指出，跳跃方法通过委托注册到 InputControl 对应 Action 的 `started` 事件；`started` 表示按钮从未按下变为按下的瞬间。这一解释与“避免按住时连续施力”的目标一致。

素材与设置影响：本课不新增图片素材；输入资产新增 Jump Action/Binding，PlayerController 新增跳跃入口，Rigidbody2D 调整 Gravity Scale，并需要一个可靠的落地判断。跳跃参数会影响后续跳跃动画、墙跳、滑墙、平台间距和相机节奏，不能只在孤立测试场景中调节。

Godot 项目采用的结论：通过 Input Map 的跳跃 action 与 `Input.is_action_just_pressed()` 表达按下瞬间；`CharacterBody2D` 通常直接设置 `velocity.y = -jump_velocity`，不照搬 Unity Rigidbody2D 的 AddForce/Impulse。普通跳跃仅在 `is_on_floor()` 或项目既有宽限时间/输入缓冲规则允许时执行；空中跳、二段跳必须由明确能力状态授权。Unity `Gravity Scale=4` 只说明作者希望角色快速回落，Godot 中应联合校准重力、起跳速度、上升/下降倍率、土狼时间和输入缓冲，并以关卡平台间距与 640×360 实际试玩为准。

### 中文课堂第 10 课：物理环境监测及绘制

- 课程位置：章节 2 / 第 5 课；`chapterId=6409490c700410001fd872dd`，`sectionId=64094f14ac6aa8002064bb9f`。
- 播放器实际时长：约 `17:29`（`1049.30s`）。
- 本课重点：用独立物理检测组件判断人物是否接地，通过脚底偏移和检测半径校准范围，以 Gizmos 显示检测形状，并给人物碰撞体分配 Physics Material 2D。

视频确认的 Unity 实现：

```csharp
public class PhysicsCheck : MonoBehaviour
{
    public Vector2 bottomOffset;
    public float checkRadius;
    public LayerMask groundLayer;
    public bool isGround;

    private void Update()
    {
        Check();
    }

    public void Check()
    {
        // 检测地面
        isGround = Physics2D.OverlapCircle(
            (Vector2)transform.position + bottomOffset,
            checkRadius,
            groundLayer
        );
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.DrawWireSphere(
            (Vector2)transform.position + bottomOffset,
            checkRadius
        );
    }
}
```

课时内容和设置：

1. 在 `Assets/Scripts/Player/PhysicsCheck.cs` 创建独立检测脚本，使环境检测不继续堆叠在移动输入脚本中。
2. 查阅 Unity `Physics2D` 脚本 API，并具体确认 `Physics2D.OverlapCircle(point, radius, layerMask)` 的位置、半径、图层遮罩和 `Collider2D` 返回语义。
3. `Update()` 每帧调用 `Check()`；先用 `transform.position` 验证检测，再加 `bottomOffset` 将圆形范围移动到人物脚底。
4. `isGround` 在空中为 `false`、落到地面后为 `true`。检测只接受 `groundLayer`，地面平台明确放入单独的 `Ground` Layer，避免人物、攻击区或其他碰撞体被误认成地面。
5. 使用 `OnDrawGizmosSelected()` 和 `Gizmos.DrawWireSphere()` 在 Scene 视图绘制检测圆，让偏移、半径和碰撞轮廓可以直接观察，而不是仅盯着布尔值调试。
6. 早期调试画面显示 `Check Radius=0.2`、`Ground Layer=Ground`；后期收紧为 `Bottom Offset=(-0.05, 0)`、`Check Radius=0.08`、`Ground Layer=Ground`。这些只是本 Unity 示例素材尺寸下的调试值。
7. 同一画面中的 Player 示例仍显示 `Speed=290`、`Jump Force=16.5`；Capsule Collider 2D 显示 `Offset=(-0.05, 0.95)`、`Size=(0.7, 1.9)`。数值用于还原课程上下文，不能直接作为 Godot 最终手感参数。
8. 地面由 Tilemap、Tilemap Renderer、Tilemap Collider 2D、Rigidbody 2D 和 Composite Collider 2D 组成，平台 Composite Collider 2D 画面中的 Material 为 `None`。
9. 在 `Assets/Settings/Physics Material` 下通过 `2D -> Physics Material 2D` 创建名为 `Normal` 的材质，并将它分配给 Player 的 Capsule Collider 2D。创建后的 Inspector 画面显示 `Friction=0.4`、`Bounciness=0`。
10. 视频没有提供足够清晰的证据表明讲师随后把 `Friction` 从 `0.4` 改为 `0`，因此这里只记录“创建并分配 Normal 材质”，不把零摩擦写成课程事实。材质是否足以缓解贴墙或地形凸起阻滞，需要结合实际运动方式验证。

讨论区交叉证据：有用户反馈墙面存在小凸起时，人物仍会踩在凸起位置。这说明可靠的接地不仅取决于检测代码，还取决于人物碰撞体形状、地形碰撞轮廓、脚底探测范围，以及贴墙时是否把墙角误判为地面。

素材与设置影响：本课不新增图片素材；新增 `PhysicsCheck.cs` 和 `Normal` Physics Material 2D，给场景地形设置 `Ground` Layer，并把材质赋给 Player 的 Capsule Collider 2D。Tilemap 地形继续依靠 Composite Collider 2D 合并轮廓，检测圆必须按角色脚底基线和实际碰撞体调节。

Godot 项目采用的结论：稳定地形碰撞继续由 Geometry `TileMapLayer` 承担，玩家根节点保持 `CharacterBody2D`。`CharacterBody2D.is_on_floor()` 作为移动求解后的主要接地真相；项目已有 `scripts/general/physics_check.gd`，额外的 `RayCast2D`、`ShapeCast2D` 或 `PhysicsDirectSpaceState2D.intersect_shape()` 只用于预判、边缘容错、墙面和特殊状态。脚底探测位置使用明确 Marker/偏移节点，不依赖角色贴图原点；检测尺寸以静态类型导出参数保存，并在 640×360 逻辑视口和整数缩放下调试。Unity Gizmos 对应 Godot 的可见碰撞形状、`_draw()`/`queue_redraw()` 或 Cast 节点调试显示。Godot `PhysicsMaterial` 的摩擦与反弹不能照搬 Unity `0.4/0`，必须连同 `move_and_slide()`、碰撞体和 TileMap 碰撞轮廓一起试玩；出现墙角“踩住”时应同时检查探测圆过大、角色碰撞形状、地形轮廓凸点和墙角误判。

### 中文课堂第 11 课：创建人物基本动画

- 课程位置：章节 2 / 第 6 课；`chapterId=6409490c700410001fd872dd`，`sectionId=64095053700410001fd872eb`。
- 播放器实际时长：约 `23:23`（`1403.30s`）。
- 页面列出的目标：创建 Animator 动画控制器、创建 Clip 帧动画、创建 `PlayerAnimation` 代码、用代码控制状态转换条件。
- 本课讨论区显示“暂无讨论，期待您的参与”，没有可用的讲师答疑或用户补充。

课时内容时间线：

1. `00:00–01:30` 先查看人物原始 Sprite Sheet 上的动作分组。图集旁的英文标注区分 Idle、Running、Jump、Falling、Taking damage、Death、Spell、Crouch、Shield、Walking、Sliding、Wall sliding、Critical attack 和 Ladder climbing 等动作，说明同一张人物图集按动作行提供连续帧。
2. `01:30–02:30` 打开 Unity Animator Component 文档，区分 Animator 组件、Animator Controller、Animation Clip、状态和参数的职责；Animator Controller 是状态关系，Clip 才保存逐帧内容。
3. `02:30–04:20` 在 `Assets/Animations/Player` 下建立人物动画目录和 Player Animator Controller，并把 Controller 分配给人物的 Animator 组件。Animator 图中初始包含 Any State、Entry 和 Exit。
4. `04:20–06:40` 从人物图集按正确顺序选中 Idle 的连续精灵帧，拖入 Animation 窗口生成 Idle Clip。画面可数出 6 个 Idle 关键帧；生成 Clip 后，Animator 中自动出现 Idle 状态，Entry 指向橙色默认状态。
5. `06:00` 左右在 Animation 窗口调整 `Samples`；视频画面显示为 `12`。这决定每秒采样数，不应把它误解为素材帧总数。作者在 Scene 画面中预览循环速度，确认脚底基线没有随帧跳动。
6. `07:00–09:50` 用相同方式从图集中选择 Running 对应的连续帧，创建 Run Clip/状态并预览。动画素材直接引用已切分的原图集精灵，没有另外导出一套重复 PNG。
7. `09:50–13:20` 在 Animator 中创建 Idle 与 Run 的双向 Transition，并新增浮点参数 `velocityX`。画面中的条件组合以约 `0.1` 为阈值：横向速度绝对值大于阈值进入 Run，小于阈值返回 Idle；转换预览用于检查两个 Clip 的混合区间和响应时机。
8. `13:20–15:30` 在 `Assets/Scripts/Player` 下创建 `PlayerAnimation.cs`，让动画参数更新从 `PlayerController` 的输入和移动职责中分离出来。脚本先缓存 `Animator`，随后还缓存 `Rigidbody2D`。
9. `15:30–18:50` `Awake()` 使用 `GetComponent<Animator>()` 和 `GetComponent<Rigidbody2D>()` 获取同物体组件；`Update()` 每帧调用 `SetAnimation()`，由该函数统一向 Animator 写参数。
10. `18:50–20:10` 使用 `anim.SetFloat("velocityX", Mathf.Abs(rb.velocity.x))`。取绝对值后，无论人物向左还是向右移动，状态机都收到非负速度强度；面向翻转仍由既有朝向逻辑负责。
11. `20:10–21:40` 进入 Play 模式测试：静止时为 Idle，发生水平移动时切到 Run，停止后回到 Idle；同时观察 Animator 状态高亮和参数实时值，确认代码、状态条件与画面一致。
12. `20:40–23:23` 课程结尾还把 Walk Clip/状态放入同一控制器，并能在画面中看到 Idle、Run、Walk 三个状态。Walk 的输入规则和完整转换条件由下一课“人物行走设定”继续讲，本课不能据此声称行走系统已完成。

视频确认的 Unity 脚本核心：

```csharp
public class PlayerAnimation : MonoBehaviour
{
    private Animator anim;
    private Rigidbody2D rb;

    private void Awake()
    {
        anim = GetComponent<Animator>();
        rb = GetComponent<Rigidbody2D>();
    }

    private void Update()
    {
        SetAnimation();
    }

    public void SetAnimation()
    {
        anim.SetFloat("velocityX", Mathf.Abs(rb.velocity.x));
    }
}
```

素材与设置影响：人物动画继续使用课程人物原始 Sprite Sheet 中已经切分好的 Sprite，按动作行和帧序连续选择后拖入 Animation 窗口；本课没有引入新的外部图片。新增内容集中在 `Assets/Animations/Player` 下的 Player Animator Controller 与 Idle/Run/Walk Clips，以及 `Assets/Scripts/Player/PlayerAnimation.cs`。Idle 画面明确显示 6 个关键帧和 `Samples=12`；其他动作应按各自行的实际帧数制作，不能为了统一数量而补空帧。所有动画帧必须保持相同 Pivot、脚底基线和朝向，否则状态切换时人物会发生位置跳动。

Godot 项目采用的结论：原图集仍以 `art/imported/` 为真相来源，通过 `AtlasTexture.region`、SpriteFrames 或 AnimationPlayer 轨道引用区域，不生成逐帧重复 PNG。简单纯帧动画可以由 `AnimatedSprite2D` 承载；需要与攻击窗口、受击、状态机和复杂过渡统一时，使用 `AnimationPlayer` 配合 `AnimationTree` 或项目现有显式动画状态映射。人物脚本可以读取 `abs(velocity.x)` 作为移动强度，但 Idle/Run/Walk 的最终真相应同时考虑玩家业务状态、输入 action、是否接地、攻击/受击锁定和移动模式，不能让动画状态反向决定物理规则。Unity 的 `Samples=12` 是当前素材的可用起点，不是 Godot 全局帧率规范；需要在 640×360 逻辑视口、整数缩放和实际移动速度下检查步频、脚底滑动和切换响应。状态名或稳定动画 ID可以成为表现层契约，具体图片路径和 Clip 文件路径不能成为跨系统业务契约。Walk 状态只作为下一课的准备，本课不把它计为已完成玩法。

### 中文课堂第 12 课：人物行走设定

- 课程位置：章节 2 / 第 7 课；`chapterId=6409490c700410001fd872dd`，`sectionId=640951429bebe4001f474ea4`。
- 播放器实际时长：约 `07:08`（`428.07s`）。
- 页面列出的目标：理解回调方法的按键响应，并通过调整速度实现强制行走。
- 本课讨论区显示“暂无讨论，期待您的参与”，没有可用的讲师答疑或用户补充。

视频确认的 Unity 实现：

```csharp
private float runSpeed;
private float walkSpeed => speed / 2f;

private void Awake()
{
    rb = GetComponent<Rigidbody2D>();
    physicsCheck = GetComponent<PhysicsCheck>();

    inputControl = new PlayerInputControl();
    inputControl.Gameplay.Jump.started += Jump;

    // 必须在回调改变 speed 前保存正常跑速。
    runSpeed = speed;

    inputControl.Gameplay.WalkButton.performed += ctx =>
    {
        if (physicsCheck.isGround)
            speed = walkSpeed;
    };

    inputControl.Gameplay.WalkButton.canceled += ctx =>
    {
        if (physicsCheck.isGround)
            speed = runSpeed;
    };
}
```

课时内容和边界：

1. 在已有 Input Actions 中增加 `WalkButton`，通过该 Action 的 `performed` 与 `canceled` 生命周期分别处理按下和松开；课程不是在移动循环里直接查询具体键位。
2. `walkSpeed` 定义为当前 `speed / 2f`，按住 WalkButton 时把移动速度切为一半，松开后恢复正常跑速，因此这是“默认跑、按键强制走”的模式。
3. 两个回调都先检查 `physicsCheck.isGround`，课程只允许接地时切换走/跑速度，避免空中按键直接改变当前速度模式。
4. 初版把 `runSpeed` 写成 `private float runSpeed => speed;`。由于这是每次读取都重新返回当前 `speed` 的表达式属性，按下行走键后 `speed` 已变成慢速，松开时读取到的 `runSpeed` 也会是慢速，无法恢复。
5. 视频后段把 `runSpeed` 改为普通字段，并在注册回调前执行 `runSpeed = speed;`，先缓存 Inspector 配置的正常跑速，再允许回调修改 `speed`。这是本课最重要的代码修正，不能省略成单纯的“速度除以二”。
6. 课程沿用上一课的速度驱动动画方案：降低刚体横向速度后，Animator 根据已有速度条件显示 Walk；恢复跑速后回到 Run。行走输入负责业务速度模式，动画只读取结果。
7. 末尾进入 Play 模式实际测试了按住时慢走、松开后恢复跑动。视频没有给出足够清晰的键位文字证据，因此本文只记录稳定的 `WalkButton` Action，不猜测具体物理按键。

素材与设置影响：本课不新增图片或 Clip；继续使用上一课已建立的 Walk/Run 动画。输入资产新增或完善 `WalkButton` Action，`PlayerController.cs` 增加 `runSpeed` 缓存、`walkSpeed` 计算和按下/松开回调。行走速度会改变动画步频与单位时间位移，需要与关卡窄平台、转身加速度和战斗站位一起试玩，不能只看角色是否播放 Walk Clip。

Godot 项目采用的结论：项目已经在 `project.godot` 定义 `walk` Input Map action，并在 `scripts/player/player_controller.gd` 中保持独立的静态类型导出参数 `walk_speed` 与 `run_speed`。每个物理帧通过 `Input.is_action_pressed(&"walk")` 计算 `is_walking`，再选择目标速度；这样不需要临时覆盖同一个 `speed`，也不会出现 Unity 示例中表达式属性随可变速度一起变化的恢复错误。当前实现还通过 `move_toward()` 应用地面/空中加速度，并让动画根据接地状态、移动输入和 `is_walking` 选择 Walk/Run，符合“规则状态决定表现”的项目约束。课程只在接地时响应模式切换，而当前 Godot 实现允许空中持有 `walk` 影响空中水平目标速度；这是明确的手感差异，不应因整理课程而静默改动。若后续要对齐课程，需先决定玩家幻想是“精确慢走模式”还是“空中精细修正”，再通过单元测试和 640×360 实际试玩验证，而不是直接照搬接地判断。

### 中文课堂第 13 课：创建人物跳跃动画

- 课程位置：章节 2 / 第 8 课；`chapterId=6409490c700410001fd872dd`，`sectionId=6409514ccdfc640020f7f37b`。
- 播放器实际时长：约 `14:26`（`865.57s`）。
- 页面列出的目标：创建多个跳跃动画和落地动画、使用 Animator Blend Tree、加入 `isGround` 条件，以及配置落地动作的打断方式。
- 本课讨论区显示“暂无讨论，期待您的参与”，没有可用的讲师答疑或用户补充。

视频确认的 Unity 动画驱动核心：

```csharp
public class PlayerAnimation : MonoBehaviour
{
    private Animator anim;
    private Rigidbody2D rb;
    private PhysicsCheck physicsCheck;

    private void Awake()
    {
        anim = GetComponent<Animator>();
        rb = GetComponent<Rigidbody2D>();
        physicsCheck = GetComponent<PhysicsCheck>();
    }

    private void Update()
    {
        SetAnimation();
    }

    public void SetAnimation()
    {
        anim.SetFloat("velocityX", Mathf.Abs(rb.velocity.x));
        anim.SetFloat("velocityY", rb.velocity.y);
        anim.SetBool("isGround", physicsCheck.isGround);
    }
}
```

课时内容和动画结构：

1. 从人物原始 Sprite Sheet 中按动作阶段建立多个空中动画与独立落地动画，而不是让一条循环 Jump Clip 同时承担起跳、上升、顶点、下落和着地。
2. 在 Animator 中创建 1D Blend Tree，并把 `velocityY` 作为混合参数。Blend Tree 画面中放入四个空中 Motion，按从正到负的纵向速度阈值排列，用同一个物理量连续选择不同的跳跃阶段。
3. `PlayerAnimation` 新增 `PhysicsCheck` 引用；`Awake()` 与 Animator、Rigidbody2D 一起缓存该组件，继续保持表现脚本只读取物理结果。
4. `SetAnimation()` 保留横向 `velocityX`，新增原值写入的 `velocityY`，并通过 `anim.SetBool("isGround", physicsCheck.isGround)` 把接地真相传给 Animator。纵向速度不能取绝对值，因为上升与下落必须保留方向。
5. Animator 主图把空中 Blend Tree、落地和既有 Idle/Walk/Run 连接起来：离地进入空中状态，接地后进入 Land，再返回地面移动状态。画面还在运行时观察状态高亮，确认起跳、下落和落地顺序。
6. 落地转场配置了可被后续移动状态打断的规则，目标是角色落地后若立刻产生移动，不必被完整 Land Clip 锁住。课程页面将这一点明确列为“打断落地方法”。
7. 视频没有给出足够清晰且稳定的证据支持逐项抄写所有 Motion 名称、阈值和 Transition Inspector 数值，因此本文记录可验证的参数职责与状态关系，不把模糊画面推断成精确配置表。

素材与设置影响：本课没有引入新的外部图片，继续从同一人物 Sprite Sheet 引用连续帧；新增内容是多段空中 Clips、Land Clip、以 `velocityY` 驱动的 1D Blend Tree、`isGround` Animator Bool，以及对应 Transition/Interruption 配置。各阶段帧仍需保持统一脚底基线和 Pivot；Land 片段是否允许被移动打断，会直接影响落地反馈与操作响应，需要结合音效、尘土特效和相机反馈整体检查。

Godot 项目采用的结论：`scripts/player/player_controller.gd` 已把人物帧分为 `jump=[24,25,26,27]`、`fall=[32,33,34,35,36,37]` 和 `land=[38,39]`，分别引用原图集的 Jump Up 与 Fall/Land 行。空中用 `velocity.y < 0.0` 选择 Jump/Fall；控制器保存前后物理帧接地状态，在落地边沿开启 `0.18s` 的一次性 Land 表现窗口。Land 不锁定业务状态，水平移动及攻击、滑铲等高优先级动作可立即打断，覆盖了课程强调的落地反馈和打断规则，同时不让动画播放完毕决定玩家能否行动。当前仍采用明确的三段状态映射而非 AnimationTree Blend Tree；若未来增加更多空中阶段，阈值必须根据 Godot 的 `jump_velocity=-600`、重力、可变跳高和实际帧素材试玩确定，不能照抄 Unity 数值。

### 中文课堂第 14 课：实现人物下蹲逻辑和动画

- 课程位置：章节 2 / 第 9 课；`chapterId=6409490c700410001fd872dd`，`sectionId=64095216358e970020afe7b7`。
- 播放器实际时长：约 `15:05`（`905.43s`）。
- 页面列出的目标：建立 `isCrouch` 条件、使用 Animator Sub-State Machine，并在运行时取得碰撞体后修改 `offset` 与 `size`。
- 讨论区明确补充了一个视频正文未处理的缺口：只设置下蹲状态不会自动停止已有水平移动；用户给出的修正思路是在 `isCrouch` 时把水平速度设为零。该内容属于讨论区补充，不是视频中的最终代码。

视频确认的 Unity 规则和碰撞体处理：

```csharp
public bool isCrouch;

private CapsuleCollider2D coll;
private Vector2 originalOffset;
private Vector2 originalSize;

private void Awake()
{
    coll = GetComponent<CapsuleCollider2D>();
    originalOffset = coll.offset;
    originalSize = coll.size;
}

public void Move()
{
    // 课程复用二维移动输入的纵向分量，不新增独立 Crouch Action。
    isCrouch = inputDirection.y < -0.5f && physicsCheck.isGround;

    if (isCrouch)
    {
        coll.offset = new Vector2(-0.05f, 0.85f);
        coll.size = new Vector2(0.7f, 1.7f);
    }
    else
    {
        coll.size = originalSize;
        coll.offset = originalOffset;
    }
}
```

课时内容和状态结构：

1. 从人物原始 Sprite Sheet 建立 `blueCrouchStart` 与 `blueCrouchIdle` 两个 Clip；Start 表现进入下蹲，Idle 保持蹲伏。课程没有制作独立的横向蹲走动画。
2. Animator 新增 Bool 参数 `isCrouch`，并把下蹲状态收进一个 Sub-State Machine。子状态机内部由 Entry 进入 `blueCrouchStart`，再进入 `blueCrouchIdle`；Idle 可经 Exit/上层状态返回既有基础移动层。
3. `PlayerController` 暴露 `isCrouch`，在移动逻辑中用 `inputDirection.y < -0.5f && physicsCheck.isGround` 更新。下蹲必须接地，跳跃或下落时纵向输入不会进入蹲伏。
4. `PlayerAnimation` 把控制器的 `isCrouch` 写入 Animator 参数；动画读取规则结果，不负责决定角色是否真的处于下蹲状态。
5. 视频先缓存 CapsuleCollider2D 的原始 `offset` 和 `size`，避免退出下蹲时依赖散落的硬编码恢复值。运行画面确认正常值为 `offset=(-0.05, 0.95)`、`size=(0.7, 1.9)`。
6. 下蹲时保持 X 参数不变，只把 Y offset 从 `0.95` 降到 `0.85`、高度从 `1.9` 缩到 `1.7`，使碰撞体顶部下降而脚底位置尽量保持稳定；退出时恢复缓存值。
7. 视频末尾进入 Play 模式确认下方向输入能切换动画和胶囊尺寸。课程没有检查头顶空间是否足够，也没有阻止角色带着水平速度继续移动，因此“低矮通道内松开下蹲”和“移动中下蹲”仍是未解决边界。

玩家体验与制作影响：下蹲的幻想是主动压低轮廓、通过低矮空间或为后续动作蓄势；玩家决策应是“保持移动能力换取灵活”还是“锁定站位换取明确姿态”，而不能由动画素材偶然决定。关卡需要先在安全区域引入，再用低顶通道确认碰撞尺寸，之后与敌人、平台边缘和滑铲组合施压；若站起空间不足，应保持下蹲并给出轻微顶棚反馈，而不是强制恢复后卡入地形。动画、脚步/衣物音效、尘土或姿态切换应反馈进入和退出，但常驻 HUD 不需要增加下蹲指示。

素材与设置影响：本课新增两个下蹲 Clip、一个 Animator Bool 和一个下蹲 Sub-State Machine；没有引入新的外部图片。碰撞体变化属于玩法状态，必须与动画分别维护，并保持脚底锚点不漂移。视频中的绝对尺寸只适用于其 Unity 世界单位和角色资源，不能直接复制到本项目的 16 px 网格与 640×360 逻辑视口。

Godot 项目采用的结论：项目现已复用 `move_down` 纵向 Input Map action 实现 `is_crouching`，没有新增绑定到具体键位的业务判断。下蹲仅能在接地时进入并锁定水平移动，播放原图集 `crouch` 72–74 帧；玩家 Capsule 高度由 40 缩到 28，碰撞体同步下移以保持脚底不动。松开输入时通过世界 Shape Query 检查完整站立体积，头顶空间不足会继续保持下蹲。实现还为每个玩家实例复制 Shape，避免运行时尺寸变化污染共享资源，并用确定性测试覆盖状态切换、脚底基线、低顶保持和移动规则。滑铲仍是独立的高速无敌动作，不与下蹲混为同一状态。

### 中文课堂第 15 课：人物属性及伤害计算

- 课程位置：章节 2 / 第 10 课；`chapterId=6409490c700410001fd872dd`，`sectionId=6409524a4b7731001f66a5a3`。
- 播放器实际时长：约 `21:53`（`1312.62s`）。
- 页面列出的目标：创建 Boar 野猪木桩、使用碰撞体和触发器、创建 `Character` 与 `Attack` 代码，并实现生命值扣减。
- 本课讨论区显示“暂无讨论，期待您的参与”，没有可用的讲师答疑或用户补充。

视频确认的 Unity 核心结构：

```csharp
public class Attack : MonoBehaviour
{
    public int damage;
    public float attackRange;
    public float attackRate;

    private void OnTriggerStay2D(Collider2D other)
    {
        other.GetComponent<Character>().TakeDamage(this);
    }
}

public class Character : MonoBehaviour
{
    [Header("基本属性")]
    public float maxHealth;
    public float currentHealth;

    [Header("受伤无敌")]
    public float invulnerableDuration;
    private float invulnerableCounter;
    public bool invulnerable;

    private void Start()
    {
        currentHealth = maxHealth;
    }

    private void Update()
    {
        if (invulnerable)
        {
            invulnerableCounter -= Time.deltaTime;
            if (invulnerableCounter <= 0)
                invulnerable = false;
        }
    }

    public void TakeDamage(Attack attacker)
    {
        if (invulnerable)
            return;

        if (currentHealth - attacker.damage > 0)
        {
            currentHealth -= attacker.damage;
            TriggerInvulnerable();
        }
        else
        {
            currentHealth = 0;
            // 死亡逻辑由下一课继续实现。
        }
    }

    private void TriggerInvulnerable()
    {
        if (!invulnerable)
        {
            invulnerable = true;
            invulnerableCounter = invulnerableDuration;
        }
    }
}
```

课时内容和边界：

1. `00:00–05:30` 从野猪素材建立一个暂时只用于验证伤害的 Boar 木桩，在场景中配置 Rigidbody2D 和贴合身体轮廓的 CapsuleCollider2D；课程先确保木桩能稳定站在地形上，再进入伤害触发器设置，尚未实现敌人移动或 AI。
2. `05:30–09:30` 额外建立覆盖野猪周围的 CircleCollider2D，并把它作为触发区域使用。身体碰撞体负责实体阻挡，触发器负责接触伤害，两者职责分开；运行画面用于检查玩家进入范围时触发关系是否成立。
3. `09:30–12:20` 在通用脚本目录创建 `Character.cs`，把生命值从玩家控制器或野猪对象本身抽离出来。`maxHealth` 与 `currentHealth` 作为公开浮点属性，`Start()` 时用最大生命初始化当前生命，使同一属性组件可挂到玩家和后续敌人上。
4. `12:20–14:50` 创建 `Attack.cs`，声明整数 `damage` 与浮点 `attackRange`、`attackRate`。最终示例通过 `OnTriggerStay2D` 获取对方碰撞体上的 `Character`，再把当前 `Attack` 自身传给 `TakeDamage`；伤害数值属于攻击对象，受击对象只消费统一入口。
5. `14:50–16:10` 在 `Character.TakeDamage(Attack attacker)` 中执行 `currentHealth -= attacker.damage`，并在 Inspector/运行状态中观察生命值变化。课程此时尚未处理 UI、受击动画、击退、声音或死亡，这些职责由后续课时继续补齐。
6. `16:10–19:20` 增加受伤无敌：`TakeDamage` 开头若 `invulnerable` 为真则直接返回；成功受伤后调用 `TriggerInvulnerable()`，把 Bool 设为真并把计时器重置为 `invulnerableDuration`；`Update()` 每帧用 `Time.deltaTime` 递减，归零后恢复可受伤状态。
7. `19:20–21:53` 回到 `Attack.OnTriggerStay2D` 完成 `TakeDamage(this)` 调用，并把扣血规则改为先判断剩余生命。若本次伤害后仍大于零则扣血并触发无敌；否则直接把 `currentHealth` 设为零，为下一课的受伤和死亡逻辑留下入口。
8. 最终代码虽然声明了 `attackRange` 和 `attackRate`，但本课没有把它们用于范围计算或攻击冷却；持续触发频率实际由 `OnTriggerStay2D` 与受击方无敌时间共同限制。课程也直接假设进入触发器的 Collider2D 上存在 `Character`，没有展示空引用保护、阵营过滤、自伤过滤或多碰撞体去重，因此这些不能视为已经解决。

玩家体验与制作影响：本课建立的是战斗的最小闭环——玩家进入威胁范围、生命值减少、短时间内不被同一持续接触连续清空。受伤无敌让玩家有时间读取错误并脱离危险，但其时长会同时影响敌人碰撞伤害、连击命中和多敌人夹击，必须作为明确可调参数，而不是由动画长度偶然决定。关卡教学应先用单一木桩或低风险敌人确认接触伤害，再与平台边缘和多个攻击源组合施压；失败需要有清楚的受击、生命变化和重试反馈。本课没有完成这些表现和失败恢复，不能仅凭数值已经扣减就宣称战斗体验完成。

素材与设置影响：本课继续使用已有野猪 Sprite，不新增外部图片；场景侧增加 Boar 木桩的 Rigidbody2D、身体 CapsuleCollider2D、伤害 CircleCollider2D，以及 `Character`、`Attack` 组件。脚本侧新增共享属性和攻击数据入口。身体碰撞与伤害触发范围必须独立调试，不能从透明像素边界自动推导；生命、伤害和无敌时长也应作为数据契约稳定保存，避免散落在动画事件或多个敌人脚本中。

Godot 项目采用的结论：当前项目已经覆盖并扩展了本课最小闭环。`scripts/general/character.gd` 是不承担碰撞与视觉的纯 `Node`，用静态类型的 `max_health`、`current_health`、`invulnerable_duration` 管理生命与无敌，并通过 `maxf(0.0, current_health - amount)` 统一钳制到零；`take_damage(attacker, amount)` 会拒绝死亡或无敌状态下的重复伤害，随后发出 `took_damage`、`health_changed`、`died` 及对应 `GameEvents`，并已接入受击音效和 ISaveable 血量/能量存档。`scripts/general/attack.gd` 由 `Area2D` 承担命中盒，通过目标公开的 `take_damage` 入口传递攻击者和数值，支持每目标单次命中或按 `attack_rate` 冷却的持续命中，不依赖受击无敌来掩盖攻击频率，也不会直接改写对方生命字段。玩家与 `EnemyCombatant` 再分别把受击击退、动画、死亡碰撞关闭和消失表现接到 Character 信号上，符合“规则状态与渲染表现分离”的项目约束。对应 `tests/unit/test_character.gd`、`test_attack.gd`、`test_enemy_combatant.gd` 已覆盖扣血、无敌、归零、死亡信号、每目标冷却和敌人死亡路径；本轮只整理课程研究，不改变现有战斗数值或玩家体验。课程示例仍提醒后续检查一个边界：所有持续伤害源都必须明确自身命中冷却，不能仅依赖目标的全局受伤无敌，否则不同攻击源会互相吞掉命中并改变多敌人战斗节奏。

### 中文课堂第 16 课：受伤和死亡的逻辑和动画

- 课程位置：章节 2 / 第 11 课；`chapterId=6409490c700410001fd872dd`，`sectionId=64095424cdfc640020f7f388`。
- 播放器实际时长：约 `25:49`（`1549.30s`）。
- 页面列出的目标：制作两种受伤动画表现、使用 UnityEvent、实现受伤/死亡函数，并用 Animator StateMachineBehaviour 收束动画状态。
- 页面明确补充：玩家死亡后应在 `CheckState()` 中根据 `isDead` 切换 GameObject Layer，死亡时改到 `Enemy`、存活时恢复 `Player`，避免敌人继续把尸体当作攻击目标。该补充属于课时页正文提示，不是视频中已经完整演示的最终代码。
- 本课讨论区显示“暂无讨论，期待您的参与”。

课时内容和边界：

1. `00:00–06:30` 先在现有 Player Animator 中制作受伤 Clip，并演示通过帧动画/颜色或姿态变化表达受击。受伤不是只改一个生命数字：角色必须有可见的瞬时反馈，同时保持与前课无敌计时的规则分离。
2. `06:30–10:30` 在 `Character` 中加入 UnityEvent，把通用属性层的“受伤”和“死亡”通知暴露给 Inspector。Player 通过事件绑定自己的表现函数，使 `Character` 不需要知道玩家控制器、Animator 或 Rigidbody2D 的具体结构。
3. `10:30–15:30` PlayerController 增加 `isHurt`、`isDead` 与击退参数。`GetHurt(Transform attacker)` 先把受伤状态设为真、清零当前刚体速度，再用玩家与攻击者的水平位置差计算归一化方向，最后以 Impulse 施加远离攻击者的 `hurtForce`。
4. `15:30–19:30` Animator 从 Any State 进入 Hurt，PlayerAnimation 把 `isHurt`/`isDead` 写入动画参数。运行时观察受击状态与动画高亮，确认事件、控制器状态和动画条件按同一击命中同步变化。
5. `19:30–23:30` 增加死亡动画和 `PlayerDead()`：死亡状态设为真，并禁用 Gameplay Action Map，阻止死亡后继续移动、跳跃或攻击。死亡动画与输入禁用由同一死亡事件触发，但是否允许重试、复活或返回菜单尚未在本课处理。
6. `23:30–25:49` 创建并挂载 Animator StateMachineBehaviour，在状态进入/退出时回写控制器标志，避免 Hurt 等一次性动画播放结束后业务状态永久卡住。课程用 Animator Behavior 解决表现状态收尾，但没有建立独立的可测试状态机协议。
7. 本课没有完成 HUD 扣血、游戏结束面板、复活、检查点恢复或存档处理；“死亡 Layer 切换”也只是页面补充。若直接把 GameObject 改成敌人层，还需检查碰撞矩阵、摄像机目标和交互系统是否被意外影响。

玩家体验与制作影响：受击的战斗五拍在本课补上了 Resolve/Recover——命中后立即有姿态或闪烁反馈、击退给出方向信息、无敌时间提供脱离窗口；死亡则应明确终止当前行动并进入可理解的失败恢复。击退过大会把玩家推下平台并放大单次错误，过小又无法读出攻击方向，因此必须和关卡边缘、敌人攻击范围及无敌时长共同试玩。死亡后禁用输入只是规则的一部分，还需要声音、画面、重试入口和恢复位置才能形成完整失败闭环。

Godot 项目采用的结论：`scripts/general/character.gd` 通过 `took_damage`/`died` 信号和 `GameEvents` 承担课程 UnityEvent 的职责；`scripts/player/player_controller.gd` 的 `_on_took_damage()` 会中断攻击与滑铲、清理命中窗口、按攻击者方向施加水平与向上击退、播放 Hurt 并闪红，`_on_died()` 会禁用输入和命中盒，随后播放 Dead 并触发游戏结束流程。玩家业务状态不会依赖 AnimationPlayer 是否自然播完：动画结束只调用明确的 `on_hurt_animation_finished()`，死亡真相仍由 Character/Controller 保存。敌人死亡则由 `EnemyCombatant` 关闭碰撞层和伤害区并延时移除，不采用把尸体改成敌人 Layer 的做法。现有实现比课程页补丁更符合项目的命名碰撞层、跨系统事件和失败恢复约束；本轮不修改受击或死亡手感。

### 中文课堂第 17 课：三段攻击动画的实现

- 课程位置：章节 2 / 第 12 课；`chapterId=6409490c700410001fd872dd`，`sectionId=640955c9ac6aa8002064bbb3`。
- 播放器实际时长：约 `14:56`（`895.57s`）。
- 课时页没有单独的目标列表；讨论区补充解释 `Has Exit Time` 与触发条件会同时生效：例如 Exit Time 为 `0.5` 且条件为 Attack Trigger 时，条件满足后仍要等动画播放到 50% 才会转出。

课时内容和动画结构：

1. `00:00–03:30` 从人物原始 Sprite Sheet 的攻击动作行依次创建三条攻击 Clip，保持帧序、Pivot 和脚底基线一致。每一段使用不同动作帧，表现连续斩击而不是重复播放同一 Clip。
2. `03:30–07:30` 在 Animator 中把三段攻击组织进同一攻击子状态机，建立 Attack1 → Attack2 → Attack3 以及各段返回 Exit 的转换。转换通过 Combo/Attack 参数与 Exit Time 控制，目的是只在允许的连段窗口进入下一击，同时让未继续输入时自然退出。
3. `07:30–11:30` PlayerController 增加攻击输入回调和 `combo` 计数。按下攻击时通知 PlayerAnimation、设置攻击中状态并推进连段编号；超过第三段后重置，避免状态机进入不存在的第四段。
4. `11:30–14:56` PlayerAnimation 把控制器的连段值和攻击触发写入 Animator，进入 Play 模式连续输入验证 Attack1/2/3 顺序与动画退出。视频主要证明动画序列可运行，尚未加入真正的命中盒、每段伤害、输入缓冲或受击打断规则。
5. Exit Time 同时承担“动作承诺”和“何时接受下一段”的职责。若阈值过晚，玩家即使提前按键也会感觉吞输入；若过早，则可在攻击尚未读清时快速取消。课程没有给出独立输入缓冲计时器，后续实现不能只照搬 Animator 条件。

玩家体验与制作影响：三段攻击的幻想是逐步加深承诺并获得更强终结反馈。玩家决策不只是连续按键，而是根据敌人硬直、距离和反击窗口选择继续连段或停止恢复。每段都需要清晰的 startup/active/recovery、可缓冲输入区间、位移与伤害数据；关卡应先用安全木桩确认节奏，再用会反击或后退的敌人测试是否能盲目连按。第三段应通过动画、音效、命中特效或击退形成明显终结感，但常驻 HUD 不需要显示连段编号。

Godot 项目采用的结论：当前 `player_controller.gd` 已实现三段连击与显式输入缓冲。`_begin_attack()` 将 `combo_index` 在 1–3 间推进，播放 `attack1`/`attack2`/`attack3`，为每段读取独立 startup/active 时长并重置 Attack 的每目标命中记录；攻击期间地面水平速度归零。动画结束时只有缓冲窗口内存在下一次输入、连段未到第三击且玩家未受伤/死亡才进入下一段，否则明确清空状态。该规则比仅依赖 Animator Exit Time 更容易做确定性测试，也允许表现动画替换而不改变战斗窗口。课程三条 Clip 和状态关系作为素材/节奏参考保留，本轮不修改现有连段数值。

### 中文课堂第 18 课：实装攻击判定

- 课程位置：章节 2 / 第 13 课；`chapterId=6409490c700410001fd872dd`，`sectionId=640956c5358e970020afe7cf`。
- 播放器实际时长：约 `17:07`（`1027.00s`）。
- 课时页记录一个已知问题：玩家原地连续攻击野猪时可能只有第一击扣血。页面把原因归于 `OnTriggerStay2D` 与刚体休眠，并建议在 Unity `Project Settings > Physics 2D` 把 `Time To Sleep` 从默认 `0.5` 调大到如 `10000`，或让碰撞盒发生移动。该建议会扩大整个项目的物理影响范围，应视为课程环境的规避方案，而不是通用攻击冷却设计。
- 本课讨论区显示“暂无讨论，期待您的参与”。

课时内容和判定结构：

1. `00:00–05:30` 在 Player 下创建面向前方的攻击判定对象，配置独立 Collider2D 并设为 Trigger。视频按挥剑覆盖范围调整判定形状和偏移，使身体碰撞、武器视觉和攻击范围分属不同对象。
2. `05:30–09:30` 为攻击区配置碰撞 Layer/Mask，并挂载上一课的 `Attack` 数据；野猪继续使用 Character 作为统一受伤入口。运行画面检查只有攻击区与可伤害目标重叠时才扣血，而玩家身体碰撞仍负责地形和实体阻挡。
3. `09:30–12:00` 在控制器的 FixedUpdate 中加入攻击/受伤状态门控：只有 `!isHurt && !isAttack` 时执行普通移动，避免攻击动画播放期间角色继续以跑步速度滑动。课程选择站定攻击，没有设计前冲、空中攻击或可取消移动。
4. `12:00–14:30` 创建 `AttackFinish : StateMachineBehaviour`；`OnStateEnter` 把 `PlayerController.isAttack` 设为真，`OnStateExit` 设回假，再挂到攻击 Animator 状态上。动画状态由此控制移动锁定的起止。
5. `14:30–17:07` 进入 Play 模式用三段攻击命中野猪并检查生命值。课程最终仍通过持续 Trigger 回调与受击无敌限制扣血频率，没有为每一段攻击建立独立的单目标命中集合；课时页所述原地重复命中问题说明该方案会受物理休眠和碰撞回调细节影响。
6. 本课没有明确展示阵营过滤、自伤保护、同一目标多碰撞体去重、攻击窗口的 startup/active/recovery 数据、伤害来源稳定 ID 或命中停顿。把全局 `Time To Sleep` 调到极大值也可能增加不必要的物理计算，不能替代攻击系统自身的命中生命周期。

玩家体验与制作影响：攻击判定必须与挥剑画面同步，让玩家看到“剑经过目标”时命中，而不是身体靠近就掉血。判定过宽会造成隔空命中，过窄会让清晰的剑光穿过目标却无反馈；攻击期间是否锁定移动则决定角色是稳重承诺型还是位移进攻型。每一击需要独立处理一次命中、音效、停顿、闪白/击退和第三段终结反馈，并在受击、死亡、场景切换时强制关闭命中盒。

Godot 项目采用的结论：玩家场景使用独立 `AttackPivot/Attack` Area2D，朝向通过 Pivot 缩放更新，不让身体碰撞承担伤害。`_tick_attack_hitbox()` 以静态类型的 startup/active 计时显式开启和关闭命中区；`Attack.per_target_one_hit=true` 时每次攻击窗口对同一目标只命中一次，下一段由 `reset_hits()` 重新开放。持续攻击源则按 `attack_rate` 保存每目标冷却，不依赖 Character 的全局无敌或物理休眠。受击、死亡、输入禁用和动画结束都会关闭命中盒，移动锁定由 Controller 的 `is_attacking` 业务状态决定，而不是由 AnimationPlayer 状态反向成为唯一真相。`tests/unit/test_attack.gd` 已覆盖单目标一次命中、持续攻击冷却与离开后重置；课程的原地连续攻击缺口在项目架构中已有明确替代方案，因此不调整 Godot 全局物理休眠设置。

### 中文课堂第 19 课：野猪——基本的移动逻辑和动画

- 课程位置：章节 3 / 第 1 课；`chapterId=64095814700410001fd87304`，`sectionId=64095814700410001fd87305`。
- 播放器实际时长：约 `16:35`（`994.83s`）。
- 课时页补充：Tilemap 墙壁若按图片透明像素自动生成碰撞，轮廓可能凹凸不平；应在 Sprite Editor 的 `Custom Physics Shape` 中把墙面修成规则矩形。该提示直接影响敌人贴墙移动的稳定性。
- 本课讨论区显示“暂无讨论，期待您的参与”。

课时内容和边界：

1. `00:00–05:30` 整理 Boar 层级与 prefab，把身体碰撞、接触攻击区、Character 属性和动画组件放到同一敌人对象上；运行画面确认野猪和玩家都能稳定站在地面且接触关系正常。
2. `05:30–11:30` 从野猪 Sprite Sheet 建立 Idle 与 Walk 动画，并在 Animator 中配置默认状态和移动状态。动画只负责表现，课程随后用脚本速度驱动移动，而不是用 Root Motion 推动像素角色。
3. `11:30–15:30` 创建公共 `Enemy.cs`，缓存 Rigidbody2D/Animator，声明 `normalSpeed`、`chaseSpeed`、`currentSpeed` 和 `faceDir`；初始化时把当前速度设为普通速度，Update 根据 `transform.localScale.x` 推导面向方向，FixedUpdate 调用 Move。
4. `15:30–16:35` `Move()` 通过 Rigidbody2D 横向速度让野猪沿当前朝向移动，进入 Play 模式观察自动巡逻的基础效果。本课尚未处理撞墙、平台边缘、等待、追击、受击或死亡，因此野猪会持续向一个方向前进。
5. 视频中的移动表达式画面包含把 `Time.deltaTime` 乘入 Rigidbody2D 速度的写法；这与课程前面“直接设置速度时不再额外乘 deltaTime”的说明存在潜在冲突，应以实际 Unity 版本和最终代码为准，不能迁移为 Godot 结论。

玩家体验与制作影响：基础野猪的职责是形成可读的地面移动威胁。玩家首先应能从轮廓、朝向和步频判断它会向哪边移动，再决定跳过、攻击或保持距离。Idle/Walk 切换必须与实际速度一致，墙面碰撞和脚底接触必须稳定，否则敌人会抖动、卡墙或滑出平台，破坏攻击时机的可读性。

Godot 项目采用的结论：项目的 `Boar` 继承 `EnemyMinion`/`Enemy` 状态机，不把所有逻辑堆进单个脚本。移动由 `BoarPatrolState` 和 `BoarChaseState` 设置 `CharacterBody2D.velocity.x`，统一在 Enemy 物理流程中 `move_and_slide()`；速度使用 Godot 每秒单位，不额外乘 delta。普通野猪使用持续接触攻击区，`attack_damage` 会写入共享 Attack 组件；Patrol/Chase 分别播放 Walk/Run，受击恢复后由当前状态重新选择正确动画。课程对 prefab、Idle/Walk 和公共敌人速度字段的拆分已覆盖，项目保留显式 Patrol/Chase/Skill 架构。

### 中文课堂第 20 课：野猪——撞墙判定和等候计时

- 课程位置：章节 3 / 第 2 课；`chapterId=64095814700410001fd87304`，`sectionId=64095cc2ac6aa8002064bbca`。
- 播放器实际时长：约 `17:24`（`1043.87s`）。
- 课时页明确修正：地面检测偏移的 X 分量必须乘 `transform.localScale.x`，这样野猪翻转后检测方向才随朝向改变；页面指向视频约 `16:00` 的对应代码，并给出 `Check()`/`OnDrawGizmosSelected()` 示例。
- 本课讨论区显示“暂无讨论，期待您的参与”。

课时内容和检测结构：

1. `00:00–04:30` 复用并扩展 `PhysicsCheck`，为野猪配置脚底、左墙和右墙三个圆形检测点。`Check()` 每帧用 `Physics2D.OverlapCircle` 检查 Ground Layer，Gizmos 同时绘制三个圆，便于在 Scene 视图校准位置与半径。
2. `04:30–08:30` `Awake()` 获取 CapsuleCollider2D，并根据碰撞体 bounds/offset 推导左右和底部检测偏移，减少每个敌人 prefab 重复手填。视频随后在野猪对象上检查 Gizmo 是否贴合脚底和身体侧面。
3. `08:30–12:30` Enemy 缓存 PhysicsCheck；Update 根据当前朝向读取左/右碰墙结果，撞墙时翻转 `transform.localScale`。面向方向和检测方向必须同步，否则转身后仍会检测旧的一侧并反复翻转。
4. `12:30–16:00` 加入等待状态/计时：野猪检测到墙后先停止移动并播放等待/Idle，计时结束再完成转身并恢复 Walk，使巡逻节奏不呈现瞬时机械反弹。运行画面用于观察墙前停顿和恢复移动。
5. `16:00–17:24` 回到 PhysicsCheck 修正底部/前方检测偏移随 `localScale.x` 翻转的问题，并再次测试。课程主要处理墙体，没有形成完整的平台边缘预判；若地形墙面碰撞不平，检测圆仍可能在像素凸点上误判。

玩家体验与制作影响：墙前短暂停顿既是 AI 技术处理，也是玩家可利用的恢复窗口。它让野猪的巡逻周期更可预测，玩家能在转身前后选择背刺或越过。等待时间、检测半径和墙面形状要共同调试；过短会像碰撞抖动，过长会让敌人失去压力。关卡还需要检查平台边缘，不能只保证撞墙转身而让野猪走出悬崖。

Godot 项目采用的结论：`scripts/general/physics_check.gd` 用缓存的 CircleShape2D/PhysicsShapeQueryParameters2D 检查地面、左右墙和前方地面，默认从父节点 CollisionShape2D 推导偏移，并排除自身 RID。`should_turn_for_patrol(direction)` 同时处理迎面墙壁和前方无地面，比课程只做墙面更完整。`BoarPatrolState` 在需要转向时反转待恢复方向、设置 `0.4s` 等待、清零速度并播放 Idle，计时结束后恢复 Walk；检测节点不依赖视觉 Sprite 缩放，而是显式接收方向参数。课程关于等待反馈、平整 Tilemap 墙面和调试检测点的目标均已接入。

### 中文课堂第 21 课：野猪——受伤及死亡的逻辑和动画

- 课程位置：章节 3 / 第 3 课；`chapterId=64095814700410001fd87304`，`sectionId=64095f6b700410001fd87317`。
- 播放器实际时长：约 `23:45`（`1424.57s`）。
- 课时页没有额外正文提示；讨论区显示“暂无讨论，期待您的参与”。

课时内容和状态处理：

1. `00:00–06:30` 从野猪 Sprite Sheet 建立 Hurt 与 Dead Clip，并把它们接入现有 Idle/Walk Animator。Hurt 从 Any State 进入，再根据当前移动/等待状态返回；Dead 是终止状态，不返回普通移动。
2. `06:30–12:30` Enemy 增加 `isHurt`、`isDead` 与 `hurtForce`，并通过 Character 的受伤/死亡 UnityEvent 把攻击者信息传给敌人脚本。受伤发生时暂停普通移动，避免击退与巡逻速度同时写 Rigidbody2D。
3. `12:30–17:30` `OnHurt` 根据攻击者与野猪的水平位置差计算远离攻击者的方向，设置 Hurt Trigger 并施加 Impulse。视频先展示直接切换 `isHurt`，随后改为协程，让受伤锁定保持约 `0.5s` 后再恢复。
4. `17:30–21:30` 进入 Play 模式反复攻击野猪，检查每次受击的朝向、击退、动画和无敌间隔；死亡时不再恢复 Walk/Idle。
5. `21:30–23:45` `OnDie()` 把对象 Layer 改为不再参与正常战斗的层、设置 Animator `dead=true` 并保存 `isDead=true`；死亡 Clip 末尾通过 Animation Event 调用 `DestroyAfterAnimation()`，最终 `Destroy(gameObject)`。
6. 课程的死亡销毁依赖动画事件正确存在；若 Clip 被替换、事件漏配或动画未播放，对象可能永久留在场景。课程也没有处理掉落、存档持久化、Encounter 计数或对象池回收。

玩家体验与制作影响：敌人受击需要同时传达“命中了谁、从哪边命中、是否还能追击”。方向击退给玩家位置优势，死亡动画则确认威胁已解除；碰撞与攻击区必须在死亡开始时立即停用，不能等动画末帧才停止伤害。销毁前若有奖励，应在死亡真相首次成立时只结算一次，动画结束只负责表现收尾。

Godot 项目采用的结论：`EnemyCombatant` 监听子节点 Character 的 `took_damage`/`died` 信号。受击时设置硬直计时、按攻击者方向写入水平和向上击退、播放 Hurt 并闪红；死亡时立即记录持久化状态、关闭身体和所有 Area2D 碰撞、播放 Dead、发出事件并按 `despawn_after_death` 延时移除。它不依赖动画末帧事件才能关闭战斗，也能在旧存档加载死亡状态时直接移除对象。野猪当前状态会在受击恢复后重新选择 Walk/Run；Windows/OpenGL 的 Idle/Run 代表截图和动作回归测试已补齐素材与恢复路径验收。

### 中文课堂第 22 课：有限状态机、抽象类与多态

- 课程位置：章节 3 / 第 4 课；`chapterId=64095814700410001fd87304`，`sectionId=640960d99bebe4001f474ecd`。
- 播放器实际时长：约 `18:54`（`1134.40s`）。
- 课时页给出完整 `BaseState` 抽象接口：持有 `protected Enemy currentEnemy`，并要求子类实现 `OnEnter(Enemy)`、`LogicUpdate()`、`PhysicsUpdate()`、`OnExit()`。
- 页面还补充了视频 `15:46` 的修正：`BoarPatrolState.LogicUpdate()` 在没有触发等待时必须用 `else` 重新设置 `anim.SetBool("walk", true)`，否则 Walk 状态可能沿用先前的 false 而不恢复。
- 本课讨论区显示“暂无讨论，期待您的参与”。

课时内容和架构：

1. `00:00–04:30` 先把野猪特有实现从公共 Enemy 拆出为 `Boar : Enemy`，通过 override 保留公共移动并加入野猪动画行为，示范继承与多态解决“共享规则 + 敌人差异”。
2. `04:30–08:30` 创建抽象 `BaseState`，定义 Enter、逻辑更新、物理更新和 Exit 四个生命周期。状态持有当前 Enemy 引用，使状态类可以读取速度、动画、物理检测和等待参数。
3. `08:30–13:30` 创建 `BoarPatrolState : BaseState` 与 `BoarChaseState : BaseState`，实现或预留各生命周期；Patrol 负责墙/地面检测、等待和 Walk，Chase 负责追击移动与 Run。
4. `13:30–17:30` Enemy 持有 `currentState`、`patrolState`、`chaseState`。启用时进入 Patrol；Update 调用 `LogicUpdate()` 与通用计时；FixedUpdate 在未受伤、未死亡、未等待时移动，并调用状态的 `PhysicsUpdate()`；禁用时调用 `OnExit()`。
5. `17:30–18:54` 运行验证状态拆分后野猪仍能巡逻和等待。课程重点是代码结构，没有完成玩家检测和实际追击切换，后者由下一课继续。
6. 状态对象可访问整个 Enemy，降低了重复代码，但也容易让每个状态随意写公共字段。Enter/Exit 必须成对清理动画 Bool、计时器和目标引用，否则切换后会残留上一状态行为。

Godot 项目采用的结论：项目的 `BaseState` 使用 `RefCounted`，提供带静态类型 delta 的 `on_enter`、`logic_update`、`physics_update`、`on_exit`；Enemy 在 `_setup_states()` 中由具体敌人装配 Patrol/Chase/Skill，通过 `switch_state()` 统一执行 Exit → 替换 → Enter 并广播 `state_changed`。Boar、Bee、Snail 只负责选择自己的状态实现，公共受伤/死亡继续由 EnemyCombatant 管理。Godot 不需要 C# abstract 关键字才能实现该协议，但状态子类仍应显式覆写并保持职责边界。当前 `BoarPatrolState` 在进入状态时直接播放 Walk、等待时清零速度，避免只靠 Animator Bool 的残留值恢复动画。

### 中文课堂第 23 课：追击状态的转换

- 课程位置：章节 3 / 第 5 课；`chapterId=64095814700410001fd87304`，`sectionId=640961ea9bebe4001f474ed0`。
- 播放器实际时长：约 `26:08`（`1567.85s`）。
- 课时页明确修正丢失目标计时：应移除 `BoarChaseState.OnExit()` 中 `lostTimeCounter = lostTime` 的重置，把重置放入 Enemy 基类 `TimeCounter()` 的“当前发现玩家”分支；其他敌人也应使用同一规则。
- 页面示例的 `TimeCounter()` 同时处理墙前等待与丢失目标：等待归零后翻转朝向；未发现玩家且计时大于零时递减，发现玩家时重置为 `lostTime`。
- 本课讨论区显示“暂无讨论，期待您的参与”。

课时内容和状态转换：

1. `00:00–06:30` 为 Enemy 配置玩家检测范围、中心偏移、LayerMask 与 Scene Gizmo，使用 Physics2D BoxCast/范围检测判断 Player 是否进入感知区。检测结果保存攻击者 Transform，供追击方向和受击/攻击逻辑使用。
2. `06:30–12:30` 定义 NPCState 枚举与 `SwitchState`：按 Patrol/Chase 选择目标状态，先调用当前状态 OnExit，再替换引用并调用新状态 OnEnter。Patrol 的 LogicUpdate 在 `FoundPlayer()` 后切入 Chase。
3. `12:30–17:30` BoarChaseState 进入时切换追击速度和 Run；逻辑更新持续根据玩家左右位置调整面向与移动方向。Patrol 退出时关闭 Walk，Chase 退出时关闭 Run，避免动画 Bool 跨状态残留。
4. `17:30–22:30` 加入 `lostTime`/`lostTimeCounter`：短暂看不到玩家时继续保持追击，计时耗尽才返回 Patrol，避免玩家刚离开检测边缘就让野猪瞬间转身。
5. `22:30–26:08` 进入 Play 模式测试进入检测区、追击、离开范围、等待丢失计时和恢复巡逻。课程页面随后补充计时器重置位置，防止在 Chase Exit 中无条件重置而破坏跨敌人一致性。
6. 课程的范围检测没有展示世界遮挡、垂直差、平台可达性或多个玩家目标选择。只按 X 方向追击时，玩家站在不可达高台仍可能让敌人持续贴墙跑。

玩家体验与制作影响：追击需要给玩家清晰的 Read 阶段——敌人由 Walk 变 Run、朝向锁定、速度提升，让玩家知道自己已被发现。短暂丢失计时提供可利用的脱战规则，但不能让敌人在墙后透视追踪。关卡应测试同层直线、隔墙、高台、平台边缘和反复进出检测边界，确认状态不会抖动。

Godot 项目采用的结论：Enemy 的 `found_player()` 先用缓存的范围 Shape 查询候选玩家，再用射线 `can_see_target()` 验证 World 遮挡；发现玩家时保存 attacker 并重置 `lost_time_counter`。Patrol 发现玩家后切 Chase，BoarChaseState 根据目标位置设置方向、处理墙/边缘并用加速度逼近追击速度；目标清空或计时耗尽时返回 Patrol。2026-07-15 已按课程修正统一计时职责：只有 `Enemy._update_target_tracking()` 在 Chase 中刷新或递减目标记忆，Boar/Bee/Boss 的 Chase 状态不再重复扣时；`test_enemy_perception.gd` 覆盖持续可见时刷新、离开范围后按配置时长清除目标。

### 中文课堂第 24 课：蜗牛——基本的移动逻辑和动画

- 课程位置：章节 3 / 第 6 课；`chapterId=64095814700410001fd87304`，`sectionId=64096308700410001fd87319`。
- 播放器实际时长：约 `18:47`（`1127.33s`）。
- 中文课堂独有课时。
- 课时页明确说明视频没有制作蜗牛死亡动画，要求学习者自行补做，并在 Animation 最后一帧添加调用 `DestroyAfterAnimation` 的 Event；页面另给出 Animator 连线示意图。
- 本课讨论区显示“暂无讨论，期待您的参与”。

课时内容和基础职责：

1. `00:00–05:30` 把蜗牛 Sprite、Rigidbody2D、身体 Collider、接触攻击区、Character、PhysicsCheck 与 Enemy 脚本组装为独立 prefab，并在场景中检查脚底、身体尺寸与玩家接触关系。
2. `05:30–10:30` 从蜗牛图集建立 Idle/Walk/Hurt 等基础 Clip，并在 Animator 中配置移动、受击和后续缩壳状态的入口。视频为下一课预留 Skill 相关状态，但本课重点仍是基础巡逻可运行。
3. `10:30–14:30` 创建 Snail/`SnailPatrolState`，复用 Enemy 的速度、等待、物理检测和状态切换。Patrol 进入时使用普通速度；发现玩家后切换 Skill，遇墙或前方无地面时停止、关闭 Walk 并等待转身，否则保持 Walk。
4. `14:30–18:47` 把 Patrol/Skill 状态装配到蜗牛，进入 Play 模式确认缓慢移动、转身、玩家检测与动画切换。死亡动画没有在视频中完成，课时页要求自行补齐。
5. 课程沿用野猪的通用 Enemy 框架，但蜗牛的战斗幻想并不是更慢的野猪：它的核心差异是发现威胁后进入防御 Skill，因此基础速度、检测方向和背后攻击窗口需要为下一课服务。

玩家体验与制作影响：蜗牛应作为低移动压力、强位置判断的敌人。玩家需要读出它的正面感知与缩壳倾向，选择从背后接近或在它伸出身体时攻击。巡逻太快会削弱这种观察玩法，检测覆盖全方向又会消灭背刺窗口。死亡动画虽可后补，但战斗碰撞必须在死亡真相成立时立即停用，不能依赖最后一帧 Event 才停止攻击。

Godot 项目采用的结论：`Snail` 继承 EnemyMinion，Patrol 以低速移动、墙/边缘等待并播放 Walk；其 `found_player()` 使用前方距离、垂直容差、朝向和后方盲区，且继续检查世界遮挡，为玩家保留明确背刺窗口。受到伤害也会主动切入 Skill。前向接触攻击区会与视觉朝向同步翻转；Walk 和 Dead 使用各自完整 0–7 帧，死亡开始时立即关闭战斗碰撞。感知、接触伤害、朝向和完整动作条均有确定性测试与实际截图证据。

### 中文课堂第 25 课：蜗牛——特殊技能状态的实现

- 课程位置：章节 3 / 第 7 课；`chapterId=64095814700410001fd87304`，`sectionId=640965059bebe4001f474ed2`。
- 播放器实际时长：约 `15:38`（`937.63s`）。
- 中文课堂独有课时；页面没有额外正文提示，讨论区显示“暂无讨论，期待您的参与”。

课时内容和 Skill 流程：

1. `00:00–03:30` 在蜗牛 Animator 中完成缩壳/壳内保持/恢复相关状态和转换，把 Skill Trigger/Bool 与既有 Walk、Hurt、Dead 关系连接起来。
2. `03:30–07:30` Patrol 的 LogicUpdate 在 `FoundPlayer()` 后切换到 `NPCState.Skill`；创建 `SnailSkillState : BaseState`，OnEnter 保存当前 Enemy、停止 Walk、触发缩壳动画并重置持续计时。
3. `07:30–11:30` Skill 的 LogicUpdate 等待 `lostTimeCounter` 归零后切回 Patrol，使蜗牛不会在玩家刚靠近时立刻伸出；状态退出恢复普通巡逻动画和速度。
4. `11:30–15:38` 配置 Character/Animator 事件并进入 Play 模式，观察玩家靠近后蜗牛缩壳、停留一段时间、再恢复巡逻；运行画面还检查攻击时壳状态与受击表现的关系。
5. 课程用同一个 lost-time 计时器表达技能持续时间，适合作为教学最小实现，但会把“目标是否仍在附近”和“缩壳最短承诺时间”耦合。若玩家持续站在旁边，技能是否延长、何时允许伸出，需要独立规则。

玩家体验与制作影响：缩壳是防御节奏而非单纯无敌。玩家应能读出进入壳、保持和退出三个阶段，并选择等待、绕后或转移目标；若壳内永久无敌且玩家站近会无限刷新，战斗可能停滞。需要最短缩壳时间、玩家离开条件、重新发现时的打断规则，以及壳内命中的明确反馈。

Godot 项目采用的结论：`SnailSkillState` 已拆成 HIDING、WAITING、UNHIDING 三阶段。原 `Hide-Sheet` 的动作语义是前半段缩入、后半段伸出，因此 Hide 使用 0–3 帧、壳内保持第 3 帧、Unhide 使用作者绘制的 4–7 帧，而不是机械反放前半段。壳内持续刷新 Character 无敌；玩家离开正面视野后才伸出，重新发现时回到壳内；状态退出清除无敌。该实现保留课程防御节奏，同时把最短承诺时间与目标丢失计时分离。

### 中文课堂第 26 课：蜜蜂——基本的移动逻辑和动画

- 课程位置：章节 3 / 第 8 课；`chapterId=64095814700410001fd87304`，`sectionId=6409661c700410001fd8731e`。
- 播放器实际时长：约 `22:08`（`1327.73s`）。
- 中文课堂独有课时；页面没有额外正文提示，讨论区显示“暂无讨论，期待您的参与”。

课时内容和飞行巡逻：

1. `00:00–06:30` 组装 Bee prefab：飞行 Sprite/Animator、Rigidbody2D（不使用普通地面重力）、身体 Collider、攻击触发区、Character 与 Enemy 脚本。场景中调整蜜蜂尺寸、朝向和碰撞范围。
2. `06:30–11:30` 配置 Fly/Hurt/Dead 等动画和玩家检测范围，用 Gizmo 绘制感知圆；蜜蜂不依赖脚底检测，移动目标可以同时改变 X/Y。
3. `11:30–16:30` 创建 `Bee : Enemy`，增加巡逻半径，覆写玩家发现与 `GetNewPoint()`。新巡逻点围绕出生位置随机生成，使蜜蜂不会像地面敌人一样只沿单轴往返。
4. `16:30–20:30` 创建 `BeePatrolState`：进入时设置普通速度并取得随机目标；逻辑更新发现玩家后切 Chase，接近目标时进入短等待并重新取点，否则沿归一化方向飞向目标并更新朝向。
5. `20:30–22:08` 进入 Play 模式观察矩形/圆形区域内的随机悬停巡逻和转向，检查蜜蜂不会受地面平台限制。本课尚未实现追击和攻击。
6. 随机巡逻必须围绕稳定出生中心，不能每次以当前位置再次偏移，否则巡逻区域会随机漂移。到达容差和等待时间也应避免蜜蜂在目标附近高速抖动。

玩家体验与制作影响：蜜蜂引入垂直威胁，迫使玩家同时考虑头顶空间和攻击角度。巡逻应呈现可读的悬停与换点，而不是完全随机噪声；关卡需要给玩家足够纵向视野，并避免敌人在屏幕外或地形内部选点。

Godot 项目采用的结论：`Bee` 使用 `uses_gravity=false` 的 Enemy 流程，巡逻中心固定为 spawn_point 加偏移，`patrol_half_extents` 生成矩形随机点。`BeePatrolState` 在目标距离小于 12px 时等待 `0.4–1.0s` 后换点，否则设置二维 velocity 并按 X 方向翻转视觉；发现玩家后进入 Chase。项目默认 Enemy 感知还包含世界遮挡射线，避免隔墙发现玩家。课程的飞行 prefab、随机点和 Patrol 状态与项目结构一致。

### 中文课堂第 27 课：蜜蜂——追击和攻击的实现

- 课程位置：章节 3 / 第 9 课；`chapterId=64095814700410001fd87304`，`sectionId=640967114b7731001f66a5dd`。
- 播放器实际时长：约 `20:59`（`1259.05s`），已完整播放到结束。
- 课时页明确修正：`BeeChaseState` 的 `attackRateCounter -= Time.deltaTime` 必须放在攻击范围判断外。若只在范围内递减，蜜蜂离开范围时冷却会冻结，重新接近后可能长期不能按预期攻击。
- 页面给出的 LogicUpdate 还明确使用玩家位置加 `1.5f` 的垂直偏移作为目标，并以 X/Y 两轴与 `attackRange` 比较判断是否进入攻击。

已确认的课时内容：

1. `00:00–05:30` 创建 `BeeChaseState`，进入时设置追击速度并缓存 Attack；目标位置取玩家位置上方约 `1.5` 单位，让蜜蜂优先悬停到玩家头顶附近，而不是直接撞向脚底原点。
2. `05:30–10:30` 同时检查目标 X/Y 距离是否进入 `attackRange`。范围内设置 `isAttack=true` 并停止刚体速度；范围外恢复追击，移动方向为目标位置减蜜蜂位置后的归一化向量。
3. `10:30–14:30` 根据 moveDir.x 翻转朝向；PhysicsUpdate 在未受伤、未死亡且非攻击中时写入二维追击速度。丢失目标计时耗尽则返回 Patrol。
4. `14:30–18:30` 加入攻击频率计时和 Attack Trigger：冷却归零时播放攻击动画并重置为 `attack.attackRate`。Animator 增加 Attack/Hurt/Dead 关系，攻击动作期间停止移动。
5. `18:30–20:59` 配置攻击动画事件/判定区并进行最终运行测试，观察蜜蜂接近、停在攻击位置、出招、重新追击和离开范围后的冷却恢复。结尾没有新增独立代码结构，主要确认页面补丁后的追击/攻击循环可连续运行。

Godot 项目采用的结论：`BeeChaseState` 每帧在范围判断前递减 `_attack_rate_counter`，符合课时页修正；追击目标、攻击悬停高度、横纵容差和攻击间隔均为独立参数。进入攻击时停止移动并执行 0.35s Startup、0.12s Active、0.55s Retreat；Active 现在通过 `Attack.set_active()` 同时启停 monitoring 与碰撞形状，计时归零当帧关闭，并由实际玩家扣血测试证明伤害链有效。攻击/受击结束后恢复 Chase/Fly，Dead 使用 Hit/Vanish 0–3 完整序列。课程最终循环已覆盖，项目额外保留退避和世界遮挡。

### 中文课堂第 28 课：创建人物状态栏

- 课程位置：章节 4 / 第 1 课；`chapterId=6409682974ae5600200cdff3`，`sectionId=6409682974ae5600200cdff4`。
- 播放器实际时长：约 `18:16`（`1095.94s`）。
- 课时页没有额外正文提示；讨论区显示“暂无讨论，期待您的参与”。

课时内容和 UI 结构：

1. `00:00–04:30` 在 Player/场景 UI 下创建 Canvas，使用屏幕空间渲染和 Canvas Scaler，使状态栏固定在视口而不随世界相机移动。课程检查 Pixel Perfect、排序和 UI 层级。
2. `04:30–09:30` 导入状态栏素材，在 Sprite Editor 中切分头像框、横条背景、生命/能量填充等区域；需要拉伸的条框使用正确的 Border/九宫格，避免尺寸变化时端帽变形。
3. `09:30–14:30` 建立状态栏根节点，添加背景、头像和多层 Image。生命条包含即时前景和延迟层，底部另有能量/能力条；各 Image 设置 Filled/Horizontal 或合适的 Sliced 类型。
4. `14:30–18:16` 把状态栏锚定在左上安全区域，调整头像、间距、条宽和层叠顺序，最终在 Game 视图检查它不会随玩家移动，并能在不同画面内容上保持可读。
5. 本课只完成静态 UI 结构，没有把实际 Character 数值写入填充量；数据驱动由下一课完成。素材示例的像素尺寸和参考分辨率不能直接作为本项目 640×360 的最终布局。

玩家体验与制作影响：常驻 HUD 只应回答当前立即决策所需的问题——剩余生命、可用能量和危险状态。状态栏需要避开核心移动/战斗区域，头像与装饰不能挤压有效条长。生命即时层与延迟层应有清楚颜色差异，让玩家同时读出“当前剩余”和“刚刚损失”，但延迟不能慢到误导实际生存状态。

Godot 项目采用的结论：项目使用 CanvasLayer/UIRootLayer 管理常驻 UI，`scenes/ui/gameplay_hud.tscn` 在 640×360 逻辑视口中按第 28 课复用课程 `HUD/Base-UI.png`：头像底板、生命即时层、生命延迟层和能量层均是该图集的 `AtlasTexture`，而不是默认 `ProgressBar`。状态条必须使用图集右侧的深色细条槽（`60×8`）以及绿/黄/蓝细填充（`58×6`）；同图集左侧的 `58×20` 彩色按钮不属于状态条素材，不能替代填充。布局固定在左上安全区，头像左置并裁入底板；右侧两条独立细条分别容纳生命的前景/延迟层和能量层，不使用会侵占画面的通栏深色面板或文字标签。`PlayerStatBar` 仍以 Control 和 Range/TextureProgressBar 节点显示生命、延迟生命与能量；布局按整数缩放与安全区验收，不复制 Unity Canvas 的像素尺寸。第 29 课的数据流也已闭环：Character/GameEvents 更新即时条，延迟层平滑追赶，存档恢复主动同步。`test_player_hud.gd` 固定图集和层级契约，Windows/OpenGL `player_hud.png` 检查实际可读性。

### 中文课堂第 29 课：血量更新逻辑的实现

- 课程位置：章节 4 / 第 2 课；`chapterId=6409682974ae5600200cdff3`，`sectionId=6409692a6391b600208067d1`。
- 播放器实际时长：约 `20:18`（`1218.37s`）。
- 课时页没有额外正文提示；讨论区显示“暂无讨论，期待您的参与”。

课时内容和事件链：

1. `00:00–04:30` 创建 `PlayerStatBar.cs`，缓存生命前景 Image、延迟生命 Image 和能量 Image，为后续按 `fillAmount` 写入 0–1 比例做准备。
2. `04:30–08:30` 把脚本挂到状态栏并在 Inspector 连接各层 Image，先用运行态手动验证填充方向和层级，确保生命下降时露出的延迟层位于正确位置。
3. `08:30–12:30` 创建 `CharacterEventSO : ScriptableObject`，使用 `UnityAction<Character>` 传递发生变化的角色；同时建立事件监听组件，把 ScriptableObject 通道转换为 Inspector 可绑定的 UnityEvent。
4. `12:30–16:30` Character 在生命变化后 RaiseEvent(this)，PlayerStatBar 监听后读取 `currentHealth / maxHealth`，即时更新主生命 Image；延迟层按协程或平滑逻辑逐步追到目标值。能量条使用相同的比例更新思路。
5. `16:30–20:18` 创建并连接事件资产，在 Player 与 UI Inspector 中完成通道绑定；进入 Play 模式让野猪造成伤害，确认绿色当前血量立即下降、后方延迟条随后追赶，状态栏无需每帧查找玩家。
6. ScriptableObject 通道降低了场景对象直接引用，但资产若连错、监听器未启用或角色未 Raise，UI 会静默不更新；初始化和新场景加载后也必须主动同步一次当前值。

玩家体验与制作影响：血量 UI 是受击反馈的一部分，必须与闪红、击退、音效同帧开始更新。即时层代表规则真相，延迟层只表现损失幅度；低血量还应有可读但不遮挡游戏的危险提示。死亡时条值必须准确归零，复活/加载存档后必须立即同步，不能等待下一次受伤事件。

Godot 项目采用的结论：`Character.take_damage()`、heal、reset 和存档加载都会发出 `health_changed` 与 `GameEvents.character_health_changed`；`PlayerStatBar` 监听生命变化与受击事件，并能从 player 组自动解析 Character。即时生命直接写入 Range，延迟生命按 `health_delay_speed` 平滑追赶，能量按独立速度插值；低血量颜色、受击闪白和能量满值颜色均为可调表现。项目以 Autoload 信号替代 ScriptableObject EventChannel，跨场景不依赖 UnityEvent Inspector 链。现有单元测试覆盖 Character 比例和 GameEvents 信号存在，HUD 的延迟动画与视觉状态仍主要依赖冒烟/实际运行验收。

### 中文课堂第 30 课：滑墙及蹬墙跳的实现

- 课程位置：章节 5 / 第 1 课；`chapterId=640969d6700410001fd8731f`，`sectionId=640969d6700410001fd87320`。
- 播放器实际时长：约 `21:27`（`1286.74s`）。
- 中文课堂独有课时。
- 讨论区只显示平台自动过滤提示，没有可用的课程补充。

课时内容和墙面规则：

1. `00:00–05:30` 从人物图集建立 Wall Slide 动画，在 Animator 中把 Jump/Fall、Wall 与地面状态连接，加入墙面 Bool/条件，使角色离地接触墙面时进入贴墙姿态。
2. `05:30–10:30` 扩展 PhysicsCheck/PlayerController 的墙面状态判定，并准备 Normal/Wall 两种 PhysicsMaterial2D。`CheckState()` 根据是否接地或贴墙切换 Collider 的共享材质，避免贴墙时被摩擦卡住或下落速度异常。
3. `10:30–14:30` 实现滑墙：角色未接地且侧面检测命中墙体时限制向下速度，保持可控缓降；PlayerAnimation 读取墙面状态播放 Wall，离墙或落地后恢复普通 Jump/Fall/Idle。
4. `14:30–18:30` 修改 Jump 输入：地面仍执行普通跳跃；空中贴墙时根据接触左墙/右墙选择相反的水平方向，同时施加向上的 Impulse，形成离墙跳跃。
5. `18:30–21:27` 进入 Play 模式反复测试左右墙滑落、墙上跳起、连续换墙和落地恢复，调整水平/垂直冲量及检测点。结尾主要是运行验证，没有新增独立系统。
6. 课程实现没有展示土狼时间、跳跃缓冲、松键截断、输入锁或墙角/低顶边界；若玩家持续按向墙方向，离墙冲量可能被下一物理帧的普通移动立即抵消。

玩家体验与制作影响：滑墙给玩家一个“把失误转成下一步”的恢复动作，蹬墙跳则把墙面变成路线资源。玩家应清楚读出何时抓墙、向哪边弹出和何时重新获得空中控制。关卡应先用单墙安全井教学，再用双墙上升确认，最后与尖刺、敌人和移动平台组合施压；失败后重试点不能让玩家重复过长的攀爬段。

Godot 项目采用的结论：`PlayerController` 通过 PhysicsCheck 左/右检测和 `not on_floor` 计算 `is_on_wall_grab`，将下落速度限制为 `wall_slide_max_speed=140`。跳跃缓冲存在时，贴墙会写入 `wall_jump_vertical_velocity=-560` 与离墙 `wall_jump_horizontal_velocity=380`，并设置 `wall_jump_input_lock=0.10s`，防止持续方向输入立即把玩家拉回墙；同时保留土狼时间、跳跃缓冲和松键短跳。动画使用 `char_blue_2` 的 Wall Slide 24–27 帧，不让动画决定物理真相。单元测试覆盖墙滑必须处于下落且输入朝墙、动作图集语义和输入锁参数；完整左右墙连跳仍需在 640×360 实际关卡中持续试玩。

### 中文课堂第 31 课：滑铲的逻辑和动画的实现

- 课程位置：章节 5 / 第 2 课；`chapterId=640969d6700410001fd8731f`，`sectionId=64096aec700410001fd87326`。
- 播放器实际时长：约 `29:24`（`1763.82s`）。
- 中文课堂独有课时。
- 课时页补充：滑铲期间还要切换 Player 的 Layer，避免与 Enemy 发生碰撞；示例在 `CheckState()` 中让 `isDead || isSlide` 使用 Enemy Layer，否则恢复 Player Layer。

课时内容和滑铲规则：

1. `00:00–05:30` 从人物图集切出滑铲帧并建立 Slide 动画，检查帧序、循环方式和朝向；动画只负责表现，是否正在滑铲由 PlayerController 的 `isSlide` 状态保存。
2. `05:30–10:30` 在输入系统加入 Slide 回调。只有未处于滑铲时才能开始；根据人物朝向和 `slideDistance` 计算目标 X 坐标，再启动 `TriggerSlide(targetPos)` 协程，避免重复输入叠加多个滑铲。
3. `10:30–16:30` 协程逐帧使用刚体位移向目标推进；离地或左右墙检测命中时提前中断，接近目标位置后结束并复位 `isSlide`。这种实现把固定距离、地面条件和墙体阻挡都作为显式终止条件。
4. `16:30–22:30` 配置滑铲动画和碰撞体状态：进入滑铲时调整 Collider 的 offset/size，结束后恢复 Awake 中缓存的原始尺寸；同时按页面补充切换碰撞 Layer，避免滑铲过程中被 Enemy 实体碰撞阻塞。
5. `22:30–27:30` 把滑铲接入人物能量值和状态栏。滑铲消耗 Power，UI 通过 `currentPower / maxPower` 更新能量填充，并在恢复状态中逐步回充；能量不足时不能无限连续滑铲。
6. `27:30–29:24` 回到 PlayerController 整理 `isSlide`、碰撞状态和动画条件，并在 Play 模式验证移动中滑铲、撞墙中断、离地中断、连续输入限制及能量恢复。结尾主要是代码回看与运行确认。

玩家体验与制作影响：滑铲是快速穿越危险区和调整站位的承诺动作。玩家需要预判朝向、剩余能量和落点；关卡应先用宽阔安全地面教学，再用低矮通道或可穿越攻击确认用途，最后与敌人、尖刺和平台边缘组合施压。碰撞体缩放、无敌窗口和实体穿透必须与动画帧同步，否则会出现“看似躲过但仍受击”或卡入墙体的问题。

Godot 项目采用的结论：`PlayerController` 使用 `slide` Input Map action，以 `slide_speed=320` 向朝向侧固定 `slide_distance=140.8px` 目标推进，并保留独立冷却和短无敌窗口。开始时消耗可导出的 `slide_power_cost=20`，该数值是项目默认值，课程画面未提供可核实原值；能量不足不会进入状态或触发冷却。滑铲时身体 Capsule 从高 40 缩到 24，HurtBox 从高 34 缩到 20，均下移以保持脚底基线，同时临时移除敌人攻击/危险层 collision mask。到点、撞墙、离地、超时及所有外部打断都走 `_end_slide()` 统一恢复碰撞、形状和水平速度，音频改用独立 `slide` ID。15 项单测覆盖左右方向、重复输入、Power、碰撞形状/mask、撞墙、离地、冷却与打断恢复；Windows/OpenGL `player_slide.png` 已核对姿态和 HUD 能量反馈。

### 中文课堂第 32 课：摄像机跟随及攻击抖动实现

- 课程位置：章节 6 / 第 1 课；`chapterId=64096c089bebe4001f474edf`，`sectionId=64096c089bebe4001f474ee0`。
- 播放器实际时长：约 `20:47`（`1246.85s`）。
- 课时页没有额外正文提示。

课时内容和摄像机链路：

1. `00:00–05:30` 安装/启用 Cinemachine，创建 Virtual Camera 并把 Player 设为 Follow 目标；通过 Body/Framing Transposer 参数调整跟随阻尼和画面构图，而不是直接把 Main Camera 设为 Player 子节点。
2. `05:30–10:30` 为像素游戏配置 Cinemachine Pixel Perfect，并创建场景 Bounds 的 PolygonCollider2D；Virtual Camera 加入 Cinemachine Confiner 2D，限制相机不显示关卡边界之外的空白区域。
3. `10:30–16:30` 编写 `CameraControl`，缓存 Confiner2D；场景加载后按 Bounds 标签寻找新的边界对象，把它的 Collider2D 写入 `m_BoundingShape2D`，解决切换关卡后仍使用旧边界的问题。
4. `16:30–19:30` 给相机配置 Cinemachine Impulse Listener，并在攻击/命中侧设置 Impulse Source。触发冲击时由监听器叠加短暂噪声位移，抖动结束后自动回到正常跟随位置。
5. `19:30–20:47` 在 Game 视图验证人物移动时的跟随、关卡边缘约束和攻击冲击反馈，检查抖动不会永久改变相机位置或越出 Confiner 范围。

玩家体验与制作影响：跟随相机应优先展示玩家下一步要去的空间，同时减少频繁反向时的晃动。攻击抖动用于强调命中重量，不应在普通移动或每个弱反馈上滥用；强度、持续时间和触发来源需要数据化，并为眩晕敏感玩家保留减弱或关闭选项。关卡边界必须在场景加载完成后立即生效，避免出生首帧看到场外空白。

Godot 项目采用的结论：`CameraControl : Camera2D` 监听 `GameEvents.camera_shake_requested` 与 `after_scene_loaded`，使用 dead zone、指数插值、水平前视和垂直偏移跟随 player 组；场景边界来自 `camera_bounds` 组中的矩形 CollisionShape2D，并按视口尺寸夹紧相机中心。边界计算包含碰撞子节点的偏移、旋转与缩放；地图轴小于 640×360 可见范围时相机固定在该轴中心。受击反馈通过 GameEvents 传入强度和时长，Camera2D offset 使用衰减随机噪声并在结束或零时长请求时归零。7 项相机单测覆盖逻辑视口、dead zone、出生构图、边界刷新/夹紧、小地图居中和抖动归零；Fade 另有 4 项测试覆盖暂停树下仍完成 Tween。Level 2 OpenGL 到达区与 Boss 区截图已检查边界和 HUD 构图。

### 中文课堂第 33 课：音源设置和音效播放

- 课程位置：章节 6 / 第 2 课；`chapterId=64096c089bebe4001f474edf`，`sectionId=64096d0bcdfc640020f7f3cd`。
- 播放器实际时长：约 `23:00`（`1380.05s`）。
- 课时页没有额外正文提示。

课时内容和声音架构：

1. `00:00–06:00` 导入 BGM 与角色/敌人音效，检查压缩、循环和加载设置；在场景中建立 AudioSource，先验证背景音乐可以循环播放、音效可以按动作触发。
2. `06:00–12:30` 创建 Audio Mixer，并把通道整理为 Master、BGM 和 FX 分组。BGM 与效果音分别路由，避免只能用一个总音量同时控制所有声音。
3. `12:30–16:30` 编写 `AudioManager`，持有 BGM/FX 两个 AudioSource，并监听 `PlayAudioEventSO`。启用时订阅事件、禁用时解除订阅；收到 AudioClip 后给对应 Source 赋值并播放，避免场景对象直接查找播放器。
4. `16:30–20:30` 在 Inspector 连接 BGMEvent、FXEvent、两个 AudioSource 与 Mixer 输出组；角色、敌人和场景对象通过事件资产或 AudioDefinition 式组件请求播放，不直接依赖 AudioManager 实例。
5. `20:30–23:00` 在运行态检查背景音乐、攻击/受伤等效果音和 Mixer 电平，确认多次触发不会中断 BGM，场景对象只负责选择音频和发出事件。课程示例仍以单个 FX Source 为主，密集并发音效需要额外池化或 `PlayOneShot` 策略。

玩家体验与制作影响：音频是动作可读性的一部分。移动、攻击、命中、受伤、奖励和环境危险应有不同职责，BGM 不应掩盖关键战斗提示；同类音效需要并发上限、音量/音高变化和优先级，避免快速攻击时互相截断或形成刺耳叠加。暂停、场景切换、设置持久化和无障碍音量选项也必须纳入同一音频契约。

Godot 项目采用的结论：`AudioManager` 通过 `GameEvents.play_bgm_id/play_sfx` 等信号接收稳定内容 ID，使用一个循环 BGM Player 和 8 槽 FX 池；BGM 路由 `Music`、FX 路由 `SFX`，两者发送到 `Master`。三路线性音量写入真实 AudioServer Bus，0 值通过 mute 实现真静音；BGM Player 只承担淡入，FX 满载时抢占最早使用的槽。`slide` 与 `interact` 已使用独立内容 ID，场景加载仍会清理残留 FX。11 项单测覆盖 Bus 路由、真静音、占位 SFX、BGM 循环/节奏、淡入、暂停、停止和销毁后事件。仓库没有课程正式音频文件，因此现有程序生成声音仍明确作为占位，正式录音/授权资产与可听混音验收是外部资产阻塞，不能标为严格完成。

### 中文课堂第 34 课：水和荆棘的逻辑实现

- 课程位置：章节 6 / 第 3 课；`chapterId=64096c089bebe4001f474edf`，`sectionId=64096deb700410001fd87330`。
- 播放器实际时长：约 `07:20`（`440.23s`）。
- 课时页没有额外正文提示。

课时内容和环境危险规则：

1. `00:00–02:30` 把水体视觉 Tilemap 与玩法触发区分开，为水面/水坑增加 Collider/Trigger，并使用 Water 标签标识致命区域。水流动画本身不承担伤害判断。
2. `02:30–04:30` 在 Character 的 `OnTriggerStay2D` 检查 Water 标签，进入水体后把角色送入既有生命归零/死亡事件链，而不是在水对象里直接操作 PlayerController 动画。
3. `04:30–06:00` 为荆棘建立独立场景对象，配置 Sprite、触发 Collider 和已有 Attack 组件；荆棘通过统一攻击入口提供固定伤害，因此仍受 Character 的无敌/受伤规则约束。
4. `06:00–07:20` 在 Play 模式分别测试落入水体和接触荆棘：水体触发死亡流程，荆棘扣除生命并显示 HUD 变化。课程没有展开复活点、持续接触频率、击退方向或环境危险音画反馈。

玩家体验与制作影响：水和荆棘必须在玩家承诺动作前清楚可读。致死水域需要安全边缘、明确落点和快速重试；可受伤荆棘需要预警轮廓、受击反馈与无敌窗口，不能因每物理帧重复伤害瞬间清空生命。关卡应先在低惩罚位置单独介绍，再与跳跃、滑铲或敌人压力组合；检查点要控制重复路程。

Godot 项目采用的结论：项目已把水体视觉与玩法触发分离，并新增独立 `water_hazard.tscn`、`thorn_hazard.tscn` 与 `EnvironmentHazard : Area2D`。当前项目默认采用固定 1 点伤害、`0.75s` 每目标间隔且不可格挡，伤害统一经过目标 `take_damage()`；滑铲仍按玩家既有无敌规则忽略 Hazard 层。Level 2 已放置可见水域危险区，2 项单测覆盖统一伤害入口、间隔和 HurtBox 去重，Windows/OpenGL `level_2_water_hazard.png` 已检查视觉区域与触发范围。课程没有给出持续接触精确数值，因此这些参数是项目批准默认值，不冒充课程原值。

### 中文课堂第 35 课：人物可互动标识

- 课程位置：章节 7 / 第 1 课；`chapterId=64096e626391b600208067da`，`sectionId=64096e626391b600208067db`。
- 播放器实际时长：约 `27:16`（`1636.14s`）。
- 课时页没有额外正文提示。

课时内容和交互提示链：

1. `00:00–06:30` 从按键/设备素材中切出交互图标，在 Player 下创建 Sign 子对象并放到角色头顶附近；先在场景视图确认提示大小、锚点和像素清晰度。
2. `06:30–12:30` 为 Sign 建立出现/待机动画和 Animator 参数，使提示在进入可交互范围时有短促出现反馈，而不是毫无过渡地常驻画面。
3. `12:30–18:30` 给 Player 增加 Trigger 检测区并编写 `Sign`。脚本缓存提示对象/Animator，通过 `canPress` 控制 SpriteRenderer 显隐；检测到带 `Interactable` 标签的 Collider 时允许显示，离开后关闭。
4. `18:30–23:30` 处理人物左右翻转：提示对象的局部缩放跟随 Player 反向修正，保证按键图标/文字不会随角色 Sprite 镜像成反字。
5. `23:30–27:16` 把 Chest 标为 Interactable 并在运行态测试：远离时无提示，进入范围提示出现，换向后仍保持正确朝向，离开范围后消失。本课只完成“可以交互”的可见信号，实际动作在下一课接入。

玩家体验与制作影响：交互提示只应回答“现在可以做什么”，不应抢占移动和战斗视线。提示应在玩家进入有效距离后稳定出现，离开后及时消失；多个对象重叠时必须有确定的目标选择规则。键鼠、手柄和未来触屏图标应来自当前输入设备映射，不能永远显示固定键位。

Godot 项目采用的结论：玩家场景的 `Sign : Area2D` 使用 CircleShape 检测区和课程 HUD `GameButtons.png` 的 16×16 Prompt；脚本监听 body/area 进入退出，仅在输入启用、角色存活且未暂停时显示，并修正提示的水平缩放。可交互对象以 WeakRef 候选集合登记，每帧清理失效引用并选择最近目标；当前目标离开后会自动回退到剩余候选，不受进入顺序影响。`player.tscn` 已配置独立 PromptAnimationPlayer，show/hide 只改变 alpha 与 Y 偏移，不与朝向 scale 冲突。Sign 使用 ALWAYS process，在 SceneTree 暂停时禁止交互并收起提示。4 项单测覆盖最近目标、退出回退、暂停隐藏和动画轨道契约，Windows/OpenGL `player_interaction_prompt.png` 已核对图标、位置和场景遮挡。

### 中文课堂第 36 课：场景互动的逻辑实现

- 课程位置：章节 7 / 第 2 课；`chapterId=64096e626391b600208067da`，`sectionId=64096eb99bebe4001f474ee3`。
- 播放器实际时长：约 `18:41`（`1121.00s`）。
- 课时页没有额外正文提示。

课时内容和交互协议：

1. `00:00–05:30` 为 Chest 配置交互 Trigger，并在 Sign 中增加 Input System 的 Interact 回调。`Update()` 继续只负责提示显隐/朝向，输入触发与范围检测分离。
2. `05:30–10:30` 定义 `IInteractable` 接口及 `TriggerAction()`，让 Sign 缓存当前范围内对象的接口引用；按下 interact 时只调用协议，不需要知道目标是宝箱、门还是传送点。
3. `10:30–14:30` 让 `Chest : MonoBehaviour, IInteractable` 实现 `TriggerAction()`，从调试输出逐步替换为 `OpenChest()`；打开时切换打开 Sprite/状态，并避免同一宝箱反复执行。
4. `14:30–18:41` 在 Inspector 连接 Player Input 的 Interact 回调，进入 Play 模式验证提示、按键、宝箱打开和离开范围。课程完成的是最小交互闭环，没有奖励生成、存档恢复、多个目标选择或失败反馈。

玩家体验与制作影响：交互必须满足“看见提示—按下动作—立即反馈—状态持久”的闭环。宝箱打开后应明确给出动画、音效、奖励和不可重复状态；无效输入不能静默让玩家怀疑按键失效。若多个目标同时可用，应按距离/朝向或优先级选择，并把选择结果通过提示位置或高亮表达。

Godot 项目采用的结论：项目以 `IInteractable` 命名约定和 `trigger_action()` 鸭子类型替代 C# interface。Sign 的 `_unhandled_input()` 读取 `interact` action，调用最近的缓存目标并广播独立 `interact` 音效 ID；Chest 实现一次性打开、动画、SFX、Loot 表、PlayerProgression 奖励、通知 UI、碰撞关闭和 ISaveable 持久化。`CollectibleReward` 与 `Breakable` 进一步覆盖自动拾取和攻击破坏奖励。测试已验证宝箱奖励只发一次、打开状态写入存档、稳定 ID、收集物去重及加载后移除；Sign 自身的重叠候选/最近目标和 Prompt 动画也已有确定性测试与可视截图。完整“真实输入按键→目标副作用”的设备级录制仍可在最终可执行候选包上补做，但不再是规则实现缺口。

### 中文课堂第 37 课：场景管理和切换

- 课程位置：章节 7 / 第 3 课；`chapterId=64096e626391b600208067da`，`sectionId=64096fb84b7731001f66a5eb`。
- 播放器实际时长：约 `28:15`（`1694.63s`）。
- 课时页没有额外正文提示。

课时内容和加载架构：

1. `00:00–06:30` 安装并初始化 Unity Addressables，把地点场景加入 Addressables 分组；课程把 Player、相机、UI 和 Manager 保留在持久场景中，关卡地点场景单独以 Additive 方式加载。
2. `06:30–12:30` 整理 Forest 等地点场景的根结构与边界，创建 `GameSceneSO` 保存 `SceneReference`、场景类型和显示信息，业务对象不再散落字符串场景名。
3. `12:30–18:30` 创建携带 `GameSceneSO locationToLoad`、`Vector3 positionToGo` 和 `bool fadeScreen` 的场景加载事件通道；传送点只发请求，不直接调用 SceneManager。
4. `18:30–24:00` 编写持久 `SceneLoader`：启动时用 Addressables 加载 firstLoadScene；启用/禁用时订阅加载请求，收到请求后缓存目标场景、出生坐标与淡入参数，并启动 `UnloadPreviousScene()` 协程。
5. `24:00–28:15` 协程按需等待淡入时长，卸载 `currentLoadedScene.sceneReference`，再异步加载新地点场景。课程开始建立 `isLoading` 防重入和当前场景句柄，但加载后的放置与事件刷新留到下一课。

玩家体验与制作影响：场景切换不是单纯换地图，而是“提交离开—遮蔽加载—在明确入口恢复控制”的完整过渡。玩家应在交互后立即得到反馈，不能在黑屏前继续移动或重复触发；新场景必须保持正确朝向、出生位置、HUD、相机边界和音频状态。场景元数据要使用稳定内容 ID/资源引用，才能支撑存档、继续游戏和旧版本迁移。

Godot 项目采用的结论：项目使用 `GameSceneResource.tres` 保存 `scene_path/display_name/scene_type`，TeleportPoint 通过 `GameEvents.scene_load_requested` 传递资源、二维出生坐标和淡入选项。SceneLoader 是 Autoload，负责切换前捕获存档状态、工作线程加载 PackedScene、`change_scene_to_packed()` 和加载锁；由于 Godot 4.7 的 threaded request 泄漏回归，当前实现明确避开 `load_threaded_request()`，使用自持 Thread + `ResourceLoader.load()`。与课程的 Additive 持久 Player 架构不同，Godot 每个地点场景包含自己的 Player/UI/Camera，只有 Autoload 服务跨场景持久；因此每个可加载场景必须满足相同入口契约。SceneLoader 现以 IDLE/FADING_TO_BLACK/LOADING/REVEALING 表达业务阶段，`_is_loading` 忽略并发请求；单元测试检查线程策略、淡入前不启动加载与并发保护，e2e 覆盖菜单、Demo、Level2 往返和回菜单。

### 中文课堂第 38 课：场景加载后的执行逻辑

- 课程位置：章节 7 / 第 4 课；`chapterId=64096e626391b600208067da`，`sectionId=640971199bebe4001f474ee5`。
- 播放器实际时长：约 `18:15`（`1095.49s`）。
- 课时页没有额外正文提示。

课时内容和完成回调：

1. `00:00–05:00` 给传送点配置目标 GameSceneSO、目标坐标和是否 Fade；运行时先暴露了旧场景卸载后、新场景激活前只剩持久 Player/UI 的空画面，说明加载时序必须由遮罩覆盖。
2. `05:00–09:30` 使用 `Addressables.LoadSceneAsync(..., LoadSceneMode.Additive, true)` 获取异步句柄，并把 `OnLoadCompleted` 注册到 `Completed`，避免在场景对象尚未实例化时提前访问出生点或边界。
3. `09:30–12:30` 补正 Sign 的 Confirm 回调：只有 `canPress` 时调用 `targetItem.TriggerAction()`，并播放交互 AudioDefinition，使传送请求与提示/音效形成闭环。
4. `12:30–16:30` 在 `OnLoadCompleted` 保存新的 `currentLoadedScene`，把持久 Player 移到 `positionToGo` 并重新激活；随后清除 `isLoading`。加载期间 Player 会暂时关闭，防止黑屏或空场景阶段继续输入。
5. `16:30–18:15` 增加 `AfterSceneLoadedEvent`，在场景、玩家位置和可用状态全部就绪后发出，让相机边界、UI 或其他持久系统重新解析新场景依赖。淡出逻辑仍由下一课补齐。

玩家体验与制作影响：出生点必须是加载完成后的第一个可信玩法状态。相机、HUD、输入、碰撞和音频只能在新场景与玩家坐标都就绪后恢复；若先发事件再放置玩家，会产生首帧相机跳动、错误边界或存档坐标覆盖。加载失败也需要恢复输入、显示错误或安全返回菜单，不能永久停留黑屏。

Godot 项目采用的结论：`change_scene_to_packed()` 后，SceneLoader 等到下一帧 `_finish_scene_change()`，先锁定新场景 Player，再应用请求坐标和延迟存档恢复；随后请求揭幕并等待完成，按“位置/数据恢复→揭幕→after_scene_loaded→输入解锁”收尾。CameraControl、AudioManager 和 PlayerMapPanel 在通知阶段刷新，而玩家只在这些依赖稳定后恢复控制。加载或 `change_scene_to_packed()` 失败时不会切走原场景，SceneLoader 会先揭开黑屏、再恢复原 Player 输入并清理请求状态。单元测试已覆盖严格顺序、并发请求和真实 0.4 秒失败回滚；e2e 等待 `is_transition_active()` 归零后再操作，并覆盖 Demo↔Level2、回菜单与 Continue。

### 中文课堂第 39 课：场景淡入淡出效果

- 课程位置：章节 7 / 第 5 课；`chapterId=64096e626391b600208067da`，`sectionId=6409743074ae5600200ce011`。
- 播放器实际时长：约 `17:48`（`1067.75s`）。
- 课时页明确列出“DOTween 插件安装和使用”“Image 组件实现 Fade 效果”。

课时内容和淡入淡出时序：

1. `00:00–05:30` 安装/配置 DOTween，在持久 Main Canvas 上创建覆盖全屏的黑色 Fade Image，使用 Stretch 锚点保证不同分辨率都能完全遮蔽场景。
2. `05:30–10:30` 调整 Image 初始颜色和 Alpha，在运行态确认全黑/透明两种端点；遮罩位于普通 HUD 之上，场景卸载产生的空画面不再直接暴露。
3. `10:30–14:30` 创建 `FadeEventSO`，用目标颜色和持续时间广播 Fade 请求；SceneLoader 在卸载旧地点前发出淡入黑屏，在 OnLoadCompleted 放置玩家后发出淡出透明，并最后 Raise AfterSceneLoaded。
4. `14:30–16:30` 编写 `FadeCanvas` 监听器，持有 UI Image，通过 DOTween `DOBlendableColor(target, duration)` 插值颜色，避免每帧手写 Alpha 状态机。
5. `16:30–17:48` 在 Play 模式往返场景，确认遮罩先覆盖、旧场景卸载、新场景加载、玩家定位、遮罩揭开；结尾主要是最终运行验证。

玩家体验与制作影响：Fade 的职责是隐藏不可信加载状态并清楚表达空间转换，不应成为无意义等待。淡入持续时间要足够覆盖卸载，但不拖慢频繁往返；淡出前必须保证出生点和相机稳定。过渡期间应阻止玩家输入和重复交互，并为慢盘加载保留持续黑屏或加载提示，而不是固定延时后提前揭开空场景。

Godot 项目采用的结论：`FadeCanvas : CanvasLayer` 在 layer 100 创建全屏 ColorRect，监听带颜色、时长和方向的 `GameEvents.fade_requested`，用原生 Tween 插值，因此无需引入 DOTween 类依赖；Tween 设置为暂停时仍处理，并会取消前一次未完成 Tween。SceneLoader 在覆盖黑屏前锁定旧 Player，等待 `0.4s` 后启动后台加载；新场景定位和存档恢复完成后再请求透明，揭幕完成才广播 AfterSceneLoaded 并解锁新 Player。FadeCanvas 的 `MOUSE_FILTER_IGNORE` 只表达它不承担业务输入规则，输入真相由 SceneLoader 管理。4 项 Fade 单测覆盖零/非零时长、不同颜色、最新请求取消旧 Tween以及暂停树下仍完成；SceneLoader 另有 7 项测试和 E2E 覆盖转场顺序、并发忽略与失败恢复。

### 中文课堂第 40 课：主场景制作

- 课程位置：章节 7 / 第 6 课；`chapterId=64096e626391b600208067da`，`sectionId=640975324b7731001f66a5f5`。
- 播放器实际时长：约 `23:59`（`1439.40s`）。
- 课时页提示 Canvas Scaler 使用固定参考分辨率，示例为 `1920×1080`。

课时内容和菜单构成：

1. `00:00–06:30` 以已有森林地点作为主菜单的动态背景，让菜单进入游戏世界本身，而不是单独的纯色工具页；整理相机、角色和环境层，使背景在菜单状态下仍有轻量生命感。
2. `06:30–12:30` 在 Canvas 上制作游戏标题和半透明菜单区域，建立清晰的标题层、操作层与背景层；Canvas Scaler 固定参考分辨率，避免窗口变化导致按钮位置和比例失控。
3. `12:30–18:30` 创建“新的冒险 / 继续 / 退出”三个按钮，配置 TextMeshPro 字体、字号、间距和按钮状态，使键鼠与手柄导航都有确定顺序。
4. `18:30–22:00` 调整菜单整体构图和按钮导航，在运行态检查标题、背景角色、按钮可读性与选中状态；半透明面板用于提高文字对动态背景的对比度。
5. `22:00–23:59` 补充场景加载期间的输入管理：收到加载请求时关闭 Player Input，`AfterSceneLoaded` 后再恢复，避免转场期间移动、攻击或重复触发交互。

玩家体验与制作影响：主菜单是玩家第一次判断游戏气质、可读性和控制方式的场景。动态背景可以提前建立冒险氛围，但不能抢走按钮对比度；默认焦点、禁用态和手柄导航必须无需鼠标也能完成。进入游戏后只能在新场景、出生点、相机和淡出都可信时恢复控制。

Godot 项目采用的结论：`warrior_menu.tscn` 已有标题、“新的冒险 / 继续游戏 / 退出”、音量与语言切换，Control 使用全屏锚点，符合项目 `640×360` 逻辑视口和整数缩放基线；`MainMenu` 也会根据存档启用继续按钮并设置默认焦点。菜单现复用课程 `Legacy-Fantasy-High Forest` 的 `Green-Tree.png` 建立三层循环森林景深，并通过 AnimationPlayer 缓慢移动各层；按钮区使用半透明承载面板保证文字对比，没有引入课程外素材。3 项菜单资源契约测试保护课程纹理、三层 Parallax、循环动画、640×360 遮罩和既有导航路径，Windows/OpenGL `warrior_menu.png` 已检查标题、按钮、禁用态和场景遮挡。转场输入封锁继续由 SceneLoader 的显式阶段负责，FadeCanvas 不作为输入规则来源。

### 中文课堂第 41 课：实现“新的冒险”逻辑

- 课程位置：章节 7 / 第 7 课；`chapterId=64096e626391b600208067da`，`sectionId=6409763f4b7731001f66a5fa`。
- 播放器实际时长：约 `16:36`（`996.18s`）。
- 课时页补充：Character 即使新增 New Game 函数，仍要在 `Start()` 中执行 `currentHealth = maxHealth`，保证敌人等普通 Character 出生时有正确血量。

课时内容和新游戏流程：

1. `00:00–04:30` 创建 `StartNewGame Event`，由菜单按钮发出新冒险请求；菜单只表达玩家意图，不直接散落场景加载细节。
2. `04:30–08:30` 把新游戏事件连接到默认地点加载，让场景管理器按既有加载、出生位置和淡入淡出流程进入第一张地图。
3. `08:30–12:30` 为 Player/Character 连接 New Game 初始化，重置玩家本轮状态；同时保留 Character 在 `Start()` 的最大生命值初始化，避免只监听新游戏事件的 Player 正常、普通敌人却以零血量出生。
4. `12:30–15:00` 在菜单 `OnEnable()` 中把当前 EventSystem 选中对象设为 New Game 按钮，保证菜单重新启用或手柄进入时有明确焦点。
5. `15:00–16:36` 实现 Exit：编辑器内输出调试信息，正式运行调用 `Application.Quit()`；最后回到场景验证新游戏、默认焦点和退出入口。

玩家体验与制作影响：“新的冒险”必须建立完全干净且可预测的新会话，不能继承上一局的生命、奖励、场景对象或存档内存态。菜单按下后要立即给出选中/转场反馈，并在加载完成前禁止重复提交。继续游戏与新游戏必须是两条明确的数据路径；默认焦点则保证玩家用键盘或手柄打开菜单后可以马上操作。

Godot 项目采用的结论：`MainMenu` 发出 `GameEvents.new_game_started`，`DataManager` 清空内存数据，PlayerController 与 PlayerProgression 分别重置运行态，`MenuFlow` 再把事件转换成带 `GameSceneResource` 的默认关卡加载请求；继续游戏则读取存档场景并走独立事件。退出使用 `get_tree().quit()`。这比课程示例更明确地分离了 UI、数据和场景职责。当前默认焦点策略优先选择可用的“继续游戏”，无存档时才选“新的冒险”，与课程始终选 New Game 不同但有合理依据。DataManager 单测已验证新游戏事件清空旧坐标、数值、场景和加载状态；SceneLoader 单测覆盖转场并发忽略；E2E 同时覆盖新游戏进入 Demo 与 Continue 恢复场景、位置、生命、能量和 HUD。`get_tree().quit()` 不在单元测试中调用，退出按钮的存在和导航由菜单场景契约与实际截图验证。

### 中文课堂第 42 课：存储点及画面效果

- 课程位置：章节 8 / 第 1 课；`chapterId=64097bb5358e970020afe81e`，`sectionId=64097811cdfc640020f7f3e5`。
- 播放器实际时长：约 `20:43`（`1242.75s`）。
- 课时页补充：为避免 Sign Sprite 与岩石子物体交叉排序穿帮，应在 Save Point Rock 上添加 Sort Group，把根与子物体作为整体参与叠层排序。

课时内容和存储点反馈：

1. `00:00–04:30` 从岩石和发光符号素材组装 Save Point，准备熄灭/点亮两套 Sprite，并让脚本缓存 SpriteRenderer；存储点首先要能在远处被识别为特殊交互物。
2. `04:30–09:00` 让 SavePoint 实现 `IInteractable`，触发后切换为点亮状态并设置已激活标志；课程借用 Chest 的一次性状态写法，避免反复执行首次激活逻辑。
3. `09:00–13:30` 在场景中配置碰撞、提示和运行验证，确认玩家进入范围能交互，激活后符号发生明显变化；本课先建立存储点的状态和反馈，实际数据结构在下一课继续。
4. `13:30–18:30` 配置 Post Processing Volume，通过 Vignette、Color Adjustments 等效果调整场景整体气氛，并围绕存储点制作更集中的亮暗/色彩对比，让激活对象在洞穴环境中清楚可读。
5. `18:30–20:43` 检查存储点根、岩石和 Sign 子物体的排序，使用 Sort Group 避免玩家经过时子 Sprite 分别插入其他物件层级；结尾在场景中验证组合物件与画面效果。

玩家体验与制作影响：存储点必须同时表达“这里可以保存”“是否已经激活”“保存是否成功”。只有写文件而没有光效、动画、音效或 HUD 回执会让玩家不确定进度是否安全；反过来，持续强烈后处理也会污染战斗可读性。首次激活奖励、重复使用、恢复生命、重生点更新和失败重试规则需要由设计明确，并与实际持久化成功/失败状态一致。

Godot 项目采用的结论：`SavePoint : Area2D` 已实现真实 Interactable 范围和 inactive/saving/active 规则状态。视觉严格使用课程素材族：Props-Rocks 岩石作为底座，SignCharacters 同一 X 符号的深色/青色区域分别作为熄灭与点亮 Sprite，并用 CanvasGroup 对应课程 Sort Group，未生成或手绘替代符号。触发时先让 DataManager 采集激活态，写盘成功后才确认激活、播放专用音效 ID、显示“进度已保存”并发首次奖励；失败则回滚首次激活、不给奖励并明确提示磁盘问题。重复交互仍会保存但不会重复给首次奖励，读档会恢复亮态，同时兼容旧场景路径键。自动化覆盖成功、失败、重复激活、旧档和交互层契约；Windows/OpenGL 截图覆盖未激活、已激活、成功和失败四态。当前声音仍是 AudioManager 生成的占位音，正式录制音频归入独立音频管线任务。

### 中文课堂第 43 课：数据结构及坐标保存加载

- 课程位置：章节 8 / 第 2 课；`chapterId=64097bb5358e970020afe81e`，`sectionId=6409797a9bebe4001f474ef6`。
- 播放器实际时长：约 `30:16`（`1816.15s`）。
- 课时页补充：给 DataManager 添加 `[DefaultExecutionOrder(-100)]`，保证它先于其他注册 ISaveable 的脚本创建；否则对象在 `OnEnable()` 注册时会遇到空引用。

课时内容和存档协议：

1. `00:00–06:30` 从存储点触发需求反推通用 `Data` 容器，建立角色坐标字典、浮点值字典和场景信息等字段；数据结构负责表达状态，不让每个对象自行决定文件格式。
2. `06:30–13:00` 定义 `ISaveable` 接口，包含注册、注销、`GetSaveData(Data)` 和 `LoadData(Data)`；可持久化对象只负责把自身状态写入共享 Data 或从中恢复。
3. `13:00–19:00` 创建 `DataDefinition`，为场景对象提供稳定字符串 ID；位置等数据以 ID 为键写入字典，避免直接依赖对象引用或临时运行实例。
4. `19:00–25:30` 编写单例 DataManager，维护 `List<ISaveable>` 和当前 Data；启用时订阅保存事件，提供去重注册/注销，保存时遍历所有已注册对象采集状态。
5. `25:30–30:16` 让 Character 接入 ISaveable：用 DataDefinition ID 将 `transform.position` 写入 `characterPosDict`，加载时按同一 ID 恢复坐标；运行态验证移动后保存、改变位置、加载回原坐标。

玩家体验与制作影响：坐标保存的真正契约是“同一个内容对象在未来版本仍能被识别”，而不只是当前运行能取到 Transform。稳定 ID、注册顺序和加载时机一旦错误，玩家会在错误地点出生、对象状态串位或继续游戏失败。保存与加载应有明确成功/失败反馈，并对重复 ID、缺失对象和旧版本字段提供可诊断处理。

Godot 项目采用的结论：项目已有共享 Dictionary Schema、DataManager 注册表、`get_save_data/load_save_data` 鸭子协议和 `PersistenceKeyUtility`；PlayerController 按稳定键保存二维位置，Character、SavePoint、敌人、宝箱、破坏物和收集物都接入同一协议。DataManager 是 Autoload，因此初始化顺序天然早于普通场景节点，避免了课程的 MonoBehaviour 单例竞态。项目增加 `schema_version`、损坏文件隔离、1 MiB 上限和可测试路径覆盖；缺少版本号或 v0 的 `sceneToSave`、`characterPosDict`、`floatDataDict` 等课程旧字段会迁移到 v1 后再校验，未来版本则安全拒绝。当前保留的结构风险是缺少 DataDefinition 时 `PersistenceKeyUtility` 会回退节点路径，场景重组仍需显式 legacy key。DataManager 11 项单测覆盖原子写盘、延迟注入、v0 迁移、角色坐标/浮点往返、未来版本、错误字段、超大文件和损坏隔离。

### 中文课堂第 44 课：人物数值及场景的保存加载

- 课程位置：章节 8 / 第 3 课；`chapterId=64097bb5358e970020afe81e`，`sectionId=64097af0700410001fd87337`。
- 播放器实际时长：约 `16:36`（`995.82s`）。
- 课时页没有单独正文提示；讨论区再次指出 DataManager 执行顺序会影响 SceneLoader 注册，并提醒跨场景预制对象需要在新场景加载完成后重新注入持久数据。

课时内容和继续游戏流程：

1. `00:00–05:30` 扩展 Character 的 `GetSaveData()`，除位置外，把当前生命和能量按 `ID + health/power` 键写入浮点字典；首次遇到键时添加，已有键时覆盖。
2. `05:30–09:00` 在 `LoadData()` 中恢复位置、生命和能量，并主动 Raise/Invoke 生命变化事件，让 HUD 在数据注入后立即刷新，而不是显示加载前的默认满血。
3. `09:00–12:30` 让 SceneLoader 也实现 ISaveable，保存当前加载的地点 GameSceneSO；场景服务成为存档的一部分，但仍通过场景资源而不是裸字符串按钮逻辑完成跳转。
4. `12:30–15:00` 实现继续游戏：从 Data 取玩家 ID 对应坐标与已保存场景，组装正常加载请求并启用 Fade；新地点加载完成后，再让场景中的可持久化对象读取各自数据。
5. `15:00–16:36` 在运行态保存人物数值和地点，返回菜单后继续游戏，验证场景、位置、生命/能量和 HUD 状态恢复；结尾展示 SceneLoader 的 Get/LoadData 实现。

玩家体验与制作影响：继续游戏必须恢复一个内部一致的世界快照，而不是仅把玩家传送回某个坐标。场景先加载、对象后注册、数据再注入、HUD 最后刷新，这一顺序需要明确；否则会出现首帧满血后跳变、宝箱复活、敌人状态丢失或出生位置被默认入口覆盖。新游戏还必须清除旧持久数据，不能把继续游戏的快照带入新会话。

Godot 项目采用的结论：Character 用稳定键保存生命/能量，PlayerController 保存位置，DataManager 保存当前场景元数据，MenuFlow 的继续按钮读取已保存场景路径并请求 SceneLoader；PlayerStatBar 通过生命变化信号刷新。与课程不同，SceneLoader 本身未实现 ISaveable，当前场景由场景对象在存档采集阶段调用 DataManager 记录，职责仍可接受。现有 e2e 覆盖菜单进入 Demo、场景往返和存档点写盘，但没有真正执行“受伤/耗能→保存→回菜单→继续→恢复场景、坐标、数值和对象状态”的完整重启流程。`load_from_disk()` 只对当时已注册的 saveable 注入数据，新场景稍后实例化的对象能否自动读取内存数据依赖各自生命周期实现，需补跨场景加载顺序测试；这与课程讨论区暴露的问题一致。

### 中文课堂第 45 课：制作游戏结束面板

- 课程位置：章节 8 / 第 4 课；`chapterId=64097bb5358e970020afe81e`，`sectionId=64097bd574ae5600200ce038`。
- 播放器实际时长：约 `20:52`（`1251.97s`）。
- 课时页没有额外正文提示。

课时内容和失败恢复：

1. `00:00–05:30` 在主 Canvas 上创建 Game Over 面板，包含标题、半透明背景和“重新开始 / 返回菜单”按钮；默认隐藏，保持正常 HUD 不受影响。
2. `05:30–10:00` 创建 Game Over 事件并连接玩家死亡流程，角色死亡后禁用输入、显示面板；在 Player Input/事件资产中配置死亡与 UI 回调。
3. `10:00–14:30` 给 UIManager 增加面板引用和事件订阅，收到 Game Over 时显示面板，并通过 EventSystem 默认选中 Restart 按钮，保证键盘/手柄可以立即重试。
4. `14:30–18:30` 扩展 SceneLoader 的 New Game、Back To Menu 等流程；重新开始走已保存场景/加载事件，返回菜单则卸载地点并加载 Menu 场景，继续复用 Fade 和场景服务。
5. `18:30–20:52` 在 UIManager 中处理面板开启/关闭、默认焦点和场景切换后的复位，运行验证玩家死亡、面板出现、按钮导航、重新进入关卡及返回菜单。

玩家体验与制作影响：失败界面不是死亡提示文字，而是“理解失败—选择恢复策略—安全回到可玩状态”的闭环。重试应明确说明从最近存储点、当前场景入口还是新游戏开始，并保留/回滚正确的数据；返回菜单不能留下暂停、输入锁、死亡动画或半透明遮罩。按钮必须有默认焦点，且失败原因、损失和可恢复内容应在玩家做决定前可理解。

Godot 项目采用的结论：PlayerController 死亡后禁用输入/碰撞、播放死亡动画并发出 `GameEvents.game_over`；常驻 `GameplayOverlay` 订阅该事件，暂停场景树并显示带默认焦点的“重新开始 / 返回主菜单”。重试通过 `SceneLoader.restart_requested` 重新装载当前 `GameSceneResource`，使用关卡默认出生点；返回菜单同样复用 SceneLoader/Fade，完成后清理暂停和输入锁。角色单测覆盖死亡/复活规则，UIManager、SceneLoader 与 E2E 覆盖重试、回菜单和转场恢复，Windows/OpenGL `gameplay_game_over.png` 已核对 640×360 下的按钮可读性与遮挡。

### 中文课堂第 46 课：序列化保存数据文件

- 课程位置：章节 8 / 第 5 课；`chapterId=64097bb5358e970020afe81e`，`sectionId=64097c3d4b7731001f66a600`。
- 播放器实际时长：约 `18:03`（`1083.01s`）。
- 本课为中文课堂独有内容；讨论区明确提到依赖包 `com.unity.nuget.newtonsoft-json`，也有人反馈保存瞬间崩溃，说明文件写入失败必须有诊断和保护。

课时内容和文件持久化：

1. `00:00–04:30` 安装/启用 Newtonsoft.Json，并再次检查 DataManager 的生命周期和事件连接；内存中的 Data 只有写入持久目录后，退出进程再继续游戏才成立。
2. `04:30–08:00` 设置 DataManager 的 Script Execution Order，保证它早于其他对象注册；建立 `Application.persistentDataPath` 下的保存目录、文件名与最终 `data.sav` 路径。
3. `08:00–12:30` 保存时先让全部 ISaveable 写入共享 Data，再用 `JsonConvert.SerializeObject(saveData)` 得到 JSON；目录不存在则创建，最后 `File.WriteAllText(resultPath, jsonData)` 写盘。
4. `12:30–15:30` 加载时先判断文件是否存在，读取文本并反序列化为 Data，再遍历 saveable 调用 `LoadData()`；没有文件时保持新游戏默认状态。
5. `15:30–18:03` 处理 Unity `Vector3` 不能直接按期望格式持久化的问题，创建 `SerializableVector3` 包装和隐式转换，角色坐标字典改用可序列化类型；运行验证保存文件和重新加载。

玩家体验与制作影响：磁盘存档必须是原子、可恢复和可诊断的。玩家不应因断电、磁盘满、权限失败或版本升级丢掉唯一进度；写盘成功后才应播放“保存完成”反馈。文本 JSON 便于调试但也容易被篡改，单机项目可以接受可编辑性，却仍需要 schema、备份和损坏隔离。

Godot 项目采用的结论：DataManager 使用 `user://SAVE_DATA/data.sav`、内置 `JSON.stringify/parse_string` 与 FileAccess；Vector2/Vector3 显式展开为 `{x,y,z}`。写盘先校验字段和 1 MiB 上限，写入 `.tmp` 并 flush/close，再把旧主文件轮换为 `.previous` 后提交；失败会广播 `save_completed(false)`，SavePoint 回滚激活、不发首次奖励并显示失败反馈。读盘先检查大小，再执行 v0→v1 迁移与场景/坐标/浮点字段校验；无效或未来版本隔离到 `.bak`，不注入运行态。11 项 DataManager、4 项 SavePoint 单测和 E2E Continue 路径覆盖这些规则；Web IndexedDB 和真实磁盘满仍需目标平台验证。

### 中文课堂第 47 课：实现移动设备屏幕操控

- 课程位置：章节 9 / 第 1 课；`chapterId=64099278c747e7001fd898d8`，`sectionId=6409924bd8132400201006d7`。
- 播放器实际时长：约 `11:29`（`689.30s`）。
- 课时页没有额外正文提示。

课时内容和触屏输入：

1. `00:00–03:30` 在 HUD 中建立 Mobile Touch 根节点，按左右拇指区域规划控件，左侧保留移动摇杆、右侧放置跳跃/攻击等动作按钮。
2. `03:30–06:30` 使用 On-Screen Stick 制作半透明虚拟摇杆，设置背景、摇杆柄、移动范围、锚点和触摸区域；UI 只生成 Input System 输入，不直接调用 Player 移动函数。
3. `06:30–08:30` 创建 On-Screen Button，把不同彩色按钮绑定到 Jump、Attack 等既有 Input action；键盘、手柄和触屏因此共用同一玩法状态机。
4. `08:30–10:00` 在 UIManager 暴露 `mobileTouch`，根据运行平台或设备条件显示/隐藏触屏 UI，避免桌面端常驻遮挡画面。
5. `10:00–11:29` 配置 Unity Remote/移动设备连接，在真机画面中检查摇杆和按钮响应、分辨率与操作区域。

玩家体验与制作影响：触屏不是把键盘按钮平铺到屏幕上。拇指可达范围、按钮容错、同时按移动/跳跃/攻击、横屏安全区、不同宽高比和遮挡战斗区域都需要真机测试。所有输入仍应转换成统一 action，避免移动端产生另一套角色逻辑。

Godot 项目采用的结论：当前目标平台明确为 Windows/Linux PC，因此不应为贴近课程新增触屏 HUD、移动导出依赖或另一套玩家控制。项目已坚持 Input Map action，未来若扩展移动端可用 `TouchScreenButton`/虚拟摇杆映射到现有 action；`SafeAreaInsetAnchor` 也提供安全区基础。当前没有任何 TouchScreenButton、虚拟摇杆或移动端显隐实现，这对当前范围不是缺陷。值得保留的验收要求是：若平台范围变化，必须在实际手机上验证多指并发、屏幕旋转、刘海安全区、UI 遮挡和帧率，不能仅在桌面模拟鼠标点击。

### 中文课堂第 48 课：暂停面板及声音控制

- 课程位置：章节 9 / 第 2 课；`chapterId=64099278c747e7001fd898d8`，`sectionId=640993b8fbd8c8001fa20189`。
- 播放器实际时长：约 `19:21`（`1160.92s`）。
- 课时页没有额外正文提示。

课时内容和暂停/音频设置：

1. `00:00–05:30` 在主 Canvas/HUD 中创建暂停入口和 Pause Panel，配置半透明背景、继续、声音设置与返回菜单等操作；面板默认隐藏，并兼顾移动端暂停按钮。
2. `05:30–10:00` 建立 Pause 事件和 UIManager 面板切换：打开时显示面板、设置默认焦点并把 `Time.timeScale` 设为 0，关闭时恢复为 1；暂停 UI 自身需要使用不受时间缩放影响的交互。
3. `10:00–13:30` 创建 Audio Mixer，把 Master/Music/SFX 等声音分组暴露为可调参数，确保暂停时仍能操作设置，而不是直接停止所有 AudioSource。
4. `13:30–17:00` 给暂停面板加入 Slider/开关，通过事件把 UI 值同步到 Mixer 参数；音量通常需要从线性 Slider 转为分贝，并在重新打开面板时回填当前值。
5. `17:00–19:21` UIManager 订阅音量同步事件，`OnSyncVolumeEvent(float amount)` 更新 Mixer；`TogglePausePanel()` 负责面板显隐、Pause 事件和 Time Scale，运行验证暂停、继续、声音变化与按钮导航。

玩家体验与制作影响：暂停必须冻结所有会改变游戏结果的状态，同时保持菜单输入、UI 动画和必要音效可用。恢复时不能留下速度、按键边沿或输入缓存导致角色瞬移/攻击。声音设置应区分主音量、音乐与音效，并持久化到下次启动；返回菜单前要先解除暂停，避免菜单场景也处于停帧状态。

Godot 项目采用的结论：GameEvents、UIManager 与 AudioManager 已有暂停和音量的服务层：收到 `pause_toggled` 后设置 `get_tree().paused`，BGM 同步暂停；AudioManager 支持 Master、独立 BGM/SFX 内部音量与线性转分贝，主菜单也有 Master Slider。实际玩法却没有任何脚本读取 `pause` action 或发出 `raise_pause_toggled()`，关卡场景没有 Pause Panel、继续/返回菜单按钮、默认焦点或音量控件，因此“暂停已实现”的 GDD 结论不成立，目前只有后端能力。还需验证 Autoload/UI 的 process_mode 能在树暂停时继续处理解除暂停输入；当前 AudioManager 和 UIManager 各自用布尔翻转，若漏掉或重复事件可能不同步。音量没有持久化，且只有主菜单 Slider，没有 Music/SFX 独立 UI。正式完成需补暂停面板、输入入口、焦点、回菜单自动解暂停、设置保存、实际运行截图和暂停期间物理/计时/音频测试。

### 中文课堂第 49 课：打包生成游戏

- 课程位置：章节 9 / 第 3 课；`chapterId=64099278c747e7001fd898d8`，`sectionId=6409947b7378df001fcc9153`。
- 播放器实际时长：约 `13:54`（`833.51s`）。
- 课时页明确提示：编辑调试阶段 Addressables 可选择 `Use Asset Database`；正式打包时每次内容修改后都必须重新 Build Addressables。

课时内容和发布构建：

1. `00:00–04:00` 整理最终场景和 HUD 状态，确认菜单、地点、UI 与加载服务在编辑器 Play 模式下可运行；打包前先处理显而易见的引用和画面问题。
2. `04:00–06:30` 检查 Addressables Groups：调试可使用 Asset Database，但正式包需要执行 New Build/Default Build Script，并在内容改动后重新生成资源目录。
3. `06:30–09:30` 打开 Player Settings 配置产品名、默认分辨率、全屏/窗口行为、图标与平台选项；这些设置决定最终独立程序的第一印象和显示兼容性。
4. `09:30–11:30` 检查 Build Settings 中的启动场景和所需持久/地点场景，选择目标平台和输出位置；遗漏启动场景或资源内容会产生编辑器正常、打包后黑屏/缺图的问题。
5. `11:30–13:54` 执行 Build，等待生成独立应用，在编辑器外实际启动并走一遍菜单和关卡；课程以可运行的最终包完成整个系列。

玩家体验与制作影响：发布验证必须使用真正的独立包，因为编辑器缓存、开发资源路径、输入焦点、窗口模式、存档目录和性能都可能不同。构建成功不等于游戏可发布，仍需验证新安装启动、继续游戏、音频、全屏切换、退出、崩溃日志和目标平台权限。

Godot 项目采用的结论：项目已锁定 640×360 逻辑视口、1280×720 默认窗口、整数缩放和 Windows/Linux PC 目标，也有 headless import、单元、集成、E2E 与视觉捕获入口。`export_presets.cfg` 已排除 tests、gdUnit4、MCP 运行时、报告、制作文档、构建目录和编辑器展示内容，Windows/Linux 精简 PCK 已生成且开发目录枚举为 0；Windows Godot 4.7 以 `--main-pack` 挂载精简 PCK 启动通过。完整命令、哈希和限制记录在 `production/releases/pc-build-evidence-2026-07-15.md`。当前环境没有 4.7 export templates，无法把最新精简 PCK 重新封装为 EXE/ELF；原生 Linux 运行仍需 Linux/CI 环境。课程的核心结论仍是“每次内容变化后重新生成并运行最终包”，因此这两项保持外部阻塞，不以编辑器内测试替代。

### 中文课堂第 50 课：全部代码文件

- 课程位置：章节 9 / 第 4 课；`chapterId=64099278c747e7001fd898d8`，`sectionId=64ad47cef5fbd60022b8d19a`。
- 本课没有视频播放器，是课程资料页。
- 页面正文说明：所有代码文件只供学习过程中对照、参考和纠错，禁止随意转发传播。
- 页面提供两个受限资料入口：夸克网盘与迅雷网盘；本研究只核验入口与用途，没有下载、复制或重新分发代码包。

资料页内容和使用边界：

1. 页面把完整代码定位为学习对照材料，不是可直接纳入其他项目的模板或公共授权源码。
2. 资料的合理用途是核对课程过程中可能漏写的字段、事件连接与文件名；不能替代理解各课实际画面和实现顺序。
3. 本项目是 Godot 4.7 架构，不能把 Unity C#、MonoBehaviour 生命周期、Addressables 或 ScriptableObject 事件通道直接复制进运行时。
4. 即使参考同类逻辑，也必须遵守本项目的静态类型、GameEvents/Autoload、GameSceneResource、ISaveable、稳定内容 ID 和测试规范。
5. 版权提示意味着不得把资料包上传到仓库、附在研究文档中或对外共享；文档只记录课程概念和本项目独立对照结论。

Godot 项目采用的结论：不下载或导入完整课程代码。当前仓库已经以独立实现覆盖课程主要功能，并在本研究中逐课记录了哪些内容已具备、部分具备或待实现。以后若为定位特定课程勘误而打开资料，只能做最小范围人工对照，不复制受限源文件，也不能让它覆盖项目既有架构和用户修改。第 50 课的完成证据是登录后的资料页面、无视频状态、版权正文和两个资料入口均已实际核验，而不是虚构一个播放时长。

## 课程整体结构

中文课堂教程可以归纳为九个制作阶段；下列 B 站集号仅用于对应已有公开合集：

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

## 当前项目设置基线

教程展示 Unity 配置方法；项目制作时以以下 Godot 4.7 设置为准，避免在实现阶段重新发明一套参数。

### 画布、像素和图层

| 设置 | 当前值 | 依据/用途 |
| --- | --- | --- |
| 逻辑视口 | `640×360` | `project.godot`；所有视觉验收按此尺寸 |
| 默认窗口 | `1280×720` | 2 倍显示 |
| 拉伸 | `canvas_items` + `expand` | 保持 2D 内容布局 |
| 缩放模式 | `integer` | 避免非整数像素抖动 |
| 环境网格 | 16 px | Forest 图集和 Geometry Terrain 基线 |
| 纹理过滤 | Nearest | 像素素材不得使用线性模糊 |
| 地图表现层 | Background / Geometry / Water / Foreground | 只有 Geometry 承担 World 碰撞 |

物理层固定为：`World`、`Player`、`Enemy`、`PlayerAttack`、`EnemyAttack`、`Interactable`、`Hazard`、`OneWayPlatform`。教程中的 Unity Layer/Collider Override 概念必须映射到这些命名层，不能在场景里继续使用无语义数字。

### 输入和角色场景

- 业务逻辑只读取 Input Map action：`move`、`move_left`、`move_right`、`jump`、`attack`、`walk`、`slide`、`interact`、`pause`、`heal`、`skill_slash`。
- 玩家根节点使用 `CharacterBody2D`；视觉、身体碰撞、地面/墙面检测和攻击盒相互独立。
- 地面角色根节点是脚底锚点，视觉底部与身体碰撞底部误差不得超过 1 个逻辑像素。
- 移动、伤害、攻击窗口和死亡由脚本状态负责；动画只表现已经确定的业务状态。

### TileMapLayer 和动态素材

- `GeometryTiles` 使用 `forest_tileset.tres` 的 Terrain 绘制可站立地形和墙体。
- `BackgroundTiles`、`WaterTiles`、`ForegroundTiles` 只负责表现，不添加 World 碰撞。
- 动态水体直接引用 `Forest-1.png`：河面表层/主体/深层使用横向 4 帧、3 FPS；瀑布左/中/右使用纵向 4 帧、7 FPS；河岸静态组合块与两类动画分开使用。
- 水和荆棘的伤害逻辑使用独立 `Area2D`/Hazard 层，不从装饰 Tile 是否存在推断玩法状态。
- 变尺寸树木、建筑和矿石使用 Scene Paint/正式 prefab，不强塞进 16×16 TileMapLayer。

## 素材来源与使用方式

### 页面明确的素材来源

| 素材 | 作者/来源 | 当前项目位置 | 使用方式 |
| --- | --- | --- | --- |
| Generic Character | [Brullov](https://brullov.itch.io/generic-char-asset) | `art/imported/Generic-Character/` | 玩家颜色变体和动画 sheet；使用原 sheet 帧区域 |
| Legacy Fantasy High Forest | [Anokolisa](https://anokolisa.itch.io/sidescroller-pixelart-sprites-asset-pack-forest-16x16) | `art/imported/Legacy-Fantasy-High Forest/` | 16 px 地形、背景、树木、水体、敌人和摆件 |
| 中文课堂整理素材/UI 按钮 | M_Studio 课程主页资料 | 未作为项目来源真相 | 只有确认授权和来源后才能导入；B 站简介不提供直接包 |
| 主场景字体 | `@oooooohmygosh`，作者在第 31 集简介指向 `BV1sP411g7PZ` | 需按当前 UI 字体资产审计 | 不因教程使用就默认取得再分发权 |
| Unity Quick Start Asset Bundle | Unity Asset Store 推广链接 | 不作为项目依赖 | 仅是简介推广资源，不进入 Godot 运行时 |

### 本项目的素材管线

1. 原始 sheet/atlas 保存在 `art/imported/`，是纹理内容真相来源。
2. Tile 使用 TileSet atlas 坐标；角色/敌人动画使用 SpriteFrames 或 `AtlasTexture.region`。
3. 不再为每格 Tile、每个动作帧批量生成独立 PNG；人工合成或修复内容才进入 `art/runtime/derived/`。
4. `data/asset_manifest.json` 记录技术区域，`data/editor_asset_catalog.json` 记录编辑职责和语义验收。
5. `editor.editor_ready=true` 才能生成 Scene Paint；`standalone` 可独立摆放，`kit_piece` 必须组合。
6. `Hive.png`、`Forest-2.png`、`Buildings.png`、`Props-Rocks.png` 等不规则 atlas 不按透明连通块自动切成正式素材。
7. 背景、前景、水体、地形、交互物和攻击/伤害区域必须分别承担清晰职责，不能用“看起来像”代替碰撞或玩法定义。

### 动画素材使用约定

- Idle、Walk、Run、Fly 等循环动画；Attack、Hurt、Death 默认不循环。
- 玩家 `AnimationPlayer` 负责片段时序，`PlayerController` 映射 sheet 帧；敌人动画由各敌人场景的动画节点负责。
- 同一属性只能有一个运行时所有者，禁止脚本和 AnimationPlayer 同时每帧改写 `Sprite2D.frame`。
- 攻击盒按 startup / active / recovery 窗口启停，不能仅凭“当前显示的是攻击帧”决定伤害。

## 作者简介中的关键补充与勘误

这些内容是作者在各视频简介中明确补充的实现约束，应优先于仅凭标题做的概括。

| 集数 | 补充/勘误 | Godot 项目处理 |
| ---: | --- | --- |
| 1 | 创建项目后必须验证代码编辑器能够代码补全 | Godot 编辑器/GDScript 静态类型和语言服务器必须正常 |
| 2 | 人物与场景素材分别来自 Brullov、Anokolisa；课程主页另有整理素材和 UI 按钮 | 保留原作者来源；课程整理包需单独确认授权 |
| 9 | 包含地面图层、Physics2D 检测、Gizmos 和光滑物理材质 | 对应 `physics_check.gd`、调试形状和角色碰撞材质 |
| 15 | Collider Layer Override 仅 Unity 2022.2+ 有 | Godot 使用命名 collision layer/mask，不复制 Unity 版本条件 |
| 16 | Tilemap 自动像素碰撞可能造成墙面不平，应在 Custom Physics Shape 中修平 | Geometry Terrain 必须提供可预测的平墙/地面碰撞 |
| 17 | 墙/地面检测方向要乘 `transform.localScale.x`，作者标注在 16:00 | Godot 检测节点不继承视觉缩放；朝向通过独立检测方向或 RayCast target 更新 |
| 19 | 15:46 的 `LogicUpdate()` 需补 `else`，重新设置 `walk=true` | 状态进入/退出必须显式设置动画状态，避免沿用上一状态残留 |
| 20 | 丢失目标计时不应在 Chase `OnExit` 重置；发现玩家时在公共计时逻辑中重置 | 目标可见/丢失时间属于敌人感知协议，不由单个动画状态私有维护 |
| 27 | 掉落/生成物品可参考作者的 3D RPG 高级课 `BV1cy4y1m7Ua` | 本项目继续使用 Loot/CollectibleReward 数据与正式 prefab |
| 31 | 字体来源另见 `BV1sP411g7PZ` | 引入字体前记录许可证和再分发范围 |
| 32 | `New Game` 加入 Character 后，`Start` 仍需把当前血量赋为最大血量 | 本项目新游戏初始化与存档加载分离，避免旧运行态泄漏 |

## 逐集索引与项目映射

状态含义：

- **已具备**：项目已有对应实现和基本测试。
- **部分具备**：已有基础，但体验、内容或验证未完整覆盖。
- **待实现**：教程涉及，项目尚无可靠实现。
- **外部阻塞**：仓库内代码管线已完成，但缺少授权资产、导出模板或目标平台环境。
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
| 11 | [跳跃动画 Blend Tree](https://www.bilibili.com/video/BV11M4y1e7kD) | 上升、下落、落地动画混合 | Jump/Fall/Land 独立帧映射、落地边沿窗口及视觉截图 | 已具备 |
| 12 | [人物属性和伤害](https://www.bilibili.com/video/BV14u4y1d7yE) | 属性、碰撞与伤害计算 | `character.gd`、统一伤害入口 | 已具备 |
| 13 | [受伤和死亡](https://www.bilibili.com/video/BV1Fk4y1H7TQ) | 受伤动画、死亡逻辑、事件 | 无敌帧、受击、死亡、复活和反馈事件 | 已具备 |
| 14 | [三段攻击动画](https://www.bilibili.com/video/BV1Ju41187CY) | 连击动画切换 | 三段攻击和输入缓存 | 已具备 |
| 15 | [攻击判定](https://www.bilibili.com/video/BV1bM4y177Ap) | 动画期间启停攻击范围 | `attack.gd` 与攻击时序 | 已具备 |
| 16 | [野猪基础移动和动画](https://www.bilibili.com/video/BV1oz4y1E7aJ) | 巡逻、墙面碰撞和动画 | Boar 脚本及敌人基础层 | 已具备，正式场景已接入 level_2 |
| 17 | [野猪撞墙和等待](https://www.bilibili.com/video/BV1Lk4y1N7ZD) | 朝向检测、撞墙、等待计时 | PhysicsCheck、Patrol 等待/恢复动画与动作回归 | 已具备 |
| 18 | [野猪受伤和死亡](https://www.bilibili.com/video/BV1Ah4y1C7JB) | 敌人受击和死亡动画 | `enemy_combatant.gd` | 已接入 Boar Hurt/Dead 图集与战斗碰撞 |
| 19 | [有限状态机和抽象类多态](https://www.bilibili.com/video/BV1xp4y137Xr) | 状态模式和敌人公共基类 | `base_state.gd`、Patrol/Chase/Skill | 已具备 |
| 20 | [追击状态转换](https://www.bilibili.com/video/BV1kP411x7UW) | 感知、追击、丢失目标和返回 | 敌人感知与状态切换 | 已具备 |
| 21 | [创建人物状态栏](https://www.bilibili.com/video/BV1Lu411E7MQ) | 血量 UI 结构 | HUD 和 `player_stat_bar.gd` | 已具备 |
| 22 | [血量更新逻辑](https://www.bilibili.com/video/BV1Uh4y1N7pT) | 属性事件驱动 UI | GameEvents / 信号更新 HUD | 已具备 |
| 23 | [摄像机跟随和攻击抖动](https://www.bilibili.com/video/BV1i94y1W75i) | 跟随、边界和打击震动 | Camera2D 跟随、边界夹紧、反馈抖动与归零测试 | 已具备 |
| 24 | [音源设置和音效](https://www.bilibili.com/video/BV1WK4y1F7nH) | BGM、SFX 和播放接口 | Music/SFX Bus、事件 ID、并发池和音量控制 | 外部阻塞：缺课程授权正式音源 |
| 25 | [水和荆棘逻辑](https://www.bilibili.com/video/BV1mw411Y7pM) | 环境区域、伤害与反馈 | 独立 Hazard、统一伤害入口、间隔与 Level 2 实例 | 已具备 |
| 26 | [人物可互动标识](https://www.bilibili.com/video/BV13w411c7zU) | 进入交互范围时显示提示 | 最近目标、课程图标、show/hide 动画与暂停规则 | 已具备 |
| 27 | [场景互动逻辑](https://www.bilibili.com/video/BV1p94y1b7ka) | 宝箱、物品、触发和奖励 | Chest、Breakable、CollectibleReward | 已具备 |
| 28 | [场景管理和切换](https://www.bilibili.com/video/BV1mu4y1E7de) | 场景引用、传送和切换流程 | `GameSceneResource`、`SceneLoader` | 已具备 |
| 29 | [场景加载后的执行逻辑](https://www.bilibili.com/video/BV15C4y1S7Tc) | 出生点、加载完成和场景初始化 | 定位/恢复后揭幕、通知、解锁及异常恢复 | 已具备 |
| 30 | [场景淡入淡出](https://www.bilibili.com/video/BV11N411u7q9) | 切换遮罩和异步时序 | `fade_canvas.gd` + SceneLoader | 已具备 |
| 31 | [主场景制作](https://www.bilibili.com/video/BV1MC4y127aV) | 主菜单和 UI 结构 | 课程森林素材三层背景、半透明面板、菜单与 MenuFlow | 已具备 |
| 32 | [新的冒险](https://www.bilibili.com/video/BV1sw41187WH) | 新游戏初始化和状态重置 | 新游戏流程、存档隔离和角色初始化 | 已具备 |
| 33 | [存储点和画面效果](https://www.bilibili.com/video/BV11u4y1K7p8) | 存档点、恢复和视觉提示 | `save_point.gd` | 已具备 |
| 34 | [数据结构及坐标保存加载](https://www.bilibili.com/video/BV1a5411B7XD) | 数据模型、场景 ID 和坐标 | DataManager、ISaveable、稳定内容 ID | 已具备并增加旧存档兼容要求 |
| 35 | [人物数值及场景保存加载](https://www.bilibili.com/video/BV1k94y1T7hB) | 玩家状态和场景持久化 | Continue 恢复场景、位置、生命、能量、对象状态与 HUD | 已具备 |
| 36 | [游戏结束面板](https://www.bilibili.com/video/BV1RN4y1p7xm) | 失败/完成 UI 和重试 | GameplayOverlay、默认焦点、重试与回菜单 | 已具备 |
| 37 | [移动设备屏幕操控](https://www.bilibili.com/video/BV1Li4y1p72V) | 触屏输入 | 当前目标平台为 Windows/Linux PC | 非当前目标 |
| 38 | [暂停面板和声音控制](https://www.bilibili.com/video/BV1mC411B7a2) | 暂停、音量和 UI 状态 | 暂停树、继续/回菜单、主/音乐/音效三路控制 | 已具备 |
| 39 | [打包生成游戏](https://www.bilibili.com/video/BV1uZ421U7Qz) | 构建配置和最终导出 | 精简 Windows/Linux PCK 与 Windows 挂载启动 | 外部阻塞：缺 4.7 模板及原生 Linux 环境 |

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
4. ~~完成 Boar 正式场景、状态表现和关卡遭遇验证。~~（2026-07-15 已完成并通过实际渲染截图、装载和通路测试）
5. 补齐水体/荆棘等环境伤害的设计、反馈和测试。
6. 实际校准相机跟随、攻击震动、受击反馈和音效同步。
7. 完成章节结束、失败重试和游戏结束面板闭环。
8. 在现有 Windows/Linux 导出证据基础上，补 Linux 原生运行、发布包资源精简、干净用户目录存档验证和发布检查清单。

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
