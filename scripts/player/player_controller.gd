class_name PlayerController
extends CharacterBody2D
## 玩家控制（替代 Unity 项目里的 PlayerController.cs）
##
## 功能集合：
##   - 移动 / 行走切换 / 跳跃 / 蹬墙跳
##   - 蹲下 / 滑铲（带无敌帧 + 临时变更碰撞层）
##   - 三段连击（combo），蓄力时间窗口
##   - 受击 / 死亡 / 复活
##   - 治疗与技能斩，分别绑定 heal / skill_slash 输入动作
##   - 自动化驱动接口（供 AI 控制 / 测试脚本使用）
##
## 节点期望：
##   $Sprite                 Sprite2D / AnimatedSprite2D
##   $AnimationPlayer        AnimationPlayer，含 idle/run/walk/jump/fall/attack1..3/hurt/dead/slide/wall
##   $CollisionShape2D       身体主碰撞
##   $PhysicsCheck           PhysicsCheck（脚下/左右）
##   $Character              Character（血量/能量）
##   $AttackPivot/Attack     Attack（连击命中区，可多个）

const SPEED_NORMAL := 220.0
const SPEED_WALK := 110.0
const JUMP_VELOCITY := -600.0
const WALL_JUMP_X := 380.0
const WALL_JUMP_Y := -560.0
const SLIDE_SPEED := 320.0
const SLIDE_DURATION := 0.44
const COMBO_RESET := 0.70
const ATTACK_BUFFER_TIME := 0.50
const HURT_KNOCKBACK := 220.0
const WALL_SLIDE_MAX_SPEED := 140.0
const ATTACK_STARTUP_TIMES := [0.0, 0.06, 0.05, 0.08]
const ATTACK_ACTIVE_TIMES := [0.0, 0.16, 0.14, 0.20]
const SPRITE_ANIMATION_FRAMES := {
	"idle": [0, 1, 2, 3, 4, 5],
	"attack1": [8, 9, 10, 11, 12, 13],
	"attack2": [13, 14, 15],
	"attack3": [32, 33, 34, 35, 36, 37, 38, 39],
	"run": [16, 17, 18, 19, 20, 21, 22, 23],
	"walk": [16, 17, 18, 19, 20, 21, 22, 23],
	"jump": [24, 25, 26, 27],
	"fall": [28, 29],
	"wall": [27],
	"hurt": [40, 41, 42, 43],
	"dead": [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59],
	"slide": [16, 17, 18, 19, 20, 21, 22, 23],
}
const SECONDARY_SPRITE_ANIMATIONS := {
	"attack3": true,
	"slide": true,
}

@export var sprite_path: NodePath = ^"Sprite"
@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var character_path: NodePath = ^"Character"
@export var physics_check_path: NodePath = ^"PhysicsCheck"
@export var attack_root_path: NodePath = ^"AttackPivot"
@export var attack_area_path: NodePath = ^"AttackPivot/Attack"
@export var attack_hitbox_path: NodePath = ^"AttackPivot/Attack/CollisionShape2D"
@export var heal_skill_path: NodePath = ^"HealSkill"
@export var slash_skill_path: NodePath = ^"SkillSlash"
@export var secondary_sprite_texture: Texture2D

@export var walk_speed: float = SPEED_WALK
@export var run_speed: float = SPEED_NORMAL
@export var jump_velocity: float = JUMP_VELOCITY
@export var slide_speed: float = SLIDE_SPEED
@export var slide_duration: float = SLIDE_DURATION
@export var slide_cooldown: float = 0.6
@export var hide_body_after_death: float = 1.2
@export var ground_acceleration: float = 1400.0
@export var ground_turn_acceleration: float = 3000.0
@export var ground_deceleration: float = 3000.0
@export var air_acceleration: float = 1000.0
@export var attack_buffer_time: float = ATTACK_BUFFER_TIME
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var wall_jump_input_lock: float = 0.10
@export_range(0.1, 0.9, 0.05) var jump_release_ratio: float = 0.5

