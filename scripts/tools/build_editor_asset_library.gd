extends SceneTree
## 从 editor_asset_catalog.json 生成 Godot 编辑器可用的分类 TileSet 与 Scene Paint 场景。
##
## 所有编辑器资源优先引用原始图集：
## - 16×16 地图图块通过 TileSetAtlasSource 注册 atlas 坐标；
## - 变尺寸树木/建筑通过 AtlasTexture.region 引用原图；
## - 角色和敌人动画通过原始 sheet 的 frame region 创建 SpriteFrames。
##
## 运行：godot --headless --path . --script res://scripts/tools/build_editor_asset_library.gd

const CATALOG_PATH := "res://data/editor_asset_catalog.json"
const TILESET_OUTPUT_DIR := "res://data/tilesets"
const SCENE_OUTPUT_DIR := "res://scenes/editor_library"
const TILE_SIZE := Vector2i(16, 16)

const TILESET_SPECS: Array[Dictionary] = [
	{
		"palette": "forest_background",
		"path": "res://data/tilesets/forest_background_tileset.tres",
		"resource_name": "Forest Background",
	},
	{
		"palette": "forest_foreground",
		"path": "res://data/tilesets/forest_foreground_tileset.tres",
		"resource_name": "Forest Foreground",
	},
	{
		"palette": "forest_library",
		"path": "res://data/tilesets/forest_library_tileset.tres",
		"resource_name": "Forest Atlas Library",
	},
]


func _initialize() -> void:
	var catalog := _load_catalog()
	if catalog.is_empty():
		quit(1)
		return

	_ensure_directory(TILESET_OUTPUT_DIR)
	_reset_generated_directory(SCENE_OUTPUT_DIR)

	var assets: Array = catalog.get("assets", [])
	for spec: Dictionary in TILESET_SPECS:
		if not _build_tileset(assets, spec):
			quit(1)
			return
	if not _build_water_tileset(catalog):
		quit(1)
		return

	var scene_count := _build_scene_paint_assets(assets)
	var animation_count := _build_animation_previews(catalog.get("animations", []))
	print(
		"editor_asset_library: TileSet %d 个，Scene Paint %d 个，动画预览 %d 个"
		% [TILESET_SPECS.size() + 1, scene_count, animation_count])
	quit()


