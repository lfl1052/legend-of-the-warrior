class_name Snail
extends EnemyMinion
## 蜗牛（替代 Unity 项目里的 Snail.cs）
##
## 缓慢巡逻，发现玩家时缩进壳里（Skill）获得短时间无敌。

@export var attack_damage: int = 1
@export var front_sight_distance: float = 96.0
@export var rear_blind_margin: float = 10.0


func _setup_states() -> void:
	patrol_state = SnailPatrolState.new()
	skill_state = SnailSkillState.new()
	chase_state = SnailPatrolState.new()


func _on_character_damage(by: Node) -> void:
	super._on_character_damage(by)
	if not is_dead and skill_state != null:
		switch_state(Enums.NPCState.SKILL)


func found_player() -> bool:
	var player := _find_nearest_player()
	if player == null:
		return false
	var delta := player.global_position - global_position
	if absf(delta.x) > front_sight_distance:
		return false
	if absf(delta.y) > check_distance:
		return false
	var facing := _get_facing_direction()
	if delta.x * float(facing) < -rear_blind_margin:
		if attacker == player:
			attacker = null
			lost_time_counter = 0.0
		return false
	attacker = player
	lost_time_counter = lost_time
	return true


func _find_nearest_player() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance: float = INF
	for node in get_tree().get_nodes_in_group(&"player"):
		var player := node as Node2D
		if player == null:
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance < nearest_distance:
			nearest = player
			nearest_distance = distance
	return nearest


func _get_facing_direction() -> int:
	if visual_root == null:
		return 1
	return 1 if visual_root.scale.x < 0.0 else -1
