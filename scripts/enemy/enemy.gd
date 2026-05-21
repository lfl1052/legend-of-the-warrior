class_name Enemy
extends EnemyCombatant
## 敌人主控（替代 Unity 项目里的 Enemy / EnemyMinion）
##
## 维护一个简单状态机（Patrol / Chase / Skill），状态对象继承自 BaseState。
## 子类（Bee/Boar/Snail 等）在 _ready 之前装配 patrol/chase/skill_state。
##
## 期望节点结构：
##   Visual/PatrolPoint     Node2D（用于巡逻范围/朝向参考）
##   PhysicsCheck           PhysicsCheck（脚下/左右）

signal state_changed(new_state: int)

@export var normal_speed: float = 80.0
@export var chase_speed: float = 160.0
@export var lost_time: float = 1.5
@export var check_distance: float = 4.5
@export var attack_layer_mask: int = 1 << 1            # Player 层

@export_node_path("PhysicsCheck") var physics_check_path: NodePath = ^"PhysicsCheck"

@onready var physics_check: PhysicsCheck = get_node_or_null(physics_check_path) as PhysicsCheck

var current_speed: float = 0.0
var current_state: int = Enums.NPCState.PATROL
var lost_time_counter: float = 0.0
var spawn_point: Vector2 = Vector2.ZERO

var rb: CharacterBody2D :
	get: return self

var patrol_state: BaseState
var chase_state: BaseState
var skill_state: BaseState

var _active_state: BaseState


func _ready() -> void:
	super._ready()
	spawn_point = global_position
	current_speed = normal_speed
	_setup_states()
	switch_state(Enums.NPCState.PATROL)


func _process(delta: float) -> void:
	if is_dead:
		return
	if _active_state != null:
		_active_state.logic_update(delta)
	# 失去目标计数
	if attacker != null:
		lost_time_counter -= delta
		if lost_time_counter <= 0.0:
			attacker = null


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead or is_hurt:
		return
	if _active_state != null:
		_active_state.physics_update(delta)
	move_and_slide()


# ----- 状态机 ------------------------------------------------------------------

func _setup_states() -> void:
	# 子类负责实例化并赋值；这里默认空状态
	pass


func switch_state(new_state: int) -> void:
	current_state = new_state
	var next: BaseState = null
	match new_state:
		Enums.NPCState.PATROL: next = patrol_state
		Enums.NPCState.CHASE: next = chase_state
		Enums.NPCState.SKILL: next = skill_state
	if _active_state != null:
		_active_state.on_exit()
	_active_state = next
	if _active_state != null:
		_active_state.on_enter(self)
	state_changed.emit(new_state)


# ----- 玩家发现（默认实现：Overlap 圆形） --------------------------------------

func found_player() -> bool:
	var space := get_world_2d().direct_space_state
	if space == null:
		return false
	var shape := CircleShape2D.new()
	shape.radius = check_distance
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = attack_layer_mask
	query.collide_with_bodies = true
	for hit in space.intersect_shape(query, 4):
		var node: Node = hit.get("collider")
		if node != null and node.is_in_group(&"player"):
			attacker = node
			lost_time_counter = lost_time
			return true
	return false


# ----- 巡逻点接口（子类覆写） --------------------------------------------------

func get_new_patrol_point() -> Vector2:
	return spawn_point


# ----- 朝向 -------------------------------------------------------------------

func face_direction(dir_x: float) -> void:
	if dir_x == 0.0 or visual_root == null:
		return
	var s := visual_root.scale
	s.x = absf(s.x) * (-1.0 if dir_x > 0.0 else 1.0)
	visual_root.scale = s
