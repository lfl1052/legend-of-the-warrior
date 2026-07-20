# Active Session State

## Session Extract — HUD 信息层级优化 2026-07-16
- Goal: 在课程式状态栏素材修正后，清理仍常驻的成长数据面板，确保 640×360 首屏以生命/能量和战斗画面为主。
- Implemented: `PlayerProgressionPanel` 只在下一能力满足真实代币门槛时显示，解锁后自动收起；地图仍由 `map_panel` action 按需显示。未改动状态条数据流、课程图集或玩家能力规则。
- Verification: Godot 4.7 headless import PASS；HUD 单测新增成长面板隐藏/可解锁显示路径，2/2 PASS；Windows/OpenGL `player_hud.png` 已确认右上游玩区域清空；E2E 冒烟 7/7 PASS。

## Session Extract — 第 28–29 课状态栏视觉修正 2026-07-16
- Goal: 修正人物状态栏虽然使用课程图集、但视觉层级仍混入大面积通栏面板且误用按钮切片的问题，严格按课程头像左置、生命即时/延迟分层、能量独立细条的结构落地。
- Implemented: `gameplay_hud.tscn` 移除 `StatBackdrop`、HP/EN 标签和错误的 `58×20` 彩色按钮切片；改用 `Base-UI.png` 右侧 `60×8` 深色槽与绿/黄/蓝 `58×6` 细条，头像裁在课程底板内。经实际画面复核，头像底板最终从 `46×46` 收至 `28×28`，状态条距头像 `2px`、两条之间相隔 `3px`，形成紧凑的左上信息组；人物同源图集按 `1.25x` 放大并裁去躯干，只保留头部和少量肩部。`test_player_hud.gd` 现在验证紧凑结构、头像裁切与尺寸、前景/延迟层顺序和课程图集引用，避免仅检查路径而漏掉实际资源或布局退化。
- Verification: Godot 4.7 headless import PASS；HUD 单测 1/1 PASS；Windows/OpenGL `reports/playtest/player_hud.png` 已人工检查；E2E 冒烟 7/7 PASS，Continue 后生命、能量与 HUD 均正确同步。

## Session Extract — 成长、Boss 与课程状态栏收口 2026-07-16
- Goal: 完成 P2 成长槽位/场景面板、Boss 阶段/竞技场物理门锁，并确认人物状态栏按课程第 28–29 课使用对应 HUD 素材；同时更新遗留 P3 GDD。
- Implemented: `PlayerProgression` 作为 Player 子节点存档真实 `unlocked_slots`，Heal/SkillSlash 不再读取静态配置；零代价治疗自动解锁，面板按 `progression.json` 消耗升级代币解锁斩击，地图在 `map` 解锁后以 M 展示 JSON 路线。Boss 两个阶段阈值现在缩短蓄力/冷却、提升追击、扩大范围并在末阶段提升伤害；`BossArenaLock` 关闭 Level 2 两侧 StaticBody2D 门锁，死亡后开启。共享 `gameplay_hud.tscn` 用 `HUD/Base-UI.png` 的 atlas 图块实现头像框、即时/延迟生命与能量条，并在两个关卡实例化成长/地图面板和奖励通知。
- Fixed during verification: 地图面板此前把 RuntimeData JSON 强制为 Resource，现已直接读取 JSON，同时按玩家所属关卡解析场景名；门锁初始层在首次开门调用时明确关闭。
- Verification: Godot 4.7 headless import PASS；GdUnit4 37 套件、193/193 PASS；Level 2/Demo 装载 PASS；自动通路 22.33s PASS；E2E 7/7 PASS；Windows/OpenGL 截图 `player_hud.png`、`player_map_panel.png`、`boss_arena_locked.png` 已人工检查。

