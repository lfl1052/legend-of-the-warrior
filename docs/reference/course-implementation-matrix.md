# 《勇士传说》课程实现对照表

更新日期：2026-07-15。状态以实际代码、自动化和运行截图为准，不以旧 GDD 的“已实现”标签代替验收。

执行约束：后续课程功能先定位到具体课时，再使用该课时明确出现的素材族、状态和反馈。项目缺少课程原素材时记录资产缺口，不以无关素材或自行绘制内容冒充课程实现；仅在 Godot API 与 Unity API 不同处做职责等价替换。

## 本轮优先项

| 优先级 | 课程能力 | 当前状态 | Godot 实现 | 验证证据 |
|---:|---|---|---|---|
| P0 | Game Over、重试、返回菜单 | 已完成 | `GameplayOverlay` + `UIManager` + `SceneLoader.restart_requested` | `gameplay_game_over.png`；死亡/复活单测；E2E |
| P0 | 暂停菜单与音量 | 已完成 | 暂停树、继续/回菜单、主/音乐/音效三路控制、显式音频暂停 | `gameplay_pause.png`；AudioManager 单测 |
| P0 | Continue 完整恢复 | 已完成 | 新场景注册后延迟注入位置、生命、能量与对象状态；HUD 同步 | E2E 第 7 步：场景/位置/生命/能量/HUD |
| P0 | 原子存档 | 已完成 | `.tmp` 写入并 flush/close，主文件轮换 `.previous` 后替换；结果事件 | DataManager 11 项单测 |
| P1 | 转场输入锁与异常恢复 | 已完成 | SceneLoader 使用显式转场阶段；并发请求忽略，失败时揭开原场景，成功时定位/恢复→揭幕→通知→解锁 | SceneLoader 7 项、Fade 4 项单测 + E2E |
| P1 | 水/荆棘环境伤害 | 已完成 | 独立 Hazard Area2D，固定 1 点、0.75 秒间隔、不可格挡，统一走 `take_damage` | Hazard 2 项单测；`level_2_water_hazard.png` |
| P1 | Encounter 清场战利品 | 已完成 | 稳定 encounter ID、Loot JSON、全员死亡聚合、Progression 防重复、通知 | Encounter 单测；`level_2_boss_reward.png` |
| P1 | 存储点正式反馈 | 已完成 | 按第 42 课使用 Props-Rocks 岩石与 SignCharacters 熄灭/点亮双 Sprite，CanvasGroup 对应 Sort Group；含成功/失败提示、失败回滚、专用音效 ID、旧档兼容 | SavePoint 4 项单测；`save_point_*.png` |

## 剩余项收尾结果

| 优先级 | 课程能力 | 当前状态 | 本轮结果 / 仍需外部输入 |
|---:|---|---|---|
| P1 | 正式音频管线 | 代码管线完成，正式资产阻塞 | 新增 `Music` / `SFX` Bus、真静音、独立音量、8 槽最旧抢占以及 `slide` / `interact` ID；仓库没有课程原音源，程序生成音仍明确标为占位，需取得课程授权音源后做可听混音验收 |
| P2 | 交互提示健壮性 | 已完成 | 候选集合按最近目标选择，退出/释放后自动回退；Prompt 使用课程 HUD 图集和独立 show/hide 动画；3 项单测与 `player_interaction_prompt.png` |
| P2 | 相机与 Fade 边界 | 已完成 | 变换后边界刷新、640×360 夹紧、小地图居中、抖动归零、暂停态 Fade 均覆盖；Camera/Fade 11 项单测与 Level 2 OpenGL 截图 |
| P2 | 主场景课程视觉 | 已完成 | 复用课程森林树木图集建立三层循环 Parallax，按钮使用半透明承载层；3 项契约测试与 `warrior_menu.png` |
| P2 | 课程式滑铲闭环 | 已完成 | 固定 140.8px 目标距离、Power 消耗、身体/HurtBox 缩短、撞墙/离地/到点/超时结束、统一恢复 mask、专用 `slide` ID；15 项单测与 `player_slide.png` |
| P2 | 存档 Schema 迁移 | 已完成 | v0 课程字段别名迁移到 v1；未来版本安全拒绝；1 MiB 上限；场景、坐标、浮点字段校验；11 项 DataManager 单测 |
| P3 | 发布包收尾 | 过滤与 PCK 验证完成，可执行重导出受环境阻塞 | Windows/Linux PCK 各 308 条目、开发目录 0 条目，Windows 引擎挂载启动通过；本机缺 4.7 导出模板，无法重导过滤后的 EXE/ELF，原生 Linux 运行仍需外部环境 |

## 当前验证基线

- Godot 4.7 headless import：PASS。
- GdUnit4：34 套件，186/186 PASS。
- E2E：7/7 PASS。
- Level 2/Demo 装载、碰撞、路线结构与 22.33 秒自动通路：PASS。
- Windows/OpenGL 代表截图：主菜单、Game Over、Pause、水域、Boss 奖励、存储点四态、滑铲、交互提示与相机边界均已人工检查。
