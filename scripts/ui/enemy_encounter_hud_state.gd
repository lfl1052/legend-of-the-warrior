class_name EnemyEncounterHudState
extends RefCounted
## Boss/精英 血条焦点协调器（替代 Unity 项目里的 EnemyEncounterHudState）
##
## Unity 静态类的等价物。GDScript 没有静态事件，所以挂在 GameEvents 自动加载上：
## - GameEvents.encounter_focus_changed(owner) 事件已经在主信号总线里
## - 这里提供 set_active / clear / reset / get_active_source 静态方法
## owner 必须实现 IEnemyHealthBarSource 接口（鸭子类型）：
##   - should_show_health_bar: bool
##   - get_display_name_key() -> String

static var _active_source: Object = null
static var _active_priority: int = -2147483648


static func get_active_source() -> Object:
	if not _is_valid(_active_source) or not _should_show(_active_source):
		reset()
	return _active_source


static func set_active(source: Object, priority: int = 0) -> bool:
	if not _is_valid(source) or not _should_show(source):
		return false
	if _is_same_source(_active_source, source):
		_active_priority = priority
		return true
	if _is_valid(_active_source) and _active_priority > priority:
		return false
	_active_source = source
	_active_priority = priority
	GameEvents.raise_encounter_focus_changed(_active_source)
	return true


static func clear(source: Object) -> void:
	if not _is_same_source(_active_source, source):
		return
	reset()


static func reset() -> void:
	if _active_source == null and _active_priority == -2147483648:
		return
	_active_source = null
	_active_priority = -2147483648
	GameEvents.raise_encounter_focus_changed(null)


static func _is_valid(source: Object) -> bool:
	if source == null:
		return false
	if source is Node:
		return is_instance_valid(source) and (source as Node).is_inside_tree()
	return is_instance_valid(source)


static func _should_show(source: Object) -> bool:
	if source == null:
		return false
	if "should_show_health_bar" in source:
		return bool(source.should_show_health_bar)
	if source.has_method("get_should_show_health_bar"):
		return bool(source.call("get_should_show_health_bar"))
	return true


static func _is_same_source(left: Object, right: Object) -> bool:
	if left == right:
		return true
	if left == null or right == null:
		return false
	return is_instance_valid(left) and is_instance_valid(right) and left.get_instance_id() == right.get_instance_id()