var input_enabled: bool = true
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var is_sliding: bool = false
var is_walking: bool = false
var is_on_wall_grab: bool = false
var combo_index: int = 0

# 自动化输入（用于调试 / 教学脚本）
var ai_move_x: float = 0.0
var ai_jump: bool = false
var ai_attack: bool = false
var ai_slide: bool = false
var ai_active: bool = false

var _facing: int = 1
var _slide_timer: float = 0.0
var _slide_cooldown_timer: float = 0.0
var _combo_timer: float = 0.0
var _attack_buffer_timer: float = 0.0
var _attack_startup_timer: float = 0.0
var _attack_active_timer: float = 0.0
var _attack_window_active: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _wall_jump_lock_timer: float = 0.0
var _normal_layer: int = 0
var _normal_mask: int = 0
var _sprite_base_modulate: Color = Color.WHITE
var _primary_sprite_texture: Texture2D
var _death_hide_scheduled: bool = false

@onready var _sprite: Node2D = get_node_or_null(sprite_path)
@onready var _anim: AnimationPlayer = get_node_or_null(animation_player_path)
@onready var _character: Character = get_node_or_null(character_path)
@onready var _physics_check: PhysicsCheck = get_node_or_null(physics_check_path)
@onready var _attack_root: Node2D = get_node_or_null(attack_root_path)
@onready var _attack_area := get_node_or_null(attack_area_path)
@onready var _attack_hitbox := get_node_or_null(attack_hitbox_path)
@onready var _heal_skill: Node = get_node_or_null(heal_skill_path)
@onready var _slash_skill: Node = get_node_or_null(slash_skill_path)


func _ready() -> void:
	add_to_group(&"player")
	add_to_group(&"damageable")
	_normal_layer = collision_layer
	_normal_mask = collision_mask
	if _sprite is CanvasItem:
		_sprite_base_modulate = (_sprite as CanvasItem).modulate
	if _sprite is Sprite2D:
		_primary_sprite_texture = (_sprite as Sprite2D).texture
	if _character != null:
		_character.died.connect(_on_died)
		_character.took_damage.connect(_on_took_damage)
	_set_attack_hitbox_active(false)
	GameEvents.new_game_started.connect(prepare_for_new_game_session)
	DataManager.register(self)


func _exit_tree() -> void:
	DataManager.unregister(self)


func _process(delta: float) -> void:
	_tick_attack_hitbox(delta)
	_update_sprite_frame()


