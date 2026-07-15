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


func test_camera_refreshes_transformed_rectangle_bounds() -> void:
	var bounds_area := auto_free(Area2D.new()) as Area2D
	bounds_area.add_to_group(&"camera_bounds")
	bounds_area.global_position = Vector2(400.0, 240.0)
	add_child(bounds_area)
	var shape_node := CollisionShape2D.new()
	shape_node.position = Vector2(20.0, 10.0)
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(800.0, 480.0)
	shape_node.shape = rectangle
	bounds_area.add_child(shape_node)

	var camera := auto_free(CameraControl.new()) as CameraControl
	camera.follow_player = false
	add_child(camera)
	await get_tree().process_frame
	camera._refresh_bounds()

	assert_bool(camera.get("_has_bounds")).is_true()
	assert_vector((camera.get("_bounds") as Rect2).position).is_equal(Vector2(20.0, 10.0))
	assert_vector((camera.get("_bounds") as Rect2).size).is_equal(Vector2(800.0, 480.0))


func test_camera_clamps_using_640_by_360_logical_viewport() -> void:
	var camera := auto_free(CameraControl.new()) as CameraControl
	camera.follow_player = false
	add_child(camera)
	await get_tree().process_frame
	camera.set("_has_bounds", true)
	camera.set("_bounds", Rect2(0.0, 0.0, 1280.0, 720.0))

	var clamped := camera._clamp_position_to_bounds(Vector2(-100.0, 900.0))

	assert_vector(camera.get_viewport_rect().size).is_equal(Vector2(640.0, 360.0))
	assert_vector(clamped).is_equal(Vector2(320.0, 540.0))


func test_camera_centers_axis_when_bounds_are_smaller_than_viewport() -> void:
	var camera := auto_free(CameraControl.new()) as CameraControl
	camera.follow_player = false
	add_child(camera)
	await get_tree().process_frame
	camera.set("_has_bounds", true)
	camera.set("_bounds", Rect2(100.0, 80.0, 320.0, 180.0))

	assert_vector(camera._clamp_position_to_bounds(Vector2.ZERO)).is_equal(Vector2(260.0, 170.0))


func test_camera_shake_resets_offset_after_duration() -> void:
	var camera := auto_free(CameraControl.new()) as CameraControl
	camera.follow_player = false
	add_child(camera)
	camera._on_camera_shake_requested(1.0, 0.05)
	camera._process(0.06)

	assert_vector(camera.offset).is_equal(Vector2.ZERO)
