extends GdUnitTestSuite


func test_project_uses_pixel_art_logical_viewport_and_integer_scale() -> void:
	var viewport_size := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width")),
		int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	var window_size := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/window_width_override")),
		int(ProjectSettings.get_setting("display/window/size/window_height_override")))

	assert_vector(viewport_size).is_equal(Vector2i(640, 360))
	assert_vector(window_size).is_equal(Vector2i(1280, 720))
	assert_str(ProjectSettings.get_setting("display/window/stretch/scale_mode")).is_equal("integer")


func test_camera_dead_zone_holds_until_target_exits_margin() -> void:
	var camera := auto_free(CameraControl.new()) as CameraControl
	camera.follow_player = false
	camera.dead_zone = Vector2(48.0, 24.0)
	add_child(camera)
	await get_tree().process_frame

	assert_vector(camera._dead_zone_corrected_position(Vector2.ZERO, Vector2(30.0, 20.0))).is_equal(Vector2.ZERO)
	assert_vector(camera._dead_zone_corrected_position(Vector2.ZERO, Vector2(80.0, 40.0))).is_equal(Vector2(32.0, 16.0))


func test_camera_snap_uses_vertical_composition_offset() -> void:
	var player := auto_free(CharacterBody2D.new()) as CharacterBody2D
	player.add_to_group(&"player")
	player.global_position = Vector2(240.0, 300.0)
	add_child(player)

	var camera := auto_free(CameraControl.new()) as CameraControl
	camera.follow_player = false
	camera.vertical_offset = -64.0
	add_child(camera)
	await get_tree().process_frame
	camera._snap_to_follow_target()

	assert_vector(camera.global_position).is_equal(Vector2(240.0, 236.0))
