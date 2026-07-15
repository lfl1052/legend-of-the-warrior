class_name SavePoint
extends Area2D
## 可交互存储点。规则状态由存档结果确认，视觉只呈现 inactive/saving/active。

signal first_activation
signal activated
signal save_failed

@export var save_id_prefix: String = "save_point"
@export var legacy_save_ids: Array[String] = []
@export var first_activation_reward: StringName = &"power-refill"
@export var loop_pulse: bool = true
@export_range(0.4, 4.0, 0.1) var pulse_period: float = 1.4

@export_node_path("Node2D") var visual_root_path: NodePath = ^"Visual"
@export_node_path("CanvasItem") var inactive_sprite_path: NodePath = ^"Visual/InactiveSign"
@export_node_path("CanvasItem") var active_sprite_path: NodePath = ^"Visual/ActiveSign"

var _activated: bool = false
var _saving: bool = false
var _pulse_t: float = 0.0
var _activated_before_save: bool = false
var _pending_first_activation: bool = false
var _visual_root: Node2D
var _inactive_sprite: CanvasItem
var _active_sprite: CanvasItem
var _feedback_tween: Tween


func _ready() -> void:
	add_to_group(&"interactable")
	monitoring = false
	monitorable = true
	_visual_root = get_node_or_null(visual_root_path) as Node2D
	_inactive_sprite = get_node_or_null(inactive_sprite_path) as CanvasItem
	_active_sprite = get_node_or_null(active_sprite_path) as CanvasItem
	if not GameEvents.save_completed.is_connected(_on_save_completed):
		GameEvents.save_completed.connect(_on_save_completed)
	DataManager.register(self)
	_refresh_visual_state()


func _exit_tree() -> void:
	if GameEvents.save_completed.is_connected(_on_save_completed):
		GameEvents.save_completed.disconnect(_on_save_completed)
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	DataManager.unregister(self)


func _process(delta: float) -> void:
	if not loop_pulse or _active_sprite == null or not _activated:
		return
	_pulse_t = fmod(_pulse_t + delta, pulse_period)
	_active_sprite.modulate.a = 0.78 + 0.22 * sin((_pulse_t / pulse_period) * TAU)


func trigger_action() -> void:
	if _saving:
		return
	_activated_before_save = _activated
	_pending_first_activation = not _activated
	# DataManager 会同步采集状态，因此先暂时置为 active；失败时再回滚。
	_activated = true
	_saving = true
	_refresh_visual_state()
	GameEvents.raise_save_data()


func is_activated() -> bool:
	return _activated


func is_saving() -> bool:
	return _saving


func _on_save_completed(success: bool) -> void:
	if not _saving:
		return
	_saving = false
	if success:
		_play_success_feedback()
		GameEvents.raise_play_sfx(&"save_success", global_position)
		GameEvents.raise_reward_notification(&"save-success", {
			"notification_chinese": "进度已保存",
			"notification_english": "Progress saved",
			"_progression_applied": true,
		})
		activated.emit()
		if _pending_first_activation:
			first_activation.emit()
			if first_activation_reward != &"":
				GameEvents.raise_reward_notification(first_activation_reward, {"amount": 1})
	else:
		_activated = _activated_before_save
		_play_failure_feedback()
		GameEvents.raise_play_sfx(&"save_failure", global_position)
		GameEvents.raise_reward_notification(&"save-failed", {
			"notification_chinese": "保存失败，请检查磁盘空间",
			"notification_english": "Save failed. Check available storage",
			"_progression_applied": true,
			"major": true,
		})
		save_failed.emit()
	_pending_first_activation = false
	_refresh_visual_state()


func _play_success_feedback() -> void:
	_reset_feedback_tween()
	if _visual_root == null:
		return
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_visual_root, "scale", Vector2(1.12, 1.12), 0.1)
	_feedback_tween.tween_property(_visual_root, "scale", Vector2.ONE, 0.18)


func _play_failure_feedback() -> void:
	_reset_feedback_tween()
	if _visual_root == null:
		return
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_visual_root, "position:x", -3.0, 0.05).as_relative()
	_feedback_tween.tween_property(_visual_root, "position:x", 6.0, 0.08).as_relative()
	_feedback_tween.tween_property(_visual_root, "position:x", -3.0, 0.05).as_relative()


func _reset_feedback_tween() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = null
	if _visual_root != null:
		_visual_root.position.x = 0.0
		_visual_root.scale = Vector2.ONE


func _refresh_visual_state() -> void:
	if _inactive_sprite != null:
		_inactive_sprite.visible = not _activated
		_inactive_sprite.modulate = Color.WHITE
	if _active_sprite != null:
		_active_sprite.visible = _activated
		_active_sprite.modulate = Color.WHITE


func get_save_id() -> String:
	if not save_id_prefix.is_empty():
		return save_id_prefix
	return PersistenceKeyUtility.resolve_key(self, "save_point")


func get_save_data(data: Dictionary) -> void:
	var floats: Dictionary = data.get("float_data", {})
	floats[get_save_id() + "_done"] = 1.0 if _activated else 0.0
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var floats: Dictionary = data.get("float_data", {})
	var restored := float(floats.get(get_save_id() + "_done", 0.0)) >= 0.5
	if not restored:
		for legacy_id in legacy_save_ids:
			if float(floats.get(legacy_id + "_done", 0.0)) >= 0.5:
				restored = true
				break
	_activated = restored
	_saving = false
	_refresh_visual_state()
