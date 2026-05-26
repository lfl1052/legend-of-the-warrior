# Story 1-7 — dev-only validator: 检查 GameSceneResource.scene_path 文件存在

**Status**: Complete
**Last Updated**: 2026-05-21
**Completed**: 2026-05-21
**Sprint**: 1
**Priority**: should-have
**Owner**: gameplay-programmer
**Estimate**: 0.5 day
**Type**: Logic
**ADR Governing Implementation**: docs/architecture/adr-003-game-scene-resource.md
**Manifest Version**: N/A — control-manifest.md 暂未创建
**TR-ID**: N/A — tr-registry.yaml 尚未引入；本 story 直接对应 ADR-003 Validation Criteria 的最后一条遗留项

## 用户故事

作为 **关卡 / 场景配置的维护者**，
我需要 **一个开发期工具脚本扫描 `data/*.tres`、报告所有 `scene_path` 指向的 `.tscn` 实际不存在的条目**，
以便 **新增场景或重构资源时，避免 .tres 漂移到死链而要等冒烟测试甚至运行时才被 SceneLoader 报 `INVALID_RESOURCE`**。

## 背景与 ADR 引用

ADR-003《GameSceneResource(.tres) 取代裸字符串场景路径》在 Validation Criteria 中已勾选 6 项，最后一项遗留：

> [ ] 加 dev-only validator 检查 `.tres.scene_path` 实际存在

并在 Risks 表第 1 行明确：

> | `.tres` 与 `.tscn` 路径不一致（人工维护） | Medium | Medium | 提供 dev-only validator skill 检查 scene_path 文件存在；`/code-review` 可加规则 |

本 story 落地这条 mitigation。GameSceneResource 字段（`scripts/resources/game_scene_resource.gd`）：

| 字段 | 类型 | 含义 |
|------|------|------|
| `scene_path` | `String`（@export_file("*.tscn")） | 目标 `.tscn` 文件 res:// 路径 |
| `display_name` | `String` | 本地化键 |
| `scene_type` | `int` Enums.SceneType.MENU / LOACTION（保留 Unity 拼写） |

当前 `data/` 下有 2 个 `.tres`：`scene_level_demo.tres`、`scene_warrior_menu.tres`，将作为 fixture。

## 验收标准

- [x] **AC-1 核心扫描函数**：`SceneResourceValidator.validate(scan_dir: String) -> Array[Dictionary]` 实现，扫描 `scan_dir` 下所有 `.tres`，对每个加载为 Resource 后探测 `scene_path` 字段（无该字段的 .tres 跳过），返回元素结构 `{ "tres_path": String, "scene_path": String, "scene_exists": bool, "display_name": String, "scene_type": int }`
- [x] **AC-2 死链检测正确**：当某条 .tres 的 `scene_path` 指向不存在文件时，对应返回项 `scene_exists == false`；当文件存在时 `scene_exists == true`
- [x] **AC-3 编辑器入口**：脚本带 `@tool`，可通过 EditorScript（File → New EditorScript 或 Tools 菜单触发）运行，输出格式 `[scene-validator] OK: N 个 .tres 全部命中` 或 `[scene-validator] FAIL: M / N 个 .tres 死链：\n  - res://data/foo.tres → res://scenes/missing.tscn` 到 Output 面板
- [x] **AC-4 单元测试覆盖**（`tests/unit/test_scene_resource_validator.gd`）：
  - `test_scene_resource_validator_returns_entry_per_tres` — 扫描固定 fixture 目录，返回项数 == fixture 中 .tres 数
  - `test_scene_resource_validator_marks_missing_path_as_dead` — 构造一条 `scene_path = "res://__nonexistent__.tscn"` 的 .tres fixture，断言 `scene_exists == false`
  - `test_scene_resource_validator_marks_existing_path_as_alive` — 用 `data/scene_warrior_menu.tres` 真实条目，断言 `scene_exists == true`
  - `test_scene_resource_validator_skips_non_game_scene_tres` — fixture 里放一个不带 `scene_path` 字段的 .tres（如 `LootTableResource`），断言被跳过不报错
- [x] **AC-5 不破坏 .tres**：validator 只 `load(...)` 后读字段，不写回任何 .tres / .tscn / 项目文件
- [x] **AC-6 命名与风格**：单元测试遵循 `test_[system]_[scenario]_[expected_result]` 与 AAA 三段式；GDScript 静态类型强制（`: Type` / `-> ReturnType`）

## 实现笔记

