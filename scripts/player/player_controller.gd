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
const ATTACK_HITBOX_SIZES := [
	Vector2.ZERO,
	Vector2(44.0, 32.0),
	Vector2(54.0, 36.0),
	Vector2(68.0, 44.0),
]
const ATTACK_HITBOX_OFFSETS := [
	Vector2.ZERO,
	Vector2(34.0, -2.0),
	Vector2(40.0, -1.0),
	Vector2(46.0, -2.0),
]
const SPRITE_ANIMATION_FRAMES := {
	"idle": [0, 1, 2, 3, 4, 5],
	"attack1": [8, 9, 10, 11, 12, 13],
	"attack2": [13, 14, 15],
	"attack3": [32, 33, 34, 35, 36, 37, 38, 39],
	"run": [16, 17, 18, 19, 20, 21, 22, 23],
	"walk": [0, 1, 2, 3, 4, 5, 6, 7],
	"jump": [24, 25, 26, 27],
	"fall": [32, 33, 34, 35, 36, 37],
	"land": [38, 39],
	"wall": [24, 25, 26, 27],
	"hurt": [40, 41, 42, 43],
	"dead": [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59],
	"skill_slash": [64, 65, 66, 67, 68, 69, 70, 71],
	"heal": [64, 65, 66, 67, 68, 69, 70, 71],
	"crouch": [72, 73, 74],
	"block": [80, 81, 82],
	"slide": [16, 17, 18, 19, 20, 21, 22, 23],
	"climb": [40, 41, 42, 43, 44, 45, 46, 47],
}
const SECONDARY_SPRITE_ANIMATIONS := {
	"attack3": true,
	"climb": true,
	"slide": true,
	"walk": true,
	"wall": true,
}

@export var sprite_path: NodePath = ^"Sprite"
@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var character_path: NodePath = ^"Character"
@export var physics_check_path: NodePath = ^"PhysicsCheck"
@export var attack_root_path: NodePath = ^"AttackPivot"
@export var attack_area_path: NodePath = ^"AttackPivot/Attack"
@export var attack_hitbox_path: NodePath = ^"AttackPivot/Attack/CollisionShape2D"
@export var body_collider_path: NodePath = ^"CollisionShape2D"
@export var hurtbox_collider_path: NodePath = ^"HurtBox/CollisionShape2D"
@export var heal_skill_path: NodePath = ^"HealSkill"
@export var slash_skill_path: NodePath = ^"SkillSlash"
@export var secondary_sprite_texture: Texture2D

@export var walk_speed: float = SPEED_WALK
@export var run_speed: float = SPEED_NORMAL
@export var jump_velocity: float = JUMP_VELOCITY
@export var slide_speed: float = SLIDE_SPEED
@export var slide_duration: float = SLIDE_DURATION
@export var slide_distance: float = SLIDE_SPEED * SLIDE_DURATION
@export var slide_cooldown: float = 0.6
@export var slide_power_cost: float = 20.0
@export var slide_collider_height: float = 24.0
@export var slide_hurtbox_height: float = 20.0
@export var hide_body_after_death: float = 1.2
@export var ground_acceleration: float = 1400.0
@export var ground_turn_acceleration: float = 3000.0
@export var ground_deceleration: float = 3000.0
@export var air_acceleration: float = 1000.0
@export var attack_buffer_time: float = ATTACK_BUFFER_TIME
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var wall_jump_input_lock: float = 0.10
@export var wall_jump_horizontal_velocity: float = WALL_JUMP_X
@export var wall_jump_vertical_velocity: float = WALL_JUMP_Y
@export var wall_slide_max_speed: float = WALL_SLIDE_MAX_SPEED
@export var crouch_collider_height: float = 28.0
@export var crouch_hurtbox_height: float = 22.0
@export var climb_speed: float = 120.0
@export var ladder_snap_speed: float = 480.0
@export var land_visual_duration: float = 0.18
@export var block_power_cost: float = 15.0
@export_range(0.1, 0.9, 0.05) var jump_release_ratio: float = 0.5