## Session Extract — 课程主场景与文档一致性收口 2026-07-15
- Goal: 继续审计课程剩余项，修复第 40 课主场景视觉缺口和研究/GDD 中实现前旧状态。
- Implemented: `warrior_menu.tscn` 复用课程 `Green-Tree.png` 建立三层循环森林景深和半透明按钮承载层，保持现有按钮路径与 MenuFlow；新增 3 项菜单契约测试和新游戏清理单测；更新环境伤害、Fade、Game Over、Encounter、菜单、存档与发布状态文档。
- Verification: Godot 4.7 headless import PASS；GdUnit4 34 套件、186/186 PASS；E2E 7/7 PASS；Level 2/Demo 装载 PASS；自动通路 22.33s PASS；Windows/OpenGL `warrior_menu.png` 已检查。Windows/Linux 最新 PCK 均为 4,056,980 bytes、SHA-256 `87371E99F3F87B6CFE98090D4BC393AD2E7A309A322422EB378A41B2A787D5D0`，Windows `--main-pack` 120 帧启动 PASS。
- External blockers unchanged: 缺课程正式授权音源；缺 Godot 4.7 export templates；缺原生 Linux/CI 运行环境。

## Session Extract — 课程剩余项集中收尾 2026-07-15
- Goal: 按 `course-implementation-matrix.md` 完成音频架构、交互提示、相机/Fade、课程式滑铲、存档迁移与发布精简，不使用课程外素材冒充完成。
- Implemented: 新增 Music/SFX Bus 与最旧 FX 抢占，补 `slide`/`interact` ID；Sign 改为 WeakRef 候选集合和最近目标，配置课程 HUD Prompt show/hide；相机支持变换边界、小地图居中和抖动归零，Fade 暂停态继续；滑铲改为固定 140.8px、Power 20、身体/HurtBox 缩短和统一中断恢复；DataManager 加 v0→v1、未来版本拒绝、1 MiB 上限与字段校验；导出排除测试、插件和开发内容，移除 MCP 运行时 Autoload。
- Verification: Godot 4.7 import PASS；GdUnit4 33 套件、182/182 PASS；E2E 7/7 PASS；Level 2/Demo 装载 PASS；自动通路 22.33s PASS。Windows/OpenGL 证据：`player_slide.png`、`player_interaction_prompt.png`、`level_2_arrival.png`、`level_2_boss.png`。Windows/Linux PCK 各 308 条目且开发目录 0 条目，Windows `--main-pack` 启动 PASS。
- External blockers: 仓库没有课程正式音源，现有生成声音只能继续标为占位；当前环境缺 Godot 4.7 export templates，过滤后 EXE/ELF 未重新封装；原生 Linux 运行仍待 Linux/CI 环境。

## Session Extract — 存储点正式反馈闭环 2026-07-15
- Goal: 完成课程下一项 P1 存储点体验，不再只证明文件写出。
- Implemented: 新增 `scenes/props/save_point.tscn`，按课程第 42 课使用 Props-Rocks 岩石与 SignCharacters 熄灭/点亮双 Sprite，并用 CanvasGroup 对应 Sort Group；SavePoint 改为真实 Area2D，支持 inactive/saving/active、成功确认、失败回滚、首次奖励防重复、稳定 ID 与旧路径键兼容。成功/失败分别显示通知并使用 `save_success` / `save_failure` 音效 ID。
- Verification: Godot 4.7 headless import PASS；GdUnit4 32 套件 155/155 PASS；E2E 7/7 PASS；Level 2 装载 PASS。Windows/OpenGL 证据：`save_point_inactive.png`、`save_point_active.png`、`save_point_success.png`、`save_point_failure.png`。
- Next: P1 正式音频管线，包括正式资产、BGM/SFX Bus、混音与并发抢占规则。

## Session Extract — 课程优先缺口闭环 2026-07-15
- Goal: 按优先级完成 Game Over、Pause、Continue/原子存档、环境伤害和 Encounter 战利品闭环。
- Implemented: 常驻 GameplayOverlay 提供死亡重试/回菜单与暂停三路音量；SceneLoader 统一锁定转场输入并支持当前场景重试；DataManager 使用 `.tmp` + `.previous` 原子轮换并在新场景注册后延迟恢复；Character 正式注册存档，Continue 可恢复位置、生命和能量；新增固定伤害水/荆棘 Hazard；Level 2 Boss 通过稳定 encounter ID 和 Loot JSON 一次性发奖。
- Verification: Godot 4.7 headless import PASS；GdUnit4 31 套件 151/151 PASS；E2E 7/7 PASS；Level 2 装载检查 PASS。Windows/OpenGL 证据：`gameplay_game_over.png`、`gameplay_pause.png`、`level_2_water_hazard.png`、`level_2_boss_reward.png`。
- Course matrix: `docs/reference/course-implementation-matrix.md`。下一优先级是存储点正式反馈与正式音频管线。

