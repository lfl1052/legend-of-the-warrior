class_name BossEnemy
extends EnemyEncounterCombatant
## Boss（替代 Unity 项目里的 BossEnemy 抽象基类）
##
## 与 EliteEnemy 的区别：
##   - 一旦发现玩家就锁场（通常配合 EncounterTrigger 关门）
##   - HUD 使用专属 Boss 血条
##
## 子类按需扩展技能与阶段逻辑。

@export var lock_arena_on_engage: bool = true


func _on_character_damage(by: Node) -> void:
	super._on_character_damage(by)
	if lock_arena_on_engage:
		GameEvents.encounter_focus_changed.emit(self)
