class_name BeePatrolState
extends BaseState
## 蜜蜂巡逻状态（替代 Unity 项目里的 BeePatrolState）
##
## 在 patrolHalfExtents 范围内随机选点悬停飞行。
## 一旦发现玩家就切换到 Chase。

const ARRIVE_DISTANCE := 12.0

var _current_target: Vector2 = Vector2.ZERO
var _wait_timer: float = 0.0


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	if current_enemy.has_method("get"):
		current_enemy.set("current_speed", current_enemy.normal_speed)
	if current_enemy.anim != null:
		_play_if_present(current_enemy.anim, "fly")
	_pick_new_target()


func logic_update(_delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead or current_enemy.is_hurt:
		return

	if current_enemy.has_method("found_player") and current_enemy.found_player():
		current_enemy.switch_state(Enums.NPCState.CHASE)
		return

	if _wait_timer > 0.0:
		_wait_timer -= _delta
		current_enemy.velocity = Vector2.ZERO
		return

	var to_target := _current_target - current_enemy.global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		_wait_timer = randf_range(0.4, 1.0)
		_pick_new_target()
		return

	var dir := to_target.normalized()
	current_enemy.velocity = dir * current_enemy.normal_speed
	current_enemy.face_direction(dir.x)


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	super.on_exit()


func _pick_new_target() -> void:
	if current_enemy.has_method("get_new_patrol_point"):
		var p: Variant = current_enemy.get_new_patrol_point()
		if p is Vector2:
			_current_target = p


func _play_if_present(ap: AnimationPlayer, anim_name: String) -> void:
	if ap.has_animation(anim_name) and ap.current_animation != anim_name:
		ap.play(anim_name)
