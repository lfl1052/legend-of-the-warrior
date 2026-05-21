class_name SnailSkillState
extends BaseState
## 蜗牛缩壳（替代 Unity 项目里的 SnailSkillState）
##
## 进入后开启无敌、播放 hide 动画；用 lost_time 倒计时控制持续时间，
## 时间到即返回巡逻。期间持续把无敌时间同步到 Character。

var _timer: float = 0.0


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.velocity.x = 0.0
	current_enemy.current_speed = current_enemy.chase_speed
	current_enemy.lost_time_counter = current_enemy.lost_time
	_timer = current_enemy.lost_time

	if current_enemy.anim != null and current_enemy.anim.has_animation("hide"):
		current_enemy.anim.play("hide")

	var character: Character = _get_character()
	if character != null:
		character.is_invulnerable = true
		character.invulnerable_counter = _timer


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead:
		return

	_timer -= delta
	current_enemy.lost_time_counter = _timer
	current_enemy.velocity.x = 0.0

	var character: Character = _get_character()
	if character != null:
		character.invulnerable_counter = _timer

	if _timer <= 0.0:
		current_enemy.switch_state(Enums.NPCState.PATROL)


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	if current_enemy != null:
		var character: Character = _get_character()
		if character != null:
			character.is_invulnerable = false
			character.invulnerable_counter = 0.0
	super.on_exit()


func _get_character() -> Character:
	if current_enemy == null:
		return null
	for child in current_enemy.get_children():
		if child is Character:
			return child
	return null
