# Story 1-8 - 第二关脚手架 + chapter 关联

**Status**: Complete
**Last Updated**: 2026-05-22
**Completed**: 2026-05-22
**Sprint**: 1
**Priority**: nice-to-have
**Owner**: level-designer
**Estimate**: 1.0 day
**Type**: Level / Data

## 用户故事

作为关卡维护者，我需要一个第二关基础脚手架和对应场景元数据，并把它关联到 chapter_1，便于后续继续扩展关卡内容与场景流转。

## 验收标准

- [x] 创建 `scenes/levels/level_2.tscn` 基础结构。
- [x] 创建 `data/scene_level_2.tres`，指向真实 `.tscn`。
- [x] `data/chapters.json` 中 `chapter_1.scene_ids` 包含 `level_demo` 与 `level_2`。
- [x] 场景资源 validator 覆盖 level_2。
- [x] 第二关场景可 headless 加载。

## 实现笔记

- `level_2.tscn` 沿用 demo 关卡结构：World / Player / enemies / SavePoint / Teleport / Camera / HUD / FadeCanvas。
- 第二关加入 `BossEnemy` 占位实例，给后续 Boss 战内容留入口。
- `TeleportToDemo` 暂时回到 `level_demo`，保证关卡脚手架具备可用返回路径。
- 新增 `test_chapter_data.gd` 验证 chapter 关联，新版 scene validator 测试验证 `scene_level_2.tres` 指向真实场景。

## Test Evidence

- `Godot_v4.6.3-stable_win64.exe --headless --path . --check-only` Exit 0
- `addons\gdUnit4\runtest.cmd --add tests\unit` Exit 0, 43/43 PASS
- `Godot_v4.6.3-stable_win64.exe --headless --path . --scene res://scenes/levels/level_2.tscn --quit-after 20` Exit 0

## 关联文件

- `scenes/levels/level_2.tscn`
- `data/scene_level_2.tres`
- `data/chapters.json`
- `tests/unit/test_chapter_data.gd`
- `tests/unit/test_scene_resource_validator.gd`