# ---------------------------------------------------------------------------
# 主物理循环
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_tick_dash_cooldown(delta)
	_tick_movement_windows(delta)
	if is_dead:
		velocity.x = 0.0
		velocity.y += _gravity() * delta
		move_and_slide()
		return

	if not is_attacking:
		_combo_timer = maxf(0.0, _combo_timer - delta)
		if _combo_timer == 0.0:
			combo_index = 0

	if is_sliding:
		_tick_slide(delta)
		return

	var move_dir := _read_move_input()
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = coyote_time
	if _read_jump_pressed():
		_jump_buffer_timer = jump_buffer_time

	# 重力
	if not on_floor:
		velocity.y += _gravity() * delta

	# 蹬墙跳判定
	var grabbing_wall := not on_floor and (_physics_check != null) and (_physics_check.touch_left or _physics_check.touch_right)
	is_on_wall_grab = grabbing_wall
	if grabbing_wall and velocity.y > WALL_SLIDE_MAX_SPEED:
		velocity.y = WALL_SLIDE_MAX_SPEED

	# 跳跃缓冲：落地前的输入会保留到下一次可跳时刻。
	if _jump_buffer_timer > 0.0:
		if on_floor or _coyote_timer > 0.0:
			velocity.y = jump_velocity
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
			GameEvents.raise_play_sfx(&"jump", global_position)
		elif grabbing_wall:
			velocity.y = WALL_JUMP_Y
			velocity.x = WALL_JUMP_X * (1 if _physics_check.touch_left else -1)
			_facing = sign(velocity.x)
			_wall_jump_lock_timer = wall_jump_input_lock
			_jump_buffer_timer = 0.0
			GameEvents.raise_play_sfx(&"jump", global_position)

	# 松开跳跃时截断上升速度，形成短按轻跳 / 长按高跳。
	if _read_jump_released():
		_apply_jump_release()

	# 攻击输入在当前动作中会缓存一段时间，动画结束后直接衔接下一段。
	if _read_attack_pressed() and not is_hurt:
		if is_attacking:
			_queue_attack()
		else:
			_begin_attack()

	# 滑铲
	if _read_slide_pressed() and on_floor and not is_attacking and not is_hurt and can_dash():
		_begin_slide(move_dir)

	# 治疗
	if Input.is_action_just_pressed(&"heal") and _heal_skill != null and _heal_skill.has_method("try_use"):
		_heal_skill.call("try_use", self)

	# 技能斩
	if Input.is_action_just_pressed(&"skill_slash") and _slash_skill != null and _slash_skill.has_method("try_use"):
		_slash_skill.call("try_use", self)

	# 平移速度
	is_walking = Input.is_action_pressed(&"walk")
	if is_attacking and on_floor:
		velocity.x = 0.0
	elif is_hurt:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	elif _wall_jump_lock_timer > 0.0:
		# 保留离墙初速度，防止玩家尚未来得及松开方向键就被拉回墙面。
		pass
	else:
		var speed := walk_speed if is_walking else run_speed
		var target_speed := move_dir * speed
		var acceleration := air_acceleration
		if on_floor:
			if is_zero_approx(move_dir):
				acceleration = ground_deceleration
			elif not is_zero_approx(velocity.x) and signf(velocity.x) != signf(move_dir):
				acceleration = ground_turn_acceleration
			else:
				acceleration = ground_acceleration
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		if move_dir != 0.0:
			_facing = int(sign(move_dir))

	# 朝向
	if _sprite != null:
		var s := _sprite.scale
		s.x = absf(s.x) * _facing
		_sprite.scale = s
	if _attack_root != null:
		var sa := _attack_root.scale
		sa.x = absf(sa.x) * _facing
		_attack_root.scale = sa

	move_and_slide()
	_update_animation(move_dir, on_floor, grabbing_wall)


# ---------------------------------------------------------------------------
# 输入读取（含自动化覆盖）
# ---------------------------------------------------------------------------

func _read_move_input() -> float:
	if not input_enabled:
		return 0.0
	if ai_active:
		return ai_move_x
	return Input.get_axis(&"move_left", &"move_right")


func _read_jump_pressed() -> bool:
	if not input_enabled:
		return false
	if ai_active and ai_jump:
		ai_jump = false
		return true
	return Input.is_action_just_pressed(&"jump")


func _read_jump_released() -> bool:
	if not input_enabled or ai_active:
		return false
	return Input.is_action_just_released(&"jump")


func _read_attack_pressed() -> bool:
	if not input_enabled:
		return false
	if ai_active and ai_attack:
		ai_attack = false
		return true
	return Input.is_action_just_pressed(&"attack")


func _read_slide_pressed() -> bool:
	if not input_enabled:
		return false
	if ai_active and ai_slide:
		ai_slide = false
		return true
	return Input.is_action_just_pressed(&"slide")


func set_gameplay_input_active(active: bool) -> void:
	input_enabled = active
	if not active:
		velocity = Vector2.ZERO
		is_attacking = false
		is_sliding = false
		_attack_buffer_timer = 0.0
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_wall_jump_lock_timer = 0.0
		_set_attack_hitbox_active(false)


# ---------------------------------------------------------------------------
# 战斗
# ---------------------------------------------------------------------------

