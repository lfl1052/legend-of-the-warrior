class_name BossEnemy
extends EnemyEncounterCombatant

const BOSS_CHASE_STATE_SCRIPT := preload("res://scripts/enemy/boss_chase_state.gd")
const BOSS_SKILL_STATE_SCRIPT := preload("res://scripts/enemy/boss_skill_state.gd")
## Boss（替代 Unity 项目里的 BossEnemy 抽象基类）
##
## 与 EliteEnemy 的区别：
##   - 一旦发现玩家就锁场（通常配合 EncounterTrigger 关门）
##   - HUD 使用专属 Boss 血条
##
## 子类按需扩展技能与阶段逻辑。

@export var lock_arena_on_engage: bool = true
@export var skill_id: StringName = &"boss_shockwave"
@export var skill_cooldown: float = 3.5
@export var skill_trigger_range: float = 180.0
@export var skill_windup_duration: float = 0.45
@export var skill_active_duration: float = 0.18
@export var skill_recovery_duration: float = 0.5
@export var phase_skill_cooldown_multipliers: Array[float] = [1.0, 0.77, 0.61]
@export var phase_windup_multipliers: Array[float] = [1.0, 0.75, 0.55]
@export var phase_active_multipliers: Array[float] = [1.0, 1.10, 1.25]
@export var phase_recovery_multipliers: Array[float] = [1.0, 0.76, 0.58]
@export var phase_skill_damage: Array[int] = [2, 2, 3]
@export var phase_skill_radius_multipliers: Array[float] = [1.0, 1.28, 1.56]
@export var phase_chase_speed_multipliers: Array[float] = [1.0, 1.14, 1.28]
@export var chase_offset: Vector2 = Vector2.ZERO
@export_node_path("Area2D") var skill_attack_path: NodePath = ^"SkillAttack"

signal arena_engaged
signal arena_completed

var _skill_attack: Attack
var _skill_telegraph: RadialAttackTelegraph
var _skill_shape: CircleShape2D
var _base_skill_radius: float = 72.0
var _arena_is_engaged: bool = false


func _ready() -> void:
	_skill_attack = get_node_or_null(skill_attack_path) as Attack
	_skill_telegraph = get_node_or_null(^"SkillTelegraph") as RadialAttackTelegraph
	if _skill_attack != null:
		_skill_attack.set_active(false)
		var collider := _skill_attack.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
		if collider != null and collider.shape is CircleShape2D:
			_skill_shape = (collider.shape as CircleShape2D).duplicate() as CircleShape2D
			collider.shape = _skill_shape
			_base_skill_radius = _skill_shape.radius
	super._ready()
	register_skill(skill_id, skill_cooldown)
	phase_changed.connect(_on_phase_changed)
	_apply_phase_modifiers()


func _process(delta: float) -> void:
	super._process(delta)
	if current_state != Enums.NPCState.CHASE or attacker == null or is_dead or is_hurt:
		return
	var attacker_node := attacker as Node2D
	if attacker_node == null:
		return
	if global_position.distance_to(attacker_node.global_position) <= skill_trigger_range and trigger_skill(skill_id):
		switch_state(Enums.NPCState.SKILL)


func _setup_states() -> void:
	patrol_state = BoarPatrolState.new()
	chase_state = BOSS_CHASE_STATE_SCRIPT.new()
	skill_state = BOSS_SKILL_STATE_SCRIPT.new()


func _on_character_damage(by: Node) -> void:
	super._on_character_damage(by)
	if is_hurt and current_state == Enums.NPCState.SKILL:
		switch_state(Enums.NPCState.CHASE)
	_engage_arena()


func _on_character_died() -> void:
	set_skill_hitbox_active(false)
	set_skill_telegraph_phase(&"off")
	if _arena_is_engaged:
		arena_completed.emit()
	super._on_character_died()


func found_player() -> bool:
	var found := super.found_player()
	if found:
		_engage_arena()
	return found


func set_skill_hitbox_active(active: bool) -> void:
	if _skill_attack != null:
		_skill_attack.set_active(active)


func set_skill_telegraph_phase(phase: StringName) -> void:
	if _skill_telegraph == null:
		return
	match phase:
		&"windup": _skill_telegraph.show_windup()
		&"active": _skill_telegraph.show_active()
		_: _skill_telegraph.hide_telegraph()


func get_skill_windup_duration() -> float:
	return skill_windup_duration * _phase_float(phase_windup_multipliers, 1.0)


func get_skill_active_duration() -> float:
	return skill_active_duration * _phase_float(phase_active_multipliers, 1.0)


func get_skill_recovery_duration() -> float:
	return skill_recovery_duration * _phase_float(phase_recovery_multipliers, 1.0)


func get_skill_cooldown_duration(id: StringName, default_duration: float) -> float:
	if id != skill_id:
		return super.get_skill_cooldown_duration(id, default_duration)
	return default_duration * _phase_float(phase_skill_cooldown_multipliers, 1.0)


func get_phase_chase_speed() -> float:
	return chase_speed * _phase_float(phase_chase_speed_multipliers, 1.0)


func get_chase_offset() -> Vector2:
	return chase_offset


func get_health_current() -> float:
	return character.current_health if character != null else 0.0


func get_health_max() -> float:
	return character.max_health if character != null else 0.0


func get_max_poise() -> float:
	return max_poise


func _on_phase_changed(_new_phase: int) -> void:
	_apply_phase_modifiers()


func _apply_phase_modifiers() -> void:
	if _skill_attack != null:
		_skill_attack.damage = _phase_int(phase_skill_damage, _skill_attack.damage)
	var radius := _base_skill_radius * _phase_float(phase_skill_radius_multipliers, 1.0)
	if _skill_shape != null:
		_skill_shape.radius = radius
	if _skill_telegraph != null:
		_skill_telegraph.radius = radius
		_skill_telegraph.queue_redraw()


func _engage_arena() -> void:
	if _arena_is_engaged:
		return
	_arena_is_engaged = true
	if lock_arena_on_engage:
		arena_engaged.emit()
	GameEvents.raise_encounter_focus_changed(self)


func _phase_float(values: Array[float], fallback: float) -> float:
	if values.is_empty():
		return fallback
	return values[mini(phase_index, values.size() - 1)]


func _phase_int(values: Array[int], fallback: int) -> int:
	if values.is_empty():
		return fallback
	return values[mini(phase_index, values.size() - 1)]
