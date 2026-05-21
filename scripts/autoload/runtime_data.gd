extends Node
## 运行时数据加载器（替代 Unity 的 LegendOfWarriorRuntimeData 静态类）
##
## 启动时从 res://data 读取以下 5 份 JSON：
##   loot.json           战利品表
##   progression.json    玩家进阶里程碑
##   chapters.json       章节定义
##   scene_links.json    场景跳转关系
##   ui_strings.json     UI 文本
##
## 文件可缺失，对应字典就保持空。

const DATA_DIR := "res://data/"

var loot_tables: Dictionary = {}                    # id -> Dictionary
var player_progression: Dictionary = {}             # 单一进阶配置
var chapters: Dictionary = {}                       # id -> Dictionary
var scene_links: Dictionary = {}                    # id -> Dictionary
var ui_strings: Dictionary = {}                     # key -> Dictionary{ language -> text }


func _ready() -> void:
	_reload_all()


func _reload_all() -> void:
	loot_tables = _load_dictionary("loot.json", "id")
	player_progression = _load_object("progression.json")
	chapters = _load_dictionary("chapters.json", "id")
	scene_links = _load_dictionary("scene_links.json", "id")
	ui_strings = _load_dictionary("ui_strings.json", "key")


# ----- 公共查询 -----------------------------------------------------------------

func try_get_loot_table(id: StringName) -> Dictionary:
	return loot_tables.get(id, {})


func get_player_progression() -> Dictionary:
	return player_progression


func try_get_chapter(id: StringName) -> Dictionary:
	return chapters.get(id, {})


func try_get_scene_link(id: StringName) -> Dictionary:
	return scene_links.get(id, {})


func try_get_ui_string(key: StringName, language: String = "zh") -> String:
	var entry: Dictionary = ui_strings.get(key, {})
	if entry.is_empty():
		return String(key)
	if entry.has(language):
		return String(entry[language])
	if entry.has("zh"):
		return String(entry["zh"])
	if entry.has("en"):
		return String(entry["en"])
	return String(key)


# ----- 内部 ----------------------------------------------------------------------

func _load_object(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		return {}
	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("RuntimeData: %s 不是 JSON 对象" % path)
		return {}
	return parsed


func _load_dictionary(file_name: String, key_field: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		return {}
	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(raw)
	var result: Dictionary = {}
	if typeof(parsed) == TYPE_ARRAY:
		for entry in parsed:
			if typeof(entry) == TYPE_DICTIONARY and entry.has(key_field):
				result[StringName(entry[key_field])] = entry
	elif typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed:
			result[StringName(k)] = parsed[k]
	else:
		push_warning("RuntimeData: %s 既不是数组也不是对象" % path)
	return result
