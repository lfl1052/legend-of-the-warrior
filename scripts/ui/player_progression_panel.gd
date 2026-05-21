class_name PlayerProgressionPanel
extends Control
## 玩家成长面板（替代 Unity 项目里的 PlayerProgressionPanel.cs）
##
## 展示教程代币 / 升级代币 / 已开宝箱、未来解锁槽位预览。
## 通过 PlayerProgression 节点的 progression_changed 信号刷新。

@export_node_path("CanvasItem") var header_label_path: NodePath
@export_node_path("CanvasItem") var summary_label_path: NodePath
@export_node_path("CanvasItem") var metrics_label_path: NodePath
@export_node_path("CanvasItem") var next_slot_label_path: NodePath

@export var locked_color: Color = Color(0.75, 0.91, 0.78, 1)
@export var ready_color: Color = Color(1, 0.92, 0.62, 1)

var _header: Label
var _summary: Label
var _metrics: Label
var _next_slot: Label
var _progression: PlayerProgression


func _ready() -> void:
	_header = get_node_or_null(header_label_path) as Label
	_summary = get_node_or_null(summary_label_path) as Label
	_metrics = get_node_or_null(metrics_label_path) as Label
	_next_slot = get_node_or_null(next_slot_label_path) as Label
	if not LanguageManager.language_changed.is_connected(_on_language_changed):
		LanguageManager.language_changed.connect(_on_language_changed)
	_resolve_progression()
	refresh()


func _process(_delta: float) -> void:
	if _progression == null or not is_instance_valid(_progression):
		_resolve_progression()


func _resolve_progression() -> void:
	if _progression != null and _progression.progression_changed.is_connected(_on_progression_changed):
		_progression.progression_changed.disconnect(_on_progression_changed)
	_progression = null
	for player in get_tree().get_nodes_in_group(&"player"):
		for child in player.get_children():
			if child is PlayerProgression:
				_progression = child
				break
		if _progression != null:
			break
	if _progression != null:
		_progression.progression_changed.connect(_on_progression_changed)
		refresh()


func refresh() -> void:
	visible = _progression != null
	if _progression == null:
		return

	var ready_count := _progression.get_ready_future_unlock_slot_count()
	var total_count := _progression.get_future_unlock_slot_count()

	if _header != null:
		_header.text = LanguageManager.get_text("ui.progression.header")
	if _summary != null:
		var fmt := "规划槽位 %d/%d" if LanguageManager.current_language == "zh" else "Slots %d/%d"
		_summary.text = fmt % [ready_count, total_count]
	if _metrics != null:
		var template := "教程代币 %d\n升级代币 %d\n已领宝箱 %d" if LanguageManager.current_language == "zh" \
			else "Tutorial Tokens %d\nUpgrade Tokens %d\nClaimed Chests %d"
		_metrics.text = template % [
			_progression.tutorial_economy_tokens,
			_progression.upgrade_tokens,
			_progression.opened_chest_rewards,
		]
	if _next_slot != null:
		_next_slot.text = _format_next_slot(ready_count, total_count)
		_next_slot.modulate = ready_color if ready_count >= total_count and total_count > 0 else locked_color


func _format_next_slot(ready_count: int, total_count: int) -> String:
	if total_count <= 0:
		return LanguageManager.get_text("ui.progression.no_slots")
	if ready_count >= total_count:
		return LanguageManager.get_text("ui.progression.all_ready")
	var slot_id := _progression.get_next_future_unlock_slot_id()
	var label := slot_id.replace("-", " ")
	if LanguageManager.current_language == "zh":
		return "下一规划：%s" % label
	return "Next slot: %s" % label


func _on_progression_changed(_p: PlayerProgression) -> void:
	refresh()


func _on_language_changed(_language: String) -> void:
	refresh()
