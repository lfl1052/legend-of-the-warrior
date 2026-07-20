extends GdUnitTestSuite

const HUD_SCENE := preload("res://scenes/ui/gameplay_hud.tscn")
const BASE_UI_PATH := "res://art/imported/Legacy-Fantasy-High Forest/HUD/Base-UI.png"
const PLAYER_PROGRESSION_SCRIPT := preload("res://scripts/player/player_progression.gd")


func test_player_hud_uses_course_base_ui_for_status_layers() -> void:
	var hud := auto_free(HUD_SCENE.instantiate()) as Control
	add_child(hud)
	await get_tree().process_frame

	var stat_bar := hud.get_node("PlayerStatBar") as PlayerStatBar
	assert_object(stat_bar).is_not_null()
	var progression_panel := hud.get_node("ProgressionPanel") as PlayerProgressionPanel
	assert_object(progression_panel).is_not_null()
	assert_bool(progression_panel.visible).is_false()
	assert_object(hud.get_node("MapPanel") as PlayerMapPanel).is_not_null()
	# 第 28 课的结构是头像旁两条独立状态条，不能退化为带文本的大面板。
	for path in ["HealthFrame", "PowerFrame"]:
		var frame := stat_bar.get_node_or_null(path) as TextureRect
		assert_object(frame).is_not_null()
		assert_bool(frame.texture is AtlasTexture).is_true()
		assert_str((frame.texture as AtlasTexture).atlas.resource_path).is_equal(BASE_UI_PATH)
	assert_object(stat_bar.get_node_or_null("StatBackdrop")).is_null()
	assert_object(stat_bar.get_node_or_null("HealthTag")).is_null()
	assert_object(stat_bar.get_node_or_null("PowerTag")).is_null()
	assert_float(stat_bar.size.x).is_less_equal(92.0)
	var portrait_frame := stat_bar.get_node("PortraitFrame") as TextureRect
	assert_float(portrait_frame.size.x).is_equal(28.0)
	assert_float(portrait_frame.size.y).is_equal(28.0)
	var portrait_clip := stat_bar.get_node_or_null("PortraitClip") as Control
	assert_object(portrait_clip).is_not_null()
	assert_bool(portrait_clip.clip_contents).is_true()
	var portrait := portrait_clip.get_node_or_null("PlayerPortrait") as Sprite2D
	assert_object(portrait).is_not_null()
	assert_float(portrait.scale.x).is_equal(1.25)
	assert_float(portrait.scale.y).is_equal(1.25)
	for path in ["PortraitFrame", "HealthDelayBar", "HealthBar", "PowerBar"]:
		var node := stat_bar.get_node(path) as Control
		var texture: Texture2D = null
		if node is TextureRect:
			texture = (node as TextureRect).texture
		elif node is TextureProgressBar:
			texture = (node as TextureProgressBar).texture_progress
		assert_bool(texture is AtlasTexture).is_true()
		assert_str((texture as AtlasTexture).atlas.resource_path).is_equal(BASE_UI_PATH)
	var health_delay := stat_bar.get_node("HealthDelayBar") as TextureProgressBar
	var health := stat_bar.get_node("HealthBar") as TextureProgressBar
	var power := stat_bar.get_node("PowerBar") as TextureProgressBar
	assert_float(health.position.x).is_equal(31.0)
	assert_float(health_delay.position.y).is_equal(health.position.y)
	assert_int(health_delay.get_index()).is_less(health.get_index())
	assert_float(power.position.y - health.position.y).is_equal(11.0)


func test_progression_panel_only_appears_for_an_actionable_unlock() -> void:
	var player: Node = auto_free(Node.new()) as Node
	player.add_to_group(&"player")
	add_child(player)
	var progression: PlayerProgression = auto_free(PLAYER_PROGRESSION_SCRIPT.new()) as PlayerProgression
	progression.save_id = "test_player_hud_progression"
	player.add_child(progression)
	var hud: Control = auto_free(HUD_SCENE.instantiate()) as Control
	add_child(hud)
	await get_tree().process_frame

	var panel: PlayerProgressionPanel = hud.get_node("ProgressionPanel") as PlayerProgressionPanel
	assert_bool(panel.visible).is_false()
	progression.upgrade_tokens = 1
	panel.refresh()
	assert_bool(panel.visible).is_true()
