class_name EnemyCombatant
extends CharacterBody2D
## 敌人战斗基类（替代 Unity 项目里的 EnemyCombatant）
##
## 处理：
##   - 受击位移 / 硬直 / 死亡持久化
##   - 与 Character 节点联动（血量/能量）
##   - ISaveable，记录"此实例是否已死亡"

signal hurt_started(attacker: Node)
signal died_event

@export var hurt_force: float = 320.0
@export var hurt_recover_time: float = 0.42
@export var auto_register_save: bool = true
@export var save_id_prefix: String = "enemy"

@export_node_path("Character") var character_path: NodePath = ^"Character"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"AnimationPlayer"
@export_node_path("Node2D") var visual_root_path: NodePath = ^"Visual"

var attacker: Node = null
var is_hurt: bool = false
var is_dead: bool = false

@onready var character: Character = get_node_or_null(character_path) as Character
@onready var anim: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer
@onready var visual_root: Node2D = get_node_or_null(visual_root_path) as Node2D

var _hurt_timer: float = 0.0


func _ready() -> void:
	add_to_group(&"enemy")
	add_to_group(&"damageable")
	if character != null:
		character.took_damage.connect(_on_character_damage)
		character.died.connect(_on_character_died)
	if auto_register_save:
		DataManager.register(self)


func _exit_tree() -> void:
	if auto_register_save:
		DataManager.unregister(self)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		velocity.y += _gravity() * delta
		move_and_slide()
		return

	if is_hurt:
		_hurt_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		velocity.y += _gravity() * delta
		move_and_slide()
		if _hurt_timer <= 0.0:
			is_hurt = false


# ----- 受击外部入口 ------------------------------------------------------------

func take_damage(by: Node, amount: float = 1.0) -> void:
	if is_dead or character == null:
		return
	attacker = by
	character.take_damage(by, amount)


func _on_character_damage(by: Node) -> void:
	is_hurt = true
	_hurt_timer = hurt_recover_time
	if by is Node2D:
		var n2d := by as Node2D
		var dir := signf(global_position.x - n2d.global_position.x)
		if dir == 0.0:
			dir = -1.0
		velocity = Vector2(dir * hurt_force, -hurt_force * 0.55)
	if anim != null and anim.has_animation("hurt"):
		anim.play("hurt")
	hurt_started.emit(by)


func _on_character_died() -> void:
	is_dead = true
	is_hurt = false
	velocity = Vector2.ZERO
	if anim != null and anim.has_animation("dead"):
		anim.play("dead")
	died_event.emit()


func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/2d/default_gravity", 2000.0))


# ----- ISaveable ---------------------------------------------------------------

func get_save_id() -> String:
	return PersistenceKeyUtility.resolve_key(self, save_id_prefix)


func get_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	var floats: Dictionary = data.get("float_data", {})
	floats[key + "_dead"] = 1.0 if is_dead else 0.0
	data["float_data"] = floats


func load_save_data(data: Dictionary) -> void:
	var key := get_save_id()
	var floats: Dictionary = data.get("float_data", {})
	if floats.get(key + "_dead", 0.0) >= 0.5:
		is_dead = true
		visible = false
		set_physics_process(false)
		set_process(false)
