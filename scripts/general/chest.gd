extends Node2D
## 宝箱（替代 Unity 项目里的 Chest）
##
## - 实现 IInteractable.trigger_action()
## - 通过 RuntimeData.try_get_loot_table() 拿奖励
## - 用 GameEvents.raise_reward_notification() 通知 UI
## - 持久化"是否已开"标记到 DataManager.float_data 字典

@export var loot_table_id: StringName = &""
@export var open_animation: StringName = &"open"
@export var auto_register_save: bool = true
@export var save_id_prefix: String = "chest"

@export_node_path("AnimationPlayer") var animation_player_path: NodePath
@export_node_path("CollisionShape2D") var collider_path: NodePath

var _opened: bool = false
var _data_def: DataDefinition


func _ready() -> void:
	add_to_group(&"interactable")
	_data_def = _ensure_data_definition()
	if auto_register_save:
		DataManager.register(self)


func _exit_tree() -> void:
	if auto_register_save:
		DataManager.unregister(self)


# ----- IInteractable -----------------------------------------------------------

func trigger_action() -> void:
	if _opened:
		return
	_opened = true
	_play_open_anim()
	_apply_rewards()
	_disable_collider()


# ----- 内部 --------------------------------------------------------------------

func _play_open_anim() -> void:
	var ap := get_node_or_null(animation_player_path) as AnimationPlayer
	if ap != null and ap.has_animation(open_animation):
		ap.play(open_animation)


func _apply_rewards() -> void:
	if loot_table_id == &"":
		return
	var table := RuntimeData.try_get_loot_table(loot_table_id)
	if table.is_empty():
		return
	var entries: Array = table.get("entries", [])
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var reward_id := StringName(entry.get("reward_id", ""))
		if reward_id == &"":
			continue
		GameEvents.raise_reward_notification(reward_id, entry)


func _disable_collider() -> void:
	var col := get_node_or_null(collider_path) as CollisionShape2D
	if col != null:
		col.set_deferred("disabled", true)


func _ensure_data_definition() -> DataDefinition:
	for child in get_children():
		if child is DataDefinition:
			return child
	var def := DataDefinition.new()
	def.name = "DataDefinition"
	add_child(def)
	return def


# ----- 存档接口 ----------------------------------------------------------------

func get_save_id() -> String:
	return PersistenceKeyUtility.resolve_key(self, save_id_prefix)


func get_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	floats[key + "_opened"] = 1.0 if _opened else 0.0
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	if floats.get(key + "_opened", 0.0) >= 0.5:
		_opened = true
		_disable_collider()
