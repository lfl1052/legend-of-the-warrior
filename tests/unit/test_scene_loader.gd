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


func test_scene_loader_can_lock_and_restore_player_input() -> void:
	var loader: Node = auto_free(SCENE_LOADER_SCRIPT.new())
	add_child(loader)
	var player: FakeInputPlayer = auto_free(FakeInputPlayer.new())
	add_child(player)
	player.add_to_group(&"player")

	loader.call("_set_player_input_active", false)
	loader.call("_set_player_input_active", true)

	assert_array(player.received_states).contains_exactly([false, true])


func test_scene_loader_ignores_duplicate_request_while_transition_is_active() -> void:
	var loader: Node = auto_free(SCENE_LOADER_SCRIPT.new())
	add_child(loader)
	var first_scene := GameSceneResource.new()
	first_scene.scene_path = "res://scenes/levels/level_demo.tscn"
	var second_scene := GameSceneResource.new()
	second_scene.scene_path = "res://scenes/levels/level_2.tscn"
	loader.set("_is_loading", true)
	loader.set("_pending_scene_resource", first_scene)
	loader.set("_pending_position", Vector3(12.0, 34.0, 0.0))

	loader.call("_on_scene_load_requested", second_scene, Vector3(90.0, 12.0, 0.0), true)

	assert_object(loader.get("_pending_scene_resource")).is_same(first_scene)
	assert_vector(loader.get("_pending_position")).is_equal(Vector3(12.0, 34.0, 0.0))


func test_scene_loader_failure_reveals_existing_scene_before_restoring_input() -> void:
	var loader: Node = auto_free(SCENE_LOADER_SCRIPT.new())
	add_child(loader)
	var player: FakeInputPlayer = auto_free(FakeInputPlayer.new())
	add_child(player)
	player.add_to_group(&"player")
	loader.set("_is_loading", true)
	loader.set("_pending_fade", true)
	var reveal_requests: Array[bool] = []
	var fade_recorder := func(_color: Color, _duration: float, fade_in: bool) -> void:
		reveal_requests.append(fade_in)
	GameEvents.fade_requested.connect(fade_recorder)

	await assert_error(func() -> void:
		loader.call("_recover_from_load_failure", "test failure")
	).is_push_error("SceneLoader: test failure")

	assert_array(reveal_requests).contains_exactly([false])
	assert_array(player.received_states).is_empty()
	assert_bool(loader.get("_is_loading")).is_true()
	assert_int(loader.get("_phase")).is_equal(3)
	await get_tree().create_timer(0.45).timeout
	if GameEvents.fade_requested.is_connected(fade_recorder):
		GameEvents.fade_requested.disconnect(fade_recorder)
	assert_array(player.received_states).contains_exactly([true])
	assert_bool(loader.get("_is_loading")).is_false()
	assert_int(loader.get("_phase")).is_equal(0)


func test_scene_loader_notifies_before_unlocking_new_player_input() -> void:
	var loader: Node = auto_free(SCENE_LOADER_SCRIPT.new())
	add_child(loader)
	var player: FakeInputPlayer = auto_free(FakeInputPlayer.new())
	add_child(player)
	player.add_to_group(&"player")
	loader.set("_is_loading", true)
	loader.set("_pending_fade", false)
	loader.set("_pending_position", Vector3(48.0, 96.0, 0.0))
	var notification_state := {
		"input_states": [] as Array[bool],
		"is_loading": false,
	}
	var recorder := func() -> void:
		notification_state["input_states"] = player.received_states.duplicate()
		notification_state["is_loading"] = loader.get("_is_loading")
	GameEvents.after_scene_loaded.connect(recorder)

	loader.call("_finish_scene_change")

	if GameEvents.after_scene_loaded.is_connected(recorder):
		GameEvents.after_scene_loaded.disconnect(recorder)
	assert_array(notification_state["input_states"]).contains_exactly([false])
	assert_bool(notification_state["is_loading"]).is_true()
	assert_array(player.received_states).contains_exactly([false, true])
	assert_vector(player.global_position).is_equal(Vector2(48.0, 96.0))
	assert_bool(loader.get("_is_loading")).is_false()


class FakeInputPlayer extends Node2D:
	var received_states: Array[bool] = []

	func set_gameplay_input_active(active: bool) -> void:
		received_states.append(active)
