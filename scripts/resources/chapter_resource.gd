class_name ChapterResource
extends Resource
## 章节定义（替代 Unity 项目里的 ChapterDefinition）

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var scene_ids: Array[StringName] = []
@export var unlock_requirement: StringName = &""


static func from_dict(dict: Dictionary) -> ChapterResource:
	var res := ChapterResource.new()
	res.id = StringName(dict.get("id", ""))
	res.display_name_key = StringName(dict.get("display_name_key", ""))
	res.unlock_requirement = StringName(dict.get("unlock_requirement", ""))
	for sid in dict.get("scene_ids", []):
		res.scene_ids.append(StringName(sid))
	return res
