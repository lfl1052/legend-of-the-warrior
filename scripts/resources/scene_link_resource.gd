class_name SceneLinkResource
extends Resource
## 场景跳转关系（替代 Unity 项目里的 SceneLinkDefinition）

@export var id: StringName = &""
@export var from_scene: StringName = &""
@export var to_scene: StringName = &""
@export var spawn_point: Vector3 = Vector3.ZERO
@export var requires_unlock: StringName = &""


static func from_dict(dict: Dictionary) -> SceneLinkResource:
	var res := SceneLinkResource.new()
	res.id = StringName(dict.get("id", ""))
	res.from_scene = StringName(dict.get("from_scene", ""))
	res.to_scene = StringName(dict.get("to_scene", ""))
	var sp: Variant = dict.get("spawn_point", null)
	if typeof(sp) == TYPE_DICTIONARY:
		res.spawn_point = Vector3(
			float(sp.get("x", 0.0)),
			float(sp.get("y", 0.0)),
			float(sp.get("z", 0.0)))
	res.requires_unlock = StringName(dict.get("requires_unlock", ""))
	return res