func _begin_attack() -> void:
	_attack_buffer_timer = 0.0
	combo_index = (combo_index % 3) + 1
	_combo_timer = COMBO_RESET
	is_attacking = true
	_attack_startup_timer = float(ATTACK_STARTUP_TIMES[combo_index])
	_attack_active_timer = float(ATTACK_ACTIVE_TIMES[combo_index])
	_attack_window_active = false
	_set_attack_hitbox_active(false)
	if _attack_area != null:
		var attack := _attack_area as Attack
		if attack != null:
			attack.damage = combo_index
			attack.reset_hits()
	if _anim != null:
		var anim_name := "attack%d" % combo_index
		if _anim.has_animation(anim_name):
			_anim.play(anim_name)
		else:
			# fallback: 单一 attack 动画
			if _anim.has_animation("attack"):
				_anim.play("attack")


func on_attack_animation_finished() -> void:
	_attack_startup_timer = 0.0
	_attack_active_timer = 0.0
	_attack_window_active = false
	_set_attack_hitbox_active(false)
	if _attack_buffer_timer > 0.0 and combo_index < 3 and not is_hurt and not is_dead:
		is_attacking = false
		_begin_attack()
		return
	_attack_buffer_timer = 0.0
	is_attacking = false


func _queue_attack() -> void:
	_attack_buffer_timer = attack_buffer_time


func on_hurt_animation_finished() -> void:
	is_hurt = false
	_reset_sprite_modulate()


func take_damage(by: Node, amount: float = 1.0) -> void:
	if _character == null:
		return
	_character.take_damage(by, amount)


func _tick_attack_hitbox(delta: float) -> void:
	if not is_attacking:
		if _attack_window_active:
			_attack_window_active = false
			_set_attack_hitbox_active(false)
		return

	if _attack_startup_timer > 0.0:
		_attack_startup_timer = maxf(0.0, _attack_startup_timer - delta)
		if _attack_startup_timer > 0.0:
			return

	if not _attack_window_active and _attack_active_timer > 0.0:
		_attack_window_active = true
		_set_attack_hitbox_active(true)

	if _attack_active_timer > 0.0:
		_attack_active_timer = maxf(0.0, _attack_active_timer - delta)
		if _attack_active_timer <= 0.0:
			_attack_window_active = false
			_set_attack_hitbox_active(false)


func _set_attack_hitbox_active(active: bool) -> void:
	if _attack_area != null:
		var attack := _attack_area as Attack
		if attack != null:
			attack.set_active(active)
	elif _attack_hitbox != null:
		var hitbox := _attack_hitbox as CollisionShape2D
		if hitbox != null:
			hitbox.set_deferred("disabled", not active)


func _flash_sprite(color: Color) -> void:
	if _sprite is CanvasItem:
		(_sprite as CanvasItem).modulate = color


func _reset_sprite_modulate() -> void:
	if _sprite is CanvasItem:
		(_sprite as CanvasItem).modulate = _sprite_base_modulate


func _on_took_damage(attacker: Node) -> void:
	if is_dead:
		return
	is_hurt = true
	is_attacking = false
	is_sliding = false
	combo_index = 0
	_attack_buffer_timer = 0.0
	_attack_startup_timer = 0.0
	_attack_active_timer = 0.0
	_attack_window_active = false
	_set_attack_hitbox_active(false)
	_restore_normal_collision()
	_flash_sprite(Color(1.0, 0.55, 0.55, 1.0))
	if attacker is Node2D:
		var node2d := attacker as Node2D
		var dir := signf(global_position.x - node2d.global_position.x)
		if dir == 0.0:
			dir = -_facing
		velocity = Vector2(dir * HURT_KNOCKBACK, jump_velocity * 0.4)
	if _anim != null and _anim.has_animation("hurt"):
		_anim.play("hurt")


