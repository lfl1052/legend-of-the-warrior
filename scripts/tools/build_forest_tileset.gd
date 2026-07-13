extends SceneTree
## 重建森林 TileSet 的 Terrain Set、World 碰撞和安全装饰图块。
## 运行：godot --headless --path . --script res://scripts/tools/build_forest_tileset.gd

const TILESET_PATH := "res://data/forest_tileset.tres"
const SOURCE_ID := 0
const CORNER_SOURCE_ID := 1
const CORNER_TEXTURE_PATH := "res://art/processed/map/terrain/forest_ground_inner_corners.png"
const TERRAIN_SET := 0
const FOREST_GROUND := 0

const TOP_LEFT := Vector2i(0, 0)
const TOP_MIDS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const TOP_RIGHT := Vector2i(4, 0)
const LEFT_WALLS: Array[Vector2i] = [Vector2i(0, 2), Vector2i(0, 3)]
const CENTERS: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
	Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
]
const RIGHT_WALLS: Array[Vector2i] = [Vector2i(4, 2), Vector2i(4, 3)]
const BOTTOM_LEFT := Vector2i(0, 4)
const BOTTOM_MIDS: Array[Vector2i] = [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
const BOTTOM_RIGHT := Vector2i(4, 4)
# 派生图集中两个 1×2 组合块：上半格补草冠，下半格保留原始草岩转角。
const INNER_MISSING_TOP_LEFT := Vector2i(0, 0)
const INNER_MISSING_TOP_RIGHT := Vector2i(1, 0)
const SOURCE_INNER_CORNERS: Array[Vector2i] = [Vector2i(5, 4), Vector2i(6, 4)]

# 这些单元各自包含完整的 16×16 蘑菇，不会截到相邻道具素材。
const FOREGROUND_DECOR: Array[Vector2i] = [
	Vector2i(10, 17), Vector2i(15, 17),
	Vector2i(10, 18), Vector2i(15, 18),
]
const UNSAFE_LEGACY_DECOR: Array[Vector2i] = [
	Vector2i(6, 17), Vector2i(7, 17), Vector2i(8, 17),
	Vector2i(3, 18), Vector2i(5, 18),
]

const TL := TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER
const TR := TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER
const BL := TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER
const BR := TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER
const ALL_CORNERS: Array[int] = [TL, TR, BL, BR]

var _full_tile_polygon := PackedVector2Array([
	Vector2(-8.0, -8.0),
	Vector2(8.0, -8.0),
	Vector2(8.0, 8.0),
	Vector2(-8.0, 8.0),
])


func _initialize() -> void:
	var tile_set := load(TILESET_PATH) as TileSet
	if tile_set == null:
		_fail("无法加载 %s" % TILESET_PATH)
		return

	var atlas := tile_set.get_source(SOURCE_ID) as TileSetAtlasSource
	if atlas == null:
		_fail("forest_tileset 缺少 atlas source 0")
		return

	_configure_atlas_tiles(atlas)
	var corner_atlas := _configure_corner_atlas(tile_set)
	if corner_atlas == null:
		return
	_configure_physics(tile_set, atlas, corner_atlas)
	_configure_terrain(tile_set, atlas, corner_atlas)

	var error := ResourceSaver.save(tile_set, TILESET_PATH)
	if error != OK:
		_fail("保存 forest_tileset 失败：%s" % error_string(error))
		return

	print(
		"forest_tileset: Terrain 规则 %d 类，实体图块 %d 个，前景装饰 %d 个"
		% [11, _base_terrain_tiles().size() + 2, FOREGROUND_DECOR.size()])
	quit()


func _configure_atlas_tiles(atlas: TileSetAtlasSource) -> void:
	# 重建实际使用区域，避免历史上被逐格注册的草冠与扩展顶面重叠。
	for coords in (
			_base_terrain_tiles() + SOURCE_INNER_CORNERS
			+ FOREGROUND_DECOR + UNSAFE_LEGACY_DECOR):
		if atlas.has_tile(coords):
			atlas.remove_tile(coords)

	for y in range(0, 2):
		for x in range(0, 5):
			var coords := Vector2i(x, y)
			if atlas.has_tile(coords):
				atlas.remove_tile(coords)
	for y in range(3, 5):
		for x in range(5, 7):
			var coords := Vector2i(x, y)
			if atlas.has_tile(coords):
				atlas.remove_tile(coords)

	for coords in [TOP_LEFT] + TOP_MIDS + [TOP_RIGHT]:
		atlas.create_tile(coords, Vector2i(1, 2))
		var tile_data := atlas.get_tile_data(coords, 0)
		tile_data.texture_origin = Vector2i(0, 8)

	for coords in LEFT_WALLS + CENTERS + RIGHT_WALLS:
		atlas.create_tile(coords)
	for coords in [BOTTOM_LEFT] + BOTTOM_MIDS + [BOTTOM_RIGHT]:
		atlas.create_tile(coords)
	for coords in FOREGROUND_DECOR:
		atlas.create_tile(coords)


func _configure_corner_atlas(tile_set: TileSet) -> TileSetAtlasSource:
	var texture := load(CORNER_TEXTURE_PATH) as Texture2D
	if texture == null:
		_fail("无法加载凹角派生图集 %s" % CORNER_TEXTURE_PATH)
		return null
	if tile_set.has_source(CORNER_SOURCE_ID):
		tile_set.remove_source(CORNER_SOURCE_ID)
	var corner_atlas := TileSetAtlasSource.new()
	corner_atlas.texture = texture
	corner_atlas.texture_region_size = Vector2i(16, 16)
	tile_set.add_source(corner_atlas, CORNER_SOURCE_ID)
	for coords in [INNER_MISSING_TOP_LEFT, INNER_MISSING_TOP_RIGHT]:
		corner_atlas.create_tile(coords, Vector2i(1, 2))
		var tile_data := corner_atlas.get_tile_data(coords, 0)
		tile_data.texture_origin = Vector2i(0, 8)
	return corner_atlas


func _configure_physics(
		tile_set: TileSet,
		atlas: TileSetAtlasSource,
		corner_atlas: TileSetAtlasSource) -> void:
	while tile_set.get_physics_layers_count() > 0:
		tile_set.remove_physics_layer(0)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)

	for coords in _base_terrain_tiles():
		var tile_data := atlas.get_tile_data(coords, 0)
		if tile_data == null:
			_fail("forest_tileset 缺少实体图块 %s" % coords)
			return
		tile_data.set_collision_polygons_count(0, 1)
		tile_data.set_collision_polygon_points(0, 0, _full_tile_polygon)
	for coords in [INNER_MISSING_TOP_LEFT, INNER_MISSING_TOP_RIGHT]:
		var tile_data := corner_atlas.get_tile_data(coords, 0)
		tile_data.set_collision_polygons_count(0, 1)
		tile_data.set_collision_polygon_points(0, 0, _full_tile_polygon)


