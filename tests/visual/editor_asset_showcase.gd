extends Node2D
## 全量编辑器素材验收关卡。
##
## GUI：方向键移动，Space/Enter 跳到下一页，Esc 退出。
## Headless：自动逐页截图到 reports/playtest/asset_showcase/。

const PAGE_SIZE := Vector2(640.0, 360.0)
const TILE_ORIGIN := Vector2(32.0, 64.0)
const TILE_COLUMNS := 24
const TILE_ROWS := 11
const SCENE_COLUMNS := 5
const SCENE_ROWS := 2
const SCENE_CELL_SIZE := Vector2(128.0, 140.0)
const OUTPUT_DIR := "res://reports/playtest/asset_showcase"

const TILESET_SECTIONS: Array[Dictionary] = [
	{
		"title": "Background Tiles",
		"path": "res://data/tilesets/forest_background_tileset.tres",
	},
	{
		"title": "Geometry Terrain Tiles",
		"path": "res://data/forest_tileset.tres",
	},
	{
		"title": "Animated Water Tiles",
		"path": "res://data/tilesets/forest_water_tileset.tres",
	},
	{
		"title": "Foreground Tiles",
		"path": "res://data/tilesets/forest_foreground_tileset.tres",
	},
	{
		"title": "Complete Atlas Library",
		"path": "res://data/tilesets/forest_library_tileset.tres",
	},
]

const SCENE_ROOT := "res://scenes/editor_library/scenes"
const ANIMATED_ROOT := "res://scenes/editor_library/animated"

var _pages: Array[Node2D] = []
var _page_titles: Array[String] = []
var _camera: Camera2D
var _page_label: Label
var _status_label: Label
var _current_page: int = 0
var _loaded_scene_count: int = 0
var _loaded_animation_count: int = 0
var _loaded_tile_count: int = 0
var _expected_scene_count: int = 0
var _expected_animation_count: int = 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("17212d"))
	_load_expected_counts()
	_camera = Camera2D.new()
	_camera.name = "ShowcaseCamera"
	_camera.enabled = true
	_camera.position = PAGE_SIZE * 0.5
	add_child(_camera)
	_build_overlay()
	_build_tileset_pages()
	_build_scene_library_pages()
	_build_animation_pages()
	_build_theme_composition_pages()
	_update_page_label()
	print(
		"asset_showcase: pages=%d tiles=%d scenes=%d animations=%d"
		% [_pages.size(), _loaded_tile_count, _loaded_scene_count, _loaded_animation_count])
	if OS.get_cmdline_user_args().has("--capture-showcase"):
		call_deferred("_capture_all_pages")
	elif DisplayServer.get_name() == "headless":
		var counts_valid := (
			_loaded_scene_count == _expected_scene_count
			and _loaded_animation_count == _expected_animation_count)
		print("asset_showcase: headless structure validation %s" % ("passed" if counts_valid else "failed"))
		get_tree().quit(0 if counts_valid else 1)


func _load_expected_counts() -> void:
	var text := FileAccess.get_file_as_string("res://data/editor_asset_catalog.json")
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var catalog := parsed as Dictionary
	_expected_scene_count = int(catalog.get("summary", {}).get("scene_paint_ready", 0))
	_expected_animation_count = (catalog.get("animations", []) as Array).size()


func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--capture-showcase"):
		return
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if not direction.is_zero_approx():
		_camera.position += direction * 420.0 * delta
		_current_page = clampi(roundi((_camera.position.x - PAGE_SIZE.x * 0.5) / PAGE_SIZE.x), 0, _pages.size() - 1)
		_update_page_label()
	if Input.is_action_just_pressed(&"ui_accept"):
		_go_to_page((_current_page + 1) % _pages.size())
	if Input.is_action_just_pressed(&"ui_cancel"):
		get_tree().quit()


func _build_overlay() -> void:
	var overlay := CanvasLayer.new()
	overlay.name = "Overlay"
	add_child(overlay)

	var header := ColorRect.new()
	header.offset_right = PAGE_SIZE.x
	header.offset_bottom = 42.0
	header.color = Color(0.03, 0.05, 0.08, 0.88)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(header)

	_page_label = Label.new()
	_page_label.position = Vector2(12.0, 5.0)
	_page_label.add_theme_font_size_override(&"font_size", 16)
	header.add_child(_page_label)

	_status_label = Label.new()
	_status_label.position = Vector2(12.0, 25.0)
	_status_label.add_theme_font_size_override(&"font_size", 10)
	_status_label.modulate = Color(0.75, 0.82, 0.9)
	header.add_child(_status_label)


