extends GdUnitTestSuite


func test_fade_in_covers_screen_and_fade_out_reveals_scene() -> void:
	var fade_canvas: FadeCanvas = auto_free(FadeCanvas.new())
	add_child(fade_canvas)
	await get_tree().process_frame

	var fade_rect := fade_canvas.get_child(0) as ColorRect
	assert_object(fade_rect).is_not_null()

	GameEvents.raise_fade_in(Color.BLACK, 0.0)
	assert_float(fade_rect.color.a).is_equal(1.0)

	GameEvents.raise_fade_out(Color.BLACK, 0.0)
	assert_float(fade_rect.color.a).is_equal(0.0)


func test_nonzero_fade_completes_with_requested_color() -> void:
	var fade_canvas: FadeCanvas = auto_free(FadeCanvas.new())
	add_child(fade_canvas)
	await get_tree().process_frame
	var fade_rect := fade_canvas.get_child(0) as ColorRect
	var tint := Color(0.2, 0.5, 0.8, 1.0)

	GameEvents.raise_fade_in(tint, 0.03)
	await get_tree().create_timer(0.06).timeout

	assert_float(fade_rect.color.r).is_equal_approx(tint.r, 0.01)
	assert_float(fade_rect.color.g).is_equal_approx(tint.g, 0.01)
	assert_float(fade_rect.color.b).is_equal_approx(tint.b, 0.01)
	assert_float(fade_rect.color.a).is_equal_approx(1.0, 0.01)


func test_latest_fade_request_cancels_previous_tween() -> void:
	var fade_canvas: FadeCanvas = auto_free(FadeCanvas.new())
	add_child(fade_canvas)
	await get_tree().process_frame
	var fade_rect := fade_canvas.get_child(0) as ColorRect

	GameEvents.raise_fade_in(Color.BLACK, 0.2)
	await get_tree().create_timer(0.03).timeout
	GameEvents.raise_fade_in(Color(0.9, 0.2, 0.1, 1.0), 0.0)

	assert_float(fade_rect.color.r).is_equal_approx(0.9, 0.01)
	assert_float(fade_rect.color.g).is_equal_approx(0.2, 0.01)
	assert_float(fade_rect.color.b).is_equal_approx(0.1, 0.01)
	assert_float(fade_rect.color.a).is_equal_approx(1.0, 0.01)


func test_fade_tween_completes_while_scene_tree_is_paused() -> void:
	var fade_canvas: FadeCanvas = auto_free(FadeCanvas.new())
	add_child(fade_canvas)
	await get_tree().process_frame
	var fade_rect := fade_canvas.get_child(0) as ColorRect

	get_tree().paused = true
	GameEvents.raise_fade_in(Color.BLACK, 0.03)
	await get_tree().create_timer(0.07, true).timeout
	get_tree().paused = false

	assert_float(fade_rect.color.a).is_equal_approx(1.0, 0.01)
