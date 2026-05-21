class_name PlayerSkillSlash
extends Node
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
@export var collision_mask: int = 1 << 2     # Enemy 层（项目第 3 个 2D 物理层）


func try_use(player: PlayerController) -> bool:
	if player == null:
		return false
	var character: Character = player.get_node_or_null(player.character_path) as Character
	if character == null or character.is_dead():
		return false

	if not _is_unlocked():
		return false

	if not character.consume_power(power_cost):
		return false

	_apply_aoe(player)
	return true


func _is_unlocked() -> bool:
	var progression := PlayerProgressionResource.from_dict(RuntimeData.get_player_progression())
	return progression.has_unlock_slot(unlock_slot)


func _apply_aoe(player: PlayerController) -> void:
	var space := player.get_world_2d().direct_space_state
	if space == null:
		return
	var facing := signf(player.scale.x)
	if facing == 0.0:
		facing = 1.0
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

	for hit in space.intersect_shape(query, 16):
		var collider: Node = hit.get("collider")
		if collider != null and collider.has_method("take_damage"):
			collider.call("take_damage", player, damage)
