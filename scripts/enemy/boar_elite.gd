class_name BoarElite
extends EliteEnemy
## 野猪精英（替代 Unity 项目里的 BoarElite.cs）
##
## 与普通野猪相比：
##   - 拥有冲撞技能（BoarEliteSkillState）
##   - 有更大的索敌范围（aggro_range）和脱战范围（disengage_range）
##   - 巡逻范围用 patrol_radius 表示

@export var patrol_radius: float = 200.0
@export var aggro_range: float = 220.0
@export var disengage_range: float = 360.0

@export var skill_windup_duration: float = 0.55
@export var skill_charge_duration: float = 1.1
@export var skill_charge_speed: float = 320.0
@export var skill_recovery_duration: float = 0.65
@export var skill_cooldown: float = 5.0
@export var skill_id: StringName = &"boar_elite_charge"


func _setup_states() -> void:
	patrol_state = BoarPatrolState.new()
	chase_state = BoarChaseState.new()
	skill_state = BoarEliteSkillState.new()


func _ready() -> void:
	super._ready()
	register_skill(skill_id, skill_cooldown)


func _process(delta: float) -> void:
	super._process(delta)
	# 简单触发：在 Chase 中、冷却就绪、距离合适时进入 Skill
	if current_state == Enums.NPCState.CHASE and attacker is Node2D:
		var dist := global_position.distance_to((attacker as Node2D).global_position)
		if dist < aggro_range and trigger_skill(skill_id):
			switch_state(Enums.NPCState.SKILL)


# ----- BoarEliteSkillState 调用 ------------------------------------------------

func get_skill_windup_duration() -> float:
	return skill_windup_duration


func get_skill_charge_duration() -> float:
	return skill_charge_duration


func get_skill_charge_speed() -> float:
	return skill_charge_speed


func get_skill_recovery_duration() -> float:
	return skill_recovery_duration


# ----- 巡逻 -------------------------------------------------------------------

func get_new_patrol_point() -> Vector2:
	var ox := randf_range(-patrol_radius, patrol_radius)
	return spawn_point + Vector2(ox, 0.0)


# ----- 玩家发现：使用 aggro_range / disengage_range -----------------------------

func found_player() -> bool:
	var space := get_world_2d().direct_space_state
	if space == null:
		return false
	var radius := disengage_range if attacker != null else aggro_range
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = attack_layer_mask
	for hit in space.intersect_shape(query, 4):
		var node: Node = hit.get("collider")
		if node != null and node.is_in_group(&"player"):
			attacker = node
			lost_time_counter = lost_time
			return true
	return false
