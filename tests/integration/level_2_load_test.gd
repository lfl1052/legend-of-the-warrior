extends Node2D

const TOP_MIDS_FOR_TEST := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const LEVEL_CHECKS := {
	"res://scenes/levels/level_2.tscn": {
		"name": "level_2",
		"surface_y": 512.0,
		"required_nodes": [
			"Player",
			"Player/Sign",
			"DistantForest",
			"MidForest",
			"NearForest",
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
			"MidForest",
			"NearForest",
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
	_assert(_parallax_layers_are_valid(scene), "%s uses ordered 640px Parallax2D layers" % level_name)
	_assert(_terrain_occludes_parallax(scene), "%s terrain renders in front of parallax trees" % level_name)
	_assert(_tilemap_layers_are_valid(scene), "%s uses separated TileMapLayer roles and TileSet collision" % level_name)
	_assert(scene.get_node_or_null("World/Ground") == null, "%s has no duplicate rectangle ground collider" % level_name)
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	_assert(player != null and player.is_on_floor(), "%s player stands on TileMap collision" % level_name)
	_assert(_count_nodes_in_group(scene, &"player") >= 1, "%s registers a player" % level_name)
	_assert(_count_nodes_in_group(scene, &"enemy") >= int(check["min_enemy_count"]), "%s registers enemies" % level_name)
	if level_name == "level_2":
		_assert(_level_2_encounter_order_is_valid(scene), "level_2 encounter ladder progresses left to right")
		_assert(_level_2_terrain_tiles_follow_atlas_contract(scene), "level_2 uses extended tops and connected inner corners")
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
	for layer_path in ["DistantForest", "MidForest", "NearForest"]:
		var visuals := scene.get_node_or_null(layer_path)
		if visuals == null:
			return false
		for child in visuals.get_children():
			var sprite := child as Sprite2D
			if sprite == null:
				continue
			if _sprite_bottom_y(sprite) > surface_y + 0.5:
				return false
	return true


func _parallax_layers_are_valid(scene: Node) -> bool:
	var distant := scene.get_node_or_null("DistantForest") as Parallax2D
	var middle := scene.get_node_or_null("MidForest") as Parallax2D
	var near := scene.get_node_or_null("NearForest") as Parallax2D
	if distant == null or middle == null or near == null:
		return false
	if distant.repeat_size.x != 640.0 or middle.repeat_size.x != 640.0 or near.repeat_size.x != 640.0:
		return false
	if not (distant.scroll_scale.x < middle.scroll_scale.x and middle.scroll_scale.x < near.scroll_scale.x):
		return false
	return distant.get_child_count() >= 2 and middle.get_child_count() >= 2 and near.get_child_count() >= 1


func _terrain_occludes_parallax(scene: Node) -> bool:
	var near := scene.get_node_or_null("NearForest") as CanvasItem
	var geometry := scene.get_node_or_null("MapVisuals/GeometryTiles") as CanvasItem
	if near == null or geometry == null:
		return false
	return _effective_z_index(geometry) > _effective_z_index(near)


func _effective_z_index(item: CanvasItem) -> int:
	var result := item.z_index
	var parent := item.get_parent() as CanvasItem
	while item.z_as_relative and parent != null:
		result += parent.z_index
		item = parent
		parent = item.get_parent() as CanvasItem
	return result


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
	var top_tile := atlas.get_tile_data(Vector2i(1, 0), 0)
	var side_tile := atlas.get_tile_data(Vector2i(0, 2), 0)
	var fill_tile := atlas.get_tile_data(Vector2i(2, 2), 0)
	var decor_tile := atlas.get_tile_data(Vector2i(10, 17), 0)
	return (
		top_tile != null
		and top_tile.get_collision_polygons_count(0) == 1
		and side_tile != null
		and side_tile.get_collision_polygons_count(0) == 1
		and fill_tile != null
		and fill_tile.get_collision_polygons_count(0) == 1
		and decor_tile != null
		and decor_tile.get_collision_polygons_count(0) == 0
		and geometry.tile_set.get_terrain_sets_count() == 1
		and geometry.tile_set.get_terrain_set_mode(0) == TileSet.TERRAIN_MODE_MATCH_CORNERS
		and geometry.tile_set.get_terrains_count(0) == 1
		and geometry.tile_set.get_terrain_name(0, 0) == "Forest Ground"
	)


func _level_2_terrain_tiles_follow_atlas_contract(scene: Node) -> bool:
	var background := scene.get_node_or_null("MapVisuals/BackgroundTiles") as TileMapLayer
	var geometry := scene.get_node_or_null("MapVisuals/GeometryTiles") as TileMapLayer
	if background == null or geometry == null:
		return false
	var atlas := geometry.tile_set.get_source(0) as TileSetAtlasSource
	if atlas == null:
		return false
	var top_data := atlas.get_tile_data(Vector2i(0, 0), 0)
	var ground_top := geometry.get_cell_atlas_coords(Vector2i(-110, 32))
	var platform_top := geometry.get_cell_atlas_coords(Vector2i(-126, 29))
	var platform_left_wall := geometry.get_cell_atlas_coords(Vector2i(-126, 30))
	var inner_left := geometry.get_cell_atlas_coords(Vector2i(-126, 32))
	var inner_right := geometry.get_cell_atlas_coords(Vector2i(-113, 32))
	var inner_left_source := geometry.get_cell_source_id(Vector2i(-126, 32))
	var inner_right_source := geometry.get_cell_source_id(Vector2i(-113, 32))
	return (
		background.get_used_cells().is_empty()
		and atlas.get_tile_size_in_atlas(Vector2i(0, 0)) == Vector2i(1, 2)
		and top_data != null
		and top_data.texture_origin == Vector2i(0, 8)
		and top_data.get_terrain_set() == 0
		and top_data.get_terrain() == 0
		and top_data.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER) == 0
		and ground_top in TOP_MIDS_FOR_TEST
		and platform_top == Vector2i(0, 0)
		and platform_left_wall in [Vector2i(0, 2), Vector2i(0, 3)]
		and inner_left_source == 1
		and inner_right_source == 1
		and inner_left == Vector2i(0, 0)
		and inner_right == Vector2i(1, 0)
		and geometry.get_cell_source_id(Vector2i(-126, 31)) == 0
		and geometry.get_cell_source_id(Vector2i(-127, 32)) == 0
	)


func _level_2_encounter_order_is_valid(scene: Node) -> bool:
	var ordered_paths := [
		"Player",
		"SnailA",
		"BeeA",
		"SavePoint",
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
