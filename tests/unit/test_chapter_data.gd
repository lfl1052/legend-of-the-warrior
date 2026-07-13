extends GdUnitTestSuite


func test_chapter_1_includes_demo_and_level_2() -> void:
	# Arrange
	RuntimeData._reload_all()
	# Act
	var chapter := RuntimeData.try_get_chapter(&"chapter_1")
	var scene_ids: Array = chapter.get("scene_ids", [])
	# Assert
	assert_dict(chapter).is_not_empty()
	assert_bool(scene_ids.has("level_demo")).is_true()
	assert_bool(scene_ids.has("level_2")).is_true()


func test_level_2_layout_defines_long_route_and_platform_sequence() -> void:
	RuntimeData._reload_all()

	var layout := RuntimeData.try_get_level_layout(&"level_2")
	var ground: Dictionary = layout.get("ground", {})
	var platforms: Array = layout.get("platforms", [])
	var segments: Array = ground.get("segments", [])

	assert_dict(layout).is_not_empty()
	assert_int(int(ground.get("right", 0)) - int(ground.get("left", 0))).is_greater_equal(300)
	assert_array(segments).is_empty()
	assert_int(platforms.size()).is_greater_equal(6)
	var platform_rows: Dictionary = {}
	for platform: Dictionary in platforms:
		platform_rows[int(platform.get("top_row", 32))] = true
		var platform_bottom := (
			int(platform.get("top_row", 32)) + int(platform.get("depth", 0)))
		if bool(platform.get("merge_with_ground", false)):
			assert_int(platform_bottom).is_equal(int(ground.get("top_row", 32)))
		else:
			assert_int(platform_bottom).is_less_equal(int(ground.get("top_row", 32)) - 2)
	assert_int(platform_rows.size()).is_greater_equal(2)
