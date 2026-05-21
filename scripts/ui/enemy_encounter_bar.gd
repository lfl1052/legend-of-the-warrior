class_name EnemyEncounterBar
extends Control
## Boss/精英 血条 UI（替代 Unity 项目里的 EnemyEncounterBar.cs）
##
## 监听 GameEvents.encounter_focus_changed 切换显示对象，每帧从 owner
## 拉取血量、阶段、势的数值。owner 鸭子类型字段/方法：
##   get_health_ratio() -> float
##   get_health_current() -> float
##   get_health_max() -> float
##   get_phase_index() -> int
##   get_phase_count() -> int
##   get_poise_ratio() -> float
##   get_max_poise() -> float
##   get_display_name_key() -> String

@export_node_path("CanvasItem") var name_label_path: NodePath
@export_node_path("CanvasItem") var phase_label_path: NodePath
@export_node_path("CanvasItem") var health_value_label_path: NodePath
@export_node_path("Range") var health_fill_path: NodePath
@export_node_path("Control") var poise_root_path: NodePath
@export_node_path("Range") var poise_fill_path: NodePath
@export var fade_speed: float = 7.5

var _name_label: Label
var _phase_label: Label
var _health_value_label: Label
var _health_fill: Range
var _poise_root: Control
var _poise_fill: Range
var _current_source: Object = null
var _is_visible: bool = false


func _ready() -> void:
	_name_label = get_node_or_null(name_label_path) as Label
	_phase_label = get_node_or_null(phase_label_path) as Label
	_health_value_label = get_node_or_null(health_value_label_path) as Label
	_health_fill = get_node_or_null(health_fill_path) as Range
	_poise_root = get_node_or_null(poise_root_path) as Control
	_poise_fill = get_node_or_null(poise_fill_path) as Range
	modulate.a = 0.0
	if not GameEvents.encounter_focus_changed.is_connected(_on_focus_changed):
		GameEvents.encounter_focus_changed.connect(_on_focus_changed)


func _process(delta: float) -> void:
	var source := EnemyEncounterHudState.get_active_source()
	if source != null:
		_current_source = source
		_apply_source(source)
		_is_visible = true
	else:
		_current_source = null
		_is_visible = false
	_apply_fade(delta)


func _on_focus_changed(owner: Object) -> void:
	_current_source = owner
	if owner != null:
		_apply_source(owner)
	_is_visible = owner != null


func _apply_source(source: Object) -> void:
	if source == null:
		return
	if _name_label != null:
		var key := ""
		if source.has_method("get_display_name_key"):
			key = String(source.call("get_display_name_key"))
		_name_label.text = LanguageManager.get_text(key) if key != "" else "Encounter"
	if _health_fill != null and source.has_method("get_health_ratio"):
		_health_fill.value = float(source.call("get_health_ratio")) * _health_fill.max_value
	if _health_value_label != null and source.has_method("get_health_current") and source.has_method("get_health_max"):
		var cur := int(ceilf(float(source.call("get_health_current"))))
		var max_health := maxi(1, int(ceilf(float(source.call("get_health_max")))))
		_health_value_label.text = "%d / %d" % [cur, max_health]

	var has_phase := source.has_method("get_phase_count") and source.has_method("get_phase_index")
	if _phase_label != null:
		if has_phase and int(source.call("get_phase_count")) > 1:
			_phase_label.visible = true
			_phase_label.text = "P%d/%d" % [int(source.call("get_phase_index")) + 1, int(source.call("get_phase_count"))]
		else:
			_phase_label.visible = false

	var has_poise := source.has_method("get_max_poise") and float(source.call("get_max_poise")) > 0.0
	if _poise_root != null:
		_poise_root.visible = has_poise
	if has_poise and _poise_fill != null and source.has_method("get_poise_ratio"):
		_poise_fill.value = clampf(float(source.call("get_poise_ratio")), 0.0, 1.0) * _poise_fill.max_value


func _apply_fade(delta: float) -> void:
	var target := 1.0 if _is_visible else 0.0
	if delta <= 0.0:
		modulate.a = target
		return
	modulate.a = move_toward(modulate.a, target, fade_speed * delta)
