extends SceneTree
## 重新生成 forest_tileset.tres 的 World 物理层。
## 运行：godot --headless --path . --script res://scripts/tools/build_forest_tileset.gd

const TILESET_PATH := "res://data/forest_tileset.tres"
const SOURCE_ID := 0
const SOLID_TILES: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4),
]
var _full_tile_polygon := PackedVector2Array([
	Vector2(-8.0, -8.0),
	Vector2(8.0, -8.0),
	Vector2(8.0, 8.0),
	Vector2(-8.0, 8.0),
])


func _initialize() -> void:
	var tile_set := load(TILESET_PATH) as TileSet
	if tile_set == null:
		push_error("无法加载 %s" % TILESET_PATH)
		quit(1)
		return

	while tile_set.get_physics_layers_count() > 0:
		tile_set.remove_physics_layer(0)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var atlas := tile_set.get_source(SOURCE_ID) as TileSetAtlasSource
	if atlas == null:
		push_error("forest_tileset 缺少 atlas source 0")
		quit(1)
		return

	for coords in SOLID_TILES:
		var tile_data := atlas.get_tile_data(coords, 0)
		if tile_data == null:
			push_error("forest_tileset 缺少实体图块 %s" % coords)
			quit(1)
			return
		tile_data.set_collision_polygons_count(0, 1)
		tile_data.set_collision_polygon_points(0, 0, _full_tile_polygon)

	var error := ResourceSaver.save(tile_set, TILESET_PATH)
	if error != OK:
		push_error("保存 forest_tileset 失败：%s" % error_string(error))
		quit(1)
		return
	print("forest_tileset: 已为 %d 个实体图块生成 World 碰撞" % SOLID_TILES.size())
	quit()
