extends Node

const MENU := preload("res://scenes/levels/warrior_menu.tscn")


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	add_child(MENU.instantiate())
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var output_dir := ProjectSettings.globalize_path("res://reports/playtest")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var path := output_dir.path_join("warrior_menu.png")
	var error := image.save_png(path)
	if error != OK:
		push_error("menu capture: 保存失败 %s" % path)
		get_tree().quit(1)
		return
	print("menu capture: %s (%s)" % [path, image.get_size()])
	get_tree().quit()
