# Story 1-9 — 升级 GdUnit4 到兼容 Godot 4.6.1 的版本

**Status**: Complete
**Last Updated**: 2026-05-21
**Completed**: 2026-05-21
**Sprint**: 1
**Priority**: should-have
**Owner**: godot-gdscript-specialist
**Estimate**: 0.5 day

## 用户故事

作为 **测试基础设施的维护者**，
我需要 **GdUnit4 在 Godot 4.6.1 下能从 CLI 跑通 `runtest.cmd --add tests/unit`**，
以便 **未来 CI / pre-commit 钩子能批量校验单元测试，不再依赖手动开编辑器面板**。

## 背景

Sprint 1 落地的 6 个单元测试在 Godot 4.6.1 + GdUnit4 v4.4.3 组合下 CLI 加载阶段就报 Parse Error 失败。根因是 GdUnit4 vendored 源码使用了 4.5 之前的 API：

| 文件 | 行 | 不兼容点 |
|------|----|---------|
| `addons/gdUnit4/src/core/GdUnitFileAccess.gd` | 191 | `FileAccess.get_as_text(true)` — 4.6 移除 bool 参数 |
| `addons/gdUnit4/src/doubler/CallableDoubler.gd` | 84 | `Callable.call(...)` 签名与 native 父类不符（4.6 强制校验 `native_method_override`） |
| `addons/gdUnit4/bin/GdUnitCmdTool.gd` | 108 | `DirAccess.current_dir` 已改名 |

详见 [Story 1-5](1-5-test-infrastructure-cleanup.md) 的"实现笔记"区块。

## 验收标准

- [x] `addons/gdUnit4/` 升级到与 Godot 4.6.1 兼容的版本（v4.5+ 或 master）
- [x] `addons/gdUnit4/plugin.cfg` 的 `version=` 字段同步更新
- [x] 在新版本下执行 `set GODOT_BIN=E:\Godot\Godot.exe && addons\gdUnit4\runtest.cmd --add tests/unit` 退出码 0
- [x] 6 个单元测试用例全部 PASS（`test_data_manager.gd` 3 个 + `test_attack.gd` 3 个 + `test_player_progression.gd` 3 个 + `test_character.gd` + `test_persistence_key_utility.gd` + `test_game_events.gd`）
- [x] 升级路径写入 `tests/README.md`，移除当前的"已知问题"块

## 注意事项

- `test_persistence_key_utility.gd` 单文件解析有遗留警告 `Cannot infer the type of "def" variable`，与 GdUnit4 升级独立。如该文件继续阻塞测试套件，临时 skip 或在 1-9 同期清理。
- 升级后回头校验 `language_manager.gd:59` 的 String 类型修复仍有效（不应被覆盖回 `var := cfg.get_value(...)`）。

## 关联文件

- `addons/gdUnit4/`（整个插件目录将被替换）
- `addons/gdUnit4/plugin.cfg`
- `tests/README.md`（移除"已知问题"块）

## Completion Notes
**Completed**: 2026-05-21
**Criteria**: 5/5 passing（无 deferred）
**Deviations**: 无 BLOCKING；范围外延仅同步 `.claude/docs/technical-preferences.md` 与 `design/gdd/systems-index.md` 的版本号引用，属合理外延
**Test Evidence**: `runtest.cmd --add tests/unit` Exit 0；36 用例全 PASS（`tests/unit/test_data_manager.gd`、`test_attack.gd`、`test_player_progression.gd`、`test_character.gd`、`test_persistence_key_utility.gd`、`test_game_events.gd`）
**Code Review**: Complete — APPROVED WITH SUGGESTIONS（2 条非 BLOCKING：`test_persistence_key_utility` 弱断言可锁形态；`test_game_events` 的 `disconnect` 可挪入 `after_test`）

### 实现要点
- 仓库迁移：`MikeSchulze/gdUnit4` → `godot-gdunit-labs/gdUnit4`，下载 `v6.1.3.zip` 替换整个 `addons/gdUnit4/`
- 升级后必须先跑一次 `Godot.exe --headless --path . --quit --import` 重建脚本缓存，否则首次 CLI 跑会报 `Identifier "GdUnitTestCIRunner" not declared`
- 暴露的 4 处 GDScript lambda by-value 捕获 bug（`emit_count` / `received` / `value` × 2）：用 `Dictionary` 包装 state 绕开
- `test_character_take_damage_emits_died_signal`：`await assert_signal()` 必须在信号触发前进入等待，所以伤害调用要 `call_deferred` 让它发生在下一帧
