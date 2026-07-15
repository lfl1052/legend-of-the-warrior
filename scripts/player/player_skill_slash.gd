class_name PlayerSkillSlash
extends Node2D
## 技能斩（替代 Unity 项目里的 PlayerSkillSlash）
##
## 触发条件：
##   - 解锁 "skill-1" 槽位
##   - 当前能量 >= power_cost（默认 35）
## 行为：
##   在玩家朝向方向做 OverlapBox AOE 命中，对每个目标造成 damage 伤害。

@export var unlock_slot: StringName = &"skill-1"
@export var power_cost: float = 35.0
@export var damage: int = 2
@export var hit_box_size: Vector2 = Vector2(160.0, 80.0)
@export var hit_box_offset: Vector2 = Vector2(80.0, 0.0)
@export var collision_mask: int = (1 << 2) | (1 << 9) # Enemy + EnemyHurtBox
@export var preview_windup_duration: float = 0.32
@export var preview_total_duration: float = 0.64

var _preview_elapsed: float = 0.0
var _preview_facing: int = 1
var _preview_visible: bool = false
var _preview_active: bool = false


func _ready() -> void:
	set_process(false)
	show_behind_parent = true


func try_use(player: PlayerController) -> bool:
	if player == null:
		return false
	var character: Character = player.get_node_or_null(player.character_path) as Character
	if character == null or character.is_dead():
		return false

	if not _is_unlocked():
		return false
	if not player.can_begin_skill_slash():
		return false

	if not character.consume_power(power_cost):
		return false

	var began := player.begin_skill_slash(Callable(self, "_apply_aoe").bind(player))
	if began:
		_begin_preview(player.get_facing_direction())
	return began


func _process(delta: float) -> void:
	_preview_elapsed += delta
	if not _preview_active and _preview_elapsed >= preview_windup_duration:
		set_preview_active()
	if _preview_elapsed >= preview_total_duration:
		cancel_preview()


func _draw() -> void:
	if not _preview_visible:
		return
	var sweep_radius := hit_box_size.x
	var vertical_scale := hit_box_size.y / (sweep_radius * 2.0)
	var origin_x := (hit_box_offset.x - hit_box_size.x * 0.5) * float(_preview_facing)
	var start_angle := -PI * 0.5 if _preview_facing > 0 else PI * 0.5
	var end_angle := PI * 0.5 if _preview_facing > 0 else PI * 1.5
	draw_set_transform(Vector2(origin_x, hit_box_offset.y), 0.0, Vector2(1.0, vertical_scale))
	var edge := Color(0.72, 0.96, 1.0, 0.95 if _preview_active else 0.68)
	var trail := Color(0.18, 0.78, 1.0, 0.32 if _preview_active else 0.12)
	draw_arc(Vector2.ZERO, sweep_radius, start_angle, end_angle, 40, edge, 4.0, true)
	if _preview_active:
		draw_arc(Vector2.ZERO, sweep_radius * 0.82, start_angle, end_angle, 40, trail, 14.0, true)
		draw_arc(Vector2.ZERO, sweep_radius * 0.58, start_angle, end_angle, 32, trail, 18.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _begin_preview(facing: int) -> void:
	_preview_elapsed = 0.0
	_preview_facing = facing
	_preview_visible = true
	_preview_active = false
	set_process(true)
	queue_redraw()


func set_preview_active() -> void:
	if not _preview_visible:
		return
	_preview_active = true
	queue_redraw()


func cancel_preview() -> void:
	_preview_visible = false
	_preview_active = false
	set_process(false)
	queue_redraw()


func _is_unlocked() -> bool:
	var progression := PlayerProgressionResource.from_dict(RuntimeData.get_player_progression())
	return progression.has_unlock_slot(unlock_slot)


func _apply_aoe(player: PlayerController) -> void:
	var space := player.get_world_2d().direct_space_state
	if space == null:
		return
	var facing := float(player.get_facing_direction())
	var center := player.global_position + Vector2(hit_box_offset.x * facing, hit_box_offset.y)

	var box := RectangleShape2D.new()
	box.size = hit_box_size

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0.0, center)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]

	var hit_targets: Dictionary = {}
	for hit in space.intersect_shape(query, 16):
		var collider: Node = hit.get("collider")
		var receiver := _resolve_damage_receiver(collider)
		if receiver != null and receiver.has_method("take_damage") \
				and not hit_targets.has(receiver.get_instance_id()):
			hit_targets[receiver.get_instance_id()] = true
			receiver.call("take_damage", player, damage)
	if not hit_targets.is_empty():
		GameEvents.raise_combat_hit_feedback(1.4, 0.055, center)


func _resolve_damage_receiver(collider: Node) -> Node:
	if collider == null or not is_instance_valid(collider):
		return null
	if collider.has_method("get_damage_receiver"):
		return collider.call("get_damage_receiver") as Node
	if collider.get_node_or_null(^"HurtBox") is HurtBox:
		return null
	return collider
