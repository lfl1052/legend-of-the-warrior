class_name ForestLevelTilemap
extends Node2D
## 根据 data/level_layouts.json 的稳定 layout_id 生成森林三层 TileMapLayer。
##
## BackgroundTiles：预留给背景装饰，永不参与碰撞。
## GeometryTiles：只接收占用单元，由 Terrain Set 自动选择边、角和中心。
## ForegroundTiles：完整单格蘑菇，永不参与碰撞。

const FOREST_TILESET := preload("res://data/forest_tileset.tres")
const SOURCE_ID := 0
const TERRAIN_SET := 0
const FOREST_GROUND := 0
const FOREGROUND_DECOR: Array[Vector2i] = [
	Vector2i(10, 17), Vector2i(15, 17),
	Vector2i(10, 18), Vector2i(15, 18),
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

	var occupied: Dictionary[Vector2i, bool] = {}
	var surfaces: Array[Dictionary] = []
	var ground: Dictionary = layout.get("ground", {})
	var ground_top_row := int(ground.get("top_row", 32))
	_add_landmass(
		occupied,
		surfaces,
		int(ground.get("left", -80)),
		int(ground.get("right", 80)),
		ground_top_row,
		int(ground.get("depth", 10)),
		"ground")

	var platform_index := 0
	for value: Variant in layout.get("platforms", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var platform: Dictionary = value
		var left := int(platform.get("left", 0))
		var width := int(platform.get("width", 2))
		var top_row := int(platform.get("top_row", 30))
		var depth := int(platform.get("depth", 1))
		var merge_with_ground := bool(platform.get("merge_with_ground", false))
		if merge_with_ground and top_row + depth < ground_top_row:
			push_error("ForestLevelTilemap: 平台 %d 标记贴地但没有接触主地面" % platform_index)
			platform_index += 1
			continue
		if not merge_with_ground and top_row + depth > ground_top_row - 2:
			push_error("ForestLevelTilemap: 平台 %d 缺少与主地面的完整空气间隔" % platform_index)
			platform_index += 1
			continue
		_add_landmass(
			occupied,
			surfaces,
			left,
			left + width - 1,
			top_row,
			depth,
			"platform_%d" % platform_index,
			merge_with_ground)
		platform_index += 1

	if occupied.is_empty():
		push_error("ForestLevelTilemap: 布局 %s 没有可绘制地形" % layout_id)
		return

	var cells: Array[Vector2i] = []
	cells.assign(occupied.keys())
	_geometry_layer.set_cells_terrain_connect(cells, TERRAIN_SET, FOREST_GROUND, true)

	var decoration_seed := int(layout.get("decoration_seed", 0))
	for surface in surfaces:
		_paint_surface_decor(
			occupied,
			int(surface["left"]),
			int(surface["right"]),
			int(surface["top_row"]),
			decoration_seed + int(surface["salt"]))


func _prepare_layer(layer: TileMapLayer, collision_enabled: bool) -> void:
	layer.tile_set = FOREST_TILESET
	layer.collision_enabled = collision_enabled
	layer.clear()


func _add_landmass(
		occupied: Dictionary[Vector2i, bool],
		surfaces: Array[Dictionary],
		left: int,
		right: int,
		top_row: int,
		depth: int,
		label: String,
		allow_overlap: bool = false) -> bool:
	if right - left + 1 < 2:
		push_error("ForestLevelTilemap: %s 宽度不足 2，当前 Terrain 不支持单格岛" % label)
		return false
	if depth < 1:
		push_error("ForestLevelTilemap: %s 深度不足 1，当前 Terrain 不支持单格横条" % label)
		return false
	for x in range(left, right + 1):
		for y in range(top_row, top_row + depth + 1):
			var coords := Vector2i(x, y)
			if occupied.has(coords) and not allow_overlap:
				push_error("ForestLevelTilemap: %s 与其他地块在 %s 相交" % [label, coords])
				return false
	for x in range(left, right + 1):
		for y in range(top_row, top_row + depth + 1):
			occupied[Vector2i(x, y)] = true
	surfaces.append({
		"left": left,
		"right": right,
		"top_row": top_row,
		"salt": surfaces.size() * 17,
	})
	return true


func _paint_surface_decor(
		occupied: Dictionary[Vector2i, bool],
		left: int,
		right: int,
		top_row: int,
		seed: int) -> void:
	for x in range(left + 2, right - 1):
		if occupied.has(Vector2i(x, top_row - 1)):
			continue
		if not _should_place_decor(x, seed):
			continue
		var decor_index := posmod((x * 13) + seed, FOREGROUND_DECOR.size())
		_foreground_layer.set_cell(
			Vector2i(x, top_row - 1), SOURCE_ID, FOREGROUND_DECOR[decor_index])


func _should_place_decor(x: int, seed: int) -> bool:
	return posmod((x * 19) + seed, 37) == 0 or posmod((x * 11) + seed, 61) == 0