func _on_died() -> void:
	is_dead = true
	is_attacking = false
	is_sliding = false
	is_hurt = false
	_attack_buffer_timer = 0.0
	input_enabled = false
	_set_attack_hitbox_active(false)
	_restore_normal_collision()
	_set_body_collision_enabled(false)
	_disable_interaction_probe(true)
	_reset_sprite_modulate()
	velocity = Vector2.ZERO
	if _anim != null and _anim.has_animation("dead"):
		_anim.play("dead")
	GameEvents.raise_game_over()
	_schedule_death_hide()


func revive_at(pos: Vector2) -> void:
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_sliding = false
	_death_hide_scheduled = false
	_attack_buffer_timer = 0.0
	visible = true
	input_enabled = true
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_wall_jump_lock_timer = 0.0
	_set_attack_hitbox_active(false)
	_restore_normal_collision()
	_set_body_collision_enabled(true)
	_disable_interaction_probe(false)
	_reset_sprite_modulate()
	global_position = pos
	if _character != null:
		_character.reset_to_full()


func prepare_for_new_game_session() -> void:
	combo_index = 0
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_sliding = false
	_death_hide_scheduled = false
	_attack_buffer_timer = 0.0
	visible = true
	input_enabled = true
	_slide_cooldown_timer = 0.0
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_wall_jump_lock_timer = 0.0
	_set_attack_hitbox_active(false)
	_restore_normal_collision()
	_set_body_collision_enabled(true)
	_disable_interaction_probe(false)
	_reset_sprite_modulate()
	if _character != null:
		_character.reset_to_full()


# ---------------------------------------------------------------------------
# 滑铲
# ---------------------------------------------------------------------------

func _begin_slide(move_dir: float) -> void:
	is_sliding = true
	_slide_timer = slide_duration
	_slide_cooldown_timer = slide_cooldown
	if move_dir != 0.0:
		_facing = int(sign(move_dir))
	velocity.x = _facing * slide_speed
	# Temporarily ignore enemy attack / hazard layers during the early slide frames.
	collision_mask &= ~(1 << 4)
	collision_mask &= ~(1 << 6)
	if _character != null:
		_character.set_invulnerable_for(slide_duration * 0.6)
	GameEvents.raise_play_sfx(&"jump", global_position)
	if _anim != null and _anim.has_animation("slide"):
		_anim.play("slide")


func _tick_slide(delta: float) -> void:
	_slide_timer -= delta
	velocity.y += _gravity() * delta
	if not is_on_floor():
		_slide_timer = minf(_slide_timer, 0.05)
	move_and_slide()
	if _slide_timer <= 0.0:
		is_sliding = false
		velocity.x = 0.0
		_restore_normal_collision()


func can_dash() -> bool:
	return _slide_cooldown_timer <= 0.0


func _tick_dash_cooldown(delta: float) -> void:
	_slide_cooldown_timer = maxf(0.0, _slide_cooldown_timer - delta)


func _tick_movement_windows(delta: float) -> void:
	_coyote_timer = maxf(0.0, _coyote_timer - delta)
	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
	_wall_jump_lock_timer = maxf(0.0, _wall_jump_lock_timer - delta)
	_attack_buffer_timer = maxf(0.0, _attack_buffer_timer - delta)


func _apply_jump_release() -> void:
	if velocity.y < jump_velocity * jump_release_ratio:
		velocity.y = jump_velocity * jump_release_ratio


func _restore_normal_collision() -> void:
	collision_layer = _normal_layer
	collision_mask = _normal_mask


func _disable_interaction_probe(disabled: bool) -> void:
	var sign := get_node_or_null(^"Sign") as Area2D
	if sign == null:
		return
	sign.monitoring = not disabled
	sign.monitorable = false


func _set_body_collision_enabled(enabled: bool) -> void:
	if enabled:
		collision_layer = _normal_layer
		collision_mask = _normal_mask
	else:
		collision_layer = 0
		collision_mask = 0
	var body_shape := get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", not enabled)


