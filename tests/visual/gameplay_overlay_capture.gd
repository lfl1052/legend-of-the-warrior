extends Node

func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var overlay := GameplayOverlay.new()
	add_child(overlay)
	await get_tree().process_frame
	var output_dir := ProjectSettings.globalize_path("res://reports/playtest")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for state in [&"game_over", &"pause"]:
		if state == &"game_over":
			overlay.show_game_over()
		else:
			overlay.show_pause()
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		var image := get_viewport().get_texture().get_image()
		if image == null:
			push_error("gameplay overlay capture: 当前显示驱动不支持截图")
			get_tree().quit(1)
			return
		var path := output_dir.path_join("gameplay_%s.png" % String(state))
		if image.save_png(path) != OK:
			push_error("gameplay overlay capture: 保存失败 %s" % path)
			get_tree().quit(1)
			return
		print("gameplay overlay capture: %s" % path)
	get_tree().quit()