var input_enabled: bool = true
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var is_sliding: bool = false
var is_using_skill: bool = false
var is_crouching: bool = false
var is_blocking: bool = false
var is_climbing: bool = false
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
var _slide_target_x: float = 0.0
var _slide_direction: int = 1
var _combo_timer: float = 0.0
var _attack_buffer_timer: float = 0.0
var _attack_startup_timer: float = 0.0
var _attack_active_timer: float = 0.0
var _attack_window_active: bool = false
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _wall_jump_lock_timer: float = 0.0
var _land_visual_timer: float = 0.0
var _normal_layer: int = 0
var _normal_mask: int = 0
var _sprite_base_modulate: Color = Color.WHITE
var _primary_sprite_texture: Texture2D
var _death_hide_scheduled: bool = false
var _pending_skill_effect: Callable
var _skill_effect_applied: bool = false
var _active_ladder: Area2D
var _standing_collider_height: float = 0.0
var _standing_collider_position: Vector2 = Vector2.ZERO
var _standing_hurtbox_height: float = 0.0
var _standing_hurtbox_position: Vector2 = Vector2.ZERO

@onready var _sprite: Node2D = get_node_or_null(sprite_path)
@onready var _anim: AnimationPlayer = get_node_or_null(animation_player_path)
@onready var _character: Character = get_node_or_null(character_path)
@onready var _physics_check: PhysicsCheck = get_node_or_null(physics_check_path)
@onready var _attack_root: Node2D = get_node_or_null(attack_root_path)
@onready var _attack_area := get_node_or_null(attack_area_path)
@onready var _attack_hitbox := get_node_or_null(attack_hitbox_path)
@onready var _body_collider: CollisionShape2D = get_node_or_null(body_collider_path) as CollisionShape2D
@onready var _hurtbox_collider: CollisionShape2D = \
		get_node_or_null(hurtbox_collider_path) as CollisionShape2D
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
	_prepare_body_collider()
	_prepare_hurtbox_collider()
	_prepare_attack_hitbox()
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
	if is_using_skill:
		if not is_on_floor():
			velocity.y += _gravity() * delta
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
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
	var vertical_dir := _read_vertical_input()
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = coyote_time

	_update_ground_stances(on_floor, vertical_dir)
	if _active_ladder != null and (is_climbing or absf(vertical_dir) > 0.05):
		_set_crouching(false, true)
		is_blocking = false
		is_climbing = true
		if _read_jump_pressed():
			_leave_ladder_with_jump()
		else:
			_tick_ladder_climb(vertical_dir, delta)
		return
	if is_climbing:
		_stop_climbing()

	var jump_pressed := _read_jump_pressed()
	if jump_pressed and is_blocking:
		is_blocking = false
	if jump_pressed and is_crouching:
		_set_crouching(false)
	if jump_pressed and not is_crouching:
		_jump_buffer_timer = jump_buffer_time

	# 重力
	if not on_floor:
		velocity.y += _gravity() * delta

	# 蹬墙跳判定
	var touching_wall := not on_floor and (_physics_check != null) \
			and (_physics_check.touch_left or _physics_check.touch_right)
	var wall_sliding := _should_wall_slide(
		move_dir,
		on_floor,
		_physics_check != null and _physics_check.touch_left,
		_physics_check != null and _physics_check.touch_right)
	is_on_wall_grab = wall_sliding
	if wall_sliding:
		velocity.y = minf(velocity.y, wall_slide_max_speed)
		_facing = 1 if _physics_check.touch_left else -1

	# 跳跃缓冲：落地前的输入会保留到下一次可跳时刻。
	if _jump_buffer_timer > 0.0:
		if on_floor or _coyote_timer > 0.0:
			velocity.y = jump_velocity
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
			GameEvents.raise_play_sfx(&"jump", global_position)
		elif touching_wall:
			velocity.y = wall_jump_vertical_velocity
			velocity.x = wall_jump_horizontal_velocity * (1 if _physics_check.touch_left else -1)
			_facing = sign(velocity.x)
			_wall_jump_lock_timer = wall_jump_input_lock
			_jump_buffer_timer = 0.0
			GameEvents.raise_play_sfx(&"jump", global_position)

	# 松开跳跃时截断上升速度，形成短按轻跳 / 长按高跳。
	if _read_jump_released():
		_apply_jump_release()

	# 攻击输入在当前动作中会缓存一段时间，动画结束后直接衔接下一段。
	if _read_attack_pressed() and not is_hurt and not is_crouching and not is_blocking:
		if is_attacking:
			_queue_attack()
		else:
			_begin_attack()

	# 滑铲
	if _read_slide_pressed() and on_floor and not is_attacking and not is_hurt \
			and not is_crouching and not is_blocking and can_dash():
		if _begin_slide(move_dir):
			_tick_slide(delta)
			return

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
	elif is_crouching or is_blocking:
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
	var now_on_floor := is_on_floor()
	if not on_floor and now_on_floor:
		_land_visual_timer = land_visual_duration
	_update_animation(move_dir, now_on_floor, wall_sliding and not now_on_floor)


