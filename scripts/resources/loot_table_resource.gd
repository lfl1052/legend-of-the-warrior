class_name LootTableResource
extends Resource
## 战利品表资源（替代 Unity 项目里的 LootTableDefinition）
##
## entries 数组项形如：
##   {
##     "reward_id": "tutorial-economy-token",
##     "amount": 1,
##     "weight": 100
##   }

@export var id: StringName = &""
@export var entries: Array[Dictionary] = []


func is_empty() -> bool:
	return entries.is_empty()


static func from_dict(dict: Dictionary) -> LootTableResource:
	var res := LootTableResource.new()
	res.id = StringName(dict.get("id", ""))
	var raw_entries: Array = dict.get("entries", [])
	for entry in raw_entries:
		if typeof(entry) == TYPE_DICTIONARY:
			res.entries.append(entry)
	return res
