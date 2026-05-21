# 系统 GDD: Autoload 服务层

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-AUTOLOAD |
| **系统名称** | Autoload 服务层 |
| **优先级** | 🔴 P0 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/autoload/` 共 7 个 `.gd` + `mcp_bridge_game.gd` |

---

## 概述

从 Unity 项目迁移过来的 8 个常驻服务，在 Godot 中通过 `project.godot [autoload]` 注册为场景树根节点子节点。每个服务负责一个横切关注点，通过 `GameEvents` 信号总线通信，模块间无直接引用。

## 架构图

```
SceneTree.root
 ├── GameEvents      # 信号总线
 ├── RuntimeData     # JSON 数据加载
 ├── DataManager     # 存档/读档
 ├── SceneLoader     # 场景加载
 ├── AudioManager    # 音频
 ├── LanguageManager # 双语
 ├── UIManager       # UI 根层
 └── McpBridgeGame   # 编辑器 MCP 协议桥
```

## 各服务详述

### 1. GameEvents — 全局信号总线

**文件**: `scripts/autoload/game_events.gd` (~170 行)

替代 Unity 的 `ScriptableObject EventChannel` 体系（VoidEventSO / FloatEventSO / CharacterEventSO / FadeEventSO / SceneLoadEventSO）。

**信号分组**:

| 分组 | 信号 | 参数 |
|------|------|------|
| 流程 | `new_game_started`, `save_data_requested`, `load_data_requested`, `back_to_menu_requested`, `game_over`, `after_scene_loaded`, `camera_shake`, `pause_toggled` | 无参 |
| 数值 | `volume_changed`, `volume_synced` | `amount: float` |
| 音频 | `play_bgm`, `play_fx` | `stream: AudioStream`, `position: Vector2` |
| 角色 | `character_health_changed`, `character_took_damage`, `character_died` | `character: Object`, `attacker: Node` |
| 淡入淡出 | `fade_requested` | `color: Color`, `duration: float`, `fade_in: bool` |
| 场景加载 | `scene_load_requested`, `scene_unloaded` | `scene_resource: Resource`, `position_to_go: Vector3`, `fade_screen: bool` |
| Encounter | `encounter_focus_changed`, `encounter_phase_changed`, `encounter_poise_changed`, `encounter_skill_cooldown_changed` | `encounter_owner: Object`, `phase_index: int`, `ratio: float`, `skill_id: StringName` |
| UI/奖励 | `reward_notification` | `reward_id: StringName`, `payload: Dictionary` |

**设计约束**:
- 所有信号都有 `raise_xxx()` 包装方法，禁止订阅方直接 `emit`
- 信号参数显式类型声明
- autoload 节点常驻，不需要 `disconnect`（非 autoload 节点仍需在 `_exit_tree` 中 disconnect）
- `character_health_changed(character: Object)` 用 Object 而非 Character，兼容 Encounter HUD

### 2. RuntimeData — 运行时数据

**文件**: `scripts/autoload/runtime_data.gd` (~100 行)

替代 Unity 的 `LegendOfWarriorRuntimeData` 静态类。启动时从 `res://data/` 加载 5 份 JSON 文件。

**加载的数据集**:

| JSON 文件 | 字段 | 内容 |
|-----------|------|------|
| `loot.json` | `loot_tables: Dictionary` | 战利品表 id -> Dictionary |
| `progression.json` | `player_progression: Dictionary` | 玩家进阶配置 |
| `chapters.json` | `chapters: Dictionary` | 章节定义 id -> Dictionary |
| `scene_links.json` | `scene_links: Dictionary` | 场景跳转关系 id -> Dictionary |
| `ui_strings.json` | `ui_strings: Dictionary` | UI 文本 key -> {zh/en -> String} |

**查询 API**:
- `try_get_loot_table(id: StringName) -> Dictionary`
- `get_player_progression() -> Dictionary`
- `try_get_chapter(id: StringName) -> Dictionary`
- `try_get_scene_link(id: StringName) -> Dictionary`
- `try_get_ui_string(key: StringName, language: String) -> String`

**容错**: 文件可缺失（对应字典保持空），JSON 格式错误仅 push_warning 不崩溃。

### 3. DataManager — 存档管理器

**文件**: `scripts/autoload/data_manager.gd` (~177 行)

替代 Unity 的 `DataManager` 单例 + Newtonsoft.Json。详见 ADR-002。

**核心功能**:
- ISaveable 鸭子类型注册表（`register` / `unregister`）
- 写盘 `capture_runtime_state()` → `JSON.stringify` → `FileAccess.WRITE` → `user://SAVE_DATA/data.sav`
- 读盘 `load_from_disk()` → 解析 JSON → 分发 `load_save_data` 给所有注册者
- 损坏存档自动隔离到 `data.sav.bak`
- Schema v1: `{schema_version, scene_to_save, character_pos, float_data}`

**帮助方法**:
- `record_character_position(id, position: Vector3)`
- `record_float(key, value: float)`
- `record_scene(scene_resource: Resource)`
- `has_saved_game() -> bool`

### 4. SceneLoader — 场景加载

**文件**: `scripts/autoload/scene_loader.gd` (~126 行)

替代 Unity 的 `SceneLoader` + Addressables 异步加载。详见 ADR-003。