# ---------------------------------------------------------------------------
# 输入读取（含自动化覆盖）
# ---------------------------------------------------------------------------

func _read_move_input() -> float:
	if not input_enabled:
		return 0.0
	if ai_active:
		return ai_move_x
	return Input.get_axis(&"move_left", &"move_right")


func _read_vertical_input() -> float:
	if not input_enabled or ai_active:
		return 0.0
	return Input.get_axis(&"move_up", &"move_down")


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
		_end_slide()
		_cancel_skill_action()
		_reset_extended_action_states()
		_attack_buffer_timer = 0.0
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_wall_jump_lock_timer = 0.0
		_set_attack_hitbox_active(false)


func _prepare_body_collider() -> void:
	if _body_collider == null or not (_body_collider.shape is CapsuleShape2D):
		return
	_body_collider.shape = _body_collider.shape.duplicate()
	var capsule := _body_collider.shape as CapsuleShape2D
	_standing_collider_height = capsule.height
	_standing_collider_position = _body_collider.position


func _prepare_hurtbox_collider() -> void:
	if _hurtbox_collider == null or not (_hurtbox_collider.shape is CapsuleShape2D):
		return
	_hurtbox_collider.shape = _hurtbox_collider.shape.duplicate()
	var capsule := _hurtbox_collider.shape as CapsuleShape2D
	_standing_hurtbox_height = capsule.height
	_standing_hurtbox_position = _hurtbox_collider.position


func _prepare_attack_hitbox() -> void:
	if _attack_hitbox == null or not (_attack_hitbox is CollisionShape2D):
		return
	var hitbox := _attack_hitbox as CollisionShape2D
	if hitbox.shape != null:
		hitbox.shape = hitbox.shape.duplicate()


func _update_ground_stances(on_floor: bool, vertical_dir: float) -> void:
	var can_enter_stance := input_enabled and on_floor and not is_attacking and not is_hurt \
			and not is_sliding and not is_using_skill and not is_climbing
	var wants_block := can_enter_stance and Input.is_action_pressed(&"block")
	if wants_block and is_crouching:
		_set_crouching(false)
	is_blocking = wants_block and not is_crouching

	var ladder_input := _active_ladder != null and absf(vertical_dir) > 0.05
	var wants_crouch := can_enter_stance and not is_blocking and not ladder_input \
			and Input.is_action_pressed(&"move_down")
	if wants_crouch:
		_set_crouching(true)
	elif is_crouching:
		_set_crouching(false, not on_floor)


func _set_crouching(active: bool, force: bool = false) -> bool:
	if is_crouching == active:
		return true
	if not active and not force and not _can_stand_up():
		return false
	is_crouching = active
	if _body_collider == null or not (_body_collider.shape is CapsuleShape2D):
		return true
	if active:
		_set_body_collider_height(crouch_collider_height)
	else:
		_set_body_collider_height(_standing_collider_height)
	_sync_hurtbox_stance(active)
	return true


