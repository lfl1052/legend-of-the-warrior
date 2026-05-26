class_name Breakable
extends StaticBody2D
## Breakable prop that can be destroyed once and optionally grants loot.

signal broken(attacker: Node)

@export var max_health: int = 1
@export var loot_table_id: StringName = &""
@export var auto_register_save: bool = true
@export var save_id_prefix: String = "breakable"
@export_node_path("CollisionShape2D") var collider_path: NodePath

var _health: int = 1
var _broken: bool = false


func _ready() -> void:
	add_to_group(&"damageable")
	_health = maxi(1, max_health)
	if auto_register_save:
		DataManager.register(self)


func _exit_tree() -> void:
	if auto_register_save:
		DataManager.unregister(self)


func take_damage(attacker: Node, amount: float = 1.0) -> void:
	if _broken:
		return
	_health = maxi(0, _health - max(1, int(ceil(amount))))
	if _health <= 0:
		_break(attacker)


func is_broken() -> bool:
	return _broken


func get_save_id() -> String:
	return PersistenceKeyUtility.resolve_key(self, save_id_prefix)


func get_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	floats[key + "_broken"] = 1.0 if _broken else 0.0
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	if floats.get(key + "_broken", 0.0) >= 0.5:
		_broken = true
		_health = 0
		_disable_collider()
		visible = false


func _break(attacker: Node) -> void:
	if _broken:
		return
	_broken = true
	_health = 0
	_disable_collider()
	visible = false
	var pos := global_position
	_apply_rewards()
	GameEvents.raise_play_sfx(&"breakable_break", pos)
	broken.emit(attacker)


func _apply_rewards() -> void:
	if loot_table_id == &"":
		return
	var breakable_id := get_save_id()
	var progression: Node = _find_player_progression()
	if progression != null:
		progression.call("try_apply_chest_rewards", breakable_id, loot_table_id)
	var table := RuntimeData.try_get_loot_table(loot_table_id)
	for entry in table.get("entries", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var reward_id := StringName(entry.get("reward_id", ""))
		if reward_id == &"":
			continue
		var payload := (entry as Dictionary).duplicate()
		payload["_progression_applied"] = progression != null
		GameEvents.raise_reward_notification(reward_id, payload)


func _disable_collider() -> void:
	var col := get_node_or_null(collider_path) as CollisionShape2D
	if col == null:
		for child in get_children():
			if child is CollisionShape2D:
				col = child
				break
	if col != null:
		col.set_deferred("disabled", true)


func _find_player_progression() -> Node:
	for node in get_tree().get_nodes_in_group(&"player_progression"):
		if node.has_method("try_apply_chest_rewards"):
			return node
	for player in get_tree().get_nodes_in_group(&"player"):
		for child in player.get_children():
			if child.has_method("try_apply_chest_rewards"):
				return child
	return null
