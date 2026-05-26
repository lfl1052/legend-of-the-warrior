@tool
class_name SceneResourceValidator
extends EditorScript
## 开发期场景资源校验器。
##
## 扫描 .tres 资源，找出带 scene_path 字段的 GameSceneResource，
## 并验证其目标 .tscn 是否真实存在。


static func validate(scan_dir: String) -> Array[Dictionary]:
	var tres_files: Array[String] = []
	_collect_tres_files(scan_dir, tres_files)
	tres_files.sort()

	var results: Array[Dictionary] = []
	for tres_path in tres_files:
		var meta := _extract_scene_meta(tres_path)
		if meta.is_empty():
			continue
		results.append(meta)
	return results


func _run() -> void:
	var results := validate("res://data")
	var dead_links: Array[Dictionary] = []
	for entry in results:
		if not bool(entry["scene_exists"]):
			dead_links.append(entry)

	if dead_links.is_empty():
		print("[scene-validator] OK: %d 个 .tres 全部命中" % results.size())
		return

	print("[scene-validator] FAIL: %d / %d 个 .tres 死链:" % [dead_links.size(), results.size()])
	for entry in dead_links:
		print("  - %s -> %s" % [entry["tres_path"], entry["scene_path"]])


static func _collect_tres_files(path: String, results: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	for file_name in dir.get_files():
		if file_name.get_extension() == "tres":
			results.append(_join_path(path, file_name))

	for dir_name in dir.get_directories():
		if dir_name.begins_with("."):
			continue
		_collect_tres_files(_join_path(path, dir_name), results)


static func _extract_scene_meta(tres_path: String) -> Dictionary:
	var resource := ResourceLoader.load(tres_path)
	if resource == null or not _has_property(resource, "scene_path"):
		return {}

	var scene_path := String(resource.get("scene_path"))
	return {
		"tres_path": tres_path,
		"scene_path": scene_path,
		"scene_exists": _check_path_exists(scene_path),
		"display_name": String(resource.get("display_name")) if _has_property(resource, "display_name") else "",
		"scene_type": int(resource.get("scene_type")) if _has_property(resource, "scene_type") else -1,
	}


static func _check_path_exists(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	return ResourceLoader.exists(scene_path, "PackedScene")


static func _has_property(resource: Resource, property_name: String) -> bool:
	for property_info in resource.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false


static func _join_path(base_path: String, child_name: String) -> String:
	return base_path.path_join(child_name)