func _build_tileset_pages() -> void:
	for section: Dictionary in TILESET_SECTIONS:
		var tile_set := load(String(section["path"])) as TileSet
		if tile_set == null:
			push_error("asset showcase: 无法加载 TileSet %s" % section["path"])
			continue
		var tiles := _collect_tiles(tile_set)
		_loaded_tile_count += tiles.size()
		var page_capacity := TILE_COLUMNS * TILE_ROWS
		var page_count := ceili(float(tiles.size()) / float(page_capacity))
		for page_index in range(page_count):
			var title := "%s (%d/%d)" % [section["title"], page_index + 1, page_count]
			var page := _create_page(title, Color("1d2a36"))
			var layer := TileMapLayer.new()
			layer.name = "TileGrid"
			layer.tile_set = tile_set
			layer.collision_enabled = false
			layer.position = TILE_ORIGIN
			layer.scale = Vector2(1.5, 1.5)
			page.add_child(layer)
			var start := page_index * page_capacity
			var finish := mini(start + page_capacity, tiles.size())
			for tile_index in range(start, finish):
				var local_index := tile_index - start
				var tile: Dictionary = tiles[tile_index]
				layer.set_cell(
					Vector2i(local_index % TILE_COLUMNS, local_index / TILE_COLUMNS),
					int(tile["source_id"]),
					tile["atlas_coords"] as Vector2i,
					int(tile["alternative"]))


func _collect_tiles(tile_set: TileSet) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source_index in range(tile_set.get_source_count()):
		var source_id := tile_set.get_source_id(source_index)
		var atlas := tile_set.get_source(source_id) as TileSetAtlasSource
		if atlas == null:
			continue
		for tile_index in range(atlas.get_tiles_count()):
			var coords := atlas.get_tile_id(tile_index)
			for alternative_index in range(atlas.get_alternative_tiles_count(coords)):
				result.append({
					"source_id": source_id,
					"atlas_coords": coords,
					"alternative": atlas.get_alternative_tile_id(coords, alternative_index),
				})
	return result


func _build_scene_library_pages() -> void:
	var grouped_paths := _collect_scene_groups(SCENE_ROOT)
	var group_names := grouped_paths.keys()
	group_names.sort()
	for group_value: Variant in group_names:
		var group_name := String(group_value)
		var paths := grouped_paths[group_name] as Array[String]
		_build_normalized_scene_pages("Scene Paint / %s" % group_name, paths, false)


func _build_animation_pages() -> void:
	var grouped_paths := _collect_scene_groups(ANIMATED_ROOT)
	var group_names := grouped_paths.keys()
	group_names.sort()
	for group_value: Variant in group_names:
		var group_name := String(group_value)
		var paths := grouped_paths[group_name] as Array[String]
		_build_normalized_scene_pages("Animated / %s" % group_name, paths, true)


func _collect_scene_groups(root_path: String) -> Dictionary:
	var result: Dictionary = {}
	_collect_scene_groups_recursive(root_path, root_path, result)
	return result


func _collect_scene_groups_recursive(root_path: String, current_path: String, result: Dictionary) -> void:
	var directory := DirAccess.open(current_path)
	if directory == null:
		return
	var files := directory.get_files()
	files.sort()
	for filename in files:
		if not filename.ends_with(".tscn"):
			continue
		var relative := current_path.trim_prefix(root_path).trim_prefix("/")
		var group_name := relative if not relative.is_empty() else "root"
		if not result.has(group_name):
			result[group_name] = [] as Array[String]
		(result[group_name] as Array[String]).append(current_path.path_join(filename))
	var directories := directory.get_directories()
	directories.sort()
	for dirname in directories:
		_collect_scene_groups_recursive(root_path, current_path.path_join(dirname), result)


