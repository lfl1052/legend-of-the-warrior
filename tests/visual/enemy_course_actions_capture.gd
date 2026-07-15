extends Node

const LEVEL := preload("res://scenes/levels/level_2.tscn")
const CAPTURES := {
	"boar_wait": {
		"enemy": ^"BoarA",
		"camera": Vector2(-1700.0, 460.0),
		"player": Vector2(-1540.0, 492.0),
		"animation": &"idle",
		"time": 0.32,
	},
	"boar_chase": {
		"enemy": ^"BoarA",
		"camera": Vector2(-1700.0, 460.0),
		"player": Vector2(-1540.0, 492.0),
		"animation": &"run",
		"time": 0.21,
	},
	"snail_hide": {
		"enemy": ^"SnailA",
		"camera": Vector2(-1200.0, 460.0),
		"player": Vector2(-1060.0, 492.0),
		"animation": &"hide",
		"time": 0.31,
	},
	"snail_unhide": {
		"enemy": ^"SnailA",
		"camera": Vector2(-1200.0, 460.0),
		"player": Vector2(-1060.0, 492.0),
		"animation": &"unhide",
		"time": 0.2,
	},
	"bee_attack": {
		"enemy": ^"BeeA",
		"camera": Vector2(-360.0, 460.0),
		"player": Vector2(-360.0, 492.0),
		"animation": &"attack",
		"time": 0.2,
	},
	"bee_chase": {
		"enemy": ^"BeeA",
		"camera": Vector2(-360.0, 460.0),
		"player": Vector2(-280.0, 492.0),
		"animation": &"chase",
		"time": 0.2,
	},
}


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	var camera := level.get_node("Camera2D") as CameraControl
	var player := level.get_node("Player") as PlayerController
	camera.follow_player = false
	player.set_gameplay_input_active(false)
	player.set_physics_process(false)
	for path in [^"BoarA", ^"SnailA", ^"BeeA"]:
		var enemy := level.get_node(path) as Enemy
		enemy.set_process(false)
		enemy.set_physics_process(false)

	var output_dir := ProjectSettings.globalize_path("res://reports/playtest")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for capture_name: String in CAPTURES:
		var capture: Dictionary = CAPTURES[capture_name]
		var enemy := level.get_node(capture["enemy"]) as Enemy
		var animation_player := enemy.get_node("AnimationPlayer") as AnimationPlayer
		player.global_position = capture["player"]
		camera.global_position = capture["camera"]
		animation_player.play(capture["animation"])
		animation_player.seek(float(capture["time"]), true)
		await get_tree().process_frame
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		var image := get_viewport().get_texture().get_image()
		if image == null:
			push_error("enemy action capture: 当前显示驱动不支持截图")
			get_tree().quit(1)
			return
		var path := output_dir.path_join("enemy_%s.png" % capture_name)
		if image.save_png(path) != OK:
			push_error("enemy action capture: 保存失败 %s" % path)
			get_tree().quit(1)
			return
		print("enemy action capture: %s" % path)
	get_tree().quit()
