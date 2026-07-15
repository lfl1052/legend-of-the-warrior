extends GdUnitTestSuite

const MENU_SCENE := preload("res://scenes/levels/warrior_menu.tscn")
const COURSE_TREE_PATH := \
		"res://art/imported/Legacy-Fantasy-High Forest/Map Assets/Trees/Green-Tree.png"


func test_menu_uses_course_forest_asset_in_three_parallax_layers() -> void:
	# Arrange
	var menu := auto_free(MENU_SCENE.instantiate()) as Node

	# Act / Assert
	for layer_path: String in ["DistantForest", "MidForest", "NearForest"]:
		var layer: Node = menu.get_node_or_null(layer_path)
		assert_bool(layer is Parallax2D).is_true()
		assert_vector((layer as Parallax2D).repeat_size).is_equal(Vector2(640.0, 0.0))

	var tree := menu.get_node("DistantForest/TreeLeft") as Sprite2D
	assert_object(tree.texture).is_not_null()
	assert_str(tree.texture.resource_path).is_equal(COURSE_TREE_PATH)
	assert_bool(tree.region_rect == Rect2(4.0, 720.0, 88.0, 208.0)).is_true()


func test_menu_background_has_looping_motion_and_readability_panel() -> void:
	# Arrange
	var menu := auto_free(MENU_SCENE.instantiate()) as Node
	var animation_player := menu.get_node("BackgroundAnimation") as AnimationPlayer
	var background := menu.get_node("Background") as ColorRect
	var readability_shade := menu.get_node("ReadabilityShade") as ColorRect

	# Act
	var animation: Animation = animation_player.get_animation(&"ambient_drift")

	# Assert
	assert_object(animation).is_not_null()
	assert_int(animation.loop_mode).is_equal(Animation.LOOP_LINEAR)
	assert_int(animation.get_track_count()).is_equal(3)
	assert_vector(background.size).is_equal(Vector2(640.0, 360.0))
	assert_vector(readability_shade.size).is_equal(Vector2(640.0, 360.0))

	var panel := menu.get_node_or_null("UI/MainMenu/MenuPanel") as Panel
	assert_object(panel).is_not_null()
	var style := panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_object(style).is_not_null()
	assert_float(style.bg_color.a).is_greater_equal(0.75)


func test_menu_keeps_existing_navigation_node_paths() -> void:
	# Arrange / Act
	var menu := auto_free(MENU_SCENE.instantiate()) as Node

	# Assert
	assert_object(menu.get_node_or_null("UI/MainMenu/Center/Buttons/NewGameButton")).is_not_null()
	assert_object(menu.get_node_or_null("UI/MainMenu/Center/Buttons/ContinueButton")).is_not_null()
	assert_object(menu.get_node_or_null("UI/MainMenu/Center/Buttons/ExitButton")).is_not_null()
