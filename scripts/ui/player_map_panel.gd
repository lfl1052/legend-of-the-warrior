class_name PlayerMapPanel
extends Control
## 路线地图面板（替代 Unity 项目里的 PlayerMapPanel.cs）
##
## 玩家解锁 "map" 槽位后才能打开。按下 InputMap "map_panel" 键切换显示。
## 内容：当前章节、当前场景名、可用路线列表（来自 RuntimeData.scene_links）。

@export_node_path("CanvasItem") var header_label_path: NodePath
@export_node_path("CanvasItem") var scene_info_label_path: NodePath
@export_node_path("CanvasItem") var route_info_label_path: NodePath
@export_node_path("CanvasItem") var footer_label_path: NodePath

var _header: Label
var _scene_info: Label
var _route_info: Label
var _footer: Label
var _progression: PlayerProgression
var _is_open: bool = false


func _ready() -> void:
	_header = get_node_or_null(header_label_path) as Label
	_scene_info = get_node_or_null(scene_info_label_path) as Label
	_route_info = get_node_or_null(route_info_label_path) as Label
	_footer = get_node_or_null(footer_label_path) as Label
	visible = false
	if not LanguageManager.language_changed.is_connected(_on_language_changed):
		LanguageManager.language_changed.connect(_on_language_changed)
	if not GameEvents.after_scene_loaded.is_connected(_on_scene_loaded):
		GameEvents.after_scene_loaded.connect(_on_scene_loaded)
	_resolve_progression()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"map_panel"):
		toggle_panel()


func toggle_panel() -> bool:
	if not _can_show():
		hide_panel()
		return false
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		refresh()
	return _is_open


func hide_panel() -> void:
	_is_open = false
	visible = false


func refresh() -> void:
	if not _can_show():
		hide_panel()
		return

	if _header != null:
		_header.text = LanguageManager.get_text("ui.map.header")

	var scene_path := get_tree().current_scene.scene_file_path if get_tree().current_scene != null else ""
	var scene_name := scene_path.get_file().get_basename()

	var routes := _collect_routes(scene_name)
	if _scene_info != null:
		_scene_info.text = _build_scene_info(scene_name, routes.size())
	if _route_info != null:
		_route_info.text = _build_route_info(routes)
	if _footer != null:
		_footer.text = LanguageManager.get_text("ui.map.footer")


func _can_show() -> bool:
	if _progression == null or not is_instance_valid(_progression):
		_resolve_progression()
	return _progression != null and _progression.is_future_unlock_slot_ready("map")


func _resolve_progression() -> void:
	for player in get_tree().get_nodes_in_group(&"player"):
		for child in player.get_children():
			if child is PlayerProgression:
				_progression = child
				return


func _on_scene_loaded() -> void:
	_resolve_progression()
	if _is_open:
		refresh()


func _on_language_changed(_language: String) -> void:
	if _is_open:
		refresh()


func _collect_routes(scene_name: String) -> Array:
	var result: Array = []
	for link_id in RuntimeData.scene_links.keys():
		var link: SceneLinkResource = RuntimeData.scene_links[link_id]
		if link == null:
			continue
		if String(link.from_scene).to_lower() != scene_name.to_lower():
			continue
		result.append(link)
	return result


func _build_scene_info(scene_name: String, route_count: int) -> String:
	if LanguageManager.current_language == "zh":
		return "当前场景  %s\n已知路线  %d" % [scene_name, route_count]
	return "Scene  %s\nKnown Routes  %d" % [scene_name, route_count]


func _build_route_info(routes: Array) -> String:
	var lines: Array[String] = []
	if routes.is_empty():
		lines.append(LanguageManager.get_text("ui.map.no_routes"))
		return "\n".join(lines)
	for link in routes:
		var sl := link as SceneLinkResource
		if sl == null:
			continue
		lines.append("- %s -> %s" % [sl.id, sl.to_scene])
	return "\n".join(lines)