func _build_normalized_scene_pages(title_prefix: String, paths: Array[String], animated: bool) -> void:
	var page_capacity := SCENE_COLUMNS * SCENE_ROWS
	var page_count := ceili(float(paths.size()) / float(page_capacity))
	for page_index in range(page_count):
		var title := "%s (%d/%d)" % [title_prefix, page_index + 1, page_count]
		var page := _create_page(title, Color("202632") if animated else Color("222a25"))
		var start := page_index * page_capacity
		var finish := mini(start + page_capacity, paths.size())
		for path_index in range(start, finish):
			var packed := load(paths[path_index]) as PackedScene
			if packed == null:
				push_error("asset showcase: 无法加载场景 %s" % paths[path_index])
				continue
			var instance := packed.instantiate() as Node2D
			if instance == null:
				continue
			var local_index := path_index - start
			var column := local_index % SCENE_COLUMNS
			var row := local_index / SCENE_COLUMNS
			var cell_origin := Vector2(column, row) * SCENE_CELL_SIZE + Vector2(0.0, 54.0)
			_add_cell_guide(page, cell_origin, SCENE_CELL_SIZE, local_index)
			var visual_size := _visual_size(instance)
			var fit_scale := _fit_scale(visual_size, Vector2(112.0, 105.0))
			instance.position = cell_origin + Vector2(SCENE_CELL_SIZE.x * 0.5, 110.0)
			instance.scale = Vector2.ONE * fit_scale
			page.add_child(instance)
			var caption := Label.new()
			caption.position = cell_origin + Vector2(4.0, 115.0)
			caption.size = Vector2(120.0, 22.0)
			caption.text = paths[path_index].get_file().get_basename().trim_prefix("map_components_")
			caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			caption.add_theme_font_size_override(&"font_size", 8)
			page.add_child(caption)
			if animated:
				_loaded_animation_count += 1
			else:
				_loaded_scene_count += 1


func _visual_size(instance: Node2D) -> Vector2:
	var sprite := instance.get_node_or_null("Visual") as Sprite2D
	if sprite != null and sprite.texture != null:
		return sprite.texture.get_size()
	var animated_sprite := instance.get_node_or_null("AnimatedVisual") as AnimatedSprite2D
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		var texture := animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, 0)
		if texture != null:
			return texture.get_size()
	return Vector2(16.0, 16.0)


func _fit_scale(source_size: Vector2, target_size: Vector2) -> float:
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return 1.0
	return clampf(minf(target_size.x / source_size.x, target_size.y / source_size.y), 0.08, 2.0)


func _add_cell_guide(page: Node2D, origin: Vector2, size: Vector2, index: int) -> void:
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([
		origin,
		origin + Vector2(size.x - 2.0, 0.0),
		origin + size - Vector2(2.0, 2.0),
		origin + Vector2(0.0, size.y - 2.0),
	])
	background.color = Color(0.09, 0.11, 0.14, 0.55) if index % 2 == 0 else Color(0.12, 0.14, 0.17, 0.55)
	background.z_index = -1
	page.add_child(background)


func _build_theme_composition_pages() -> void:
	_build_forest_composition()
	_build_mine_composition()


func _build_forest_composition() -> void:
	var page := _create_page("Composition / Forest Layering", Color("29394a"))
	_add_ground_guide(page, Color("17261a"))
	_add_composition_asset(page, "res://scenes/editor_library/scenes/background_scene/trees/map_components_trees_green_00.tscn", Vector2(110.0, 318.0), 0.48)
	_add_composition_asset(page, "res://scenes/editor_library/scenes/background_scene/trees/map_components_trees_green_16.tscn", Vector2(275.0, 318.0), 1.0)
	_add_composition_asset(page, "res://scenes/editor_library/scenes/terrain_prop_scene/rocks/map_components_rocks_default_14.tscn", Vector2(420.0, 318.0), 1.0)
	_add_composition_asset(page, "res://scenes/editor_library/animated/character/character_warrior_blue.tscn", Vector2(555.0, 318.0), 1.0)
	_add_water_preview(page, Vector2(365.0, 180.0), 7)


