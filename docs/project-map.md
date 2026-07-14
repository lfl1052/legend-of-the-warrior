# Project Map

这份文件用于快速定位当前项目文件。它按“实际开发时会找什么”组织，而不是按 Godot 的全部目录展开。

当前引擎与文档校订基线为 **Godot 4.7 stable**。

## 入口

- Godot 配置: `project.godot`
- 主场景: `scenes/levels/warrior_menu.tscn`
- 当前可玩关卡:
  - `scenes/levels/level_demo.tscn`
  - `scenes/levels/level_2.tscn`
  - `scenes/levels/asset_showcase_level.tscn`：森林高地、浅水石滩和矿洞入口的素材组合验收关卡
- 场景资源索引:
  - `data/scene_warrior_menu.tres`
  - `data/scene_level_demo.tres`
  - `data/scene_level_2.tres`

## 核心代码

- 全局服务: `scripts/autoload/`
  - `game_events.gd`: 全局信号总线
  - `runtime_data.gd`: 读取 `data/*.json`
  - `data_manager.gd`: 存档
  - `scene_loader.gd`: 场景切换
  - `audio_manager.gd`: 占位音效和 BGM
  - `language_manager.gd`: 中英文切换
  - `ui_manager.gd`: UI 注册和暂停状态
- 玩家: `scripts/player/`
  - `player_controller.gd`: 移动、跳跃、攻击、滑铲、死亡、自动化输入
  - `player_heal_skill.gd`: 治疗
  - `player_skill_slash.gd`: 技能斩
  - `player_progression.gd`: 代币、解锁、奖励进度
  - `sign.gd`: 交互探测
  - `save_point.gd`: 存档点
- 敌人: `scripts/enemy/`
  - `enemy_combatant.gd`: 受击、死亡、敌人存档
  - `enemy.gd`: Patrol / Chase / Skill 状态机
  - `base_state.gd`: 状态基类
  - `bee.gd`, `snail.gd`, `boar.gd`, `boss_enemy.gd`: 敌人差异
  - `*_patrol_state.gd`, `*_chase_state.gd`, `*_skill_state.gd`: 状态实现
- 通用战斗/交互: `scripts/general/`
  - `character.gd`: 血量、能量、无敌帧
  - `attack.gd`: 命中盒、伤害、hit feedback
  - `physics_check.gd`: 地面、墙、前方地面检测
  - `chest.gd`, `breakable.gd`, `collectible_reward.gd`: 可交互/奖励物
- UI: `scripts/ui/`
  - `main_menu.gd`, `menu_flow.gd`
  - `fade_canvas.gd`
  - `player_stat_bar.gd`
  - `reward_notification_ui.gd`
  - `localized_text.gd`, `language_toggle_button.gd`
- 资源类: `scripts/resources/`
- 场景切换组件: `scripts/transition/`
- 工具脚本: `scripts/tools/`
  - `level_2_forest_tile_painter.gd`: 按 `layout_id` 生成 Geometry，并管理 Background/Water/Foreground 编辑层
  - `build_forest_tileset.gd`: 重建森林 TileSet 的 World 碰撞
  - `process_art_assets.py`: 扫描原图集并记录帧/组件区域，不生成裁剪 PNG
  - `build_editor_asset_catalog.py`: 生成编辑器职责和动画目录
  - `build_editor_asset_library.gd`: 生成分类 TileSet、Scene Paint 场景和动画预览

## 场景

- 玩家 prefab: `scenes/player/player.tscn`
- 敌人 prefab:
  - `scenes/enemy/bee.tscn`
  - `scenes/enemy/snail.tscn`
  - `scenes/enemy/boss_enemy.tscn`
- 道具 prefab:
  - `scenes/props/chest.tscn`
  - `scenes/props/breakable_rock.tscn`
  - `scenes/props/collectible_reward.tscn`

## 数据

- 奖励表: `data/loot.json`
- 玩家成长: `data/progression.json`
- 章节: `data/chapters.json`
- 场景关系: `data/scene_links.json`
- UI 文本: `data/ui_strings.json`
- 森林 TileSet: `data/forest_tileset.tres`
- 编辑器素材目录: `data/editor_asset_catalog.json`
- 分类 TileSet: `data/tilesets/`
- 森林关卡布局: `data/level_layouts.json`
- 大型美术处理清单: `data/asset_manifest.json`

## 测试

- 单元测试: `tests/unit/`
- 集成测试:
  - `tests/integration/level_2_load_test.tscn`
  - `tests/integration/level_2_traversal_test.tscn`
  - `tests/integration/boss_skill_state_test.tscn`
- 视觉回归:
  - `tests/visual/level_2_playtest_capture.tscn`
  - `tests/visual/menu_playtest_capture.tscn`
  - `tests/visual/editor_asset_showcase.tscn`：分类素材分页 QA 长廊
- 冒烟测试:
  - `tests/e2e/smoke_test.tscn`
  - `tests/e2e/smoke_test.gd`

## 美术目录约定

- `art/imported/`: 原始图集和 sheet，是编辑器与运行时纹理的主要真相来源。
- `art/runtime/derived/`: 仅保存原图无法直接表达的人工合成/修复素材。
- `scenes/editor_library/`: 引用原图 region 的 Scene Paint 场景和动画预览。
- `data/tilesets/`: Background / Foreground / Water / Library 分类 TileSet。
- `art/processed/`: 已于 2026-07-14 移除；不再生成单格或逐帧裁剪 PNG。
- `output/imagegen/`: 生成图和中间图，不作为运行时直接资源使用。

完整使用方法见 `docs/art-asset-library.md`。

## 文档和生产资料

- 系统 GDD: `design/gdd/`
  - `forest-chapter-redesign.md`: Godot 4.7 森林关卡、角色和敌人重设计蓝图
- 架构决策: `docs/architecture/`
- Godot 4.7 教程校订: `docs/reference/warrior-legend-godot-notes/`
- 《勇士传说》39 集视频合集的 Unity→Godot 制作映射: `docs/reference/warrior-legend-video-series-study.md`
- 像素密度、角色比例和碰撞基线: `design/gdd/pixel-art-and-collision-standard.md`
- 生产/故事/QA: `production/`
- 项目说明: `CLAUDE.md`