func _schedule_death_hide() -> void:
	if _death_hide_scheduled:
		return
	_death_hide_scheduled = true
	if hide_body_after_death <= 0.0 or get_tree() == null:
		call_deferred("_hide_dead_body")
		return
	get_tree().create_timer(hide_body_after_death).timeout.connect(_hide_dead_body, CONNECT_ONE_SHOT)


func _hide_dead_body() -> void:
	if is_dead:
		visible = false


# ---------------------------------------------------------------------------
# 动画
# ---------------------------------------------------------------------------

func _update_animation(move_dir: float, on_floor: bool, grabbing_wall: bool) -> void:
	if _anim == null or is_attacking or is_hurt or is_dead or is_sliding:
		return
	if grabbing_wall:
		_play_if_present("wall")
	elif not on_floor:
		_play_if_present("jump" if velocity.y < 0.0 else "fall")
	elif absf(move_dir) > 0.05:
		_play_if_present("walk" if is_walking else "run")
	else:
		_play_if_present("idle")


func _play_if_present(anim_name: String) -> void:
	if _anim != null and _anim.has_animation(anim_name) and _anim.current_animation != anim_name:
		_anim.play(anim_name)


func _update_sprite_frame() -> void:
	var sprite := _sprite as Sprite2D
	if sprite == null:
		return

	var anim_name := "idle"
	if _anim != null and not String(_anim.current_animation).is_empty():
		anim_name = String(_anim.current_animation)

	var frames: Array = get_sprite_animation_frames(anim_name)
	if frames.is_empty():
		return

	var uses_secondary := SECONDARY_SPRITE_ANIMATIONS.has(anim_name)
	var target_texture := secondary_sprite_texture if uses_secondary else _primary_sprite_texture
	if target_texture != null and sprite.texture != target_texture:
		sprite.texture = target_texture
		sprite.hframes = 8
		sprite.vframes = 7 if uses_secondary else 11

	var frame_index := 0
	if _anim != null and _anim.has_animation(anim_name):
		var anim := _anim.get_animation(anim_name)
		var anim_length := maxf(anim.length, 0.001)
		var anim_position := clampf(_anim.current_animation_position, 0.0, anim_length)
		frame_index = mini(int(floor(anim_position / anim_length * frames.size())), frames.size() - 1)
		if anim.loop_mode != Animation.LOOP_NONE:
			frame_index %= frames.size()

	sprite.frame = int(frames[frame_index])


func get_sprite_animation_frames(anim_name: StringName) -> Array:
	return SPRITE_ANIMATION_FRAMES.get(String(anim_name), SPRITE_ANIMATION_FRAMES["idle"])


func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/2d/default_gravity", 2000.0))


# ---------------------------------------------------------------------------
# 自动化接口（供 AI / 调试脚本驱动）
# ---------------------------------------------------------------------------

func enable_automation(enable: bool) -> void:
	ai_active = enable
	ai_move_x = 0.0
	ai_jump = false
	ai_attack = false
	ai_slide = false


func automation_move(value: float) -> void:
	ai_move_x = clampf(value, -1.0, 1.0)


func automation_jump() -> void:
	ai_jump = true


func automation_attack() -> void:
	ai_attack = true


func automation_slide() -> void:
	ai_slide = true


# ---------------------------------------------------------------------------
# ISaveable
# ---------------------------------------------------------------------------

func get_save_id() -> String:
	return PersistenceKeyUtility.resolve_key(self, "player")


func get_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var positions: Dictionary = data.get("character_pos", {})
	positions[key] = {"x": global_position.x, "y": global_position.y, "z": 0.0}
	data["character_pos"] = positions


func load_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	if key.is_empty():
		return
	var positions: Dictionary = data.get("character_pos", {})
	if positions.has(key):
		var pos: Dictionary = positions[key]
		global_position = Vector2(float(pos.get("x", global_position.x)), float(pos.get("y", global_position.y)))
