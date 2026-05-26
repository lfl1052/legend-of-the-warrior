class_name BossSkillState
extends BaseState

const PHASE_WINDUP := 0
const PHASE_ACTIVE := 1
const PHASE_RECOVERY := 2

var _phase: int = PHASE_WINDUP
var _phase_timer: float = 0.0


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	_phase = PHASE_WINDUP
	_phase_timer = _call_float("get_skill_windup_duration")
	current_enemy.velocity = Vector2.ZERO
	if current_enemy.has_method("set_skill_hitbox_active"):
		current_enemy.call("set_skill_hitbox_active", false)
	if current_enemy.anim != null and current_enemy.anim.has_animation("skill_windup"):
		current_enemy.anim.play("skill_windup")


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead:
		return

	_phase_timer -= delta
	match _phase:
		PHASE_WINDUP:
			current_enemy.velocity = Vector2.ZERO
			if _phase_timer <= 0.0:
				_begin_active()
		PHASE_ACTIVE:
			current_enemy.velocity = Vector2.ZERO
			if _phase_timer <= 0.0:
				_begin_recovery()
		PHASE_RECOVERY:
			current_enemy.velocity = Vector2.ZERO
			if _phase_timer <= 0.0:
				current_enemy.switch_state(Enums.NPCState.CHASE)


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	if current_enemy != null:
		current_enemy.velocity = Vector2.ZERO
		if current_enemy.has_method("set_skill_hitbox_active"):
			current_enemy.call("set_skill_hitbox_active", false)
	super.on_exit()


func _begin_active() -> void:
	_phase = PHASE_ACTIVE
	_phase_timer = _call_float("get_skill_active_duration")
	if current_enemy.has_method("set_skill_hitbox_active"):
		current_enemy.call("set_skill_hitbox_active", true)
	if current_enemy.anim != null and current_enemy.anim.has_animation("skill_active"):
		current_enemy.anim.play("skill_active")


func _begin_recovery() -> void:
	_phase = PHASE_RECOVERY
	_phase_timer = _call_float("get_skill_recovery_duration")
	if current_enemy.has_method("set_skill_hitbox_active"):
		current_enemy.call("set_skill_hitbox_active", false)
	if current_enemy.anim != null and current_enemy.anim.has_animation("skill_recovery"):
		current_enemy.anim.play("skill_recovery")


func _call_float(method_name: String) -> float:
	if current_enemy != null and current_enemy.has_method(method_name):
		return float(current_enemy.call(method_name))
	return 0.0
