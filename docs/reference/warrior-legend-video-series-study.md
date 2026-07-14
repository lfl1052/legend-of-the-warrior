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
- 已核对的“章节 7 / 6.主场景制作”视频时长约 `23:59`。页面明确提示：Canvas 上的 Canvas Scaler 要调整为固定比例，例如 `1920×1080`。该条目前仅标记为“页面提示已记录”，视频内容仍需逐段整理。

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
| 7 | 2-2 创建及配置新输入系统 | 页面内容已整理 | `27:26`；代码模板、Input System、Action 配置、PlayerInput、生命周期与 Vector2 读取已记录，画面继续核验 |
| 8 | 2-3 实现移动和翻转 | 页面内容已整理 | `17:46`；刚体速度、变量获取、FixedUpdate、运行时数值与两种翻转方案已记录 |
| 9 | 2-4 实现人物跳跃 | 页面内容已整理 | `14:14`；跳跃 Action、输入 started 回调、AddForce/Impulse、Gravity Scale 与落地限制已记录 |
| 10 | 2-5 物理环境监测及绘制 | 视频画面已核验 | `17:29`；脚底圆形检测、Ground Layer、Gizmos、检测参数和 Physics Material 2D 已记录 |
| 11 | 2-6 创建人物基本动画 | 视频画面已核验 | `23:23`；Animator Controller、Idle/Run/Walk Clip、Samples、`PlayerAnimation` 与 `velocityX` 条件已记录 |
| 12 | 2-7 人物行走设定 | 视频画面已核验 | `07:08`；WalkButton 按下/松开回调、跑速缓存、半速强制行走与接地限制已记录 |
| 13 | 2-8 创建人物跳跃动画 | 视频画面已核验 | `14:26`；多段空中/落地动画、`velocityY` Blend Tree、`isGround` 与落地打断已记录 |
| 14 | 2-9 实现人物下蹲逻辑和动画 | 视频画面已核验 | `15:05`；下蹲子状态机、`isCrouch`、碰撞体 offset/size 切换与移动锁定缺口已记录 |
| 15 | 2-10 人物属性及伤害计算 | 待读取 | 以中文课堂视频为准 |
| 16 | 2-11 受伤和死亡的逻辑和动画 | 待读取 | 以中文课堂视频为准 |
| 17 | 2-12 三段攻击动画的实现 | 待读取 | 以中文课堂视频为准 |
| 18 | 2-13 实装攻击判定 | 待读取 | 以中文课堂视频为准 |
| 19 | 3-1 野猪：基本的移动逻辑和动画 | 待读取 | 以中文课堂视频为准 |
| 20 | 3-2 野猪：撞墙判定和等候计时 | 待读取 | 以中文课堂视频为准 |
| 21 | 3-3 野猪：受伤及死亡的逻辑和动画 | 待读取 | 以中文课堂视频为准 |
| 22 | 3-4 有限状态机、抽象类与多态 | 待读取 | 以中文课堂视频为准 |
| 23 | 3-5 追击状态的转换 | 待读取 | 以中文课堂视频为准 |
| 24 | 3-6 蜗牛：基本的移动逻辑和动画 | 待读取 | 中文课堂独有 |
| 25 | 3-7 蜗牛：特殊技能状态的实现 | 待读取 | 中文课堂独有 |
| 26 | 3-8 蜜蜂：基本的移动逻辑和动画 | 待读取 | 中文课堂独有 |
| 27 | 3-9 蜜蜂：追击和攻击的实现 | 待读取 | 中文课堂独有 |
| 28 | 4-1 创建人物状态栏 | 待读取 | 以中文课堂视频为准 |
| 29 | 4-2 血量更新逻辑的实现 | 待读取 | 以中文课堂视频为准 |
| 30 | 5-1 滑墙及蹬墙跳的实现 | 待读取 | 中文课堂独有 |
| 31 | 5-2 滑铲的逻辑和动画的实现 | 待读取 | 中文课堂独有 |
| 32 | 6-1 摄像机跟随及攻击抖动实现 | 待读取 | 以中文课堂视频为准 |
| 33 | 6-2 音源设置和音效播放 | 待读取 | 以中文课堂视频为准 |
| 34 | 6-3 水和荆棘的逻辑实现 | 待读取 | 以中文课堂视频为准 |
| 35 | 7-1 人物可互动标识 | 待读取 | 以中文课堂视频为准 |
| 36 | 7-2 场景互动的逻辑实现 | 待读取 | 以中文课堂视频为准 |
| 37 | 7-3 场景管理和切换 | 待读取 | 以中文课堂视频为准 |
| 38 | 7-4 场景加载后的执行逻辑 | 待读取 | 以中文课堂视频为准 |
| 39 | 7-5 场景淡入淡出效果 | 待读取 | 以中文课堂视频为准 |
| 40 | 7-6 主场景制作 | 页面提示已记录 | Canvas Scaler 固定比例示例 `1920×1080`；视频待整理 |
| 41 | 7-7 实现“新的冒险”逻辑 | 待读取 | 以中文课堂视频为准 |
| 42 | 8-1 存储点及画面效果 | 待读取 | 以中文课堂视频为准 |
| 43 | 8-2 数据结构及坐标保存加载 | 待读取 | 以中文课堂视频为准 |
| 44 | 8-3 人物数值及场景的保存加载 | 待读取 | 以中文课堂视频为准 |
| 45 | 8-4 制作游戏结束面板 | 待读取 | 以中文课堂视频为准 |
| 46 | 8-5 序列化保存数据文件 | 待读取 | 中文课堂独有 |
| 47 | 9-1 实现移动设备屏幕操控 | 待读取 | 中文课堂课时；当前 PC 项目非目标 |
| 48 | 9-2 暂停面板及声音控制 | 待读取 | 以中文课堂视频为准 |
| 49 | 9-3 打包生成游戏 | 待读取 | 以中文课堂视频为准 |
| 50 | 9-4 全部代码文件 | 待读取 | 中文课堂资料课；仅用于核验，不直接复制架构 |

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

