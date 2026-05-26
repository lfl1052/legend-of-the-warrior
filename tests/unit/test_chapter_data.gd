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
