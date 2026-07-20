extends Node
## 生成本轮成长 HUD 与 Boss 竞技场门锁的代表性截图。

const LEVEL := preload("res://scenes/levels/level_2.tscn")


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var level := LEVEL.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player := level.get_node("Player") as PlayerController
	var character := player.get_node("Character") as Character
	var progression := player.get_node("PlayerProgression") as PlayerProgression
	var camera := level.get_node("Camera2D") as CameraControl
	player.set_gameplay_input_active(false)
	camera.follow_player = false
	camera.global_position = Vector2(-2100.0, 460.0)
	character.current_health = 3.0
	character.current_power = 55.0
	await get_tree().process_frame
	await get_tree().process_frame
	_save_capture("player_hud")

	progression.unlock_slot(&"map")
	var map_panel := level.get_node("UI/HUD/MapPanel") as PlayerMapPanel
	map_panel.toggle_panel()
	await get_tree().process_frame
	_save_capture("player_map_panel")

	map_panel.hide_panel()
	player.global_position = Vector2(1600.0, 492.0)
	camera.global_position = Vector2(1850.0, 460.0)
	var boss := level.get_node("BossEnemy") as BossEnemy
	boss._engage_arena()
	await get_tree().physics_frame
	_save_capture("boss_arena_locked")
	get_tree().quit()


func _save_capture(capture_name: String) -> void:
	RenderingServer.force_draw(false)
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("HUD/Boss capture: 当前显示驱动不支持截图")
		get_tree().quit(1)
		return
	var output_dir := ProjectSettings.globalize_path("res://reports/playtest")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var path := output_dir.path_join("%s.png" % capture_name)
	if image.save_png(path) != OK:
		push_error("HUD/Boss capture: 保存失败 %s" % path)
		get_tree().quit(1)
		return
	print("HUD/Boss capture: %s" % path)
