extends Node
## 生成 level_2 的代表性可读性截图，输出到被 gitignore 的 reports/playtest/。

const LEVEL := preload("res://scenes/levels/level_2.tscn")
const CAPTURES := {
	"arrival": {"camera": Vector2(-2100.0, 460.0), "player": Vector2(-2240.0, 492.0)},
	"walk": {
		"camera": Vector2(-2100.0, 460.0),
		"player": Vector2(-2240.0, 492.0),
		"animation": &"walk",
		"animation_position": 0.25,
	},
	"fall": {
		"camera": Vector2(-2100.0, 460.0),
		"player": Vector2(-2050.0, 400.0),
		"animation": &"fall",
		"animation_position": 0.2,
	},
	"wall": {
		"camera": Vector2(-2100.0, 460.0),
		"player": Vector2(-2030.0, 405.0),
		"animation": &"wall",
		"animation_position": 0.2,
	},
	"boar": {"camera": Vector2(-1700.0, 460.0), "player": Vector2(-1540.0, 492.0)},
	"skill_slash": {
		"camera": Vector2(-1700.0, 460.0),
		"player": Vector2(-1540.0, 492.0),
		"facing": -1,
		"animation": &"skill_slash",
		"animation_position": 0.4,
	},
	"combine": {"camera": Vector2(-500.0, 460.0), "player": Vector2(-650.0, 492.0)},
	"boss": {"camera": Vector2(1700.0, 460.0), "player": Vector2(1500.0, 492.0)},
	"boss_reward": {"camera": Vector2(1700.0, 460.0), "player": Vector2(1500.0, 492.0)},
	"water_hazard": {"camera": Vector2(1120.0, 460.0), "player": Vector2(1120.0, 492.0)},
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
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	var slash_skill := player.get_node("SkillSlash") as PlayerSkillSlash
	var boss := level.get_node_or_null("BossEnemy") as BossEnemy
	for capture_name: String in CAPTURES:
		var capture: Dictionary = CAPTURES[capture_name]
		slash_skill.cancel_preview()
		if boss != null:
			boss.set_skill_telegraph_phase(&"off")
		player.is_using_skill = false
		animation_player.play(&"idle")
		player._facing = int(capture.get("facing", 1))
		var player_sprite := player.get_node("Sprite") as Sprite2D
		player_sprite.scale.x = absf(player_sprite.scale.x) * player._facing
		player.global_position = capture["player"]
		player.velocity = Vector2.ZERO
		camera.global_position = capture["camera"]
		if capture.has("animation"):
			player.is_using_skill = true
			animation_player.play(capture["animation"])
			animation_player.seek(float(capture["animation_position"]), true)
			player._update_sprite_frame()
		if capture_name == "skill_slash":
			slash_skill._begin_preview(player._facing)
			slash_skill.set_preview_active()
		elif capture_name == "boss" and boss != null:
			boss.set_skill_telegraph_phase(&"windup")
		elif capture_name == "boss_reward":
			GameEvents.raise_reward_notification(&"upgrade-token", {
				"amount": 3,
				"notification_chinese": "Boss 已击败：获得 3 枚升级代币",
				"notification_english": "Boss defeated: 3 upgrade tokens gained",
				"_progression_applied": true,
				"major": true,
			})
			await get_tree().create_timer(0.22).timeout
		await get_tree().process_frame
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		var image := get_viewport().get_texture().get_image()
		if image == null:
			push_error("playtest capture: 当前显示驱动不支持截图，请使用 windows + opengl3")
			get_tree().quit(1)
			return
		var path := output_dir.path_join("level_2_%s.png" % capture_name)
		var error := image.save_png(path)
		if error != OK:
			push_error("playtest capture: 保存失败 %s" % path)
			get_tree().quit(1)
			return
		print("playtest capture: %s" % path)

	get_tree().quit()
