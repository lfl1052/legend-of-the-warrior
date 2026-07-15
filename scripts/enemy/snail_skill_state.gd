class_name SnailSkillState
extends BaseState
## 蜗牛缩壳（替代 Unity 项目里的 SnailSkillState）
##
## 进入后开启无敌、播放 hide 动画；用 lost_time 倒计时控制持续时间，
## 时间到即返回巡逻。期间持续把无敌时间同步到 Character。

var _timer: float = 0.0
const HIDDEN_FRAME := 3
const INVULNERABLE_REFRESH_TIME := 0.25
const MIN_UNHIDE_TIME := 0.65

enum ShellPhase {
	HIDING,
	WAITING,
	UNHIDING,
}

var _phase: int = ShellPhase.HIDING


func on_enter(enemy: Node) -> void:
	super.on_enter(enemy)
	current_enemy.velocity.x = 0.0
	current_enemy.current_speed = 0.0
	current_enemy.lost_time_counter = current_enemy.lost_time
	_phase = ShellPhase.HIDING
	_set_contact_attack_active(false)
	_timer = _get_animation_length(&"hide") if _play_animation(&"hide") else 0.0

	if _timer <= 0.0:
		_hold_hidden_frame()
		_phase = ShellPhase.WAITING

	_refresh_invulnerable()


func logic_update(delta: float) -> void:
	if current_enemy == null or current_enemy.is_dead:
		return

	current_enemy.velocity.x = 0.0
	current_enemy.current_speed = 0.0
	_refresh_invulnerable()

	match _phase:
		ShellPhase.HIDING:
			_timer = maxf(0.0, _timer - delta)
			current_enemy.lost_time_counter = _timer
			if _timer <= 0.0:
				_hold_hidden_frame()
				_phase = ShellPhase.WAITING
		ShellPhase.WAITING:
			_timer = 0.0
			_hold_hidden_frame()
			if not _is_player_in_sight():
				current_enemy.attacker = null
				current_enemy.lost_time_counter = 0.0
				_phase = ShellPhase.UNHIDING
				_timer = 0.0
				if not _play_animation(&"unhide"):
					current_enemy.switch_state(Enums.NPCState.PATROL)
			else:
				current_enemy.lost_time_counter = current_enemy.lost_time
		ShellPhase.UNHIDING:
			_timer += delta
			current_enemy.lost_time_counter = maxf(0.0, MIN_UNHIDE_TIME - _timer)
			if _is_player_in_sight():
				_hold_hidden_frame()
				_phase = ShellPhase.WAITING
				return
			if _timer >= MIN_UNHIDE_TIME and not _is_animation_playing(&"unhide"):
				current_enemy.switch_state(Enums.NPCState.PATROL)


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	if current_enemy != null:
		var character: Character = _get_character()
		if character != null:
			character.set_invulnerable_for(0.0)
	_set_contact_attack_active(false)
	super.on_exit()


func _set_contact_attack_active(active: bool) -> void:
	if current_enemy != null and current_enemy.has_method("set_contact_attack_active"):
		current_enemy.call("set_contact_attack_active", active)


func _get_character() -> Character:
	if current_enemy == null:
		return null
	for child in current_enemy.get_children():
		if child is Character:
			return child
	return null


func _play_animation(anim_name: StringName) -> bool:
	if current_enemy.anim == null or not current_enemy.anim.has_animation(anim_name):
		return false
	current_enemy.anim.play(anim_name)
	return true


func _get_animation_length(anim_name: StringName) -> float:
	if current_enemy.anim == null or not current_enemy.anim.has_animation(anim_name):
		return 0.0
	var animation: Animation = current_enemy.anim.get_animation(anim_name)
	return 0.0 if animation == null else animation.length


func _is_animation_playing(anim_name: StringName) -> bool:
	return current_enemy.anim != null \
			and current_enemy.anim.current_animation == anim_name \
			and current_enemy.anim.is_playing()


func _hold_hidden_frame() -> void:
	if current_enemy.anim != null:
		current_enemy.anim.stop(true)
	var walk_sprite := current_enemy.get_node_or_null("Visual/Sprite2D") as Sprite2D
	var hide_sprite := current_enemy.get_node_or_null("Visual/Sprite2DHide") as Sprite2D
	var dead_sprite := current_enemy.get_node_or_null("Visual/Sprite2DDead") as Sprite2D
	if walk_sprite != null:
		walk_sprite.visible = false
	if hide_sprite != null:
		hide_sprite.visible = true
		hide_sprite.frame = HIDDEN_FRAME
	if dead_sprite != null:
		dead_sprite.visible = false


func _is_player_in_sight() -> bool:
	if current_enemy.has_method("found_player"):
		return current_enemy.found_player()
	return current_enemy.attacker != null


func _refresh_invulnerable() -> void:
	var character: Character = _get_character()
	if character != null:
		character.set_invulnerable_for(INVULNERABLE_REFRESH_TIME)