func _sync_hurtbox_stance(crouching: bool) -> void:
	if crouching:
		_set_hurtbox_collider_height(crouch_hurtbox_height)
	else:
		_set_hurtbox_collider_height(_standing_hurtbox_height)


func _set_body_collider_height(requested_height: float) -> void:
	if _body_collider == null or not (_body_collider.shape is CapsuleShape2D):
		return
	var capsule := _body_collider.shape as CapsuleShape2D
	var safe_height := maxf(requested_height, capsule.radius * 2.0)
	capsule.height = safe_height
	_body_collider.position = _standing_collider_position \
			+ Vector2.DOWN * ((_standing_collider_height - safe_height) * 0.5)


func _set_hurtbox_collider_height(requested_height: float) -> void:
	if _hurtbox_collider == null or not (_hurtbox_collider.shape is CapsuleShape2D):
		return
	var capsule := _hurtbox_collider.shape as CapsuleShape2D
	var safe_height := maxf(requested_height, capsule.radius * 2.0)
	capsule.height = safe_height
	_hurtbox_collider.position = _standing_hurtbox_position \
			+ Vector2.DOWN * ((_standing_hurtbox_height - safe_height) * 0.5)


func _set_slide_colliders(active: bool) -> void:
	_set_body_collider_height(slide_collider_height if active else _standing_collider_height)
	_set_hurtbox_collider_height(slide_hurtbox_height if active else _standing_hurtbox_height)


func _can_stand_up() -> bool:
	if _body_collider == null or _standing_collider_height <= 0.0 or get_world_2d() == null:
		return true
	var current_capsule := _body_collider.shape as CapsuleShape2D
	if current_capsule == null:
		return true
	var standing_shape := CapsuleShape2D.new()
	standing_shape.radius = current_capsule.radius
	standing_shape.height = _standing_collider_height
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = standing_shape
	var standing_transform := global_transform
	standing_transform.origin = to_global(_standing_collider_position)
	query.transform = standing_transform
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func enter_ladder(ladder: Area2D) -> void:
	_active_ladder = ladder


func exit_ladder(ladder: Area2D) -> void:
	if ladder != _active_ladder:
		return
	_active_ladder = null
	_stop_climbing()


func _tick_ladder_climb(vertical_dir: float, delta: float) -> void:
	if _active_ladder == null:
		_stop_climbing()
		return
	velocity.x = 0.0
	velocity.y = vertical_dir * climb_speed
	global_position.x = move_toward(
		global_position.x,
		_active_ladder.global_position.x,
		ladder_snap_speed * delta)
	move_and_slide()
	_update_animation(0.0, false, false)


func _leave_ladder_with_jump() -> void:
	_stop_climbing()
	velocity.y = jump_velocity
	velocity.x = float(_facing) * wall_jump_horizontal_velocity * 0.5
	GameEvents.raise_play_sfx(&"jump", global_position)
	move_and_slide()
	_update_animation(0.0, false, false)


func _stop_climbing() -> void:
	is_climbing = false
	if _anim != null:
		_anim.speed_scale = 1.0


func _reset_extended_action_states() -> void:
	is_blocking = false
	_stop_climbing()
	_set_crouching(false, true)
	_land_visual_timer = 0.0


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
	_configure_combo_hitbox(combo_index)
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


func _configure_combo_hitbox(attack_index: int) -> void:
	if _attack_hitbox == null or not (_attack_hitbox is CollisionShape2D):
		return
	if attack_index <= 0 or attack_index >= ATTACK_HITBOX_SIZES.size():
		return
	var hitbox := _attack_hitbox as CollisionShape2D
	var rectangle := hitbox.shape as RectangleShape2D
	if rectangle == null:
		return
	rectangle.size = ATTACK_HITBOX_SIZES[attack_index]
	hitbox.position = ATTACK_HITBOX_OFFSETS[attack_index]


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


func can_begin_skill_slash() -> bool:
	return input_enabled and not is_dead and not is_hurt and not is_attacking \
			and not is_sliding and not is_using_skill and not is_crouching \
			and not is_blocking and not is_climbing