func _build_mine_composition() -> void:
	var page := _create_page("Composition / Mine Props (Visual Only)", Color("211d1b"))
	_add_ground_guide(page, Color("241e18"))
	_add_composition_asset(page, "res://scenes/editor_library/scenes/prop_scene/mine_stone/map_components_mine_stone_default_00.tscn", Vector2(105.0, 318.0), 0.8)
	_add_composition_asset(page, "res://scenes/editor_library/scenes/prop_scene/mine_stone/map_components_mine_stone_default_01.tscn", Vector2(300.0, 318.0), 1.0)
	_add_composition_asset(page, "res://scenes/editor_library/scenes/prop_scene/mine_stone/map_components_mine_stone_default_02.tscn", Vector2(475.0, 318.0), 0.85)
	_add_composition_asset(page, "res://scenes/editor_library/scenes/terrain_prop_scene/rocks/map_components_rocks_default_31.tscn", Vector2(585.0, 318.0), 0.72)
	var warning := Label.new()
	warning.position = Vector2(170.0, 70.0)
	warning.text = "No dedicated Mine Geometry Terrain yet"
	warning.modulate = Color(1.0, 0.72, 0.36)
	warning.add_theme_font_size_override(&"font_size", 15)
	page.add_child(warning)


func _add_composition_asset(page: Node2D, scene_path: String, position_value: Vector2, scale_value: float) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("asset showcase: 组合区缺少 %s" % scene_path)
		return
	var instance := packed.instantiate() as Node2D
	instance.position = position_value
	instance.scale = Vector2.ONE * scale_value
	page.add_child(instance)


func _add_water_preview(page: Node2D, position_value: Vector2, width: int) -> void:
	var water_set := load("res://data/tilesets/forest_water_tileset.tres") as TileSet
	if water_set == null:
		return
	var water := TileMapLayer.new()
	water.name = "AnimatedWaterPreview"
	water.tile_set = water_set
	water.collision_enabled = false
	water.position = position_value
	water.scale = Vector2(1.5, 1.5)
	page.add_child(water)
	for x in range(width):
		water.set_cell(Vector2i(x, 0), 0, Vector2i(6, 14))
		water.set_cell(Vector2i(x, 1), 0, Vector2i(6, 15))
		water.set_cell(Vector2i(x, 2), 0, Vector2i(6, 16))
	var waterfall_left := width + 1
	for y in range(4):
		for column in range(3):
			water.set_cell(Vector2i(waterfall_left + column, y), 0, Vector2i(3 + column, 13))


func _add_ground_guide(page: Node2D, color: Color) -> void:
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([
		Vector2(0.0, 318.0), Vector2(PAGE_SIZE.x, 318.0), PAGE_SIZE, Vector2(0.0, PAGE_SIZE.y),
	])
	ground.color = color
	ground.z_index = -1
	page.add_child(ground)


func _create_page(title: String, color: Color) -> Node2D:
	var page := Node2D.new()
	page.name = "Page%02d" % _pages.size()
	page.position = Vector2(PAGE_SIZE.x * _pages.size(), 0.0)
	add_child(page)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(PAGE_SIZE.x, 0.0), PAGE_SIZE, Vector2(0.0, PAGE_SIZE.y),
	])
	background.color = color
	background.z_index = -10
	page.add_child(background)
	_pages.append(page)
	_page_titles.append(title)
	return page


func _go_to_page(page_index: int) -> void:
	_current_page = clampi(page_index, 0, _pages.size() - 1)
	_camera.position = Vector2(PAGE_SIZE.x * _current_page + PAGE_SIZE.x * 0.5, PAGE_SIZE.y * 0.5)
	_update_page_label()


func _update_page_label() -> void:
	if _pages.is_empty():
		return
	_page_label.text = "%02d/%02d  %s" % [_current_page + 1, _pages.size(), _page_titles[_current_page]]
	_status_label.text = "Arrows: move    Enter/Space: next page    Esc: exit"


func _capture_all_pages() -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_path)
	for warmup_frame in range(12):
		await get_tree().process_frame
	var failed := false
	for page_index in range(_pages.size()):
		_go_to_page(page_index)
		for settle_frame in range(3):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var filename := "%02d_%s.png" % [page_index + 1, _safe_filename(_page_titles[page_index])]
		var error := image.save_png(OUTPUT_DIR.path_join(filename))
		if error != OK:
			failed = true
			push_error("asset showcase: 保存失败 %s" % filename)
	print("asset_showcase: captured=%d output=%s" % [_pages.size(), output_path])
	get_tree().quit(1 if failed else 0)


func _safe_filename(value: String) -> String:
	var result := value.to_snake_case().replace("/", "_").replace("(", "").replace(")", "")
	return result.validate_filename().to_lower()
