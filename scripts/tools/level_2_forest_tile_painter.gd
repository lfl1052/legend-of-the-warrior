extends TileMapLayer

const FOREST_TILESET := preload("res://data/forest_tileset.tres")
const FOREST_ATLAS_TEXTURE := preload("res://art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png")
const SOURCE_ID := 0
const TILE_SIZE := 16
const SURFACE_GRASS_PREFIX := "SurfaceGrass_"
const GRASS_LEFT := Vector2i(0, 0)
const GRASS_MIDS := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const GRASS_RIGHT := Vector2i(4, 0)
const TOP_LEFT := Vector2i(0, 1)
const TOP_MIDS := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
const TOP_RIGHT := Vector2i(4, 1)
const LEFT_WALL := [Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)]
const RIGHT_WALL := [Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4)]
const FILL_TILES := [
	Vector2i(1, 2),
	Vector2i(2, 2),
	Vector2i(3, 2),
	Vector2i(1, 3),
	Vector2i(2, 3),
	Vector2i(3, 3),
]
const SURFACE_DECOR := [Vector2i(6, 17), Vector2i(7, 17), Vector2i(8, 17), Vector2i(3, 18), Vector2i(5, 18)]

@export var pixel_scale := 1.0
@export var ground_left_cell := -90
@export var ground_right_cell := 90
@export var ground_top_row := 32
@export var ground_fill_rows := 10


func _ready() -> void:
	_paint()


func _paint() -> void:
	tile_set = FOREST_TILESET
	scale = Vector2(pixel_scale, pixel_scale)
	clear()
	_clear_surface_grass()
	_paint_ground()
	_paint_surface_grass()
	_paint_surface_decor()


func _paint_ground() -> void:
	for x in range(ground_left_cell, ground_right_cell + 1):
		var atlas_coords: Vector2i = TOP_MIDS[posmod(x, TOP_MIDS.size())]
		if x == ground_left_cell:
			atlas_coords = TOP_LEFT
		elif x == ground_right_cell:
			atlas_coords = TOP_RIGHT

		set_cell(Vector2i(x, ground_top_row), SOURCE_ID, atlas_coords)

		for y_offset in range(1, ground_fill_rows + 1):
			set_cell(Vector2i(x, ground_top_row + y_offset), SOURCE_ID, _fill_tile_for(x, y_offset))


func _fill_tile_for(x: int, y_offset: int) -> Vector2i:
	if x == ground_left_cell:
		return LEFT_WALL[posmod(y_offset - 1, LEFT_WALL.size())]
	if x == ground_right_cell:
		return RIGHT_WALL[posmod(y_offset - 1, RIGHT_WALL.size())]

	return FILL_TILES[posmod((x * 7) + (y_offset * 3), FILL_TILES.size())]


func _paint_surface_decor() -> void:
	for x in range(ground_left_cell + 4, ground_right_cell - 3):
		if x % 31 == 0:
			set_cell(Vector2i(x, ground_top_row - 1), SOURCE_ID, SURFACE_DECOR[0])
		elif x % 43 == 0:
			set_cell(Vector2i(x, ground_top_row - 1), SOURCE_ID, SURFACE_DECOR[3])
		elif x % 53 == 0:
			set_cell(Vector2i(x, ground_top_row - 1), SOURCE_ID, SURFACE_DECOR[4])


func _paint_surface_grass() -> void:
	for x in range(ground_left_cell, ground_right_cell + 1):
		var atlas_coords: Vector2i = GRASS_MIDS[posmod(x, GRASS_MIDS.size())]
		if x == ground_left_cell:
			atlas_coords = GRASS_LEFT
		elif x == ground_right_cell:
			atlas_coords = GRASS_RIGHT

		var sprite := Sprite2D.new()
		sprite.name = "%s%s" % [SURFACE_GRASS_PREFIX, x]
		sprite.centered = false
		sprite.texture = FOREST_ATLAS_TEXTURE
		sprite.region_enabled = true
		sprite.region_rect = Rect2(atlas_coords * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE))
		sprite.position = Vector2(x * TILE_SIZE, (ground_top_row - 1) * TILE_SIZE)
		sprite.z_index = 1
		add_child(sprite)


func _clear_surface_grass() -> void:
	for child in get_children():
		if child.name.begins_with(SURFACE_GRASS_PREFIX):
			child.queue_free()