## Session Extract — Demo 玩家出生点落地修复 2026-07-15
- Goal: 修复从主菜单进入 Demo 时玩家出生在空中并下落的问题。
- Root cause: `warrior_menu.tscn` 的 `MenuFlow.default_spawn_position` 为 `(0,0)`，SceneLoader 会用该待传送坐标覆盖 Demo 场景原本正确的 `Player` `(0,492)`。
- Implemented: 默认出生点改为 `Vector2(0,492)`，并在 e2e 冒烟中检查玩家出生坐标和首个物理帧的 `is_on_floor()`。
- Verification: Godot 4.7 headless import PASS；e2e 6/6 PASS。

## Session Extract — 玩家与敌人碰撞和受击节奏修复 2026-07-15
- Goal: 修复玩家及敌人的身体框、攻击框、受击框、方向、范围提示与受击间隔，使动画表现和规则判定一致。
- Implemented: 新增 PlayerHurtBox / EnemyHurtBox 专用物理层和通用 `HurtBox` 转发节点；Attack 以规则角色为去重目标；玩家三连击使用逐段扩大的独立尺寸；下蹲同步缩短 HurtBox；修复 Snail 实际碰撞形状不翻转的假阳性；Boar 改为前向接触框并在等待/受击关闭，Snail 在等待/受击/缩壳关闭；玩家技能斩显示 160×80 精确提示，Boss 显示半径 72 预警。
- Timing: 玩家保留 0.5s 全局受击保护；普通敌人改为 0.18s，Boss 为 0.22s，使三连击可逐段命中，同时避免同一物理帧重复伤害。
- Verification: Godot 4.7 headless import PASS；完整单元测试 29 套件、143/143 PASS；e2e 6/6 PASS；Windows/OpenGL 截图 `reports/playtest/level_2_skill_slash.png` 与 `level_2_boss.png` 已检查范围可见性和场景遮挡。

## Session Extract — 三类课程敌人攻击与特殊动作修复 2026-07-15
- Goal: 对照课程第 19–27 课核对 Boar、Snail、Bee 的攻击逻辑、特殊动作和原图集映射，并修复行为与表现脱节。
- Implemented: Boar 墙/边缘等待播放 Idle、恢复 Walk，追击及受击恢复播放 Run，`attack_damage` 写入接触 Attack；Snail 接触攻击区随朝向翻转，Walk/Dead 使用完整 0–7，Hide 使用 0–3、闭壳保持 3、Unhide 使用作者绘制的 4–7；Bee Active 窗口通过 `Attack.set_active()` 真正启停 monitoring，计时归零当帧关闭，攻击/受击结束恢复 Chase/Fly，Dead 使用 Hit/Vanish 0–3。
- Design boundary: 保留课程的 Read→Commit→Resolve→Recover 节奏，不照搬 Unity API；继续使用世界遮挡、平台边缘检测、蜜蜂攻击后退避和蜗牛三阶段缩壳等 Godot 扩展。伤害仍统一经过 `Attack → take_damage()`，动画不决定 AI 真相。
- Verification: Godot 4.7 headless import 通过；定向课程动作测试 9/9 PASS；完整单元测试 29 套件、133/133 PASS；e2e 6/6 PASS。Windows/OpenGL 截图：`reports/playtest/enemy_boar_wait.png`、`enemy_boar_chase.png`、`enemy_snail_hide.png`、`enemy_snail_unhide.png`、`enemy_bee_attack.png`、`enemy_bee_chase.png`。
- Remaining: 三类普通敌人的课程动作闭环已完成；Boss 不属于本轮“三个敌人”，Encounter 战利品流程仍是独立缺口。

