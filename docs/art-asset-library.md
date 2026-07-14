# Godot 编辑器素材库

本项目采用 **原图集优先（atlas-first）** 管线。Godot 直接引用 `art/imported/` 中的原始
sheet/atlas，并使用 TileSet atlas 坐标、`AtlasTexture.region` 或 SpriteFrames 帧区域选择素材。
不再为每个图块、动作帧或树木组件生成独立 PNG。

## 目录职责

- `art/imported/`：原始素材包，是纹理内容的主要真相来源。
- `art/runtime/derived/`：只有原图无法直接表达时才保存人工合成或修复后的运行素材。
- `data/asset_manifest.json`：原图集、帧区域和组件区域的技术清单。
- `data/editor_asset_catalog.json`：Godot 编辑职责、图层、碰撞、调色板和动画分组。
- `data/tilesets/`：编辑器可选择的分类 TileSet。
- `scenes/editor_library/`：Godot 4.7 Scene Paint Mode 可使用的场景和动画预览。

`art/processed/` 已移除。它曾保存 1500 余个机械裁剪 PNG，但这些文件丢失图集上下文、
存在错误裁切风险，并重复占用导入和版本控制空间。

## 当前生成基线

以下数字用于帮助 Agent 快速判断素材库能力；重新生成后应以
`data/editor_asset_catalog.json` 的 `summary` 和实际目录为准：

- 1495 项素材已索引为原始 atlas/sheet 的帧区域、单元区域或组件区域。
- 4 个分类 TileSet：
  - `forest_background_tileset.tres`：Background。
  - `forest_foreground_tileset.tres`：Foreground。
  - `forest_water_tileset.tres`：Animated Water。
  - `forest_library_tileset.tres`：完整 Atlas Library，用于查找和试验。
- `scenes/editor_library/scenes/` 当前有 218 个经语义筛选的 Scene Paint 场景；技术索引数量不等于可直接摆放数量。
- `scenes/editor_library/animated/` 中有 10 个玩家/敌人 `AnimatedSprite2D` 动画预览。
- 动态水体直接引用 `Forest-1.png`：4 帧水面为 3 FPS，三组 3 帧水体为 2 FPS。
- 宝箱和可破坏岩石使用 `AtlasTexture.region` 引用原图，不依赖裁剪图。

## TileMapLayer 调色板

森林关卡的 `MapVisuals` 使用四个职责明确的图层：

| 图层 | TileSet | 碰撞 | 用途 |
| --- | --- | --- | --- |
| `BackgroundTiles` | `forest_background_tileset.tres` | 无 | 树冠、远景和地面后方装饰 |
| `GeometryTiles` | `forest_tileset.tres` | World | Forest Ground Terrain、边角和实体地形 |
| `WaterTiles` | `forest_water_tileset.tres` | 无 | 动态水面与水体；玩法水域另用 Area2D |
| `ForegroundTiles` | `forest_foreground_tileset.tres` | 无 | 蘑菇、草花和稀疏前景遮挡 |

`forest_library_tileset.tres` 注册 `Forest-1.png` 和 `Forest-2.png` 的全部非空 16×16
单元，用于查找和试验原始素材。正式关卡优先使用职责明确的装饰 TileSet 与 Geometry
Terrain，避免把药瓶、钥匙或树冠碎片误画进地形。

在 Godot 中：

1. 打开关卡场景并选择目标 `TileMapLayer`。
2. 在 `BackgroundTiles`、`GeometryTiles`、`WaterTiles`、`ForegroundTiles` 中选择目标职责层，并使用该层绑定的调色板。
3. Geometry 使用 Terrain 工具；背景、前景和水体使用普通绘制/散布。
4. 不给 Background、Water 或 Foreground 添加 World 碰撞。

`level_2_forest_tile_painter.gd` 只会重建被配置为生成职责的内容：

- 人工绘制的 Background、Water 和 Foreground 不会在运行时被清空。
- Foreground 程序散布只填空单元，不覆盖人工绘制。
- 新关卡可关闭 `generate_geometry_from_layout`，让 `GeometryTiles` 完全由地编手工绘制。
- 保持该选项开启时，Geometry 仍以 `data/level_layouts.json` 为真相来源并由工具生成。

## Scene Paint Mode

变尺寸素材不强塞进 16×16 网格。生成场景位于：

```text
scenes/editor_library/scenes/
├── background_scene/       # 大树等已确认独立背景组件
├── structure_kit_scene/    # 门、横梁、立柱等需要组合使用的建筑套件
├── prop_scene/             # 已确认完整的矿洞入口和矿石堆
└── terrain_prop_scene/     # 岩石等无碰撞视觉摆件
```

这些场景的纹理是指向原 atlas 的 `AtlasTexture`，根节点位于素材底部中心。使用 Godot 4.7
2D Scene Paint Mode（默认 `B`）或直接拖入场景即可。生成的 `prop_scene` 和
`terrain_prop_scene` 默认是 **visual-only**；需要交互、伤害或碰撞时，应使用正式 prefab，
例如 `scenes/props/chest.tscn` 和 `scenes/props/breakable_rock.tscn`。

### 不规则图集不能按连通块直接绘制

