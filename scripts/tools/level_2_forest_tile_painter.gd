class_name ForestLevelTilemap
extends Node2D
## 根据 data/level_layouts.json 的稳定 layout_id 生成森林三层 TileMapLayer。
##
## BackgroundTiles：草边，永不参与碰撞。
## GeometryTiles：泥土主体，碰撞由 forest_tileset.tres 的物理层提供。
## ForegroundTiles：稀疏植物，永不参与碰撞。

const FOREST_TILESET := preload("res://data/forest_tileset.tres")
const SOURCE_ID := 0
const GRASS_LEFT := Vector2i(0, 0)
const GRASS_MIDS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const GRASS_RIGHT := Vector2i(4, 0)
const TOP_LEFT := Vector2i(0, 1)
const TOP_MIDS: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
const TOP_RIGHT := Vector2i(4, 1)
const LEFT_WALL: Array[Vector2i] = [Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)]
const RIGHT_WALL: Array[Vector2i] = [Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)]
const FILL_TILES: Array[Vector2i] = [
	Vector2i(1, 2),
	Vector2i(2, 2),
	Vector2i(3, 2),
	Vector2i(1, 3),
	Vector2i(2, 3),
	Vector2i(3, 3),
]
const SURFACE_DECOR: Array[Vector2i] = [
	Vector2i(6, 17),
	Vector2i(7, 17),
	Vector2i(8, 17),
	Vector2i(3, 18),
	Vector2i(5, 18),
]

@export var layout_id: StringName = &"level_2"
@export_node_path("TileMapLayer") var background_layer_path: NodePath = ^"BackgroundTiles"
@export_node_path("TileMapLayer") var geometry_layer_path: NodePath = ^"GeometryTiles"
@export_node_path("TileMapLayer") var foreground_layer_path: NodePath = ^"ForegroundTiles"

@onready var _background_layer := get_node_or_null(background_layer_path) as TileMapLayer
@onready var _geometry_layer := get_node_or_null(geometry_layer_path) as TileMapLayer
@onready var _foreground_layer := get_node_or_null(foreground_layer_path) as TileMapLayer


func _ready() -> void:
	paint_layout()


func paint_layout() -> void:
	if _background_layer == null or _geometry_layer == null or _foreground_layer == null:
		push_error("ForestLevelTilemap: 缺少 Background/Geometry/Foreground TileMapLayer")
		return

	var layout := RuntimeData.try_get_level_layout(layout_id)
	if layout.is_empty():
		push_error("ForestLevelTilemap: 未找到布局 %s" % layout_id)
		return

	_prepare_layer(_background_layer, false)
	_prepare_layer(_geometry_layer, true)
	_prepare_layer(_foreground_layer, false)

	var ground: Dictionary = layout.get("ground", {})
	_paint_landmass(
		int(ground.get("left", -80)),
		int(ground.get("right", 80)),
		int(ground.get("top_row", 32)),
		int(ground.get("depth", 10)),
		int(layout.get("decoration_seed", 0)))

	var platform_index := 0
	for value: Variant in layout.get("platforms", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var platform: Dictionary = value
		var left := int(platform.get("left", 0))
		var width := maxi(1, int(platform.get("width", 1)))
		_paint_landmass(
			left,
			left + width - 1,
			int(platform.get("top_row", 30)),
			maxi(1, int(platform.get("depth", 2))),
			int(layout.get("decoration_seed", 0)) + platform_index * 17)
		platform_index += 1


func _prepare_layer(layer: TileMapLayer, collision_enabled: bool) -> void:
	layer.tile_set = FOREST_TILESET
	layer.collision_enabled = collision_enabled
	layer.clear()


func _paint_landmass(left: int, right: int, top_row: int, depth: int, seed: int) -> void:
	if right < left:
		return
	for x in range(left, right + 1):
		_geometry_layer.set_cell(Vector2i(x, top_row), SOURCE_ID, _top_tile_for(x, left, right))
		_background_layer.set_cell(
			Vector2i(x, top_row - 1), SOURCE_ID, _grass_tile_for(x, left, right))

		for y_offset in range(1, depth + 1):
			_geometry_layer.set_cell(
				Vector2i(x, top_row + y_offset),
				SOURCE_ID,
				_fill_tile_for(x, y_offset, left, right))

		if x > left + 1 and x < right - 1 and _should_place_decor(x, seed):
			var decor_index := posmod((x * 13) + seed, SURFACE_DECOR.size())
			_foreground_layer.set_cell(
				Vector2i(x, top_row - 1), SOURCE_ID, SURFACE_DECOR[decor_index])


func _top_tile_for(x: int, left: int, right: int) -> Vector2i:
	if x == left:
		return TOP_LEFT
	if x == right:
		return TOP_RIGHT
	return TOP_MIDS[posmod(x, TOP_MIDS.size())]


func _grass_tile_for(x: int, left: int, right: int) -> Vector2i:
	if x == left:
		return GRASS_LEFT
	if x == right:
		return GRASS_RIGHT
	return GRASS_MIDS[posmod(x, GRASS_MIDS.size())]


func _fill_tile_for(x: int, y_offset: int, left: int, right: int) -> Vector2i:
	if x == left:
		return LEFT_WALL[posmod(y_offset - 1, LEFT_WALL.size())]
	if x == right:
		return RIGHT_WALL[posmod(y_offset - 1, RIGHT_WALL.size())]
	return FILL_TILES[posmod((x * 7) + (y_offset * 3), FILL_TILES.size())]


func _should_place_decor(x: int, seed: int) -> bool:
	return posmod((x * 19) + seed, 29) == 0 or posmod((x * 11) + seed, 47) == 0
