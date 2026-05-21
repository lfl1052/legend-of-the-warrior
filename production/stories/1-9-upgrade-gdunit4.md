# Story 1-9 — 升级 GdUnit4 到兼容 Godot 4.6.1 的版本

**Status**: Not Started
**Sprint**: TBD（Sprint 1 派生 follow-up）
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

- [ ] `addons/gdUnit4/` 升级到与 Godot 4.6.1 兼容的版本（v4.5+ 或 master）
- [ ] `addons/gdUnit4/plugin.cfg` 的 `version=` 字段同步更新
- [ ] 在新版本下执行 `set GODOT_BIN=E:\Godot\Godot.exe && addons\gdUnit4\runtest.cmd --add tests/unit` 退出码 0
- [ ] 6 个单元测试用例全部 PASS（`test_data_manager.gd` 3 个 + `test_attack.gd` 3 个 + `test_player_progression.gd` 3 个 + `test_character.gd` + `test_persistence_key_utility.gd` + `test_game_events.gd`）
- [ ] 升级路径写入 `tests/README.md`，移除当前的"已知问题"块

## 注意事项

- `test_persistence_key_utility.gd` 单文件解析有遗留警告 `Cannot infer the type of "def" variable`，与 GdUnit4 升级独立。如该文件继续阻塞测试套件，临时 skip 或在 1-9 同期清理。
- 升级后回头校验 `language_manager.gd:59` 的 String 类型修复仍有效（不应被覆盖回 `var := cfg.get_value(...)`）。

## 关联文件

- `addons/gdUnit4/`（整个插件目录将被替换）
- `addons/gdUnit4/plugin.cfg`
- `tests/README.md`（移除"已知问题"块）
