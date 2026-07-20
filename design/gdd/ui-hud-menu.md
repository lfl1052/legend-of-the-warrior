# 系统 GDD: UI / HUD / 菜单

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-UI |
| **系统名称** | UI / HUD / 菜单 |
| **优先级** | 🟡 P2 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-07-16 |
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

主菜单视觉按课程第 40 课复用 `Legacy-Fantasy-High Forest` 的树木原图集，使用三层 Parallax2D 与循环 AnimationPlayer 构成缓慢森林景深；按钮区由半透明 Panel 承载。背景遮罩固定为 `640×360` 逻辑尺寸，课程纹理、循环动画和既有导航节点路径由 `test_menu_visual_contract.gd` 保护。

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

`GameplayOverlay` 在常驻 `UIRootLayer` 中提供继续、返回主菜单，以及主音量、音乐音量和音效音量三路控制。面板使用 `PROCESS_MODE_ALWAYS`，因此场景树暂停后仍可操作；UIManager 以显式状态同步 AudioManager，避免多系统各自翻转布尔值。

## Game Over

玩家死亡广播 `GameEvents.game_over` 后，UIManager 暂停场景树并显示“重新开始 / 返回主菜单”。重新开始通过 `restart_requested` 让 SceneLoader 重载当前 `GameSceneResource`，保留关卡默认出生点；返回菜单同样走 SceneLoader，不在 UI 中直接引用场景路径。两个面板都配置默认键盘焦点，并在 640×360 逻辑视口内完整显示。

## FadeCanvas

**文件**: `scripts/ui/fade_canvas.gd`
**继承**: `CanvasLayer`

全局淡入淡出层（layer=100），监听 `GameEvents.fade_requested`。

**参数说明**:
- `fade_in=true`: 从透明到彩色（黑屏淡出）
- `fade_in=false`: 从彩色到透明（淡入到亮）
- 通过 Tween 修改 `ColorRect.modulate.a` 实现

FadeCanvas 自身不决定 gameplay input，也不修改 `process_mode`；SceneLoader 在转场业务阶段显式锁定旧/新 Player，并在揭幕和依赖刷新后恢复。

## HUD

### PlayerStatBar
玩家血量/能量条位于共享 `scenes/ui/gameplay_hud.tscn`，监听 `GameEvents.character_health_changed`。它按课程第 28–29 课复用 `Legacy-Fantasy-High Forest/HUD/Base-UI.png`：头像底板、深色细条槽、生命即时层、生命延迟层和能量层均为同图集的 `AtlasTexture`；左侧头像裁入底板，右侧两条独立状态条固定在左上安全区，生命前景覆盖延迟层，能量层单独入框，不使用占据游玩区域的通栏背板。图集中的彩色按钮切片不用于状态条。前景、延迟层和能量层仍由 `PlayerStatBar` 的 `Range.value` 驱动。成长面板和地图面板同样在该 HUD 场景中实例化，但不是常驻层：成长面板仅在下一能力达到代币解锁条件时显示，地图仅在已解锁且触发 `map_panel` action 时显示；奖励通知为短时反馈。Level Demo 和 Level 2 共用该场景，避免场景间出现不同的状态栏实现。

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
