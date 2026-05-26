class_name CollectibleReward
extends Area2D

@export var reward_id: StringName = &"tutorial-economy-token"
@export var amount: int = 1
@export var notification_key: String = "ui.reward.tutorial_token"
@export var notification_chinese: String = "获得教程代币"
@export var notification_english: String = "Tutorial token gained"
@export var auto_register_save: bool = true
@export var save_id_prefix: String = "collectible"

var _collected: bool = false


func _ready() -> void:
	add_to_group(&"collectible")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	if auto_register_save:
		DataManager.register(self)


func _exit_tree() -> void:
	if auto_register_save:
		DataManager.unregister(self)


func collect(body: Node = null) -> void:
	if _collected:
		return
	if body != null and not body.is_in_group(&"player"):
		return
	_collected = true
	_record_collected_state()
	_disable_pickup()
	var payload := {
		"amount": amount,
		"notification_key": notification_key,
		"notification_chinese": notification_chinese,
		"notification_english": notification_english,
	}
	GameEvents.raise_reward_notification(reward_id, payload)
	queue_free()


func get_save_id() -> String:
	return PersistenceKeyUtility.resolve_key(self, save_id_prefix)


func _record_collected_state() -> void:
	var key := get_save_id()
	if not key.is_empty():
		DataManager.record_float(key + "_collected", 1.0)


func get_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	floats[key + "_collected"] = 1.0 if _collected else 0.0
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	if floats.get(key + "_collected", 0.0) >= 0.5:
		_collected = true
		_disable_pickup()
		call_deferred("queue_free")


func _on_body_entered(body: Node) -> void:
	collect(body)


func _disable_pickup() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	visible = false
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
