extends Node2D

const LEVEL_CHECKS := {
	"res://scenes/levels/level_2.tscn": {
		"name": "level_2",
		"surface_y": 512.0,
		"required_nodes": [
			"Player",
			"Player/Sign",
			"DistantForest",
			"MapVisuals/BackgroundTiles",
			"MapVisuals/GeometryTiles",
			"MapVisuals/ForegroundTiles",
			"World/CameraBounds",
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
			"DistantForest",
			"MapVisuals/BackgroundTiles",
			"MapVisuals/GeometryTiles",
			"MapVisuals/ForegroundTiles",
			"Snail",
			"Bee",
			"ChestA",
			"BreakableRockA",
			"SavePoint",
			"TeleportToMenu",
			"TeleportToLevel2",
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
	await get_tree().physics_frame
	await get_tree().physics_frame
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
	_assert(_tilemap_layers_are_valid(scene), "%s uses separated TileMapLayer roles and TileSet collision" % level_name)
	_assert(scene.get_node_or_null("World/Ground") == null, "%s has no duplicate rectangle ground collider" % level_name)
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	_assert(player != null and player.is_on_floor(), "%s player stands on TileMap collision" % level_name)
	_assert(_count_nodes_in_group(scene, &"player") >= 1, "%s registers a player" % level_name)
	_assert(_count_nodes_in_group(scene, &"enemy") >= int(check["min_enemy_count"]), "%s registers enemies" % level_name)
	if level_name == "level_2":
		_assert(_level_2_encounter_order_is_valid(scene), "level_2 encounter ladder progresses left to right")
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
	var visuals := scene.get_node_or_null("DistantForest")
	if visuals == null:
		return true
	for child in visuals.get_children():
		var sprite := child as Sprite2D
		if sprite == null:
			continue
		if _sprite_bottom_y(sprite) > surface_y + 0.5:
			return false
	return true


func _tilemap_layers_are_valid(scene: Node) -> bool:
	var background := scene.get_node_or_null("MapVisuals/BackgroundTiles") as TileMapLayer
	var geometry := scene.get_node_or_null("MapVisuals/GeometryTiles") as TileMapLayer
	var foreground := scene.get_node_or_null("MapVisuals/ForegroundTiles") as TileMapLayer
	if background == null or geometry == null or foreground == null:
		return false
	if background.collision_enabled or not geometry.collision_enabled or foreground.collision_enabled:
		return false
	if geometry.get_used_rect().size.x <= 0 or geometry.tile_set == null:
		return false
	if geometry.tile_set.get_physics_layers_count() != 1:
		return false
	var atlas := geometry.tile_set.get_source(0) as TileSetAtlasSource
	if atlas == null:
		return false
	var top_tile := atlas.get_tile_data(Vector2i(1, 1), 0)
	return top_tile != null and top_tile.get_collision_polygons_count(0) == 1


func _level_2_encounter_order_is_valid(scene: Node) -> bool:
	var ordered_paths := [
		"Player",
		"ThornSproutA",
		"SnailA",
		"BeeA",
		"SporeShroomA",
		"SavePoint",
		"RootStalkerA",
		"BossEnemy",
		"ChestA",
		"TeleportToDemo",
	]
	var previous_x := -INF
	for path: String in ordered_paths:
		var node := scene.get_node_or_null(path) as Node2D
		if node == null or node.global_position.x <= previous_x:
			return false
		previous_x = node.global_position.x
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