func can_begin_heal() -> bool:
	return can_begin_skill_slash()


func begin_skill_slash(effect: Callable) -> bool:
	if not can_begin_skill_slash():
		return false
	return _begin_skill_action(&"skill_slash", &"skill_slash", effect)


func begin_heal(effect: Callable) -> bool:
	if not can_begin_heal():
		return false
	return _begin_skill_action(&"heal", &"heal", effect)


func _begin_skill_action(animation_name: StringName, sfx_id: StringName, effect: Callable) -> bool:
	is_using_skill = true
	velocity.x = 0.0
	_pending_skill_effect = effect
	_skill_effect_applied = false
	GameEvents.raise_play_sfx(sfx_id, global_position)
	if _anim != null and _anim.has_animation(animation_name):
		_anim.play(animation_name)
	else:
		_apply_pending_skill_effect()
		_cancel_skill_action()
	return true


func on_skill_slash_active() -> void:
	if _slash_skill != null and _slash_skill.has_method("set_preview_active"):
		_slash_skill.call("set_preview_active")
	_apply_pending_skill_effect()


func on_heal_active() -> void:
	_apply_pending_skill_effect()


func _apply_pending_skill_effect() -> void:
	if not is_using_skill or _skill_effect_applied:
		return
	_skill_effect_applied = true
	if _pending_skill_effect.is_valid():
		_pending_skill_effect.call()


func on_skill_slash_animation_finished() -> void:
	if not is_using_skill:
		return
	_cancel_skill_action()


func on_heal_animation_finished() -> void:
	if not is_using_skill:
		return
	_cancel_skill_action()


func get_facing_direction() -> int:
	return _facing


func _cancel_skill_action() -> void:
	is_using_skill = false
	_skill_effect_applied = false
	_pending_skill_effect = Callable()
	if _slash_skill != null and _slash_skill.has_method("cancel_preview"):
		_slash_skill.call("cancel_preview")


func take_damage(by: Node, amount: float = 1.0) -> void:
	if _character == null:
		return
	if _can_block_attack(by) and _character.consume_power(block_power_cost):
		GameEvents.raise_play_sfx(&"block", global_position)
		GameEvents.raise_combat_hit_feedback(0.45, 0.02, global_position)
		return
	if is_blocking and _character.current_power < block_power_cost:
		is_blocking = false
	_character.take_damage(by, amount)


func _can_block_attack(by: Node) -> bool:
	if not is_blocking or not (by is Node2D):
		return false
	if by.has_method("bypasses_block") and bool(by.call("bypasses_block")):
		return false
	var direction := signf((by as Node2D).global_position.x - global_position.x)
	return is_zero_approx(direction) or int(direction) == _facing


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
	_end_slide()
	_cancel_skill_action()
	_reset_extended_action_states()
	combo_index = 0
	_attack_buffer_timer = 0.0
	_attack_startup_timer = 0.0
	_attack_active_timer = 0.0
	_attack_window_active = false
	_set_attack_hitbox_active(false)
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
	_end_slide()
	is_hurt = false
	_cancel_skill_action()
	_reset_extended_action_states()
	_attack_buffer_timer = 0.0
	input_enabled = false
	_set_attack_hitbox_active(false)
	_set_body_collision_enabled(false)
	_set_hurtbox_enabled(false)
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
	_end_slide()
	_cancel_skill_action()
	_reset_extended_action_states()
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
	_set_hurtbox_enabled(true)
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
	_end_slide()
	_cancel_skill_action()
	_reset_extended_action_states()
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
	_set_hurtbox_enabled(true)
	_disable_interaction_probe(false)
	_reset_sprite_modulate()
	if _character != null:
		_character.reset_to_full()


# ---------------------------------------------------------------------------
# 滑铲
# ---------------------------------------------------------------------------

