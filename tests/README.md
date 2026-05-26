# Tests — 运行指南

本目录划分为两类测试：

| 子目录 | 用途 | 框架 | 运行频率 |
|--------|------|------|----------|
| `tests/unit/` | 单元测试，Arrange / Act / Assert，无副作用 | GdUnit4 v6.1.3 | 每次 PR 必跑 |
| `tests/e2e/`  | 端到端冒烟测试，串联场景切换 + 自动化输入 | 自定义脚本（非 GdUnit4） | 关键节点 + 发版前 |

---

## 1. 单元测试 — `tests/unit/`

### 命名约定

`test_[system]_[scenario]_[expected_result].gd` / 函数同名前缀。Arrange / Act / Assert 三段式（用注释标出）。

### 当前用例清单

| 文件 | 系统 | 用例数 |
|------|------|--------|
| `test_data_manager.gd` | DataManager save/load | 3 |
| `test_attack.gd` | Attack 冷却 / one-shot | 3 |
| `test_player_progression.gd` | 宝箱奖励 / 解锁幂等 | 3 |
| `test_character.gd` | Character 血量 / 能量 / 无敌帧 | 既有 |
| `test_persistence_key_utility.gd` | PersistenceKeyUtility | 既有 |
| `test_game_events.gd` | GameEvents 信号契约 | 既有 |
| `test_scene_resource_validator.gd` | GameSceneResource 死链校验 | 4 |

### 推荐运行方式 — 编辑器内

1. Godot 4.6.1 打开项目，等待全部脚本编译完成。
2. 顶部菜单 **Project → Tools → GdUnit4 → Test Runner**。
3. 在 GdUnit4 面板里选中 `tests/unit/` 节点 → Run。

### CLI 运行（GdUnit4 命令行）

```bash
# Windows
set GODOT_BIN=E:\Godot\Godot.exe
addons\gdUnit4\runtest.cmd --add tests/unit
```

退出码 0 = 全部 PASS，非 0 = 至少一个用例失败 / 解析错误。

> 如果某次刚切换/升级 GdUnit4 版本，CLI 第一次跑可能因 `class_name` 缓存未刷新而报 `Identifier ... not declared` 解析错误。
> 解决：先跑一次 `"E:\Godot\Godot.exe" --headless --path . --quit --import` 让 Godot 重建脚本缓存，再跑 `runtest.cmd`。

---

## 2. 冒烟测试 — `tests/e2e/smoke_test.tscn`

### 用途

5 步状态机，验证 menu → level → 玩家自动化输入 → 存档 → 回菜单链路完整。**不是** GdUnit4 测试。

### 运行方式

**编辑器：**

1. Project Settings → Run → Main Scene 临时改成 `res://tests/e2e/smoke_test.tscn`
2. 按 **F5** 启动
3. 看输出窗口的 `[smoke]` 前缀日志，最后一行 `结果：PASS` 或 `FAIL`

**CLI（不进编辑器）：**

```bash
E:\Godot\Godot.exe --path . res://tests/e2e/smoke_test.tscn
```

进程退出码 0 = PASS，非 0 = FAIL。

### 用例覆盖

1. `test_menu_new_game_loads_level_demo` — 主菜单 → 关卡跳转
2. `test_level_demo_world_nodes_present` — 关卡内必备节点（Player / Camera2D / Snail / Bee / SavePoint / TeleportToMenu / HUD ...）
3. `test_player_automation_attack_damages_enemy` — 自动化输入触发玩家攻击命中敌人
4. `test_save_point_writes_save_file_to_disk` — 触发存档点 → `user://SAVE_DATA/data.sav` 写盘
5. `test_teleport_to_menu_returns_to_main_menu` — 传送门触发 → 回主菜单

### 隔离保证

- 启动前 `_purge_save_dir()` 清掉 `user://SAVE_DATA/`
- 结束后再清一次，避免污染下一次手动启动

---

## 3. 测试编写约束

- **单元测试不得依赖 filesystem / 网络 / DB 真实状态**。需要 autoload 时通过 `override_*_paths_for_test()` 重定向到 `user://TEST_*/` 隔离目录。
- **AAA 三段式**：注释 `# Arrange / # Act / # Assert` 显式标出。
- **每个 bug fix 必须配回归用例**（test-standards.md 强制）。
- **测试数据**：在测试文件内或专用 fixture 定义；禁止跨用例共享可变状态。
