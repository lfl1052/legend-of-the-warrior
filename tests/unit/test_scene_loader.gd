extends GdUnitTestSuite

const SCENE_LOADER_SCRIPT := preload("res://scripts/autoload/scene_loader.gd")


func test_scene_loader_avoids_godot_4_7_threaded_request_leak() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/autoload/scene_loader.gd")
	assert_bool(source.contains("ResourceLoader.load_threaded_request(")).is_false()
	assert_bool(source.contains("wait_to_finish()")).is_true()


func test_scene_loader_waits_for_fade_before_starting_background_load() -> void:
	var loader: Node = auto_free(SCENE_LOADER_SCRIPT.new())
	add_child(loader)
	var scene_res := GameSceneResource.new()
	scene_res.scene_path = "res://scenes/levels/level_demo.tscn"

	loader.call("_on_scene_load_requested", scene_res, Vector3.ZERO, true)
	await get_tree().process_frame

	assert_object(loader.get("_load_thread")).is_null()
	assert_str(str(loader.get("_queued_scene_path"))).is_equal(scene_res.scene_path)

	loader.set("_is_loading", false)
	loader.set("_queued_scene_path", "")
	await get_tree().create_timer(0.45).timeout


func test_scene_loader_does_not_auto_start_placeholder_bgm() -> void:
	var loader: Node = auto_free(SCENE_LOADER_SCRIPT.new())
	add_child(loader)
	var scene_res := GameSceneResource.new()
	scene_res.scene_path = "res://scenes/levels/level_demo.tscn"
	loader.set("current_scene_resource", scene_res)
	var emitted_ids: Array[StringName] = []
	var recorder := func(bgm_id: StringName, _fade_duration: float) -> void:
		emitted_ids.append(bgm_id)
	GameEvents.play_bgm_id.connect(recorder)

	loader.call("_play_bgm_for_loaded_scene")

	if GameEvents.play_bgm_id.is_connected(recorder):
		GameEvents.play_bgm_id.disconnect(recorder)
	assert_array(emitted_ids).is_empty()
