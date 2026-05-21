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

const SPEED_NORMAL := 380.0
const SPEED_WALK := 160.0
const JUMP_VELOCITY := -600.0
const WALL_JUMP_X := 380.0
const WALL_JUMP_Y := -560.0
const SLIDE_SPEED := 540.0
const SLIDE_DURATION := 0.42
const COMBO_RESET := 0.55
const HURT_KNOCKBACK := 220.0

@export var sprite_path: NodePath = ^"Sprite"
@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var character_path: NodePath = ^"Character"
@export var physics_check_path: NodePath = ^"PhysicsCheck"
@export var attack_root_path: NodePath = ^"AttackPivot"
@export var heal_skill_path: NodePath = ^"HealSkill"
@export var slash_skill_path: NodePath = ^"SkillSlash"

@export var walk_speed: float = SPEED_WALK
@export var run_speed: float = SPEED_NORMAL
@export var jump_velocity: float = JUMP_VELOCITY
@export var slide_speed: float = SLIDE_SPEED
@export var slide_duration: float = SLIDE_DURATION

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
var ai_active: bool = false

var _facing: int = 1
var _slide_timer: float = 0.0
var _combo_timer: float = 0.0
var _normal_layer: int = 0
var _normal_mask: int = 0

@onready var _sprite: Node2D = get_node_or_null(sprite_path)
@onready var _anim: AnimationPlayer = get_node_or_null(animation_player_path)
@onready var _character: Character = get_node_or_null(character_path)
@onready var _physics_check: PhysicsCheck = get_node_or_null(physics_check_path)
@onready var _attack_root: Node2D = get_node_or_null(attack_root_path)
@onready var _heal_skill: Node = get_node_or_null(heal_skill_path)
@onready var _slash_skill: Node = get_node_or_null(slash_skill_path)


func _ready() -> void:
	add_to_group(&"player")
	_normal_layer = collision_layer
	_normal_mask = collision_mask
	if _character != null:
		_character.died.connect(_on_died)
		_character.took_damage.connect(_on_took_damage)
	GameEvents.new_game_started.connect(prepare_for_new_game_session)
	DataManager.register(self)


func _exit_tree() -> void:
	DataManager.unregister(self)


# ---------------------------------------------------------------------------
# 主物理循环
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0
		velocity.y += _gravity() * delta
		move_and_slide()
		return

	_combo_timer = maxf(0.0, _combo_timer - delta)
	if _combo_timer == 0.0:
		combo_index = 0

	if is_sliding:
		_tick_slide(delta)
		return

	var move_dir := _read_move_input()
	var on_floor := is_on_floor()

	# 重力
	if not on_floor:
		velocity.y += _gravity() * delta

	# 蹬墙跳判定
	var grabbing_wall := not on_floor and (_physics_check != null) \
			and (_physics_check.touch_left or _physics_check.touch_right)
	is_on_wall_grab = grabbing_wall

	# 跳跃
	if _read_jump_pressed():
		if on_floor:
			velocity.y = jump_velocity
		elif grabbing_wall:
			velocity.y = WALL_JUMP_Y
			velocity.x = WALL_JUMP_X * (1 if _physics_check.touch_left else -1)
			_facing = sign(velocity.x)

	# 攻击
	if _read_attack_pressed() and not is_hurt and not is_attacking:
		_begin_attack()

	# 滑铲
	if Input.is_action_just_pressed(&"slide") and on_floor and not is_attacking and not is_hurt:
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
	else:
		var speed := walk_speed if is_walking else run_speed
		velocity.x = move_dir * speed
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


func _read_attack_pressed() -> bool:
	if not input_enabled:
		return false
	if ai_active and ai_attack:
		ai_attack = false
		return true
	return Input.is_action_just_pressed(&"attack")


func set_gameplay_input_active(active: bool) -> void:
	input_enabled = active
	if not active:
		velocity = Vector2.ZERO


# ---------------------------------------------------------------------------
# 战斗
# ---------------------------------------------------------------------------

func _begin_attack() -> void:
	combo_index = (combo_index % 3) + 1
	_combo_timer = COMBO_RESET
	is_attacking = true
	if _anim != null:
		var anim_name := "attack%d" % combo_index
		if _anim.has_animation(anim_name):
			_anim.play(anim_name)
		else:
			# fallback: 单一 attack 动画
			if _anim.has_animation("attack"):
				_anim.play("attack")


func on_attack_animation_finished() -> void:
	is_attacking = false


func on_hurt_animation_finished() -> void:
	is_hurt = false


func _on_took_damage(attacker: Node) -> void:
	if is_dead:
		return
	is_hurt = true
	is_attacking = false
	is_sliding = false
	_restore_normal_collision()
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
	velocity = Vector2.ZERO
	if _anim != null and _anim.has_animation("dead"):
		_anim.play("dead")
	GameEvents.raise_game_over()


func revive_at(pos: Vector2) -> void:
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_sliding = false
	global_position = pos
	if _character != null:
		_character.reset_to_full()


func prepare_for_new_game_session() -> void:
	combo_index = 0
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_sliding = false
	if _character != null:
		_character.reset_to_full()


# ---------------------------------------------------------------------------
# 滑铲
# ---------------------------------------------------------------------------

func _begin_slide(move_dir: float) -> void:
	is_sliding = true
	_slide_timer = slide_duration
	if move_dir != 0.0:
		_facing = int(sign(move_dir))
	velocity.x = _facing * slide_speed
	# 切换到 "Enemy" 物理层等价做法：临时清掉与敌方攻击层的碰撞 mask
	collision_mask &= ~(1 << 4)        # PlayerAttack 层（仅示意）
	collision_mask &= ~(1 << 6)        # Hazard 层（按项目自调整）
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
		_restore_normal_collision()


func _restore_normal_collision() -> void:
	collision_layer = _normal_layer
	collision_mask = _normal_mask


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


func automation_move(value: float) -> void:
	ai_move_x = clampf(value, -1.0, 1.0)


func automation_jump() -> void:
	ai_jump = true


func automation_attack() -> void:
	ai_attack = true


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