func _configure_terrain(
		tile_set: TileSet,
		atlas: TileSetAtlasSource,
		corner_atlas: TileSetAtlasSource) -> void:
	while tile_set.get_terrain_sets_count() > 0:
		tile_set.remove_terrain_set(0)
	tile_set.add_terrain_set(TERRAIN_SET)
	tile_set.set_terrain_set_mode(TERRAIN_SET, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	tile_set.add_terrain(TERRAIN_SET, FOREST_GROUND)
	tile_set.set_terrain_name(TERRAIN_SET, FOREST_GROUND, "Forest Ground")
	tile_set.set_terrain_color(TERRAIN_SET, FOREST_GROUND, Color("789b2c"))

	_set_pattern(atlas, [TOP_LEFT], [BR])
	_set_pattern(atlas, TOP_MIDS, [BL, BR])
	_set_pattern(atlas, [TOP_RIGHT], [BL])
	_set_pattern(atlas, LEFT_WALLS, [TR, BR])
	_set_pattern(atlas, CENTERS, ALL_CORNERS)
	_set_pattern(atlas, RIGHT_WALLS, [TL, BL])
	_set_pattern(atlas, [BOTTOM_LEFT], [TR])
	_set_pattern(atlas, BOTTOM_MIDS, [TL, TR])
	_set_pattern(atlas, [BOTTOM_RIGHT], [TL])
	_set_pattern(corner_atlas, [INNER_MISSING_TOP_RIGHT], [TL, BL, BR])
	_set_pattern(corner_atlas, [INNER_MISSING_TOP_LEFT], [TR, BL, BR])


func _set_pattern(
		atlas: TileSetAtlasSource,
		coords_list: Array[Vector2i],
		connected_corners: Array[int]) -> void:
	for coords in coords_list:
		var tile_data := atlas.get_tile_data(coords, 0)
		if tile_data == null:
			_fail("无法为缺失图块 %s 配置 Terrain" % coords)
			return
		tile_data.set_terrain_set(TERRAIN_SET)
		tile_data.set_terrain(FOREST_GROUND)
		for corner in ALL_CORNERS:
			tile_data.set_terrain_peering_bit(
				corner,
				FOREST_GROUND if corner in connected_corners else -1)
		tile_data.set_probability(1.0)


func _base_terrain_tiles() -> Array[Vector2i]:
	return (
		[TOP_LEFT] + TOP_MIDS + [TOP_RIGHT]
		+ LEFT_WALLS + CENTERS + RIGHT_WALLS
		+ [BOTTOM_LEFT] + BOTTOM_MIDS + [BOTTOM_RIGHT])


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
