extends Node2D
## 存档点（替代 Unity 项目里的 SavePoint）
##
## - 实现 trigger_action 接口
## - 首次激活时广播奖励事件 + 注入存档（GameEvents.save_data_requested）
## - 持续做"glow pulse"呼吸动画

signal first_activation
signal activated

@export var save_id_prefix: String = "save_point"
@export var first_activation_reward: StringName = &"power-refill"
@export var loop_pulse: bool = true
@export var pulse_period: float = 1.4

@export_node_path("Sprite2D") var glow_sprite_path: NodePath
@export_node_path("AnimationPlayer") var animation_player_path: NodePath

var _activated: bool = false
var _pulse_t: float = 0.0
var _glow: CanvasItem
var _ap: AnimationPlayer


func _ready() -> void:
	add_to_group(&"interactable")
	_glow = get_node_or_null(glow_sprite_path) as CanvasItem
	_ap = get_node_or_null(animation_player_path) as AnimationPlayer
	DataManager.register(self)


func _exit_tree() -> void:
	DataManager.unregister(self)


func _process(delta: float) -> void:
	if not loop_pulse or _glow == null:
		return
	_pulse_t = fmod(_pulse_t + delta, pulse_period)
	var phase := _pulse_t / pulse_period
	var intensity := 0.65 + 0.35 * sin(phase * TAU)
	_glow.modulate = Color(1.0, 1.0, 1.0, intensity)


# ----- IInteractable -----------------------------------------------------------

func trigger_action() -> void:
	var was_first := not _activated
	_activated = true

	if _ap != null and _ap.has_animation("activate"):
		_ap.play("activate")

	# 立即触发存档
	GameEvents.raise_save_data()
	activated.emit()

	if was_first:
		first_activation.emit()
		if first_activation_reward != &"":
			GameEvents.raise_reward_notification(first_activation_reward, {"amount": 1})


# ----- ISaveable ---------------------------------------------------------------

func get_save_id() -> String:
	return PersistenceKeyUtility.resolve_key(self, save_id_prefix)


func get_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	var floats: Dictionary = data.get("float_data", {})
	floats[key + "_done"] = 1.0 if _activated else 0.0
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	var floats: Dictionary = data.get("float_data", {})
	if floats.get(key + "_done", 0.0) >= 0.5:
		_activated = true
