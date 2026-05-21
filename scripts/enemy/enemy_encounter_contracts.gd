class_name EnemyEncounterContracts
extends RefCounted
## 精英/Boss 的契约接口（替代 Unity 项目里的 EnemyEncounterContracts）
##
## Godot 没有 interface，这里以"鸭子类型"约定方法名：
##   IEnemyHealthBarSource     get_health_ratio() -> float
##   IEnemyPhaseOwner          get_phase_index() -> int  /  get_phase_count() -> int
##   IEnemyPoiseOwner          get_poise_ratio() -> float
##   IEnemySkillCooldownOwner  get_skill_cooldown_ratio(id) -> float
##
## 各方实现遵循同名方法即可，HUD 通过 has_method 检测。

## 这些常量供 UI 端 has_method 检测时使用，避免拼写漂移
const M_HEALTH_RATIO := &"get_health_ratio"
const M_PHASE_INDEX := &"get_phase_index"
const M_PHASE_COUNT := &"get_phase_count"
const M_POISE_RATIO := &"get_poise_ratio"
const M_SKILL_COOLDOWN := &"get_skill_cooldown_ratio"
const M_DISPLAY_NAME := &"get_display_name_key"
