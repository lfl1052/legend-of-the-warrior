class_name Character
extends Node
## 角色基类（替代 Unity 项目里的 Character）
##
## 关键属性：
##   max_health / current_health
##   max_power / current_power / power_recover_speed
##   invulnerable_duration
##
## 关键事件（通过 GameEvents 派发，便于 HUD/UI 监听）：
##   character_health_changed
##   character_took_damage
##   character_died
##
## 该节点通常作为玩家/敌人节点的子节点存在。

signal health_changed
signal took_damage(attacker: Node)
signal died

@export var max_health: float = 5.0
@export var max_power: float = 100.0
@export var power_recover_speed: float = 8.0
@export var invulnerable_duration: float = 0.5

var current_health: float = 0.0
var current_power: float = 0.0
var is_invulnerable: bool = false
var _invulnerable_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	current_power = max_power


func _process(delta: float) -> void:
	if current_power < max_power:
		current_power = minf(max_power, current_power + power_recover_speed * delta)

	if is_invulnerable:
		_invulnerable_timer -= delta
		if _invulnerable_timer <= 0.0:
			is_invulnerable = false


# ----- 公共接口 ----------------------------------------------------------------

func take_damage(attacker: Node, amount: float = 1.0) -> void:
	if is_invulnerable or is_dead():
		return
	current_health = maxf(0.0, current_health - amount)
	is_invulnerable = true
	_invulnerable_timer = invulnerable_duration

	took_damage.emit(attacker)
	GameEvents.raise_character_took_damage(self, attacker)
	var parent := get_parent()
	var pos := Vector2.ZERO
	if parent is Node2D:
		pos = (parent as Node2D).global_position
	GameEvents.raise_play_sfx(&"hurt", pos)
	health_changed.emit()
	GameEvents.raise_character_health_changed(self)

	if is_dead():
		died.emit()
		GameEvents.raise_character_died(self)


func heal(amount: float) -> void:
	if is_dead():
		return
	current_health = minf(max_health, current_health + amount)
	health_changed.emit()
	GameEvents.raise_character_health_changed(self)


func consume_power(amount: float) -> bool:
	if current_power < amount:
		return false
	current_power -= amount
	return true


func reset_to_full() -> void:
	current_health = max_health
	current_power = max_power
	is_invulnerable = false
	_invulnerable_timer = 0.0
	health_changed.emit()
	GameEvents.raise_character_health_changed(self)


func set_invulnerable_for(duration: float) -> void:
	_invulnerable_timer = maxf(0.0, duration)
	is_invulnerable = _invulnerable_timer > 0.0


func is_dead() -> bool:
	return current_health <= 0.0


func get_health_ratio() -> float:
	return 0.0 if max_health <= 0.0 else current_health / max_health


func get_power_ratio() -> float:
	return 0.0 if max_power <= 0.0 else current_power / max_power


# ----- 存档接口（ISaveable 鸭子类型） -------------------------------------------

func get_save_id() -> String:
	return PersistenceKeyUtility.resolve_key(get_parent(), "character")


func get_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	floats[key + "_health"] = current_health
	floats[key + "_power"] = current_power
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var floats: Dictionary = data.get("float_data", {})
	if floats.has(key + "_health"):
		current_health = float(floats[key + "_health"])
	if floats.has(key + "_power"):
		current_power = float(floats[key + "_power"])
	health_changed.emit()
	GameEvents.raise_character_health_changed(self)
