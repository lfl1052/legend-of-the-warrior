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

	if not _is_unlocked(player):
		return false

	if character.get_power_ratio() < power_threshold_ratio:
		return false

	if character.current_health >= character.max_health:
		return false
	if not player.can_begin_heal():
		return false

	var amount := character.max_health * heal_ratio
	return player.begin_heal(Callable(self, "_apply_heal").bind(character, amount))


func _apply_heal(character: Character, amount: float) -> void:
	if character == null or not is_instance_valid(character) or character.is_dead():
		return
	if character.get_power_ratio() < power_threshold_ratio:
		return
	character.heal(amount)

	if consume_all_power:
		character.current_power = 0.0
	else:
		character.current_power = maxf(0.0, character.current_power - character.max_power * power_threshold_ratio)


func _is_unlocked(player: PlayerController) -> bool:
	var progression := player.get_node_or_null(^"PlayerProgression") as PlayerProgression
	return progression != null and progression.has_unlock_slot(unlock_slot)
