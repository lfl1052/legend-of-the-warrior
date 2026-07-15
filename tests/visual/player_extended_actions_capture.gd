extends Node

const LEVEL := preload("res://scenes/levels/level_demo.tscn")
const CAPTURES := {
	"land": {"player": Vector2(0.0, 492.0), "camera": Vector2(0.0, 460.0), "time": 0.1},
	"crouch": {"player": Vector2(0.0, 492.0), "camera": Vector2(0.0, 460.0), "time": 0.3},
	"heal": {"player": Vector2(0.0, 492.0), "camera": Vector2(0.0, 460.0), "time": 0.4},
	"block": {"player": Vector2(0.0, 492.0), "camera": Vector2(0.0, 460.0), "time": 0.3},
	"climb": {"player": Vector2(-600.0, 458.0), "camera": Vector2(-600.0, 460.0), "time": 0.4},
	"slide": {"player": Vector2(0.0, 492.0), "camera": Vector2(0.0, 460.0), "time": 0.24},
}


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	var player := level.get_node("Player") as PlayerController
	var camera := level.get_node("Camera2D") as CameraControl
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	player.set_gameplay_input_active(false)
	player.set_physics_process(false)
	camera.follow_player = false

	var output_dir := ProjectSettings.globalize_path("res://reports/playtest")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for animation_name: StringName in CAPTURES:
		var capture: Dictionary = CAPTURES[animation_name]
		player.global_position = capture["player"]
		camera.global_position = capture["camera"]
		if animation_name == &"slide":
			player._begin_slide(1.0)
		animation_player.play(animation_name)
		animation_player.seek(float(capture["time"]), true)
		player._update_sprite_frame()
		await get_tree().process_frame
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		var image := get_viewport().get_texture().get_image()
		if image == null:
			push_error("player action capture: 当前显示驱动不支持截图")
			get_tree().quit(1)
			return
		var path := output_dir.path_join("player_%s.png" % animation_name)
		if image.save_png(path) != OK:
			push_error("player action capture: 保存失败 %s" % path)
			get_tree().quit(1)
			return
		print("player action capture: %s" % path)

	player._end_slide()
	player.global_position = Vector2(0.0, 492.0)
	camera.global_position = Vector2(0.0, 460.0)
	player.set_gameplay_input_active(true)
	var interaction_target := Node2D.new()
	interaction_target.add_to_group(&"interactable")
	interaction_target.global_position = player.global_position + Vector2(20.0, 0.0)
	level.add_child(interaction_target)
	var sign := player.get_node("Sign") as Sign
	sign._try_capture_target(interaction_target)
	sign._process(0.0)
	var prompt_animation := sign.get_node("PromptAnimationPlayer") as AnimationPlayer
	prompt_animation.seek(0.12, true)
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	var prompt_image := get_viewport().get_texture().get_image()
	var prompt_path := output_dir.path_join("player_interaction_prompt.png")
	if prompt_image == null or prompt_image.save_png(prompt_path) != OK:
		push_error("player action capture: 交互提示截图失败")
		get_tree().quit(1)
		return
	print("player action capture: %s" % prompt_path)
	get_tree().quit()