Godot 项目采用的结论：当前 `scripts/player/player_controller.gd` 已把人物帧分为 `jump=[24,25,26,27]` 和 `fall=[28,29]`，并在空中用 `velocity.y < 0.0` 直接选择 Jump/Fall；这等价于最小化的两段纵向状态，不需要为了复刻 Unity 而强制引入 AnimationTree。项目目前没有独立 Land 动画或“上一物理帧在空中、当前帧接地”的落地边沿状态，因此不能声称已经覆盖课程的落地反馈和打断规则。若 GDD 后续批准增强落地表现，应由脚本保存前后帧接地状态，触发一次性 Land 业务/表现事件，再允许移动、攻击、滑铲等高优先级状态按明确规则打断；不能让动画播放完毕本身成为角色能否行动的唯一真相。若素材需要三段以上空中表现，可用 `velocity.y` 阈值做显式状态映射或 AnimationTree BlendSpace1D，但最终阈值必须根据 Godot 的 `jump_velocity=-600`、重力、可变跳高和实际帧素材试玩确定，不能照抄 Unity Blend Tree 数值。

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

Godot 项目采用的结论：当前项目没有 `crouch` Input Map action、`is_crouching` 状态、顶棚检测或下蹲动画；`slide` 虽然已有独立 action、速度、冷却和无敌时间，但只临时调整碰撞 mask，并未缩短 `scenes/player/player.tscn` 中半径 `12`、高度 `40` 的 `CapsuleShape2D`，不能把滑铲直接当作已完成的下蹲。若后续正式设计下蹲，应先由 GDD 决定是独立 action 还是复用 `move` 纵轴、是否允许蹲走、与攻击/跳跃/滑铲的优先级以及低顶下的站起失败规则；实现上缓存站立/下蹲 Shape 参数，通过顶棚 ShapeCast/RayCast 确认能否恢复，并为状态转换、脚底基线、低顶保持、移动锁定和旧存档无新增字段写确定性测试。此课仅作为机制研究，不在本轮改变现有玩家体验。

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
- 动态水体直接引用 `Forest-1.png`：4 帧水面为 3 FPS，三组 3 帧水体为 2 FPS。
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
