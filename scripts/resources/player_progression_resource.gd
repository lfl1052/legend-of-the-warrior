class_name PlayerProgressionResource
extends Resource
## 玩家进阶配置（替代 Unity 项目里的 PlayerProgressionDefinition）
##
## 由 RuntimeData 从 progression.json 读出后构造，包含：
##   milestones        Array[Dictionary]   每条解锁里程碑
##   future_unlock_slots Array[StringName] 还未实装但已预留的解锁位
##   default_max_health float
##   default_max_power  float
##   heal_ratio         float

@export var milestones: Array[Dictionary] = []
@export var future_unlock_slots: Array[StringName] = []
@export var default_max_health: float = 5.0
@export var default_max_power: float = 100.0
@export var heal_ratio: float = 0.45


func has_unlock_slot(slot_id: StringName) -> bool:
	if future_unlock_slots.has(slot_id):
		return true
	for m in milestones:
		if StringName(m.get("unlock_slot", "")) == slot_id:
			return true
	return false


static func from_dict(dict: Dictionary) -> PlayerProgressionResource:
	var res := PlayerProgressionResource.new()
	if dict.is_empty():
		return res
	res.default_max_health = float(dict.get("default_max_health", res.default_max_health))
	res.default_max_power = float(dict.get("default_max_power", res.default_max_power))
	res.heal_ratio = float(dict.get("heal_ratio", res.heal_ratio))
	for m in dict.get("milestones", []):
		if typeof(m) == TYPE_DICTIONARY:
			res.milestones.append(m)
	for slot in dict.get("future_unlock_slots", []):
		res.future_unlock_slots.append(StringName(slot))
	return res
