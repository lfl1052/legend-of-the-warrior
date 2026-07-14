extends Node2D
## 捕获原图集优先编辑器素材库的代表状态。

const TREE_SCENE := preload(
	"res://scenes/editor_library/scenes/background_scene/trees/map_components_trees_green_00.tscn")
const MINE_ENTRANCE_SCENE := preload(
	"res://scenes/editor_library/scenes/prop_scene/mine_stone/map_components_mine_stone_default_01.tscn")
const ROCK_SCENE := preload(
	"res://scenes/editor_library/scenes/terrain_prop_scene/rocks/map_components_rocks_default_03.tscn")
const PLAYER_PREVIEW := preload(
	"res://scenes/editor_library/animated/character/character_warrior_blue.tscn")
const WATER_TILESET := preload("res://data/tilesets/forest_water_tileset.tres")
const OUTPUT_PATH := "res://reports/playtest/editor_asset_library.png"


func _ready() -> void:
	_add_asset(TREE_SCENE, Vector2(92, 338), Vector2(0.55, 0.55))
	_add_asset(MINE_ENTRANCE_SCENE, Vector2(270, 318), Vector2(0.7, 0.7))
	_add_asset(ROCK_SCENE, Vector2(420, 314), Vector2(1.5, 1.5))
	_add_asset(PLAYER_PREVIEW, Vector2(530, 318), Vector2.ONE)

	var water := TileMapLayer.new()
	water.name = "AnimatedWaterPreview"
	water.tile_set = WATER_TILESET
	water.collision_enabled = false
	water.position = Vector2(360, 170)
	water.scale = Vector2(2, 2)
	add_child(water)
	for x in range(6):
		water.set_cell(Vector2i(x, 0), 0, Vector2i(6, 14))
		water.set_cell(Vector2i(x, 1), 0, Vector2i(3, 13))
		water.set_cell(Vector2i(x, 2), 0, Vector2i(3, 14))

	for _frame in range(12):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("editor asset capture: 保存失败 %s" % OUTPUT_PATH)
		get_tree().quit(1)
		return
	print("editor asset capture: %s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	get_tree().quit()


func _add_asset(scene: PackedScene, position_value: Vector2, scale_value: Vector2) -> void:
	var instance := scene.instantiate() as Node2D
	instance.position = position_value
	instance.scale = scale_value
	add_child(instance)
