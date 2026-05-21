# Story 1-5 — 测试基础设施整理 + GdUnit4 集成验证

**Status**: Complete (with known issues)
**Sprint**: 1
**Priority**: must-have
**Owner**: godot-gdscript-specialist
**Estimate**: 0.5 day
**Completed**: 2026-05-21

## 用户故事

作为 **后续故事的实施者**，
我需要 **测试目录结构整齐、运行方式有文档、GdUnit4 集成验证过**，
以便 **未来写新 story 时能直接照样补单元测试，而不必先回头清理基础设施**。

## 验收标准

- [x] 测试目录拆分为 `tests/unit/` 与 `tests/e2e/`：smoke_test.gd / .tscn / .uid 全部 `git mv` 进 `tests/e2e/`
- [x] `tests/README.md` 文档化运行方式（编辑器 GdUnit4 面板 / CLI / smoke_test 独立启动）
- [x] 修正全项目对旧路径 `tests/smoke_test.gd` 的 5 处引用（adr-001、adr-002、systems-index、technical-preferences、tscn 内 ext_resource）
- [x] GdUnit4 集成验证：发现 v4.4.3 与 Godot 4.6.1 三处 API 不兼容（`FileAccess.get_as_text(bool)` 取消、`Callable.call` 严格化、`DirAccess.current_dir` 改名），已记入 `tests/README.md` 已知问题区块
- [x] 派生 follow-up Story 1-9（升级 GdUnit4 到兼容 4.6.1 的版本）
- [x] 单文件解析校验：`test_data_manager.gd` / `test_attack.gd` / `test_player_progression.gd` 自身 GDScript 合法（autoload 标识符仅在整项目运行时可见）

## 实现笔记

- **runtest.cmd 不通的原因不在用例代码**：GdUnit4 v4.4.3 vendored 源码引用了 Godot 4.5 之前的 API，Godot 4.6.1 在加载阶段就报 Parse Error 把 GdUnitCmdTool.gd 阻塞住。改 vendored 源码会污染依赖且每升级一次都要重补，正确做法是升级到 v4.5+，作为 Story 1-9 跟踪。
- **绕行方案**：编辑器内 GdUnit4 面板（GUI 模式）可正常加载部分用例；CLI 批跑暂时阻塞。
- **smoke_test 路径修复**：`smoke_test.tscn` 的 `ext_resource path` 从 `res://tests/smoke_test.gd` 改为 `res://tests/e2e/smoke_test.gd`；自身 docstring 里的"运行方式"注释同步指向 `tests/e2e/smoke_test.tscn`。

## 关联文件

- 移动：`tests/smoke_test.gd` → `tests/e2e/smoke_test.gd`（含 .tscn / .uid）
- 创建：`tests/README.md`
- 修改：
  - `tests/e2e/smoke_test.tscn` ext_resource 路径
  - `docs/architecture/adr-001-autoload-event-bus.md`
  - `docs/architecture/adr-002-saveable-protocol.md`
  - `design/gdd/systems-index.md`
  - `.claude/docs/technical-preferences.md`
  - `scripts/autoload/language_manager.gd`（修复 `var lang := cfg.get_value(...)` 的 Variant 推导警告 → `var lang: String = ...`，让项目本身在 4.6.1 下不再报 Parse Error）

## 后续依赖

- **Story 1-9**：GdUnit4 升级后回头跑一次 `runtest.cmd --add tests/unit`，把 6 个用例全部走通；解除当前的 GUI-only 临时绕行