func _begin_slide(move_dir: float) -> bool:
	if is_sliding or is_dead or is_hurt or is_attacking or is_using_skill:
		return false
	if _character != null and not _character.consume_power(slide_power_cost):
		return false
	is_sliding = true
	_slide_cooldown_timer = slide_cooldown
	if move_dir != 0.0:
		_facing = int(sign(move_dir))
	_slide_direction = _facing
	_slide_target_x = global_position.x + float(_slide_direction) * maxf(0.0, slide_distance)
	var travel_duration := maxf(0.0, slide_distance) / maxf(slide_speed, 0.001)
	_slide_timer = maxf(slide_duration, travel_duration + 0.05)
	velocity.x = float(_slide_direction) * slide_speed
	_set_slide_colliders(true)
	# Temporarily ignore enemy attack / hazard layers during the early slide frames.
	collision_mask &= ~(1 << 4)
	collision_mask &= ~(1 << 6)
	if _character != null:
		_character.set_invulnerable_for(slide_duration * 0.6)
	GameEvents.raise_play_sfx(&"slide", global_position)
	if _anim != null and _anim.has_animation("slide"):
		_anim.play("slide")
	return true


func _tick_slide(delta: float) -> void:
	_slide_timer -= delta
	var remaining_distance := absf(_slide_target_x - global_position.x)
	velocity.x = float(_slide_direction) * minf(
		slide_speed,
		remaining_distance / maxf(delta, 0.0001))
	var was_on_floor := is_on_floor()
	velocity.y += _gravity() * delta
	move_and_slide()
	var reached_target := float(_slide_direction) * (global_position.x - _slide_target_x) >= -0.5
	if _slide_timer <= 0.0 or not was_on_floor or not is_on_floor() \
			or _has_horizontal_slide_collision() or reached_target:
		_end_slide()


func _has_horizontal_slide_collision() -> bool:
	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		if collision != null and absf(collision.get_normal().x) >= 0.7:
			return true
	return false


func _end_slide() -> void:
	is_sliding = false
	_slide_timer = 0.0
	velocity.x = 0.0
	_restore_normal_collision()
	_set_slide_colliders(false)


func can_dash() -> bool:
	return _slide_cooldown_timer <= 0.0


func _tick_dash_cooldown(delta: float) -> void:
	_slide_cooldown_timer = maxf(0.0, _slide_cooldown_timer - delta)


func _tick_movement_windows(delta: float) -> void:
	_coyote_timer = maxf(0.0, _coyote_timer - delta)
	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
	_wall_jump_lock_timer = maxf(0.0, _wall_jump_lock_timer - delta)
	_attack_buffer_timer = maxf(0.0, _attack_buffer_timer - delta)
	_land_visual_timer = maxf(0.0, _land_visual_timer - delta)


func _apply_jump_release() -> void:
	if velocity.y < jump_velocity * jump_release_ratio:
		velocity.y = jump_velocity * jump_release_ratio


func _should_wall_slide(
		move_dir: float,
		on_floor: bool,
		touch_left: bool,
		touch_right: bool) -> bool:
	if on_floor or velocity.y <= 0.0:
		return false
	return (touch_left and move_dir < 0.0) or (touch_right and move_dir > 0.0)


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


func _set_hurtbox_enabled(enabled: bool) -> void:
	var hurtbox := get_node_or_null(^"HurtBox") as HurtBox
	if hurtbox == null:
		return
	hurtbox.monitorable = enabled
	if _hurtbox_collider != null:
		_hurtbox_collider.set_deferred("disabled", not enabled)


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
	if _anim == null or is_attacking or is_hurt or is_dead or is_sliding or is_using_skill:
		return
	if is_climbing:
		_play_if_present("climb")
		_anim.speed_scale = 0.0 if is_zero_approx(velocity.y) else 1.0
		return
	_anim.speed_scale = 1.0
	if is_blocking:
		_play_if_present("block")
	elif is_crouching:
		_play_if_present("crouch")
	elif grabbing_wall:
		_play_if_present("wall")
	elif not on_floor:
		_play_if_present("jump" if velocity.y < 0.0 else "fall")
	elif _land_visual_timer > 0.0 and absf(move_dir) <= 0.05:
		_play_if_present("land")
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
