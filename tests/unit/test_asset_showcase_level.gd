extends GdUnitTestSuite

const SHOWCASE_LEVEL := preload("res://scenes/levels/asset_showcase_level.tscn")


func test_showcase_level_has_complete_playable_structure() -> void:
	# Arrange / Act
	var level: Node2D = auto_free(SHOWCASE_LEVEL.instantiate())

	# Assert
	assert_object(level.get_node_or_null("Player")).is_not_null()
	assert_object(level.get_node_or_null("Bee")).is_not_null()
	assert_object(level.get_node_or_null("Snail")).is_not_null()
	assert_object(level.get_node_or_null("Camera2D")).is_not_null()
	assert_bool(level.get_node_or_null("MapVisuals/BackgroundTiles") is TileMapLayer).is_true()
	assert_bool(level.get_node_or_null("MapVisuals/GeometryTiles") is TileMapLayer).is_true()
	assert_bool(level.get_node_or_null("MapVisuals/WaterTiles") is TileMapLayer).is_true()
	assert_bool(level.get_node_or_null("MapVisuals/ForegroundTiles") is TileMapLayer).is_true()


func test_showcase_level_uses_semantic_landmarks_instead_of_atlas_fragments() -> void:
	# Arrange / Act
	var level: Node2D = auto_free(SHOWCASE_LEVEL.instantiate())

	# Assert
	assert_object(level.get_node_or_null("MineEntrance")).is_not_null()
	assert_object(level.get_node_or_null("WoodenBridge")).is_not_null()
	assert_object(level.get_node_or_null("FordSteppingStone")).is_null()
	assert_object(level.get_node_or_null("FordMarkerLeft")).is_null()
	assert_object(level.get_node_or_null("FordMarkerRight")).is_null()
	assert_object(level.get_node_or_null("ForestFoliageA")).is_null()
	assert_object(level.get_node_or_null("WaterBridgeFrame")).is_null()
	assert_object(level.get_node_or_null("MineSupportFrame")).is_null()
	assert_object(level.get_node_or_null("ZoneLabels")).is_null()
	var scene_text := FileAccess.get_file_as_string("res://scenes/levels/asset_showcase_level.tscn")
	assert_bool(scene_text.contains("buildings_default_03")).is_false()
	assert_bool(scene_text.contains("foliage_scene/forest_2")).is_false()


func test_showcase_level_builds_complete_mine_work_area_and_avoids_background_fragments() -> void:
	# Arrange / Act
	var level: Node2D = auto_free(SHOWCASE_LEVEL.instantiate())
	var scene_text := FileAccess.get_file_as_string("res://scenes/levels/asset_showcase_level.tscn")
	var script_text := FileAccess.get_file_as_string("res://scripts/tools/asset_showcase_level.gd")

	# Assert
	assert_object(level.get_node_or_null("MineScaffoldLeftPost")).is_not_null()
	assert_object(level.get_node_or_null("MineScaffoldRightPost")).is_not_null()
	assert_object(level.get_node_or_null("MineScaffoldDeck")).is_not_null()
	assert_object(level.get_node_or_null("MineSupplyLogs")).is_not_null()
	assert_object(level.get_node_or_null("MineSupplyRack")).is_not_null()
	assert_bool(scene_text.contains("map_components_buildings_default_05")).is_true()
	assert_bool(scene_text.contains("map_components_buildings_default_11")).is_true()
	assert_bool(scene_text.contains("map_components_buildings_default_12")).is_true()
	assert_bool(scene_text.contains("vertex_colors = PackedColorArray")).is_true()
	assert_bool(script_text.contains("_paint_background")).is_false()
	assert_bool(script_text.contains("RIVER_GAP_LEFT := 47")).is_true()
	assert_bool(script_text.contains("RIVER_GAP_RIGHT_EXCLUSIVE := 52")).is_true()
	assert_bool(script_text.contains("WATER_LEFT := 46")).is_true()
	assert_bool(script_text.contains("WATER_RIGHT_EXCLUSIVE := 53")).is_true()


func test_showcase_level_uses_a_walkable_bridge_over_a_real_river_gap() -> void:
	# Arrange / Act
	var level: Node2D = auto_free(SHOWCASE_LEVEL.instantiate())
	var bridge := level.get_node_or_null("WoodenBridge") as Node2D
	var water := level.get_node_or_null("MapVisuals/WaterTiles") as TileMapLayer
	var bridge_scene_text := FileAccess.get_file_as_string("res://scenes/props/wooden_bridge.tscn")
	var script_text := FileAccess.get_file_as_string("res://scripts/tools/asset_showcase_level.gd")

	# Assert
	assert_object(bridge).is_not_null()
	assert_object(water).is_not_null()
	assert_int(water.z_index).is_equal(-2)
	assert_vector(water.position).is_equal(Vector2(0.0, 16.0))
	assert_bool(bridge.get_node_or_null("BridgeBody") is StaticBody2D).is_true()
	assert_bool(bridge.get_node_or_null("BridgeBody/CollisionShape2D") is CollisionShape2D).is_true()
	assert_bool(bridge_scene_text.contains("Legacy-Fantasy-High Forest/Map Assets/Forest-1.png")).is_true()
	assert_bool(bridge_scene_text.contains("region = Rect2(176, 116, 24, 44)")).is_true()
	assert_bool(bridge_scene_text.contains("region = Rect2(177, 94, 46, 12)")).is_true()
	assert_bool(bridge_scene_text.contains("region = Rect2(232, 116, 24, 44)")).is_true()
	assert_int(bridge_scene_text.count("texture = SubResource(\"AtlasTexture_bridge_middle\")")).is_equal(1)
	assert_bool(bridge_scene_text.contains("scale = Vector2(2, 2)")).is_false()
	assert_bool(bridge_scene_text.contains("size = Vector2(90, 8)")).is_true()
	assert_bool(script_text.contains("if x >= RIVER_GAP_LEFT and x < RIVER_GAP_RIGHT_EXCLUSIVE:")).is_true()
	assert_bool(script_text.contains("RIVER_SURFACE := Vector2i(6, 14)")).is_true()
	assert_bool(script_text.contains("RIVER_BODY := Vector2i(6, 15)")).is_true()
	assert_bool(script_text.contains("RIVER_DEEP := Vector2i(6, 16)")).is_true()
	assert_bool(script_text.contains("RIVER_BANK_LEFT")).is_true()
	assert_bool(script_text.contains("RIVER_BANK_RIGHT")).is_true()
	assert_bool(script_text.contains("WATER_LIGHT")).is_false()
