# ADR-0001: Autoload + GameEvents 信号总线作为跨系统通信

## Status

Accepted

## Date

2026-07-11

## Last Verified

2026-05-20

## Decision Makers

项目负责人（Unity → Godot 迁移作者）

## Summary

跨系统通信不能直接 `get_node("../../...")` 也不能让所有模块都互相 `preload`，否则迁移自 Unity 的 ScriptableObject EventChannel 系统会退化成硬耦合。决定：用一个 `GameEvents` autoload 单例集中声明全部信号 + `raise_xxx` 包装方法，作为全局事件总线。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — Godot 信号 + autoload 是稳定 API |
| **References Consulted** | `scripts/autoload/game_events.gd`、Godot 4.7 signal/Autoload docs、4.6 → 4.7 migration guide |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — 已在 5 个系统（save/scene/audio/UI/encounter）落地验证 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None（基础决策） |
| **Enables** | ADR-0002（存档系统通过 `save/load_data_requested` 信号触发）、ADR-0003（场景切换通过 `scene_load_requested(GameSceneResource, ...)` 信号触发） |
| **Blocks** | 任何跨系统功能 epic |
| **Ordering Note** | 第一条 ADR，其它系统在它之上构建 |

## Context

### Problem Statement

Unity 项目用了大量 `ScriptableObject EventChannel`（VoidEventSO / FloatEventSO / SceneLoadEventSO 等）实现解耦通信。迁移到 Godot 后必须给每条事件通道找到对等机制，否则会出现：
- UI / 战斗 / 存档系统互相硬引用
- 场景切换时 listener 注册 / 注销逻辑分散在每个模块
- 增加新事件需要改动多处

### Current State

Unity 端：每个事件一个 `*.asset`（ScriptableObject 实例），系统在 `OnEnable` 注册 listener，发起方调用 `Raise()`。
Godot 端（本决策落地后）：8 类事件全部声明在 `GameEvents` autoload，发起方 `GameEvents.raise_xxx()`，订阅方 `GameEvents.signal_name.connect(callback)`。

### Constraints

- Godot 不像 Unity 那样有 ScriptableObject 资产化的事件通道；强行用 Resource + 文件实例化会增加无谓的 .tres 维护成本
- 所有 8 个 autoload（GameEvents/RuntimeData/DataManager/SceneLoader/AudioManager/LanguageManager/UIManager/McpBridgeGame）需要在 `project.godot` 注册
- 静态类型 GDScript 强制要求信号参数有显式类型

### Requirements

- 所有跨系统通信必须经 GameEvents，不允许跨系统 `get_node` 或硬 `preload`
- 信号命名遵循"过去时事件 / 现在时请求"约定（`new_game_started`、`save_data_requested`、`scene_load_requested`）
- 性能：信号触发开销 < 10 µs / 次（Godot 内置信号已满足）

## Decision

把 Unity 的 `ScriptableObject EventChannel` 全部合并到一个 autoload `GameEvents` 上，按主题分组：流程类、数值类、音频、角色、淡入淡出、场景加载、UI 反馈、Encounter。每个信号配一个 `raise_xxx()` 包装方法，便于调用点保持与 Unity 端 `RaiseXxx()` 一致的命名习惯。

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  GameEvents (autoload)                  │
│  signals: new_game_started / scene_load_requested /     │
│           character_health_changed / play_bgm / ...     │
└─────────────────────────────────────────────────────────┘
        ▲                    ▲                  ▲
        │ raise_xxx()         │ connect()        │
        │                    │                  │
┌──────────────┐    ┌──────────────────┐  ┌──────────────────┐
│  MainMenu UI │    │  DataManager     │  │  SceneLoader     │
│  emits       │    │  listens to      │  │  listens to      │
│  new_game_   │    │  save/load_data_ │  │  scene_load_     │
│  started     │    │  requested       │  │  requested       │
└──────────────┘    └──────────────────┘  └──────────────────┘
```

### Key Interfaces

```gdscript
# 发起方
GameEvents.raise_new_game_started()
GameEvents.raise_scene_load_requested(scene_res, Vector3.ZERO, true)
GameEvents.raise_character_took_damage(self, attacker)

# 订阅方
func _ready() -> void:
    GameEvents.scene_load_requested.connect(_on_scene_load_requested)
    GameEvents.character_died.connect(_on_character_died)
