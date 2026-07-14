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
2. 在底部 TileMap 面板选择该层已绑定的 TileSet。
3. Geometry 使用 Terrain 工具；背景、前景和水体使用普通绘制/散布。
4. 不给 Background、Water 或 Foreground 添加 World 碰撞。

## Scene Paint Mode

变尺寸素材不强塞进 16×16 网格。生成场景位于：

```text
scenes/editor_library/scenes/
├── background_scene/       # 大树等背景组件
├── foliage_scene/          # Forest-2 植被和树干组件
├── structure_scene/        # 建筑组件
├── prop_scene/             # 蜂巢等视觉摆件
└── terrain_prop_scene/     # 岩石等无碰撞视觉摆件
```

这些场景的纹理是指向原 atlas 的 `AtlasTexture`，根节点位于素材底部中心。使用 Godot 4.7
2D Scene Paint Mode（默认 `B`）或直接拖入场景即可。生成的 `prop_scene` 和
`terrain_prop_scene` 默认是 **visual-only**；需要交互、伤害或碰撞时，应使用正式 prefab，
例如 `scenes/props/chest.tscn` 和 `scenes/props/breakable_rock.tscn`。

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