func _load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("缺少编辑器素材目录：%s" % CATALOG_PATH)
		return {}
	var text := FileAccess.get_file_as_string(CATALOG_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("编辑器素材目录不是 JSON 对象：%s" % CATALOG_PATH)
		return {}
	return parsed as Dictionary


func _build_tileset(assets: Array, spec: Dictionary) -> bool:
	var palette := String(spec["palette"])
	var tile_set := TileSet.new()
	tile_set.resource_name = String(spec["resource_name"])
	tile_set.tile_size = TILE_SIZE
	_add_editor_custom_data_layers(tile_set)

	var source_assets: Dictionary = {}
	for value: Variant in assets:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var asset := value as Dictionary
		var editor: Dictionary = asset.get("editor", {})
		if editor.get("paint_mode", "") != "tilemap":
			continue
		var is_library := palette == "forest_library" and String(asset.get("id", "")).begins_with("map.tiles.")
		if not is_library and editor.get("palette", "") != palette:
			continue
		var region: Variant = editor.get("region")
		if typeof(region) != TYPE_ARRAY or (region as Array).size() != 4:
			continue
		var texture_path := String(editor.get("texture", ""))
		if texture_path.is_empty():
			continue
		if not source_assets.has(texture_path):
			source_assets[texture_path] = []
		(source_assets[texture_path] as Array).append(asset)

	var texture_paths: Array = source_assets.keys()
	texture_paths.sort()
	var source_id := 0
	for texture_value: Variant in texture_paths:
		var texture_path := String(texture_value)
		var texture := load(texture_path) as Texture2D
		if texture == null:
			push_error("无法加载图集：%s" % texture_path)
			return false
		var atlas := TileSetAtlasSource.new()
		atlas.resource_name = texture_path.get_file().get_basename()
		atlas.texture = texture
		atlas.texture_region_size = TILE_SIZE
		tile_set.add_source(atlas, source_id)
		for asset_value: Variant in source_assets[texture_path]:
			var asset := asset_value as Dictionary
			var editor: Dictionary = asset["editor"]
			var region := editor["region"] as Array
			if int(region[2]) != TILE_SIZE.x or int(region[3]) != TILE_SIZE.y:
				continue
			var coords := Vector2i(int(region[0]) / TILE_SIZE.x, int(region[1]) / TILE_SIZE.y)
			if not atlas.has_tile(coords):
				atlas.create_tile(coords)
			var tile_data := atlas.get_tile_data(coords, 0)
			if tile_data != null:
				tile_data.set_custom_data("editor_role", String(editor.get("role", "library_tile")))
				tile_data.set_custom_data("asset_id", String(asset.get("id", "")))
		source_id += 1

	var error := ResourceSaver.save(tile_set, String(spec["path"]))
	if error != OK:
		push_error("保存 TileSet 失败：%s" % error_string(error))
		return false
	return true


func _build_water_tileset(catalog: Dictionary) -> bool:
	var dynamic_tiles: Array = catalog.get("rules", {}).get("dynamic_tiles", [])
	var tile_set := TileSet.new()
	tile_set.resource_name = "Forest Animated Water"
	tile_set.tile_size = TILE_SIZE
	_add_editor_custom_data_layers(tile_set)

	var texture_path := "res://art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png"
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("无法加载水体图集：%s" % texture_path)
		return false
	var atlas := TileSetAtlasSource.new()
	atlas.resource_name = "forest_1_animated_water"
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE
	tile_set.add_source(atlas, 0)

	var reserved_frames: Dictionary[Vector2i, bool] = {}
	for value: Variant in dynamic_tiles:
		var animation := value as Dictionary
		var base_array := animation.get("base", []) as Array
		var base := Vector2i(int(base_array[0]), int(base_array[1]))
		var columns := int(animation.get("columns", 1))
		var frames := int(animation.get("frames", columns))
		for frame_index in range(frames):
			var frame_offset := Vector2i(
				frame_index % columns,
				floori(frame_index / float(columns)))
			reserved_frames[base + frame_offset] = true

	for y in range(13, 17):
		for x in range(0, 10):
			var coords := Vector2i(x, y)
			if reserved_frames.has(coords):
				continue
			atlas.create_tile(coords)
			var tile_data := atlas.get_tile_data(coords, 0)
			tile_data.set_custom_data("editor_role", "water_tile")
			tile_data.set_custom_data("asset_id", "map.tiles.forest_1.%02d_%02d" % [x, y])

	for value: Variant in dynamic_tiles:
		var animation := value as Dictionary
		var base_array := animation.get("base", []) as Array
		var base := Vector2i(int(base_array[0]), int(base_array[1]))
		var columns := int(animation.get("columns", 1))
		var frames := int(animation.get("frames", columns))
		atlas.create_tile(base)
		atlas.set_tile_animation_columns(base, columns)
		atlas.set_tile_animation_frames_count(base, frames)
		atlas.set_tile_animation_speed(base, float(animation.get("fps", 2.0)))
		var tile_data := atlas.get_tile_data(base, 0)
		tile_data.set_custom_data("editor_role", "animated_water")
		tile_data.set_custom_data("asset_id", String(animation.get("id", "water")))

	var error := ResourceSaver.save(tile_set, "res://data/tilesets/forest_water_tileset.tres")
	if error != OK:
		push_error("保存动态水体 TileSet 失败：%s" % error_string(error))
		return false
	return true


func _build_scene_paint_assets(assets: Array) -> int:
	var saved_count := 0
	for value: Variant in assets:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var asset := value as Dictionary
		var editor: Dictionary = asset.get("editor", {})
		if editor.get("paint_mode", "") != "scene" or not bool(editor.get("editor_ready", false)):
			continue
		var texture := _create_editor_texture(editor)
		if texture == null:
			continue
		var root := Node2D.new()
		root.name = _node_name(String(asset.get("id", "Asset")))
		root.set_meta("asset_id", String(asset.get("id", "")))
		root.set_meta("editor_role", String(editor.get("role", "scene")))
		root.set_meta("visual_only", bool(editor.get("visual_only", false)))
		var placement := String(editor.get("placement", "standalone"))
		if placement != "standalone":
			root.set_meta("placement", placement)
		var sprite := Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(0.0, -texture.get_height() * 0.5)
		root.add_child(sprite)
		sprite.owner = root

		var family := _safe_name(String(asset.get("family", "misc")))
		var role := _safe_name(String(editor.get("role", "scene")))
		var directory := "%s/scenes/%s/%s" % [SCENE_OUTPUT_DIR, role, family]
		_ensure_directory(directory)
		var output_path := "%s/%s.tscn" % [directory, _safe_name(String(asset.get("id", "asset")))]
		if _save_packed_scene(root, output_path):
			saved_count += 1
		root.free()
	return saved_count


func _build_animation_previews(animation_sets: Array) -> int:
	var saved_count := 0
	for value: Variant in animation_sets:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var animation_set := value as Dictionary
		var frames_resource := SpriteFrames.new()
		frames_resource.remove_animation(&"default")
		var first_action := StringName()
		var frame_height := 0.0
		for action_value: Variant in animation_set.get("actions", []):
			var action := action_value as Dictionary
			var action_name := StringName(String(action.get("name", "default")))
			if first_action.is_empty():
				first_action = action_name
			frames_resource.add_animation(action_name)
			frames_resource.set_animation_speed(action_name, float(action.get("fps", 8.0)))
			frames_resource.set_animation_loop(action_name, bool(action.get("loop", true)))
			for frame_value: Variant in action.get("frames", []):
				var texture := _create_editor_texture(frame_value as Dictionary)
				if texture == null:
					continue
				frame_height = maxf(frame_height, texture.get_height())
				frames_resource.add_frame(action_name, texture)

		if first_action.is_empty():
			continue
		var root := Node2D.new()
		root.name = _node_name(String(animation_set.get("id", "AnimationPreview")))
		root.set_meta("asset_id", String(animation_set.get("id", "")))
		root.set_meta("editor_role", "animation_preview")
		var sprite := AnimatedSprite2D.new()
		sprite.name = "AnimatedVisual"
		sprite.sprite_frames = frames_resource
		sprite.animation = first_action
		sprite.autoplay = String(first_action)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(0.0, -frame_height * 0.5)
		root.add_child(sprite)
		sprite.owner = root

		var category := _safe_name(String(animation_set.get("category", "actor")))
		var directory := "%s/animated/%s" % [SCENE_OUTPUT_DIR, category]
		_ensure_directory(directory)
		var output_path := "%s/%s.tscn" % [directory, _safe_name(String(animation_set.get("id", "animation")))]
		if _save_packed_scene(root, output_path):
			saved_count += 1
		root.free()
	return saved_count


func _create_editor_texture(reference: Dictionary) -> Texture2D:
	var texture_path := String(reference.get("texture", ""))
	var source := load(texture_path) as Texture2D
	if source == null:
		push_warning("跳过无法加载的编辑器纹理：%s" % texture_path)
		return null
	var region_value: Variant = reference.get("region")
	if typeof(region_value) != TYPE_ARRAY or (region_value as Array).size() != 4:
		return source
	var region := region_value as Array
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = source
	atlas_texture.region = Rect2(
		float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	return atlas_texture


func _add_editor_custom_data_layers(tile_set: TileSet) -> void:
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(0, "editor_role")
	tile_set.set_custom_data_layer_type(0, TYPE_STRING)
	tile_set.add_custom_data_layer()
	tile_set.set_custom_data_layer_name(1, "asset_id")
	tile_set.set_custom_data_layer_type(1, TYPE_STRING)


func _save_packed_scene(root: Node, output_path: String) -> bool:
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("打包场景失败 %s：%s" % [output_path, error_string(pack_error)])
		return false
	var save_error := ResourceSaver.save(packed, output_path)
	if save_error != OK:
		push_error("保存场景失败 %s：%s" % [output_path, error_string(save_error)])
		return false
	_canonicalize_generated_scene(output_path)
	return true


func _canonicalize_generated_scene(output_path: String) -> void:
	var text := FileAccess.get_file_as_string(output_path)
	var ext_regex := RegEx.new()
	ext_regex.compile("\\[ext_resource[^\\]]* id=\\\"([^\\\"]+)\\\"\\]")
	var ext_index := 0
	for match_result: RegExMatch in ext_regex.search_all(text):
		var old_id := match_result.get_string(1)
		var new_id := "ext_%03d" % ext_index
		text = text.replace("id=\"%s\"" % old_id, "id=\"%s\"" % new_id)
		text = text.replace("ExtResource(\"%s\")" % old_id, "ExtResource(\"%s\")" % new_id)
		ext_index += 1

	var sub_regex := RegEx.new()
	sub_regex.compile("\\[sub_resource[^\\]]* id=\\\"([^\\\"]+)\\\"\\]")
	var sub_index := 0
	for match_result: RegExMatch in sub_regex.search_all(text):
		var old_id := match_result.get_string(1)
		var new_id := "sub_%03d" % sub_index
		text = text.replace("id=\"%s\"" % old_id, "id=\"%s\"" % new_id)
		text = text.replace("SubResource(\"%s\")" % old_id, "SubResource(\"%s\")" % new_id)
		sub_index += 1

	var unique_id_regex := RegEx.new()
	unique_id_regex.compile(" unique_id=\\d+")
	text = unique_id_regex.sub(text, "", true)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)


func _ensure_directory(resource_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(resource_path))


func _reset_generated_directory(resource_path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(resource_path)
	var expected_suffix := "/scenes/editor_library"
	if not absolute_path.replace("\\", "/").ends_with(expected_suffix):
		push_error("拒绝清理非编辑器素材目录：%s" % absolute_path)
		return
	if DirAccess.dir_exists_absolute(absolute_path):
		_remove_directory_recursive(absolute_path)
	DirAccess.make_dir_recursive_absolute(absolute_path)


func _remove_directory_recursive(absolute_path: String) -> void:
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	for filename in directory.get_files():
		DirAccess.remove_absolute(absolute_path.path_join(filename))
	for dirname in directory.get_directories():
		var child_path := absolute_path.path_join(dirname)
		_remove_directory_recursive(child_path)
		DirAccess.remove_absolute(child_path)


func _safe_name(value: String) -> String:
	var result := value.to_snake_case().replace(".", "_").replace("-", "_")
	return result.validate_node_name().to_lower()


func _node_name(value: String) -> String:
	return _safe_name(value).to_pascal_case()
