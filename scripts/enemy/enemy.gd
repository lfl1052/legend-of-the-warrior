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
@export var requires_line_of_sight: bool = true
@export var line_of_sight_mask: int = (1 << 0) | (1 << 1)
@export var sight_origin_offset: Vector2 = Vector2(0.0, -12.0)
@export var sight_target_offset: Vector2 = Vector2(0.0, -12.0)
@export var uses_gravity: bool = true
@export var chase_acceleration: float = 720.0

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
var _perception_shape: CircleShape2D
var _perception_query: PhysicsShapeQueryParameters2D


func _ready() -> void:
	super._ready()
	spawn_point = global_position
	current_speed = normal_speed
	_setup_perception_query()
	_setup_states()
	switch_state(Enums.NPCState.PATROL)


func _process(delta: float) -> void:
	if is_dead:
		return
	_update_target_tracking(delta)
	if _active_state != null:
		_active_state.logic_update(delta)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead or is_hurt:
		return
	if uses_gravity and not is_on_floor():
		velocity.y += _gravity() * delta
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
	if _perception_query == null or _perception_shape == null:
		_setup_perception_query()
	_perception_shape.radius = check_distance
	_perception_query.transform = Transform2D(0.0, global_position)
	_perception_query.collision_mask = attack_layer_mask
	for hit: Dictionary in space.intersect_shape(_perception_query, 8):
		var candidate := hit.get("collider") as Node2D
		if _is_target_detectable(candidate):
			attacker = candidate
			lost_time_counter = lost_time
			return true
	return false


func _setup_perception_query() -> void:
	_perception_shape = CircleShape2D.new()
	_perception_shape.radius = check_distance
	_perception_query = PhysicsShapeQueryParameters2D.new()
	_perception_query.shape = _perception_shape
	_perception_query.collide_with_areas = false
	_perception_query.collide_with_bodies = true
	_perception_query.exclude = [get_rid()]


func _update_target_tracking(delta: float) -> void:
	if current_state != Enums.NPCState.CHASE or attacker == null:
		return
	var target := attacker as Node2D
	if not is_instance_valid(target):
		_clear_target()
		return
	if _is_target_detectable(target):
		lost_time_counter = lost_time
		return
	lost_time_counter = maxf(0.0, lost_time_counter - delta)
	if lost_time_counter <= 0.0:
		_clear_target()


func _is_target_detectable(target: Node2D) -> bool:
	if target == null or not target.is_in_group(&"player"):
		return false
	if global_position.distance_squared_to(target.global_position) > check_distance * check_distance:
		return false
	return can_see_target(target)


func _clear_target() -> void:
	attacker = null
	lost_time_counter = 0.0


func can_see_target(target: Node2D) -> bool:
	if target == null:
		return false
	if not requires_line_of_sight:
		return true
	var space := get_world_2d().direct_space_state
	if space == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(
		global_position + sight_origin_offset,
		target.global_position + sight_target_offset,
		line_of_sight_mask)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == target


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
