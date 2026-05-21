# 系统 GDD: UI / HUD / 菜单

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-UI |
| **系统名称** | UI / HUD / 菜单 |
| **优先级** | 🟡 P2 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `scripts/ui/` 共 12 个 `.gd` 文件 |

---

## 概述

UI 系统包含主菜单、HUD（血量/能量条、Encounter 条、奖励通知）、语言切换、淡入淡出、暂停等。UIManager autoload 维护 UI 根 CanvasLayer 作为常驻容器。

## UI 架构

```
UI Root (CanvasLayer, layer=10)
 ├── MainMenu (Control)                    # 主菜单：新游戏/继续/退出/音量
 ├── FadeCanvas (CanvasLayer, layer=100)   # 全屏淡入淡出
 ├── PlayerStatBar                         # 玩家血量/能量 HUD
 ├── EnemyEncounterBar                     # Encounter HP/韧性条
 ├── EnemyEncounterHUDState                # Encounter HUD 状态机
 ├── RewardNotificationUI                  # 奖励弹窗
 ├── PlayerProgressionPanel                # 进阶面板
 ├── PlayerMapPanel                        # 地图面板
 ├── LanguageToggleButton                  # 语言切换按钮
 ├── SafeAreaInsetAnchor                   # 安全区域适配
 └── LocalizedText (多处)                  # 本地化文本节点
```

## UIManager

**文件**: `scripts/autoload/ui_manager.gd`

维护 UI 注册表，作为常驻 UI 的容器。

| API | 说明 |
|------|------|
| `register(name, ui_node)` | 注册 UI 控件 |
| `unregister(name)` | 注销 |
| `get_ui(name)` | 获取控件 |
| `show_ui(name)` / `hide_ui(name)` | 显示/隐藏 |
| `is_paused()` | 暂停状态 |

根 `CanvasLayer`（`UIRootLayer`, layer=10）在所有场景切换后保持存活，瞬时场景 UI 挂载到其下。

## 主菜单

**文件**: `scripts/ui/main_menu.gd`
**继承**: `Control`

三个按钮:

| 按钮 | 触发 | 条件 |
|------|------|------|
| 新游戏 | `GameEvents.raise_new_game_started()` | 始终可用 |
| 继续 | `GameEvents.raise_load_data_requested()` | 仅当 `DataManager.has_saved_game()` 为 true |
| 退出 | `get_tree().quit()` | 始终可用 |

音量 Slider 双向同步:
- `value_changed` → `GameEvents.raise_volume_changed(value)`
- 监听 `volume_synced` → 用 `set_value_no_signal` 回填

**菜单流控**由 `menu_flow.gd` 负责将按钮事件转为 `scene_load_requested`。

## 暂停

通过输入映射 `pause` 键触发 `GameEvents.raise_pause_toggled()`。

`UIManager._on_pause_toggled()`:
```gdscript
_is_paused = not _is_paused
get_tree().paused = _is_paused
ui_pause_state_changed.emit(_is_paused)
```

AudioManager 也会在 pause 时暂停 BGM。

## FadeCanvas

**文件**: `scripts/ui/fade_canvas.gd`
**继承**: `CanvasLayer`

全局淡入淡出层（layer=100），监听 `GameEvents.fade_requested`。

**参数说明**:
- `fade_in=true`: 从透明到彩色（黑屏淡出）
- `fade_in=false`: 从彩色到透明（淡入到亮）
- 通过 Tween 修改 `ColorRect.modulate.a` 实现

不阻塞输入，不修改 `process_mode`。

## HUD

### PlayerStatBar
玩家血量/能量条，监听 `GameEvents.character_health_changed`。

### EnemyEncounterBar
Encounter 专属 HP 和韧性（Poise）条。

### EnemyEncounterHUDState
Encounter HUD 状态机，管理 Encounter 战斗时 UI 的显示/隐藏切换。

## 本地化

### LocalizedText
**文件**: `scripts/ui/localized_text.gd`

监听 `LanguageManager.language_changed`，自动更新文本。

### LanguageToggleButton
**文件**: `scripts/ui/language_toggle_button.gd`

一键切换中英文（`LanguageManager.toggle_language()`）。

## 奖励系统

### RewardNotificationUI
**文件**: `scripts/ui/reward_notification_ui.gd`

监听 `GameEvents.reward_notification(reward_id, payload)` 显示获取奖励的 UI 反馈。

## 数据流

```
用户点击 / 游戏事件
    ↓
GameEvents.raise_xxx()
    ↓
各 UI 组件监听对应信号
    ├─ MainMenu → new_game_started / load_data_requested / volume_synced
    ├─ PlayerStatBar → character_health_changed
    ├─ EnemyEncounterBar → encounter_focus_changed / encounter_poise_changed
    ├─ RewardNotificationUI → reward_notification
    ├─ LanguageToggleButton → LanguageManager.toggle_language
    └─ LocalizedText → language_changed
    ↓
UI 更新自身状态
```

## UIManager 注册表维护

- 常驻 UI 通过 UIManager 的 `register()/unregister()` 管理
- 场景特有 UI 在场景根节点加载时自动挂载
- UIManager 是 autoload，不随场景切换销毁

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `GameEvents` | Autoload | 所有 UI 事件入口 |
| `LanguageManager` | Autoload | 本地化切换 |
| `DataManager` | Autoload | 检查 Continue 可用性 |
| `AudioManager` | Autoload | 音量同步 |
