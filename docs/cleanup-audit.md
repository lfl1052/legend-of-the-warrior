# Cleanup Audit

本文件记录项目整理时的安全清理建议。不要把“未被直接引用”自动等同于“可以删除”：Godot 项目里很多 `class_name` 脚本、测试、文档、美术库不会以 `res://...` 字符串形式出现。

## 当前直接运行时引用的美术

引用扫描排除了 `data/asset_manifest.json`，只统计 `project.godot`、`scenes/`、`scripts/`、`data/`、`tests/` 里的显式 `res://` 路径。

- `art/imported/Generic-Character/png/blue/char_blue_1.png`
- `art/imported/Generic-Character/png/red/char_red_1.png`
- `art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Attack/Attack-Sheet.png`
- `art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Fly/Fly-Sheet.png`
- `art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Hit/Hit-Sheet.png`
- `art/imported/Legacy-Fantasy-High Forest/Enemies/Snail/Dead-Sheet.png`
- `art/imported/Legacy-Fantasy-High Forest/Enemies/Snail/Hide-Sheet.png`
- `art/imported/Legacy-Fantasy-High Forest/Enemies/Snail/walk-Sheet.png`
- `art/imported/Legacy-Fantasy-High Forest/HUD/GameButtons.png`
- `art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png`
- `art/imported/Legacy-Fantasy-High Forest/Map Assets/Trees/Green-Tree.png`
- `art/processed/enemies/generated/root_stalker/root_stalker_sheet.png`
- `art/processed/enemies/generated/spore_shroom/spore_shroom_sheet.png`
- `art/processed/enemies/generated/thorn_sprout/thorn_sprout_sheet.png`
- `art/processed/map/props/chest/chest2_01.png`
- `art/processed/map/props/chest/chest2_02.png`
- `art/processed/map/terrain/rocks/props_rocks_01.png`

## 可以优先归档的候选

这些不是运行时必要文件，通常可以移到外部归档或加到忽略规则，但删除前建议确认是否还要保留生成过程。

- `output/imagegen/`
  - 目前包含生成图中间产物和参考图。
  - 三只生成敌人的运行时贴图已经在 `art/processed/enemies/generated/`。
  - 若不需要保留生成源，可归档；若之后还要重新处理或调整敌人图，先保留。
- `reports/report_*`
  - GdUnit 每次运行生成的报告。
  - 可删除或加入 `.gitignore`，保留最新一次报告即可。
- `.serena/`
  - 本地代码索引和记忆缓存。
  - 通常不应作为游戏资源提交；若团队不共享 Serena 记忆，可忽略。

## 已执行的安全清理

### 2026-07-11 资产库去重

本轮只删除满足以下条件的资源：

1. 文件内容 SHA-256 完全一致；
2. 不在 Godot 运行时显式引用路径中；
3. 保留路径更规范的副本；
4. 删除 PNG 时同步删除同名 `.png.import`；
5. 只清理空目录，不移动仍有内容的素材目录。

删除结果：

- 删除重复 PNG：90 个。
- 删除对应 `.png.import`：90 个。
- 移除空目录：12 个。

保留策略：

- `art/imported/Generic-Character/` 保留，删除重复的顶层 `art/imported/png/` 和顶层 `guide*.png` 副本。
- `art/processed/map/` 保留，删除误放在 `art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/` 下且与 processed 版本完全相同的地图/道具副本。
- `art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/` 暂时保留：这些是 boar 原始 sheet，不是 processed 切片的完全重复文件。

裁剪检查：

- 未发现全透明空图。
- 未发现明显的“超大透明画布里只有极小残片”的坏裁剪图。
- `art/processed/map/tiles/` 内仍有 exact duplicate tile，但它们可能对应瓦片表坐标/自动绘制规则，不在本轮按哈希直接删除。

## 需要人工确认后再动的候选

- `art/processed/characters/`
  - 当前玩家直接引用的是 `art/imported/Generic-Character/png/blue/char_blue_1.png`，不是这里的大量切片。
  - 这些可能是后续动画替换素材，不建议现在直接删。
- `art/processed/enemies/boar/`, `art/processed/enemies/bee/`, `art/processed/enemies/snail/`
  - 当前 bee/snail 场景仍直接用 `art/imported/...` 下的 sheet。
  - 处理后切片目前没有被场景直接引用，可能是预处理输出或未来替换素材。
- `art/processed/map/tiles/`, `art/processed/map/foliage/`, `art/processed/map/structures/`, `art/processed/map/props/`
  - 当前关卡主要用 `Forest-1.png` atlas 和少数 chest/rock 图。
  - 大量切片未挂场景，但可能是地图搭建素材库。
- `art/imported/`
  - 原始素材包。它很大，但里面有当前运行时直接引用的资源。
  - 更安全的整理方式是保留 `art/imported/used/` 或维护清单，而不是整目录删除。

## 不建议按“未引用”删除的脚本

下面这些脚本在直接路径扫描里会显示未引用，但大多通过 `class_name`、继承、状态机或测试间接使用。

- `scripts/enemy/base_state.gd`
- `scripts/enemy/enemy.gd`
- `scripts/enemy/enemy_minion.gd`
- `scripts/enemy/*_state.gd`
- `scripts/resources/*.gd`
- `scripts/utilities/enums.gd`
- `scripts/utilities/i_interactable.gd`
- `scripts/utilities/i_saveable.gd`

真正可能过期但需要逐个验证的脚本：

- `scripts/player/player_animation.gd`
- `scripts/general/audio_definition.gd`
- `scripts/transition/initial_load.gd`
- `scripts/ui/player_map_panel.gd`
- `scripts/ui/player_progression_panel.gd`
- `scripts/ui/safe_area_inset_anchor.gd`
- `scripts/enemy/boar_elite.gd`
- `scripts/enemy/boar_elite_skill_state.gd`

## 推荐整理顺序

1. 保留运行时核心目录：`scenes/`, `scripts/`, `data/`, 当前直接引用的 `art/` 文件。
2. 把 `output/imagegen/` 和 `reports/report_*` 作为第一批清理对象。
3. 决定 `art/processed/` 是“运行素材库”还是“可再生构建产物”。
4. 若要瘦身仓库，先把原始素材和处理后素材拆为：
   - `art/source/` 原始包
   - `art/runtime/` 当前场景直接引用
   - `art/library/` 暂未使用但保留的素材库
5. 每次移动/删除资源后运行：
   - Godot headless import
   - GdUnit unit tests
   - `tests/e2e/smoke_test.tscn`
