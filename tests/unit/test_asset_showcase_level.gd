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
	assert_object(level.get_node_or_null("FordMarkerLeft")).is_not_null()
	assert_object(level.get_node_or_null("FordSteppingStone")).is_not_null()
	assert_object(level.get_node_or_null("FordMarkerRight")).is_not_null()
	assert_object(level.get_node_or_null("ForestFoliageA")).is_null()
	assert_object(level.get_node_or_null("WaterBridgeFrame")).is_null()
	assert_object(level.get_node_or_null("MineSupportFrame")).is_null()
	assert_object(level.get_node_or_null("ZoneLabels")).is_null()
	var scene_text := FileAccess.get_file_as_string("res://scenes/levels/asset_showcase_level.tscn")
	assert_bool(scene_text.contains("buildings_default_03")).is_false()
	assert_bool(scene_text.contains("foliage_scene/forest_2")).is_false()