**加载流程**:
1. 接收 `GameEvents.scene_load_requested(scene_resource, position, fade)`
2. 可选的淡入黑屏（`FADE_DURATION_DEFAULT = 0.4s`）
3. 调用 `DataManager.try_capture_runtime_state_for_scene_transition(true)` 保存当前场景状态
4. `ResourceLoader.load_threaded_request(scene_path)` 后台加载
5. `_process` 中轮询 `load_threaded_get_status`，加载完成后:
   - `tree.change_scene_to_packed(packed)`
   - `_apply_player_position()` — 通过 "player" group 找到玩家并设置位置
   - 淡出
   - `GameEvents.raise_after_scene_loaded()`
6. 失败处理: `THREAD_LOAD_FAILED` / `INVALID_RESOURCE` 时 `push_error` + 重置状态

**特性**:
- `current_scene_resource: Resource` 跟踪当前场景元数据
- `_is_loading` 防止并发加载
- 2D 项目：位置只取 `Vector2(_pending_position.x, _pending_position.y)`

### 5. AudioManager — 音频管理器

**文件**: `scripts/autoload/audio_manager.gd` (~85 行)

替代 Unity 的 `AudioManager` + `AudioMixer`。

**架构**:
- 一个 BGM 播放器（`AudioStreamPlayer`，循环）
- 8 个 FX 播放池（`_fx_pool: Array[AudioStreamPlayer]`），全在播时复用第一个
- 所有播放器走 `Master` 总线

**事件驱动**:
| 事件 | 行为 |
|------|------|
| `play_bgm(stream)` | 切换 BGM，null 时停止；同流不重复切换 |
| `play_fx(stream, pos)` | 找空闲 slot 播放 |
| `volume_changed(amount)` | `linear_to_db` → `set_bus_volume_db` → 回发 `volume_synced` |
| `pause_toggled` | `bgm_player.stream_paused` 跟随 |
| `after_scene_loaded` | 停掉所有 FX |

### 6. LanguageManager — 语言管理器

**文件**: `scripts/autoload/language_manager.gd` (~68 行)

替代 Unity 的 `LanguageManager` + `LocalizedText` 组件。

**功能**:
- 支持语言: `["zh", "en"]`，默认 `"zh"`
- 设置切换: `set_language(lang)` / `toggle_language()`
- 文本获取: `get_text(key: StringName) → String` 优先查 `RuntimeData.ui_strings`，回退 `TranslationServer.tr`
- 持久化: `user://settings.cfg [locale] language`
- 信号: `language_changed(new_language: String)`

### 7. UIManager — UI 管理器

**文件**: `scripts/autoload/ui_manager.gd` (~72 行)

替代 Unity 的 `UIManager`。

**架构**:
- 创建根 `CanvasLayer`（`UIRootLayer`, layer=10）
- 注册表 `_registered: Dictionary` name → Control

**API**:
- `register(name, ui_node)` / `unregister(name)` / `get_ui(name)`
- `show_ui(name)` / `hide_ui(name)`
- `is_paused() → bool`
- `ui_pause_state_changed(is_paused)` 信号

**暂停**: 监听 `GameEvents.pause_toggled` → `get_tree().paused = _is_paused`

### 8. McpBridgeGame — MCP 桥

**文件**: `mcp_bridge_game.gd`

编辑器与 Godot 引擎之间的 MCP 协议桥，用于开发期工具链集成。不参与运行时逻辑。

## 注册表

在 `project.godot [autoload]` 中注册（`*` 前缀表示单例可全局访问）：

```
GameEvents="*res://scripts/autoload/game_events.gd"
RuntimeData="*res://scripts/autoload/runtime_data.gd"
DataManager="*res://scripts/autoload/data_manager.gd"
SceneLoader="*res://scripts/autoload/scene_loader.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
LanguageManager="*res://scripts/autoload/language_manager.gd"
UIManager="*res://scripts/autoload/ui_manager.gd"
McpBridgeGame="*res://mcp_bridge_game.gd"
```

## 通信约束

- **允许**: 服务 A → `GameEvents.raise_xxx()` → 服务 B
- **禁止**: 服务 A 直接 `get_node("/root/ServiceB")` 调业务方法
- **例外**: `DataManager.register(self)` 是注册模式而非业务耦合

## 接口契约

```
GameEvents          → signal + raise_xxx()
RuntimeData         → 查询方法
DataManager         → register / save / load / record_*
SceneLoader         → 监听 scene_load_requested
AudioManager        → 监听 play_bgm / play_fx / volume_changed
LanguageManager     → set_language / get_text / toggle_language
UIManager           → register / show / hide / is_paused
```

所有 autoload 通过信号连接，无直接方法调用链。

## 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| GameEvents 膨胀超过 500 行 | 低 | 低 | 按主题拆 `combat_events` / `ui_events` |
| RuntimeData JSON 文件缺失 | 中 | 低 | _load_dictionary 返回空字典 |
| 场景切换时 DataManager 未及时 save | 中 | 中 | SceneLoader 在 change_scene 前强制 capture |
| 语言切换时 UI 未刷新 | 中 | 中 | 现有 LocalizedText 节点通过 `language_changed` 信号刷新 |

## 待做

- [ ] RuntimeData 的 JSON 数据文件（`loot.json`, `progression.json`, `chapters.json`, `scene_links.json`, `ui_strings.json`）大部分未创建
