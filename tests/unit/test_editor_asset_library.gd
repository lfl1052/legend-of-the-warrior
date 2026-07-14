extends GdUnitTestSuite

const BACKGROUND_TILESET := preload("res://data/tilesets/forest_background_tileset.tres")
const FOREGROUND_TILESET := preload("res://data/tilesets/forest_foreground_tileset.tres")
const LIBRARY_TILESET := preload("res://data/tilesets/forest_library_tileset.tres")
const WATER_TILESET := preload("res://data/tilesets/forest_water_tileset.tres")
const TREE_SCENE := preload(
	"res://scenes/editor_library/scenes/background_scene/trees/map_components_trees_green_00.tscn")
const PLAYER_PREVIEW := preload(
	"res://scenes/editor_library/animated/character/character_warrior_blue.tscn")


func test_catalog_uses_original_atlases_instead_of_processed_crops() -> void:
	# Arrange / Act
	var text := FileAccess.get_file_as_string("res://data/editor_asset_catalog.json")
	var parsed: Variant = JSON.parse_string(text)

	# Assert
	assert_bool(typeof(parsed) == TYPE_DICTIONARY).is_true()
	var catalog := parsed as Dictionary
	assert_int(int(catalog.get("version", 0))).is_equal(1)
	assert_int(int(catalog.get("summary", {}).get("total_assets", 0))).is_greater(1000)
	assert_bool(text.contains("res://art/processed")).is_false()
	assert_bool(text.contains("res://art/imported")).is_true()


func test_editor_tilesets_are_separated_by_layer_and_have_no_decor_collision() -> void:
	# Arrange / Act / Assert
	assert_int(BACKGROUND_TILESET.get_source_count()).is_greater(0)
	assert_int(FOREGROUND_TILESET.get_source_count()).is_greater(0)
	assert_int(LIBRARY_TILESET.get_source_count()).is_equal(2)
	assert_int(BACKGROUND_TILESET.get_physics_layers_count()).is_equal(0)
	assert_int(FOREGROUND_TILESET.get_physics_layers_count()).is_equal(0)
	assert_int(LIBRARY_TILESET.get_physics_layers_count()).is_equal(0)
	assert_str(BACKGROUND_TILESET.get_custom_data_layer_name(0)).is_equal("editor_role")
	assert_str(FOREGROUND_TILESET.get_custom_data_layer_name(1)).is_equal("asset_id")


func test_water_tileset_contains_looping_atlas_animations() -> void:
	# Arrange
	var atlas := WATER_TILESET.get_source(0) as TileSetAtlasSource

	# Act / Assert
	assert_object(atlas).is_not_null()
	assert_int(atlas.get_tile_animation_frames_count(Vector2i(6, 14))).is_equal(4)
	assert_float(atlas.get_tile_animation_speed(Vector2i(6, 14))).is_equal(3.0)
	assert_int(atlas.get_tile_animation_frames_count(Vector2i(3, 13))).is_equal(3)
	assert_float(atlas.get_tile_animation_speed(Vector2i(3, 13))).is_equal(2.0)
	var animated_data := atlas.get_tile_data(Vector2i(6, 14), 0)
	assert_str(String(animated_data.get_custom_data("editor_role"))).is_equal("animated_water")


func test_scene_paint_asset_keeps_base_anchor_and_atlas_reference() -> void:
	# Arrange / Act
	var root: Node2D = auto_free(TREE_SCENE.instantiate())
	var sprite := root.get_node("Visual") as Sprite2D
	var atlas_texture := sprite.texture as AtlasTexture

	# Assert
	assert_object(atlas_texture).is_not_null()
	assert_bool(atlas_texture.atlas.resource_path.contains("res://art/imported/")).is_true()
	assert_float(sprite.position.y).is_equal(-atlas_texture.get_height() * 0.5)
	assert_str(String(root.get_meta("editor_role"))).is_equal("background_scene")


func test_animation_preview_uses_regions_from_original_sprite_sheet() -> void:
	# Arrange / Act
	var root: Node2D = auto_free(PLAYER_PREVIEW.instantiate())
	var sprite := root.get_node("AnimatedVisual") as AnimatedSprite2D
	var frames := sprite.sprite_frames
	var idle_frame := frames.get_frame_texture(&"idle", 0) as AtlasTexture

	# Assert
	assert_object(idle_frame).is_not_null()
	assert_bool(idle_frame.atlas.resource_path.contains("res://art/imported/Generic-Character")).is_true()
	assert_vector(idle_frame.region.size).is_equal(Vector2(56, 56))
	assert_float(frames.get_animation_speed(&"attack_combo")).is_equal(12.0)
	assert_bool(frames.get_animation_loop(&"death")).is_false()


func test_irregular_atlas_candidates_require_semantic_editor_approval() -> void:
	# Arrange / Act
	var text := FileAccess.get_file_as_string("res://data/editor_asset_catalog.json")
	var catalog := JSON.parse_string(text) as Dictionary
	var assets := catalog.get("assets", []) as Array
	var by_id: Dictionary = {}
	for value: Variant in assets:
		var asset := value as Dictionary
		by_id[String(asset.get("id", ""))] = asset

	# Assert
	assert_bool(bool(by_id["map.components.hive.default.00"]["editor"]["editor_ready"])).is_false()
	assert_str(String(by_id["map.components.hive.default.00"]["editor"]["placement"])).is_equal("atlas_fragment")
	assert_bool(bool(by_id["map.components.forest_2.default.00"]["editor"]["editor_ready"])).is_false()
	assert_bool(bool(by_id["map.components.buildings.default.03"]["editor"]["editor_ready"])).is_false()
	assert_bool(bool(by_id["map.components.rocks.default.11"]["editor"]["editor_ready"])).is_false()
	assert_bool(bool(by_id["map.components.mine_stone.default.01"]["editor"]["editor_ready"])).is_true()
	assert_str(String(by_id["map.components.mine_stone.default.01"]["editor"]["placement"])).is_equal("standalone")
	assert_int(int(catalog.get("summary", {}).get("scene_paint_ready", 0))).is_equal(218)