`Hive.png`、`Forest-2.png`、`Buildings.png` 和 `Props-Rocks.png` 不是规则网格图集。
相邻部件可能互相接触，同一个完整物件也可能由多个互不连接的透明像素岛组成。因此：

- `asset_manifest.json` 中的 component region 只是技术候选区域，不代表一个完整物件。
- `editor_asset_catalog.json` 的 `editor.editor_ready` 才表示能否直接生成 Scene Paint。
- `editor.placement = standalone` 可单独落地；`kit_piece` 必须按门、横梁、立柱等语义组合。
- `atlas_fragment` / `atlas_reference` 只用于回看原图，不得直接摆进正式关卡。
- 当前 `Hive.png` 和 `Forest-2.png` 暂不生成 Scene Paint；它们仍保留在完整 Atlas Library，等待人工区域表。
- `Buildings.png` 排除两个由相邻排版粘连而成的大区域，只开放 11 个明确的结构套件部件。
- `Props-Rocks.png` 排除 `default_04`、`default_11`、`default_16` 三个包含多个相邻岩石的错误合并区域。

选中一个 Scene Paint 前先看根节点元数据 `placement`。套件部件必须先说明它在完整结构中的职责，
不能为了覆盖素材数量而单独悬空摆放。

## 场景主题路由

Agent 和地编人员不能只根据“看起来像”来选素材。主题描述应先映射到 catalog 的素材族和编辑职责：

| 场景主题 | 主要素材族/入口 | 用途 | 当前限制 |
| --- | --- | --- | --- |
| 森林 | `forest_geometry`、`forest_background`、`forest_foreground`、`forest_water`、树木 Scene Paint | 完整森林地形和装饰分层 | Geometry 仅使用 `forest_tileset.tres` 的 Terrain |
| 矿区 | `mine_stone`、筛选后的 `rocks`、`structure_kit_scene/buildings` | 完整矿洞入口为主体；岩石做边界；建筑套件只在能组成完整结构时使用 | 当前没有专用矿区 Geometry Terrain，三类 Scene Paint 均不能替代可站立地形 |
| 森林→矿区过渡 | Forest Ground + `rocks` + `mine_stone`，少量暗色树木 | 从自然环境逐步引入岩石与矿石语言 | 必须减少花草和明亮树冠，避免主题继续读成纯森林 |

矿区现有入口：

```text
scenes/editor_library/scenes/
├── prop_scene/mine_stone/          # 4 个矿石/矿区摆件
├── terrain_prop_scene/rocks/       # 33 个已排除错误粘连区域的岩石组件
└── structure_kit_scene/buildings/  # 11 个必须组合使用的建筑结构部件
```

主题选材步骤：

1. 确定主题 ID 和过渡关系，而不是只给一个氛围形容词。
2. 将地面、墙体、背景、前景、结构、摆件、交互物分别分配素材族。
3. 检查每个素材的 `editor.role`、`paint_mode` 和 `collision`。
4. 没有对应 Geometry Terrain 时记录资产缺口，只做经批准的灰盒占位。
5. 正式 prefab 与纯视觉 Scene Paint 版本不可互换。

## 素材验收场景

- `tests/visual/editor_asset_showcase.tscn`：分页查看全部分类 TileSet、当前可绘制 Scene Paint、动画预览和主题组合；headless 会核对 catalog 的实际数量。
- `scenes/levels/asset_showcase_level.tscn`：短关卡，按“森林高地 → 浅水石滩 → 矿洞入口”组合已确认素材；它不承担全量素材覆盖职责。

```powershell
& '<Godot 4.7 path>' --path . res://tests/visual/editor_asset_showcase.tscn
& '<Godot 4.7 path>' --path . res://scenes/levels/asset_showcase_level.tscn
```

## 动态素材

- `forest_water_tileset.tres` 直接在 `Forest-1.png` 上配置循环 atlas 动画：
  - 水面 `(6,14)` 起始，4 帧，3 FPS。
  - 浅/中/深水体 `(3,13..15)` 起始，各 3 帧，2 FPS。
- `scenes/editor_library/animated/` 包含玩家颜色变体以及 Bee、Snail、Boar 的
  `AnimatedSprite2D` 预览场景。
- 动画预览直接引用原始 sheet 的帧矩形，不引用独立帧 PNG。
- 攻击、受击和死亡默认不循环；Idle、Walk、Run、Fly 等循环播放。

## 重新生成

```powershell
python scripts/tools/process_art_assets.py
python scripts/tools/build_editor_asset_catalog.py
& '<Godot 4.7 console path>' --headless --path . --script res://scripts/tools/build_editor_asset_library.gd
```

第一步只扫描原图和记录区域，不裁剪图片。第三步会安全重建
`scenes/editor_library/`，并覆盖 `data/tilesets/` 中的生成资源。

## 验证

- `tests/unit/test_editor_asset_library.gd`：验证原图引用、分类 TileSet、动态水体和动画预览。
- `tests/unit/test_forest_tileset.gd`：验证实体 Terrain 和碰撞。
- `tests/integration/level_2_load_test.tscn`：验证四层 TileMap 职责及关卡落地状态。
- 视觉检查以 640×360 逻辑视口进行，像素纹理使用 Nearest 和整数缩放。
