class_name UiStringResource
extends Resource
## 多语言文本（替代 Unity 项目里的 UiStringDefinition）

@export var key: StringName = &""
@export var translations: Dictionary = {}     # language -> string


func get_text(language: String, fallback: String = "") -> String:
	if translations.has(language):
		return String(translations[language])
	if translations.has("zh"):
		return String(translations["zh"])
	if translations.has("en"):
		return String(translations["en"])
	return fallback


static func from_dict(dict: Dictionary) -> UiStringResource:
	var res := UiStringResource.new()
	res.key = StringName(dict.get("key", ""))
	res.translations = dict.get("translations", {})
	return res
