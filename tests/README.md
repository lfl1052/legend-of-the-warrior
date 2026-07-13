# Tests — 运行指南

本目录划分为两类测试：

| 子目录 | 用途 | 框架 | 运行频率 |
|--------|------|------|----------|
| `tests/unit/` | 单元测试，Arrange / Act / Assert，无副作用 | GdUnit4 v6.1.3 | 每次 PR 必跑 |
| `tests/integration/` | 关卡装载、TileMap 碰撞和自动通路 | 自定义测试场景 | 关卡改动后 |
| `tests/e2e/`  | 端到端冒烟测试，串联场景切换 + 自动化输入 | 自定义脚本（非 GdUnit4） | 关键节点 + 发版前 |

---

## 1. 单元测试 — `tests/unit/`

### 命名约定

`test_[system]_[scenario]_[expected_result].gd` / 函数同名前缀。Arrange / Act / Assert 三段式（用注释标出）。

### 当前用例清单

| 文件 | 系统 | 用例数 |
|------|------|--------|
| `test_actor_visual_contracts.gd` | 角色比例 / 脚底基线 / 动画职责 | 5 |
| `test_attack.gd` | Attack 冷却 / one-shot | 3 |
| `test_audio_manager.gd` | 音效 / BGM / 音量 / 停止 | 9 |
| `test_boss_skill_state.gd` | Boss 技能状态循环 | 1 |
| `test_breakable.gd` | 可破坏物 / 奖励 / 存档 | 2 |
| `test_camera_control.gd` | 逻辑视口 / 相机死区 / 构图偏移 | 3 |
| `test_chapter_data.gd` | 章节与关卡布局数据 | 2 |
| `test_character.gd` | 血量 / 能量 / 无敌帧 | 15 |
| `test_chest.gd` | 宝箱 / 奖励 / 存档 | 3 |
| `test_collectible_reward.gd` | 收集物奖励 | 3 |
| `test_combat_feedback.gd` | 战斗反馈事件 | 1 |
| `test_data_manager.gd` | 存档读写 / 损坏隔离 | 3 |
| `test_enemy_combatant.gd` | 敌人受击 / 死亡 | 2 |
| `test_enemy_perception.gd` | 敌人范围感知 / 世界遮挡 | 2 |
| `test_fade_canvas.gd` | 淡入淡出 | 1 |
| `test_forest_tileset.gd` | Terrain 规则 / 碰撞 / 安全装饰 | 4 |
| `test_game_events.gd` | 全局信号契约 | 10 |
| `test_persistence_key_utility.gd` | 持久化键 | 4 |
| `test_physics_check.gd` | 巡逻墙面 / 悬崖检测 | 3 |
| `test_player_dash.gd` | 冲刺 / 跳跃窗口 / 死亡 / 复活 | 6 |
| `test_player_progression.gd` | 奖励 / 解锁幂等 | 3 |
| `test_scene_loader.gd` | 淡出与线程加载 | 2 |
| `test_scene_resource_validator.gd` | 场景资源死链校验 | 5 |
| `test_snail_behavior.gd` | 蜗牛感知 / 缩壳 | 3 |

Godot 4.7 stable 验证基线（2026-07-13）：**24 个测试套件，95/95 用例通过**。

### 推荐运行方式 — 编辑器内

1. 使用 Godot 4.7 stable 打开项目，等待全部脚本编译完成。
2. 顶部菜单 **Project → Tools → GdUnit4 → Test Runner**。
3. 在 GdUnit4 面板里选中 `tests/unit/` 节点 → Run。

### CLI 运行（GdUnit4 命令行）

```bat
# Windows
set GODOT_BIN=E:\Godot\Godot.exe
addons\gdUnit4\runtest.cmd --godot_binary "%GODOT_BIN%" --add tests/unit
```

退出码 0 = 全部 PASS，非 0 = 至少一个用例失败 / 解析错误。

> 如果某次刚切换/升级 GdUnit4 版本，CLI 第一次跑可能因 `class_name` 缓存未刷新而报 `Identifier ... not declared` 解析错误。
> 解决：先跑一次 `"E:\Godot\Godot.exe" --headless --path . --quit --import` 让 Godot 重建脚本缓存，再跑 `runtest.cmd`。

---

## 2. 冒烟测试 — `tests/e2e/smoke_test.tscn`

### 用途

6 步状态机，验证 menu → demo → 玩家自动化输入 → 存档 → level_2 往返 → 回菜单链路完整。**不是** GdUnit4 测试。

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
5. `test_demo_and_level_2_round_trip` — Demo ↔ Level 2 双向场景切换
6. `test_teleport_to_menu_returns_to_main_menu` — 传送门触发 → 回主菜单

### 关卡集成验证

- `tests/integration/level_2_load_test.tscn`：验证三层 `TileMapLayer`、TileSet 碰撞、关卡节点和角色落地。
- `tests/integration/level_2_traversal_test.tscn`：自动玩家穿越完整 `level_2` 路线，防止平台布局形成死路。
- `tests/visual/level_2_playtest_capture.tscn`：生成 arrival / combine / boss 三个代表状态截图到 `reports/playtest/`。
- `tests/visual/menu_playtest_capture.tscn`：生成 640×360 逻辑视口下的菜单截图到 `reports/playtest/`。

### 隔离保证

- 启动前 `_purge_save_dir()` 清掉 `user://SAVE_DATA/`
- 结束后再清一次，避免污染下一次手动启动

---

## 3. 测试编写约束

- **单元测试不得依赖 filesystem / 网络 / DB 真实状态**。需要 autoload 时通过 `override_*_paths_for_test()` 重定向到 `user://TEST_*/` 隔离目录。
- **AAA 三段式**：注释 `# Arrange / # Act / # Assert` 显式标出。
- **每个 bug fix 必须配回归用例**（test-standards.md 强制）。
- **测试数据**：在测试文件内或专用 fixture 定义；禁止跨用例共享可变状态。