- **核心拆分**：把"递归收集 .tres" + "加载并取字段" + "存在性判断"拆成 3 个纯函数（`_collect_tres_files` / `_extract_scene_meta` / `_check_path_exists`），便于单元测试不依赖 EditorPlugin 上下文。
- **EditorScript 入口**：`scripts/tools/scene_resource_validator.gd` 顶部 `@tool extends EditorScript`；`_run()` 调用 `validate()` 并 `print()` 结果。不做 EditorPlugin 注册（0.5 day 预算内最小成本）。
- **ResourceLoader 一致性**：用 `ResourceLoader.exists(path, "PackedScene")` 而非 `FileAccess.file_exists(path)`，让 `.import` 缓存与 `.uid` 重定向都被识别。
- **跳过非 GameSceneResource**：以 `tres.has_method("is_menu")` 或 `"scene_path" in tres` 探测，避免硬绑定 class_name 触发循环依赖（ADR-0003 已明确 inspector 字段类型用 Resource 不用 GameSceneResource）。
- **测试 fixture 隔离**：把"故意死链"的 .tres 放在 `tests/unit/fixtures/scene_validator/` 子目录，不污染 `data/`。

## Out of Scope

- ❌ **不做** Continuous Integration 集成（CI 钩子由后续 story 处理，预计与 GdUnit4 CLI 一起接 pre-commit）
- ❌ **不做** 自动修复（不重写 scene_path、不删除死链 .tres）
- ❌ **不做** 反向检查（".tscn 未被任何 .tres 引用"），只做 .tres → .tscn 单向
- ❌ **不做** EditorPlugin 注册到 Project Settings（用 EditorScript 临时跑即可）
- ❌ **不做** Locale / display_name 校验（不属于路径漂移问题）

## 依赖

- **前置 story**：None（独立工具）
- **前置 ADR**：ADR-0003 已 `Status: Accepted`
- **前置代码**：`scripts/resources/game_scene_resource.gd`（已存在）、`data/scene_*.tres`（已存在 2 份）

## 性能预算

- **运行时**：N/A — 工具脚本，dev-only，不进 release build
- **扫描耗时**：100 个 .tres < 1 s（本地 SSD），不卡编辑器
- **测试耗时**：4 个用例总计 < 0.5 s

## 引擎注意点

- `@tool` + `extends EditorScript` 在 Godot 4.6 是稳定 API，无 post-cutoff 风险
- `ResourceLoader.exists(path, type_hint)` 自 Godot 4.0 起稳定，无版本风险

## Test Evidence

- **单元测试文件**：`tests/unit/test_scene_resource_validator.gd`
- **fixture 目录**：`tests/unit/fixtures/scene_validator/`（包含 1 死链 .tres + 1 非 GameSceneResource .tres）
- **CLI 验证**：`set GODOT_BIN=D:\lfl-work\Godot_v4.6.3-stable_win64.exe && addons\gdUnit4\runtest.cmd --add tests/unit/test_scene_resource_validator.gd` 退出码 0，4 个用例 PASS
- **编辑器手动验证**：在编辑器里 File → Run → 选 `scripts/tools/scene_resource_validator.gd`，Output 面板看到 `[scene-validator] OK: 2 个 .tres 全部命中`

## 关联文件

- **创建**：
  - `scripts/tools/scene_resource_validator.gd`（@tool EditorScript）
  - `tests/unit/test_scene_resource_validator.gd`
  - `tests/unit/fixtures/scene_validator/dead_link.tres`（fixture，故意死链）
  - `tests/unit/fixtures/scene_validator/non_game_scene.tres`（fixture，无 scene_path 字段）
- **修改**：
  - ADR-0003 Validation Criteria 末项 `[ ]` → `[x]`
- **引用代码**：
  - `scripts/resources/game_scene_resource.gd`
  - `data/scene_warrior_menu.tres` / `data/scene_level_demo.tres`

## 后续依赖

- 未来 CI / pre-commit 钩子可调用 `validate()` 返回值，非空死链列表 → 退出码非 0
- 反向校验（孤儿 .tscn）可作为后续 nice-to-have story

## Completion Notes

**Completed**: 2026-05-21
**Criteria**: 6/6 passing（无 deferred）
**Deviations**: 无 BLOCKING；同时修复 `level_demo` 冒烟暴露的 Godot 4.6.3 编译 / runtime 兼容问题，属于进入本 story 前的验证前置。
**Test Evidence**: `runtest.cmd --add tests/unit` Exit 0；40 用例全 PASS。`tests/e2e/smoke_test.tscn` 已通过菜单 → demo 关卡 → 存档 → 回菜单链路。