```

### Implementation Guidelines

- **新增事件**：先在 `game_events.gd` 加 `signal xxx`，再加 `raise_xxx()` 方法。禁止订阅方直接 `emit`
- **参数类型**：信号必须显式声明类型（如 `signal volume_changed(amount: float)`）
- **生命周期**：autoload 节点常驻 SceneTree.root，不需要 disconnect；只有手动 `connect` 的非 autoload 节点才需要在 `_exit_tree` disconnect
- **Object 类型**：`character_health_changed(character: Object)` 用 Object 而非 Character，因为 Encounter HUD 也接受任意有 health 字段的对象

## Alternatives Considered

### Alternative 1: 每个 EventChannel 一个 Resource 文件

- **Description**: 严格仿 Unity 模式，把每条事件做成 `EventChannel.gd` + `*.tres` 实例
- **Pros**: 与 Unity 一一对应，迁移最忠实
- **Cons**: Godot 信号本就是一等公民，包一层 Resource 反而增加跳转成本；新增事件要建文件 + 注册 + 加载，比 autoload + signal 慢 3 倍
- **Rejection Reason**: 没有收益的形式忠实

### Alternative 2: 每个系统自己暴露 signal，调用方直接 connect

- **Description**: 不要中央 bus，PlayerController 自己有 `died` 信号，UI 直接 `player.died.connect(...)`
- **Pros**: 没有"上帝单例"，更接近 Godot 风格
- **Cons**: UI 必须知道哪个节点是 player；场景切换后所有 connect 都失效；跨场景的"游戏结束"事件无处归属
- **Rejection Reason**: 跨场景 / 跨系统事件占绝大多数，去中心化反而增加耦合

## Consequences

### Positive

- 新模块接入只需 `connect` GameEvents 上的信号，不用知道发起方是谁
- 场景切换不会造成 listener 失效（autoload 常驻）
- 与 Unity 端命名完全对齐，便于交叉对照

### Negative

- `GameEvents` 文件会随事件增加而变大（目前 ~170 行，可接受到 ~500 行；超过则按主题拆 autoload）
- 信号广播是"无目标"的，调试时要用 Godot Profiler 的 signal trace 才能查清流向

### Neutral

- 所有跨系统通信路径集中在 `game_events.gd`，便于审计但也意味着该文件是"必读"

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 信号过多导致 GameEvents 膨胀 | Medium | Low | 阈值 500 行后拆 `combat_events.gd` / `ui_events.gd` 等子 autoload |
| 订阅方未 disconnect 导致内存泄漏 | Low | Medium | 仅常驻节点订阅 GameEvents；瞬时节点用 weakref 或 `connect(..., CONNECT_ONE_SHOT)` |
| 事件命名冲突 | Low | Low | code review 强制 `raise_xxx` / `xxx_requested` / `xxx_changed` 命名约定 |

## Performance Implications

| Metric | Before (硬耦合) | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (signal emit) | n/a | < 10 µs/次 | < 50 µs/次 |
| Memory | n/a | < 1 KB（GameEvents 节点本体） | < 10 KB |
| Load Time | n/a | autoload 启动 < 1 ms | < 50 ms |

## Migration Plan

已完成。原 Unity SO 事件通道 1:1 映射到 GameEvents 信号：

1. ✅ 列出 Unity 项目所有 `*EventSO.asset` → 8 类
2. ✅ 在 `game_events.gd` 声明对应 signal + `raise_xxx`
3. ✅ 在 `project.godot [autoload]` 注册 `GameEvents`
4. ✅ 调用点全部改为 `GameEvents.raise_xxx()`
5. ✅ 订阅点 `_ready` 中 `GameEvents.xxx.connect(...)`

**Rollback plan**: 不必回滚；如确需，可把 GameEvents 单点拆成多个子 autoload，是非破坏性变更。

## Validation Criteria

- [x] `scripts/` 中无任何 `get_node("/root/...")` 直连其它系统业务节点
- [x] 跨系统事件统一走 GameEvents（已验证 save / scene / encounter / ui / audio）
- [x] 冒烟测试 `tests/e2e/smoke_test.gd` 通过（new_game_started → scene_load_requested 链路完整）
- [ ] code review 流程把"跨系统通信不走 GameEvents"列为 forbidden pattern（已写入 `.claude/docs/technical-preferences.md`）

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| Foundational — no GDD requirement. Enables: 所有 GDD 系统的跨模块解耦通信（save / scene / combat / UI / audio / encounter / progression） |

## Related

- ADR-0002（存档协议）— 通过 `save_data_requested` / `load_data_requested` 触发
- ADR-0003（场景资源化）— 通过 `scene_load_requested(GameSceneResource, ...)` 触发
- 代码：`scripts/autoload/game_events.gd`
- 代码：`scripts/autoload/data_manager.gd`（订阅 save/load）、`scripts/autoload/scene_loader.gd`（订阅 scene_load）
