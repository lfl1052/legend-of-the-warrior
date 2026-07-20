extends GdUnitTestSuite

const MAP_PANEL_SCRIPT := preload("res://scripts/ui/player_map_panel.gd")


func test_map_panel_reads_runtime_scene_link_json() -> void:
	var panel := auto_free(MAP_PANEL_SCRIPT.new()) as PlayerMapPanel
	add_child(panel)
	await get_tree().process_frame

	var routes := panel._collect_routes("level_demo")
	assert_array(routes).is_not_empty()
	assert_str(panel._build_route_info(routes)).contains("demo_to_level_2")
