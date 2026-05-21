# Story 1-2 — DataManager save/load 往返单元测试

**Status**: Complete
**Sprint**: 1
**Priority**: must-have
**Owner**: godot-gdscript-specialist
**Estimate**: 1.0 day
**Completed**: 2026-05-21

## 用户故事

作为 **存档子系统的维护者**，
我需要 **DataManager 的 save / load / 损坏隔离三条路径都有测试覆盖**，
以便 **未来重构存档格式或 schema_version 升级时能立刻发现回归**。

## 验收标准

- [x] `test_data_manager_save_writes_schema_v1` — 保存后磁盘文件存在；`schema_version=1`；`float_data` 含注册的 saveable 数据
- [x] `test_data_manager_load_restores_float_data` — 预先铺一份合法存档到磁盘，调用 `load_from_disk()` 后 saveable 的字段被还原
- [x] `test_data_manager_corrupted_file_quarantines_to_bak` — 写入非法 JSON 后调用 load，主存档被移动到 `.bak`；内存回到空状态
- [x] DataManager 提供测试可达性钩子 `override_save_paths_for_test(dir)` / `clear_test_overrides()`，避免污染真实 `user://SAVE_DATA/`
- [x] 全部 3 个用例命名遵循 `test_[system]_[scenario]_[expected_result]`，AAA 三段式

## 实现笔记

- **路径常量改为 var**：`SAVE_DIR/SAVE_FILE/SAVE_QUARANTINE` 改名为 `DEFAULT_*` 常量 + 同名 `var` 字段，运行期可被测试钩子覆盖。生产代码不应触碰 var；只读 `DEFAULT_*`。
- **隔离目录**：测试用 `user://TEST_SAVE_DATA/`，`before_test/after_test` 两端 `_clean_test_dir()` 清场。
- **FakeSaveable**：内嵌 `class FakeSaveable extends RefCounted`，实现 `get_save_id / get_save_data / load_save_data` 三接口，最小化耦合。
- **损坏文件检测**：`load_from_disk()` 看到 `JSON.parse_string()` 返回非 Dictionary 即调用 `_quarantine_corrupted()` 把主文件 copy + remove。

## 关联文件

- 创建：`tests/unit/test_data_manager.gd`
- 修改：`scripts/autoload/data_manager.gd`（新增 `override_save_paths_for_test` / `clear_test_overrides`）
- 引用代码：`scripts/utilities/i_saveable.gd`（ISaveable duck-typing 协议）

## 后续依赖

- **Story 1-4** 也使用 `override_save_paths_for_test` 隔离 PlayerProgression 的 register 副作用
- **Story 1-9** GdUnit4 升级后可在 CLI 跑通这 3 个用例（当前在编辑器面板可运行）