## Session Extract — 玩家扩展动作完整接入 2026-07-15
- Goal: 补齐课程与原图集中尚未接入的 Land、Crouch、Heal 施法、Shield 格挡和 Ladder 攀爬，确保规则状态、碰撞和动画一致。
- Implemented: Land 使用落地边沿触发的 0.18s 可打断表现；地面按 `move_down` 下蹲并把 Capsule 高度从 40 缩到 28，低顶时禁止站起；按住 `block` 只格挡朝向正面的攻击，每次成功消耗 15 能量；Heal 播放独立动画并在 0.32s 生效帧结算、0.64s 收招；进入 `LadderArea` 后可用 `move_up/down` 攀爬、停驻或跳离。受击、死亡、复活、新游戏和输入禁用都会清理扩展状态。
- Assets/Input: `land=38–39`、`heal=64–71`、`crouch=72–74`、`block=80–82` 使用主图集，`climb=40–47` 使用第二图集；新增 `move_up`、`move_down`、`block` Input Map，Demo 新增 `TrainingLadder`。
- Verification: Godot 4.7 headless import 通过；定向动作测试 7/7 PASS；完整单元测试 28 套件、124/124 PASS；e2e 6/6 PASS。Windows/OpenGL 代表截图为 `reports/playtest/player_land.png`、`player_crouch.png`、`player_heal.png`、`player_block.png`、`player_climb.png`。
- Remaining: 自动化验证覆盖规则与资源引用；本轮代表截图覆盖五种正常动作状态，但未单独录制低顶站起失败、背面破防和 Heal 被打断的可视化视频，这些边界由单元测试负责。

## Session Extract — 玩家动作图集语义修复 2026-07-15
- Goal: 修复玩家 Walk、Fall、Wall 动画虽有合法帧号但引用了错误动作行的问题。
- Implemented: Walk 改用 `char_blue_2` 的 0–7 帧；Fall 改用 `char_blue_1` 的 Fall/Land 行前段 32–37 帧，避免空中播放着地帧；Wall 改用 `char_blue_2` 的 Wall Slide 24–27 帧。新增语义测试同时检查纹理、图集行和首末帧。
- Verification: Godot 4.7 headless import 通过；完整单元测试 27 套件、116/116 PASS；e2e 6/6 PASS；Windows/OpenGL 截图 `reports/playtest/level_2_walk.png`、`level_2_fall.png`、`level_2_wall.png` 已检查动作姿态与场景关系。
- Resolved: 该轮记录的 Land、Crouch 和 Heal 表现缺口已由“玩家扩展动作完整接入”任务完成。

## Session Extract — 玩家 L 键技能斩可读性修复 2026-07-15
- Goal: 修复 `skill_slash`（默认 L 键）无动画却直接扣能量的问题，让技能的承诺、生效和收招对玩家可见。
- Implemented: 技能先检查玩家动作状态再消耗 35 点能量；播放 `spell_cast` 64–71 帧的 `skill_slash` 动画，0.32s 生效并对朝向前方 `160×80` 范围造成 2 点伤害，0.64s 收招；施法期间锁定移动、普通攻击和滑铲，受击、死亡、复活及输入禁用会取消未生效技能；命中提供战斗反馈与独立技能音效 ID。
- Verification: Godot 4.7 headless import 通过；完整单元测试 27 套件、115/115 PASS；e2e 6/6 PASS；Windows/OpenGL 代表截图 `reports/playtest/level_2_skill_slash.png` 用于核对动画帧、朝向与同屏可读性。

## Session Extract — 角色与敌人课程落地 2026-07-15
- Goal: 根据已整理的《勇士传说》课程笔记完善玩家墙滑边界、敌人追击记忆和正式野猪内容。
- Implemented: 玩家墙滑仅在下落且输入朝墙时生效，墙跳仍独立依赖墙面接触；Enemy 基类统一刷新/递减 Chase 目标记忆并缓存感知查询，Boar/Bee/Boss Chase 移除重复计时；新增正式 `scenes/enemy/boar.tscn`（Idle/Walk/Run/Hurt/Dead、Character、Attack、PhysicsCheck）并接入 level_2。
- Verification: Godot 4.7 headless import 通过；完整单元测试 111/111 PASS；level_2 装载、遭遇顺序与自动通路 PASS；e2e 6/6 PASS；Windows/OpenGL 实际渲染截图 `reports/playtest/level_2_boar.png` 已检查脚底、比例、朝向与同屏可读性。
- Remaining: 完整 Encounter 战利品流程仍未实现；下蹲已由后续“玩家扩展动作完整接入”任务完成，当前不新增第二套玩家 FSM。

