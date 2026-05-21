class_name BoarEliteSkillState
extends BaseState
## 野猪精英·冲撞技能（替代 Unity 项目里的 BoarElite 技能段）
##
## 三阶段：
##   1. windup     蓄力，原地播放 charge 动画
##   2. charge     高速冲撞，触地碎屑、撞墙强制结束
##   3. recovery   收尾硬直
##
## 完成后切回 Chase；冷却由 BoarElite 自身管理。

const PHASE_WINDUP := 0
const PHASE_CHARGE := 1
const PHASE_RECOVERY := 2

var _phase: int = PHASE_WINDUP
var _phase_timer: float = 0.0
var _direction: int = -1


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	_phase = PHASE_WINDUP
	_phase_timer = current_enemy.call("get_skill_windup_duration")

	var attacker_node: Node2D = current_enemy.attacker as Node2D
	_direction = -1
	if attacker_node != null:
		_direction = -1 if attacker_node.global_position.x < current_enemy.global_position.x else 1
	current_enemy.face_direction(_direction)
	current_enemy.velocity.x = 0.0
	if current_enemy.anim != null and current_enemy.anim.has_animation("charge_windup"):
		current_enemy.anim.play("charge_windup")


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead:
		return

	_phase_timer -= delta
	match _phase:
		PHASE_WINDUP:
			current_enemy.velocity.x = 0.0
			if _phase_timer <= 0.0:
				_phase = PHASE_CHARGE
				_phase_timer = current_enemy.call("get_skill_charge_duration")
				if current_enemy.anim != null and current_enemy.anim.has_animation("charge"):
					current_enemy.anim.play("charge")
		PHASE_CHARGE:
			var charge_speed: float = current_enemy.call("get_skill_charge_speed")
			current_enemy.velocity.x = _direction * charge_speed
			var pc: PhysicsCheck = current_enemy.physics_check
			var hit_wall := pc != null and ((_direction < 0 and pc.touch_left) or (_direction > 0 and pc.touch_right))
			if hit_wall or _phase_timer <= 0.0:
				_phase = PHASE_RECOVERY
				_phase_timer = current_enemy.call("get_skill_recovery_duration")
				current_enemy.velocity.x = 0.0
				if current_enemy.anim != null and current_enemy.anim.has_animation("charge_end"):
					current_enemy.anim.play("charge_end")
		PHASE_RECOVERY:
			current_enemy.velocity.x = 0.0
			if _phase_timer <= 0.0:
				current_enemy.switch_state(Enums.NPCState.CHASE)


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	if current_enemy != null:
		current_enemy.velocity.x = 0.0
	super.on_exit()
