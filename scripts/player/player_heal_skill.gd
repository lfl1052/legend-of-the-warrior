class_name PlayerHealSkill
extends Node
## 治疗技能（替代 Unity 项目里的 PlayerHealSkill）
##
## 触发条件：
##   - 玩家进阶解锁了 "heal" 槽位
##   - 当前能量 >= 95% 上限
##   - 当前血量 < 上限
## 治疗量 = max_health * heal_ratio（默认 0.45）

@export var unlock_slot: StringName = &"heal"
@export var power_threshold_ratio: float = 0.95
@export var heal_ratio: float = 0.45
@export var consume_all_power: bool = true


func try_use(player: PlayerController) -> bool:
	if player == null:
		return false
	var character: Character = player.get_node_or_null(player.character_path) as Character
	if character == null or character.is_dead():
		return false

	if not _is_unlocked():
		return false

	if character.get_power_ratio() < power_threshold_ratio:
		return false

	if character.current_health >= character.max_health:
		return false

	var amount := character.max_health * heal_ratio
	character.heal(amount)

	if consume_all_power:
		character.current_power = 0.0
	else:
		character.current_power = maxf(0.0, character.current_power - character.max_power * power_threshold_ratio)
	return true


func _is_unlocked() -> bool:
	var progression := PlayerProgressionResource.from_dict(RuntimeData.get_player_progression())
	return progression.has_unlock_slot(unlock_slot)