## Session Extract — 《勇士传说》课程研究 2026-07-15
- Goal: 分批实际观看中文课堂 50 课视频，并持续整理到 `docs/reference/warrior-legend-video-series-study.md`；每批 2–4 课，避免一次性扩大上下文。
- Progress: 课程研究覆盖第 1–50 课并已全部完成；按用户先前决定，第 1 课导览跳过、第 2–6 课使用已完整核验的同源 B 站内容，第 7–49 课完成中文课堂实际视频画面核验，第 50 课确认是无视频资料页并核验版权提示及资料入口。最后完成第 49 课打包生成游戏（`13:54`）和第 50 课全部代码文件资料页。
- Current comparison: 课程研究目标已完成。Godot 项目现已补充 `export_presets.cfg` 和 `production/releases/pc-build-evidence-2026-07-15.md`；Windows/Linux release 均导出成功，Windows 独立包已在编辑器外启动验证，Linux 产物已确认是 x86_64 ELF，但因本机未安装 WSL、也没有 Linux 实机，Linux 运行时验证仍待补。当前包使用 `all_resources`，尚未移除 tests、gdUnit4 和开发期 MCP 内容。Game Over、暂停面板、转场输入锁、存储点正式反馈、跨场景继续游戏和原子存档仍需后续独立任务实现。
- Next batch: 无剩余课时。后续如进入制作，应从研究文档中的明确缺口选择 Story，而不是继续复制 Unity 课程架构。

## Session Extract — Atlas-first editor asset library 2026-07-14
- Decision: original sheets/atlases are the texture source of truth; mechanical per-tile/per-frame crops are not runtime assets.
- Removed: `art/processed/` and its generated PNG/import files.
- Preserved derived art: `art/runtime/derived/terrain/forest_ground_inner_corners.png`.
- Added: source-region asset manifest, editor catalog, Background/Foreground/Water/Library TileSets, Scene Paint scenes, and actor animation previews.
- Level contract: Background, Water, and Foreground manual cells are preserved; Geometry remains data-generated by default and can opt into manual authoring.
- Dynamic tile contract: animated water lives in `WaterTiles`; visual animation does not provide gameplay collision.

## Session Extract — /story-done 2026-05-21
- Verdict: COMPLETE WITH NOTES
- Story: production/stories/1-7-scene-resource-validator.md — dev-only validator: 检查 GameSceneResource.scene_path 文件存在
- Tech debt logged: None
- Next recommended:
  - Should-Have：`production/stories/1-6-boss-skill-state.md`（BossEnemy skill_state，1.5 day）
  - Nice-to-Have：`production/stories/1-8-level-2-scaffold.md`（第二关脚手架，1.0 day）
  - Sprint close-out：`/smoke-check sprint` → `/team-qa sprint` → `/retrospective`

## Sprint 1 状态快照
- Must-Have：1-1 / 1-2 / 1-3 / 1-4 / 1-5 全部 done ✅
- Should-Have：1-9 / 1-7 / 1-6 done ✅
- Nice-to-Have：1-8 done ✅
- Sprint Goal "锁定基础系统" 的关键路径已闭环（数据契约 + 单元测试 + GdUnit4 CLI 通路）

## 建议下一步
1. 若决定收尾 Sprint 1，按 close-out 序列：`/smoke-check sprint` → `/team-qa sprint` → `/retrospective`

## Session Extract — Sprint 2 close-out 2026-05-25
- Goal: 完成 Sprint 2 Must Have scope and test it.
- Completed stories: 2-1 / 2-2 / 2-3 / 2-4 / 2-5 marked Complete.
- QA plan: `production/qa/qa-plan-sprint-2.md`.
- Smoke report: `production/qa/smoke-2026-05-25.md`.
- Verification evidence at Must Have close-out: full unit suite 50/50 PASS (`reports/report_32/` then-latest); `tests/integration/level_2_load_test.tscn` PASS; `tests/e2e/smoke_test.tscn` PASS.
- Follow-up fix during close-out: `scripts/autoload/scene_loader.gd` now queues scene paths until fade completes before polling threaded loads; regression covered by `tests/unit/test_scene_loader.gd`.
- Later session completed stories 2-6 through 2-10; see the Sprint 2 2-6 through 2-10 close-out extract below.
- Code review evidence: `production/qa/code-review-sprint-2-2026-05-25.md` approved Sprint 2 for QA hand-off with conditions after scope was expanded to 2-10.

