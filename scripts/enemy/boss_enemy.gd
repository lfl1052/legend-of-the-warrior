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
@export var chase_offset: Vector2 = Vector2.ZERO
@export_node_path("Area2D") var skill_attack_path: NodePath = ^"SkillAttack"

var _skill_attack: Attack


func _ready() -> void:
	_skill_attack = get_node_or_null(skill_attack_path) as Attack
	if _skill_attack != null:
		_skill_attack.set_active(false)
	super._ready()
	register_skill(skill_id, skill_cooldown)


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
	if lock_arena_on_engage:
		GameEvents.encounter_focus_changed.emit(self)


func set_skill_hitbox_active(active: bool) -> void:
	if _skill_attack != null:
		_skill_attack.set_active(active)


func get_skill_windup_duration() -> float:
	return skill_windup_duration


func get_skill_active_duration() -> float:
	return skill_active_duration


func get_skill_recovery_duration() -> float:
	return skill_recovery_duration


func get_chase_offset() -> Vector2:
	return chase_offset


func get_health_current() -> float:
	return character.current_health if character != null else 0.0


func get_health_max() -> float:
	return character.max_health if character != null else 0.0


func get_max_poise() -> float:
	return max_poise
