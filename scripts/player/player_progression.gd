class_name PlayerProgression
extends Node
## 玩家进阶（替代 Unity 项目里的 PlayerProgression）
##
## 维护：
##   - tutorial_economy_tokens / upgrade_tokens / map_tokens
##   - opened_chest_rewards 集合（用 Dictionary 当 set）
##   - 已解锁槽位
##
## 通过 RuntimeData.get_player_progression() 拿到 progression.json 的里程碑配置。
## 通过 GameEvents.reward_notification 接收宝箱发放的奖励。

signal tokens_changed
signal unlock_changed(slot: StringName)
signal progression_changed(progression: PlayerProgression)

@export var save_id: String = "player_progression"

var tutorial_economy_tokens: int = 0
var upgrade_tokens: int = 0
var map_tokens: int = 0
var opened_chest_rewards: Dictionary = {}
var unlocked_slots: Dictionary = {}

var _config: PlayerProgressionResource


func _ready() -> void:
	add_to_group(&"player_progression")
	_config = PlayerProgressionResource.from_dict(RuntimeData.get_player_progression())
	GameEvents.reward_notification.connect(_on_reward_notification)
	GameEvents.new_game_started.connect(_on_new_game)
	DataManager.register(self)
	_apply_future_unlock_slots()


func _exit_tree() -> void:
	remove_from_group(&"player_progression")
	DataManager.unregister(self)


# ----- 公共 API ----------------------------------------------------------------

func try_apply_chest_rewards(chest_id: String, table_id: StringName) -> bool:
	if chest_id.is_empty() or opened_chest_rewards.has(chest_id):
		return false
	opened_chest_rewards[chest_id] = true
	var table := RuntimeData.try_get_loot_table(table_id)
	for entry in table.get("entries", []):
		_apply_reward(StringName(entry.get("reward_id", "")), entry)
	_emit_progression_changed()
	return true


func has_chest_rewards(chest_id: String) -> bool:
	return not chest_id.is_empty() and opened_chest_rewards.has(chest_id)


func has_unlock_slot(slot: StringName) -> bool:
	return unlocked_slots.has(slot)


func unlock_slot(slot: StringName) -> void:
	if slot == &"" or unlocked_slots.has(slot):
		return
	unlocked_slots[slot] = true
	unlock_changed.emit(slot)
	_emit_progression_changed()


func is_future_unlock_slot_ready(slot_id: String) -> bool:
	return has_unlock_slot(StringName(slot_id))


func get_future_unlock_slot_count() -> int:
	return _config.future_unlock_slots.size() if _config != null else 0


func get_ready_future_unlock_slot_count() -> int:
	if _config == null:
		return 0
	var ready_count := 0
	for slot in _config.future_unlock_slots:
		if unlocked_slots.has(slot):
			ready_count += 1
	return ready_count


func get_next_future_unlock_slot_id() -> String:
	if _config == null:
		return ""
	for slot in _config.future_unlock_slots:
		if not unlocked_slots.has(slot):
			return String(slot)
	return ""


# ----- 事件 --------------------------------------------------------------------

func _on_reward_notification(reward_id: StringName, payload: Dictionary) -> void:
	if bool(payload.get("_progression_applied", false)):
		return
	_apply_reward(reward_id, payload)


func _on_new_game() -> void:
	tutorial_economy_tokens = 0
	upgrade_tokens = 0
	map_tokens = 0
	opened_chest_rewards.clear()
	unlocked_slots.clear()
	_apply_future_unlock_slots()
	tokens_changed.emit()
	_emit_progression_changed()


# ----- 内部 --------------------------------------------------------------------

func _apply_reward(reward_id: StringName, payload: Dictionary) -> void:
	var amount := int(payload.get("amount", 1))
	match String(reward_id):
		"tutorial-economy-token":
			tutorial_economy_tokens += amount
		"upgrade-token":
			upgrade_tokens += amount
		"map-token":
			map_tokens += amount
		"health-refill":
			_refill_player_resource("health")
		"power-refill":
			_refill_player_resource("power")
		_:
			# 解锁槽位等
			var slot := StringName(payload.get("unlock_slot", ""))
			if slot != &"":
				unlock_slot(slot)
			return
	tokens_changed.emit()
	_emit_progression_changed()


func _refill_player_resource(kind: String) -> void:
	var players := get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	var player := players[0]
	var character: Character = null
	for child in player.get_children():
		if child is Character:
			character = child
			break
	if character == null:
		return
	if kind == "health":
		character.heal(character.max_health)
	elif kind == "power":
		character.current_power = character.max_power


func _apply_future_unlock_slots() -> void:
	if _config == null:
		return
	for slot in _config.future_unlock_slots:
		unlocked_slots[slot] = true


func _emit_progression_changed() -> void:
	progression_changed.emit(self)


# ----- ISaveable ---------------------------------------------------------------

func get_save_id() -> String:
	return save_id


func get_save_data(data: Dictionary) -> void:
	var floats: Dictionary = data.get("float_data", {})
	floats[save_id + "_tut"] = float(tutorial_economy_tokens)
	floats[save_id + "_up"] = float(upgrade_tokens)
	floats[save_id + "_map"] = float(map_tokens)
	for chest_id in opened_chest_rewards.keys():
		floats[save_id + "_chest_" + String(chest_id)] = 1.0
	for slot in unlocked_slots.keys():
		floats[save_id + "_slot_" + String(slot)] = 1.0
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var floats: Dictionary = data.get("float_data", {})
	tutorial_economy_tokens = int(floats.get(save_id + "_tut", 0.0))
	upgrade_tokens = int(floats.get(save_id + "_up", 0.0))
	map_tokens = int(floats.get(save_id + "_map", 0.0))
	for k in floats.keys():
		var key_str := String(k)
		if key_str.begins_with(save_id + "_chest_"):
			opened_chest_rewards[key_str.substr((save_id + "_chest_").length())] = true
		elif key_str.begins_with(save_id + "_slot_"):
			unlocked_slots[StringName(key_str.substr((save_id + "_slot_").length()))] = true
	tokens_changed.emit()
	_emit_progression_changed()
