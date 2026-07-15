class_name EncounterRewardController
extends Node
## Encounter 清场奖励控制器。只负责聚合敌人死亡，不复制奖励或存档规则。

@export var encounter_id: String = ""
@export var loot_table_id: StringName = &""
@export var enemy_paths: Array[NodePath] = []
@export var auto_register_save: bool = true

var _enemies: Array[Node] = []
var _rewarded_this_session: bool = false


func _ready() -> void:
	if auto_register_save:
		DataManager.register(self)
	call_deferred("_configure_enemies")


func _exit_tree() -> void:
	if auto_register_save:
		DataManager.unregister(self)


func _configure_enemies() -> void:
	for path in enemy_paths:
		var enemy := get_node_or_null(path) as Node
		if enemy == null:
			continue
		_enemies.append(enemy)
		if enemy.has_signal("died_event") and not enemy.died_event.is_connected(_on_enemy_died):
			enemy.died_event.connect(_on_enemy_died.bind(enemy))
	_check_and_award()


func _on_enemy_died(_enemy: Node) -> void:
	_check_and_award()


func _check_and_award() -> void:
	if _rewarded_this_session or encounter_id.is_empty() or loot_table_id == &"" or _enemies.is_empty():
		return
	for enemy in _enemies:
		if is_instance_valid(enemy) and not bool(enemy.get("is_dead")):
			return
	_award_once()


func _award_once() -> void:
	var progression := _find_player_progression()
	if progression == null or not progression.has_method("try_apply_chest_rewards"):
		return
	var applied := bool(progression.call("try_apply_chest_rewards", encounter_id, loot_table_id))
	_rewarded_this_session = true
	if not applied:
		return
	var table := RuntimeData.try_get_loot_table(loot_table_id)
	for entry in table.get("entries", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var reward_id := StringName(entry.get("reward_id", ""))
		if reward_id == &"":
			continue
		var payload := (entry as Dictionary).duplicate()
		payload["_progression_applied"] = true
		payload["major"] = true
		GameEvents.raise_reward_notification(reward_id, payload)


func _find_player_progression() -> Node:
	for node in get_tree().get_nodes_in_group(&"player_progression"):
		if node.has_method("try_apply_chest_rewards"):
			return node
	return null


func get_save_id() -> String:
	return "encounter_reward_" + encounter_id


func get_save_data(_data: Dictionary) -> void:
	pass


func load_save_data(_data: Dictionary) -> void:
	_rewarded_this_session = false
	call_deferred("_check_and_award")
