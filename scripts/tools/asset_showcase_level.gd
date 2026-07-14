class_name AssetShowcaseLevel
extends Node2D
## 短而完整的素材验收关卡：森林高地 → 浅水石滩 → 矿洞入口。
## Scene Paint 资产使用低重复的代表变体；连续 Terrain 只承担通路和碰撞。

const OUTPUT_DIR := "res://reports/playtest/asset_showcase_level"
const GROUND_TOP := 32
const GROUND_BOTTOM := 38
const LEVEL_LEFT := 0
const LEVEL_RIGHT := 120
const TERRAIN_SET := 0
const FOREST_GROUND := 0
const WATER_SOURCE_ID := 0
const WATER_SURFACE := Vector2i(6, 14)
const WATER_LIGHT := Vector2i(3, 13)
const WATER_MID := Vector2i(3, 14)
const FOREGROUND_SOURCE_ID := 0
const FOREGROUND_COORDS: Array[Vector2i] = [
	Vector2i(10, 17), Vector2i(15, 17), Vector2i(10, 18), Vector2i(15, 18),
]

@onready var _background_tiles := $MapVisuals/BackgroundTiles as TileMapLayer
@onready var _geometry_tiles := $MapVisuals/GeometryTiles as TileMapLayer
@onready var _water_tiles := $MapVisuals/WaterTiles as TileMapLayer
@onready var _foreground_tiles := $MapVisuals/ForegroundTiles as TileMapLayer
@onready var _camera := $Camera2D as CameraControl


func _ready() -> void:
	_paint_geometry()
	_paint_water()
	_paint_foreground_accents()
	if OS.get_cmdline_user_args().has("--capture-showcase"):
		call_deferred("_capture_representative_views")
	elif DisplayServer.get_name() == "headless":
		print("asset_showcase_level: headless structure validation passed")
		get_tree().quit()


func _paint_geometry() -> void:
	_geometry_tiles.clear()
	var terrain_cells: Array[Vector2i] = []
	for x in range(LEVEL_LEFT, LEVEL_RIGHT + 1):
		for y in range(GROUND_TOP, GROUND_BOTTOM + 1):
			terrain_cells.append(Vector2i(x, y))
	_add_ground_rise(terrain_cells, 16, 24, 29)
	_add_ground_rise(terrain_cells, 88, 96, 30)
	_geometry_tiles.set_cells_terrain_connect(terrain_cells, TERRAIN_SET, FOREST_GROUND, true)


func _add_ground_rise(cells: Array[Vector2i], left: int, right: int, top: int) -> void:
	for x in range(left, right + 1):
		for y in range(top, GROUND_TOP):
			cells.append(Vector2i(x, y))


func _paint_water() -> void:
	_water_tiles.clear()
	for x in range(36, 65):
		_water_tiles.set_cell(Vector2i(x, 30), WATER_SOURCE_ID, WATER_SURFACE)
		_water_tiles.set_cell(Vector2i(x, 31), WATER_SOURCE_ID, WATER_LIGHT)
		_water_tiles.set_cell(Vector2i(x, 32), WATER_SOURCE_ID, WATER_MID)


func _paint_foreground_accents() -> void:
	_foreground_tiles.clear()
	var placements: Array[Vector2i] = [
		Vector2i(8, 31), Vector2i(26, 31), Vector2i(34, 31), Vector2i(67, 31),
		Vector2i(76, 31), Vector2i(87, 31), Vector2i(104, 31), Vector2i(116, 31),
	]
	for index in range(placements.size()):
		_foreground_tiles.set_cell(
			placements[index],
			FOREGROUND_SOURCE_ID,
			FOREGROUND_COORDS[index % FOREGROUND_COORDS.size()])


func _capture_representative_views() -> void:
	_camera.follow_player = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for frame in range(16):
		await get_tree().process_frame
	var views: Array[Dictionary] = [
		{"name": "forest_entrance", "position": Vector2(320.0, 400.0)},
		{"name": "river_ford", "position": Vector2(800.0, 390.0)},
		{"name": "mine_entrance", "position": Vector2(1440.0, 395.0)},
	]
	var failed := false
	for view: Dictionary in views:
		_camera.global_position = view["position"] as Vector2
		for settle_frame in range(4):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := OUTPUT_DIR.path_join(String(view["name"]) + ".png")
		var error := image.save_png(path)
		if error != OK:
			failed = true
			push_error("asset showcase level: 截图失败 %s" % path)
	print("asset_showcase_level: captures=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	get_tree().quit(1 if failed else 0)
