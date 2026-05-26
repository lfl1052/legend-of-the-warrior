extends Node2D

const LEVEL_CHECKS := {
	"res://scenes/levels/level_2.tscn": {
		"name": "level_2",
		"surface_y": 512.0,
		"required_nodes": [
			"Player",
			"Player/Sign",
			"SnailA",
			"BeeA",
			"BossEnemy",
			"ChestA",
			"BreakableRockA",
			"SavePoint",
			"TeleportToDemo",
			"Camera2D",
			"UI/HUD/PlayerStatBar",
			"UI/HUD/RewardNotification",
		],
		"min_enemy_count": 3,
	},
	"res://scenes/levels/level_demo.tscn": {
		"name": "level_demo",
		"surface_y": 512.0,
		"required_nodes": [
			"Player",
			"Player/Sign",
			"Snail",
			"Bee",
			"ChestA",
			"BreakableRockA",
			"SavePoint",
			"TeleportToMenu",
			"Camera2D",
			"UI/HUD/PlayerStatBar",
			"UI/HUD/RewardNotification",
		],
		"min_enemy_count": 2,
	},
}

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for level_path in LEVEL_CHECKS.keys():
		await _check_level(level_path, LEVEL_CHECKS[level_path])
	_finish()


func _check_level(level_path: String, check: Dictionary) -> void:
	var level_name := String(check["name"])
	var packed := load(level_path) as PackedScene
	_assert(packed != null, "%s packed scene loads" % level_name)
	if packed == null:
		return
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	for node_path in check["required_nodes"]:
		_assert(scene.get_node_or_null(node_path) != null, "%s has %s" % [level_name, node_path])
	var chest := scene.get_node_or_null("ChestA")
	_assert(chest != null and chest.is_in_group(&"interactable"), "%s chest is interactable" % level_name)
	var breakable := scene.get_node_or_null("BreakableRockA")
	_assert(breakable != null and breakable.is_in_group(&"damageable"), "%s breakable can be damaged" % level_name)
	var surface_y := float(check["surface_y"])
	_assert(_is_on_surface(scene, "ChestA", surface_y), "%s chest sits on generated ground" % level_name)
	_assert(_is_on_surface(scene, "BreakableRockA", surface_y), "%s breakable sits on generated ground" % level_name)
	_assert(_background_trees_clear_surface(scene, surface_y), "%s background trees do not sink below ground" % level_name)
	_assert(_count_nodes_in_group(scene, &"player") >= 1, "%s registers a player" % level_name)
	_assert(_count_nodes_in_group(scene, &"enemy") >= int(check["min_enemy_count"]), "%s registers enemies" % level_name)
	scene.queue_free()
	await get_tree().process_frame


func _count_nodes_in_group(root: Node, group_name: StringName) -> int:
	var count := 1 if root.is_in_group(group_name) else 0
	for child in root.get_children():
		count += _count_nodes_in_group(child, group_name)
	return count


func _is_on_surface(scene: Node, node_path: String, surface_y: float) -> bool:
	var node := scene.get_node_or_null(node_path) as Node2D
	if node == null:
		return false
	return absf(node.global_position.y - surface_y) <= 0.5


func _background_trees_clear_surface(scene: Node, surface_y: float) -> bool:
	var visuals := scene.get_node_or_null("MapVisuals")
	if visuals == null:
		return true
	for child in visuals.get_children():
		var sprite := child as Sprite2D
		if sprite == null or not child.name.begins_with("BackgroundTree"):
			continue
		if _sprite_bottom_y(sprite) > surface_y + 0.5:
			return false
	return true


func _sprite_bottom_y(sprite: Sprite2D) -> float:
	if sprite.texture == null:
		return sprite.global_position.y
	var rect := sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, sprite.texture.get_size())
	var local_bottom := rect.size.y * (0.5 if sprite.centered else 1.0)
	return sprite.global_position.y + absf(sprite.global_scale.y) * local_bottom


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("[level_2_load] PASS: %s" % message)
	else:
		_failed = true
		push_error("[level_2_load] FAIL: %s" % message)


func _finish() -> void:
	print("[level_2_load] result: %s" % ("FAIL" if _failed else "PASS"))
	get_tree().quit(1 if _failed else 0)
