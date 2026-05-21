# Story 1-1 — 创建 5 份起步 JSON 配置文件

**Status**: Complete
**Sprint**: 1
**Priority**: must-have
**Owner**: gameplay-programmer
**Estimate**: 1.0 day
**Completed**: 2026-05-21

## 用户故事

作为 **运行时数据消费方**（RuntimeData / PlayerProgression / LanguageManager / Chest / PlayerMapPanel），
我需要 **`res://data/` 下存在 loot/progression/chapters/scene_links/ui_strings 五份 JSON 配置**，
以便 **启动时不再触发 push_warning，并让 demo 关卡的奖励/解锁/UI 文本路径有真实数据可用**。

## 验收标准

- [x] `data/loot.json` — 5 个战利品表（教程基础/丰厚 + Demo 关卡 unlock-heal/upgrade/map）
- [x] `data/progression.json` — `default_max_health=5.0`、`heal_ratio=0.45`、3 条 milestone（heal / skill-1 / map）
- [x] `data/chapters.json` — 章节 0（菜单）+ 章节 1（含 level_demo）
- [x] `data/scene_links.json` — menu↔demo 双向跳转
- [x] `data/ui_strings.json` — 17 条 zh/en 双语条目，覆盖 ui.map.* / ui.progression.* / ui.reward.* / ui.milestone.* / ui.chapter.*
- [x] 所有 JSON 通过 `json.load()` 校验
- [x] 文件结构契合 RuntimeData._load_dictionary / _load_object 期望（数组带主键 vs 单一对象）→ 启动不再 push_warning

## 实现笔记

- **loot.json 的 `unlock_slot` 字段**：当 reward_id ∈ {tutorial-economy-token, upgrade-token, map-token, health-refill, power-refill} 之外时，PlayerProgression._apply_reward 走 default 分支，从 payload 读 `unlock_slot`。因此 `level_demo_chest_unlock_heal` / `level_demo_chest_map` 的 entry 加了 `unlock_slot` 字段，reward_id 用了占位 `unlock-slot`（不在 match 列表里，会 fallthrough）。
- **progression.json 的 milestone 字段**：当前 `PlayerProgressionResource.from_dict` 仅消费 `unlock_slot` 字段；其它字段（`tutorial_economy_tokens_required` / `upgrade_tokens_required` / `display_name_key`）为 milestone 升级面板预留，后续 story 实现 UI 时无需改 JSON。
- **scene_links 的 from_scene/to_scene**：用 scene 文件 basename（无 .tscn 扩展），匹配 `PlayerMapPanel._collect_routes` 的 `scene_path.get_file().get_basename()` 比较逻辑。
- **ui_strings 的 key 集合**：精确对应 `LanguageManager.get_text()` 调用点（grep 静态扫描得出），未来新增 UI 时同步增条目即可。

## 关联文件

- 创建：`data/loot.json`、`data/progression.json`、`data/chapters.json`、`data/scene_links.json`、`data/ui_strings.json`
- 引用代码：
  - `scripts/autoload/runtime_data.gd` — JSON 加载器
  - `scripts/resources/loot_table_resource.gd` / `chapter_resource.gd` / `scene_link_resource.gd` / `player_progression_resource.gd`
  - `scripts/player/player_progression.gd` — reward 路由
  - `scripts/general/chest.gd` — 宝箱触发战利品表
  - `scripts/ui/player_map_panel.gd` — 消费 scene_links

## 后续依赖

- **Story 1-4** (PlayerProgression 代币测试) 需要 progression.json 的 milestones 数据驱动测试用例
- **Story 1-2** (DataManager save/load) 与本 story 无强耦合，可并行