## Session Extract — Sprint 2 QA sign-off 2026-05-25
- QA sign-off report: `production/qa/qa-signoff-sprint-2-2026-05-25.md`.
- Verdict: APPROVED WITH CONDITIONS for Sprint 2.
- Conditions: human playthrough of expanded `level_demo`, visual/feedback spot-check for chest/breakable/combat/dash/audio, and user-approved merge.
- Updated Sprint 2 DoD: QA sign-off checked; code review noted as complete but merge remains pending.

<!-- QA RUN: 2026-05-25 | Sprint: sprint-2 | Verdict: CONCERNS | Report: production/qa/qa-signoff-sprint-2-2026-05-25.md -->

## Session Extract — Sprint 2 2-6 through 2-10 close-out 2026-05-25
- Goal: continue and complete Sprint 2 stories 2-6 through 2-10.
- Completed stories: 2-6 / 2-7 / 2-8 / 2-9 / 2-10 marked Complete.
- Implemented: combat hit feedback event fan-out, patrol ledge/wall detection, generated placeholder SFX, dash cooldown/invulnerability tests, generated placeholder BGM with scene-load hook and fade start.
- Audio smoke cleanup: headless runs keep audio stream assignment testable but do not start real playback; Sprint 2 `AudioStreamWAV` / `AudioStreamPlaybackWAV` smoke leak warnings are resolved.
- Reward notification smoke cleanup: `RewardNotificationUI` now uses tween callbacks and cancels active tweens on exit, removing the previous `GDScriptFunctionState` leak at smoke shutdown.
- Verification evidence: feature subset 22/22 PASS (`reports/report_42/`), full unit suite 64/64 PASS (`reports/report_45/`), `tests/integration/level_2_load_test.tscn` PASS, and `tests/e2e/smoke_test.tscn` PASS with exit code 0.
- Remaining conditions: visible-session spot-check for level route feel, chest/breakable feedback, combat feedback, dash feel, SFX/BGM mix; user-approved merge.

## Session Extract - Sprint 2 player feedback fixes 2026-05-25
- Addressed feedback: placeholder BGM now has rhythmic pulse instead of a flat sustained loop; player/enemy bodies no longer remain active in the scene after death; real collectible rewards were added and misleading key-like decoration density was reduced; snail shell behavior now checks front-facing sight, allows back attacks, and still shells when damaged.
- New/updated coverage: `tests/unit/test_audio_manager.gd`, `tests/unit/test_enemy_combatant.gd`, `tests/unit/test_player_dash.gd`, `tests/unit/test_collectible_reward.gd`, and `tests/unit/test_snail_behavior.gd`.
- Verification evidence: full unit suite 75/75 PASS (`reports/report_54/`), `tests/integration/level_2_load_test.tscn` PASS, and `tests/e2e/smoke_test.tscn` PASS with exit code 0.

## Session Extract — 课程第 37–39 课场景切换闭环 2026-07-15
- Goal: 补齐场景并发请求、失败恢复、揭幕时序与 Fade 边界，严格落实课程“遮蔽加载、定位后揭幕、最后恢复控制”的职责。
- Implemented: SceneLoader 新增 IDLE/FADING_TO_BLACK/LOADING/REVEALING 阶段；并发请求保持首个请求；旧/新 Player 在转场中均锁定；成功路径固定为位置与存档恢复→揭幕完成→AfterSceneLoaded→输入解锁；加载或切换失败时保留原场景、揭开黑屏后再恢复输入。E2E 通过 `is_transition_active()` 等待真正可操作状态，不再把场景根出现误当成加载完成。
- Fade: 保留课程职责等价的全屏 ColorRect + Tween，覆盖零/非零时长、任意颜色与新请求取消旧 Tween；没有引入新素材或无关插件。
- Verification: Godot 4.7 headless import PASS；SceneLoader/Fade 定向 10/10 PASS；完整 GdUnit4 32 套件、160/160 PASS；E2E 7/7 PASS；Level 2/Demo 装载检查 PASS。装载测试同时改用 Parallax2D 子 Sprite 的局部坐标校验作者落位，避免当前相机造成全局坐标假失败。
