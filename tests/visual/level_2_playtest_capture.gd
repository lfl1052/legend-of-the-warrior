extends Node
## 生成 level_2 的代表性可读性截图，输出到被 gitignore 的 reports/playtest/。

const LEVEL := preload("res://scenes/levels/level_2.tscn")
const CAPTURES := {
	"arrival": {"camera": Vector2(-1900.0, 460.0), "player": Vector2(-2240.0, 492.0)},
	"combine": {"camera": Vector2(-100.0, 460.0), "player": Vector2(-650.0, 492.0)},
	"boss": {"camera": Vector2(1850.0, 460.0), "player": Vector2(1500.0, 492.0)},
}


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame

	var camera := level.get_node_or_null("Camera2D") as CameraControl
	if camera == null:
		push_error("playtest capture: level_2 缺少 Camera2D")
		get_tree().quit(1)
		return
	camera.follow_player = false
	var player := level.get_node_or_null("Player") as PlayerController
	if player == null:
		push_error("playtest capture: level_2 缺少 Player")
		get_tree().quit(1)
		return
	player.set_gameplay_input_active(false)

	var output_dir := ProjectSettings.globalize_path("res://reports/playtest")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for capture_name: String in CAPTURES:
		var capture: Dictionary = CAPTURES[capture_name]
		player.global_position = capture["player"]
		player.velocity = Vector2.ZERO
		camera.global_position = capture["camera"]
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path := output_dir.path_join("level_2_%s.png" % capture_name)
		var error := image.save_png(path)
		if error != OK:
			push_error("playtest capture: 保存失败 %s" % path)
			get_tree().quit(1)
			return
		print("playtest capture: %s" % path)

	get_tree().quit()
