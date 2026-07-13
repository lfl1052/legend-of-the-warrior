extends GdUnitTestSuite

const TILESET := preload("res://data/forest_tileset.tres")
const TERRAIN_COORDS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4),
]
const INNER_CORNER_COORDS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
const SAFE_DECOR: Array[Vector2i] = [
	Vector2i(10, 17), Vector2i(15, 17), Vector2i(10, 18), Vector2i(15, 18),
]
const UNSAFE_LEGACY_DECOR: Array[Vector2i] = [
	Vector2i(6, 17), Vector2i(7, 17), Vector2i(8, 17),
	Vector2i(3, 18), Vector2i(5, 18),
]


func test_forest_ground_uses_named_corner_matching_terrain() -> void:
	# Arrange / Act
	var terrain_count := TILESET.get_terrain_sets_count()

	# Assert
	assert_int(terrain_count).is_equal(1)
	assert_int(TILESET.get_terrain_set_mode(0)).is_equal(TileSet.TERRAIN_MODE_MATCH_CORNERS)
	assert_int(TILESET.get_terrains_count(0)).is_equal(1)
	assert_str(TILESET.get_terrain_name(0, 0)).is_equal("Forest Ground")


func test_forest_ground_has_outer_edge_and_center_patterns() -> void:
	# Arrange
	var atlas := TILESET.get_source(0) as TileSetAtlasSource
	var corner_atlas := TILESET.get_source(1) as TileSetAtlasSource
	var top_left := atlas.get_tile_data(Vector2i(0, 0), 0)
	var center := atlas.get_tile_data(Vector2i(2, 2), 0)
	var inner_left := corner_atlas.get_tile_data(Vector2i(0, 0), 0)

	# Act / Assert
	assert_int(top_left.get_terrain_peering_bit(
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER)).is_equal(0)
	assert_int(top_left.get_terrain_peering_bit(
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER)).is_equal(-1)
	for corner in [
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	]:
		assert_int(center.get_terrain_peering_bit(corner)).is_equal(0)
	assert_int(inner_left.get_terrain_peering_bit(
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER)).is_equal(-1)
	assert_int(inner_left.get_terrain_peering_bit(
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER)).is_equal(0)
	assert_int(inner_left.get_terrain_peering_bit(
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER)).is_equal(0)
	assert_int(inner_left.get_terrain_peering_bit(
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER)).is_equal(0)
	assert_int(corner_atlas.get_tile_size_in_atlas(Vector2i(0, 0)).y).is_equal(2)
	assert_object(inner_left).is_not_null()
	assert_object(corner_atlas.texture).is_not_null()
	assert_vector(inner_left.texture_origin).is_equal(Vector2i(0, 8))
	assert_bool(atlas.has_tile(Vector2i(5, 4))).is_false()
	assert_bool(atlas.has_tile(Vector2i(6, 4))).is_false()


func test_all_geometry_tiles_have_collision() -> void:
	# Arrange
	var atlas := TILESET.get_source(0) as TileSetAtlasSource
	var corner_atlas := TILESET.get_source(1) as TileSetAtlasSource

	# Act / Assert
	for coords in TERRAIN_COORDS:
		var tile_data := atlas.get_tile_data(coords, 0)
		assert_object(tile_data).is_not_null()
		assert_int(tile_data.get_collision_polygons_count(0)).is_equal(1)
	for coords in INNER_CORNER_COORDS:
		var tile_data := corner_atlas.get_tile_data(coords, 0)
		assert_object(tile_data).is_not_null()
		assert_int(tile_data.get_collision_polygons_count(0)).is_equal(1)


func test_decor_tiles_are_complete_non_colliding_cells() -> void:
	# Arrange
	var atlas := TILESET.get_source(0) as TileSetAtlasSource

	# Act / Assert
	assert_int(atlas.get_tiles_count()).is_equal(TERRAIN_COORDS.size() + SAFE_DECOR.size())
	for coords in SAFE_DECOR:
		var tile_data := atlas.get_tile_data(coords, 0)
		assert_object(tile_data).is_not_null()
		assert_int(tile_data.get_collision_polygons_count(0)).is_equal(0)
	for coords in UNSAFE_LEGACY_DECOR:
		assert_bool(atlas.has_tile(coords)).is_false()
