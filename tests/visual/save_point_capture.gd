extends Node

const LEVEL := preload("res://scenes/levels/level_demo.tscn")


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	var player := level.get_node("Player") as PlayerController
	var camera := level.get_node("Camera2D") as CameraControl
	var save_point := level.get_node("SavePoint") as SavePoint
	player.set_gameplay_input_active(false)
	player.set_physics_process(false)
	player.global_position = Vector2(70.0, 492.0)
	camera.follow_player = false
	camera.global_position = Vector2(160.0, 460.0)
	var output_dir := ProjectSettings.globalize_path("res://reports/playtest")
	DirAccess.make_dir_recursive_absolute(output_dir)

	await _save_frame(output_dir.path_join("save_point_inactive.png"))
	save_point.load_save_data({"float_data": {save_point.get_save_id() + "_done": 1.0}})
	await _save_frame(output_dir.path_join("save_point_active.png"))
	GameEvents.raise_reward_notification(&"save-success", {
		"notification_chinese": "进度已保存",
		"notification_english": "Progress saved",
		"_progression_applied": true,
	})
	await get_tree().create_timer(0.22).timeout
	await _save_frame(output_dir.path_join("save_point_success.png"))
	await get_tree().create_timer(2.4).timeout
	save_point.load_save_data({"float_data": {}})
	GameEvents.raise_reward_notification(&"save-failed", {
		"notification_chinese": "保存失败，请检查磁盘空间",
		"notification_english": "Save failed. Check available storage",
		"_progression_applied": true,
		"major": true,
	})
	await get_tree().create_timer(0.22).timeout
	await _save_frame(output_dir.path_join("save_point_failure.png"))
	get_tree().quit()


func _save_frame(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	var image := get_viewport().get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		push_error("save point capture: 保存失败 %s" % path)
		get_tree().quit(1)
		return
	print("save point capture: %s" % path)
