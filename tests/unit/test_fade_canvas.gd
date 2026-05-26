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
