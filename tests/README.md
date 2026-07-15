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
| `test_actor_visual_contracts.gd` | 角色比例 / 脚底基线 / 动画图集 / HurtBox / 受击间隔 | 13 |
| `test_asset_showcase_level.gd` | 素材验收关卡结构 / 语义组合约束 | 2 |
| `test_attack.gd` | Attack 冷却 / one-shot / HurtBox 接收者去重 | 4 |
| `test_audio_manager.gd` | Music/SFX Bus / 音效 / BGM / 真静音 / 暂停 / 停止 | 11 |
| `test_boss_skill_state.gd` | Boss 技能状态循环 / 范围预警 / 受击中断 | 3 |
| `test_breakable.gd` | 可破坏物 / 奖励 / 存档 | 2 |
| `test_camera_control.gd` | 逻辑视口 / 相机死区 / 边界夹紧 / 抖动归零 | 7 |
| `test_chapter_data.gd` | 章节与关卡布局数据 | 2 |
| `test_character.gd` | 血量 / 能量 / 无敌帧 | 15 |
| `test_chest.gd` | 宝箱 / 奖励 / 存档 | 3 |
| `test_collectible_reward.gd` | 收集物奖励 | 3 |
| `test_combat_feedback.gd` | 战斗反馈事件 | 1 |
| `test_data_manager.gd` | 原子存档 / 新游戏清理 / v0 迁移 / 字段校验 / 大小限制 / 损坏隔离 | 12 |
| `test_encounter_reward_controller.gd` | Encounter 清场奖励 / 重复信号去重 | 1 |
| `test_enemy_combatant.gd` | 敌人受击 / 死亡 | 2 |
| `test_enemy_course_actions.gd` | 野猪前向攻击启停、蜜蜂窗口、蜗牛动作条/朝向/缩壳关闭攻击 | 11 |
| `test_enemy_perception.gd` | 敌人范围感知 / 世界遮挡 / 目标记忆 | 3 |
| `test_environment_hazard.gd` | 环境伤害入口 / 间隔 / HurtBox 去重 | 2 |
| `test_editor_asset_library.gd` | 原图集素材目录 / 分类 TileSet / 动态水体 / Scene Paint / 不规则图集筛选 | 6 |
| `test_fade_canvas.gd` | 淡入淡出端点 / 非零时长 / Tween 取消 / 暂停态 | 4 |
| `test_forest_tileset.gd` | Terrain 规则 / 碰撞 / 安全装饰 / 背景树裁切 | 5 |
| `test_game_events.gd` | 全局信号契约 | 10 |
| `test_menu_visual_contract.gd` | 课程森林背景 / 循环景深 / 640×360 / 菜单导航路径 | 3 |
| `test_persistence_key_utility.gd` | 持久化键 | 4 |
| `test_physics_check.gd` | 巡逻墙面 / 悬崖检测 | 3 |
| `test_player_dash.gd` | 课程式滑铲 / Power / 碰撞恢复 / 撞墙离地 / 连击与墙滑 | 15 |
| `test_player_progression.gd` | 奖励 / 解锁幂等 | 3 |
| `test_player_action_states.gd` | Land / 下蹲身体与受击框 / 三段攻击框 / 格挡 / Heal / 梯子 | 8 |
| `test_player_skill_slash.gd` | 技能斩消耗 / 生效帧 / 朝向 / 范围提示与边界 | 5 |
| `test_scene_loader.gd` | 淡出 / 线程加载 / 并发忽略 / 失败恢复 / 输入顺序 | 7 |
| `test_scene_resource_validator.gd` | 场景资源死链校验 | 5 |
| `test_save_point.gd` | 保存成功/失败、首次奖励、重复保存、旧档视觉恢复、交互范围 | 4 |
| `test_sign.gd` | 重叠交互候选 / 最近目标 / Prompt 动画 / 暂停隐藏 | 4 |
| `test_snail_behavior.gd` | 蜗牛感知 / 缩壳 | 3 |

Godot 4.7 stable 验证基线（2026-07-15）：**34 个测试套件，186/186 用例通过**。

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

7 步状态机，验证 menu → demo → 玩家自动化输入 → 存档 → level_2 往返 → 回菜单 → Continue 完整恢复。**不是** GdUnit4 测试。

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
7. `test_continue_restores_saved_player_state` — Continue 恢复保存场景、位置、生命、能量与 HUD

### 关卡集成验证

- `tests/integration/level_2_load_test.tscn`：验证三层 `TileMapLayer`、TileSet 碰撞、关卡节点和角色落地。
- `tests/integration/level_2_traversal_test.tscn`：自动玩家穿越完整 `level_2` 路线，防止平台布局形成死路。
- `tests/visual/level_2_playtest_capture.tscn`：生成 arrival / walk / fall / wall / boar / skill_slash / combine / boss / boss_reward / water_hazard 代表状态截图到 `reports/playtest/`。
- `tests/visual/gameplay_overlay_capture.tscn`：生成 Game Over 与 Pause 面板截图，检查 640×360 下按钮和三路音量控件完整可见。
- `tests/visual/save_point_capture.tscn`：生成存储点未激活、已激活、保存成功和保存失败四个代表状态截图。
- `tests/visual/player_extended_actions_capture.tscn`：生成 land / crouch / heal / block / climb 五个玩家扩展动作截图到 `reports/playtest/`。
- `tests/visual/enemy_course_actions_capture.tscn`：生成 boar wait/chase、snail hide/unhide、bee attack/chase 六个课程敌人动作截图。
- `tests/visual/menu_playtest_capture.tscn`：生成 640×360 逻辑视口下的菜单截图到 `reports/playtest/`。
- `tests/visual/editor_asset_library_capture.tscn`：验证原 atlas 的树木、建筑、岩石、动画角色与动态水体可共同实例化和绘制。
- `tests/visual/editor_asset_showcase.tscn`：分页检查分类 TileSet、经语义筛选的 Scene Paint 和动画预览；headless 会核对 catalog 数量。
- `scenes/levels/asset_showcase_level.tscn`：可玩的森林高地、浅水石滩、矿洞入口短关卡，用于验证素材能否组成完整地点。

### 隔离保证

- 启动前 `_purge_save_dir()` 清掉 `user://SAVE_DATA/`
- 结束后再清一次，避免污染下一次手动启动

---

## 3. 测试编写约束

- **单元测试不得依赖 filesystem / 网络 / DB 真实状态**。需要 autoload 时通过 `override_*_paths_for_test()` 重定向到 `user://TEST_*/` 隔离目录。
- **AAA 三段式**：注释 `# Arrange / # Act / # Assert` 显式标出。
- **每个 bug fix 必须配回归用例**（test-standards.md 强制）。
- **测试数据**：在测试文件内或专用 fixture 定义；禁止跨用例共享可变状态。
