extends GdUnitTestSuite

const ACTORS := {
	"player": {
		"scene": "res://scenes/player/player.tscn",
		"visual": ".",
		"sprite": "Sprite",
		"grounded": true,
		"height_band": Vector2(1.0, 1.0),
	},
	"snail": {
		"scene": "res://scenes/enemy/snail.tscn",
		"visual": "Visual",
		"sprite": "Visual/Sprite2D",
		"grounded": true,
		"height_band": Vector2(0.55, 0.9),
	},
	"bee": {
		"scene": "res://scenes/enemy/bee.tscn",
		"visual": "Visual",
		"sprite": "Visual/Sprite2D",
		"grounded": false,
		"height_band": Vector2(0.8, 1.3),
	},
	"boar": {
		"scene": "res://scenes/enemy/boar.tscn",
		"visual": "Visual",
		"sprite": "Visual/Sprite2D",
		"grounded": true,
		"height_band": Vector2(0.8, 0.95),
	},
	"boss": {
		"scene": "res://scenes/enemy/boss_enemy.tscn",
		"visual": "Visual",
		"sprite": "Visual/Sprite2D",
		"grounded": true,
		"height_band": Vector2(1.25, 1.8),
	},
}


func test_active_actor_scenes_follow_visual_and_collision_structure() -> void:
	for actor_name: String in ACTORS:
		var actor := await _instantiate_actor(ACTORS[actor_name])
		assert_object(actor.get_node_or_null("CollisionShape2D")).is_not_null()
		assert_object(actor.get_node_or_null("AnimationPlayer")).is_not_null()
		assert_object(actor.get_node_or_null(ACTORS[actor_name]["sprite"])).is_not_null()


func test_active_actors_separate_body_and_hurtbox_colliders() -> void:
	for actor_name: String in ACTORS:
		var actor := await _instantiate_actor(ACTORS[actor_name])
		var body := actor.get_node("CollisionShape2D") as CollisionShape2D
		var hurtbox := actor.get_node_or_null("HurtBox") as HurtBox
		assert_object(hurtbox).is_not_null()
		var hurt_shape := hurtbox.get_node("CollisionShape2D") as CollisionShape2D
		assert_object(hurt_shape.shape).is_not_null()
		assert_object(hurt_shape.shape).is_not_same(body.shape)
		assert_float(_shape_half_height(hurt_shape.shape)).is_less_equal(
				_shape_half_height(body.shape))


func test_damage_intervals_are_tuned_by_combat_role() -> void:
	var player := await _instantiate_actor(ACTORS["player"])
	assert_float((player.get_node("Character") as Character).invulnerable_duration).is_equal(0.5)
	for actor_name in ["snail", "bee", "boar"]:
		var enemy := await _instantiate_actor(ACTORS[actor_name])
		assert_float((enemy.get_node("Character") as Character).invulnerable_duration).is_equal(0.18)
	var boss := await _instantiate_actor(ACTORS["boss"])
	assert_float((boss.get_node("Character") as Character).invulnerable_duration).is_equal(0.22)


func test_ground_actor_visible_feet_match_body_collider() -> void:
	for actor_name: String in ACTORS:
		var spec: Dictionary = ACTORS[actor_name]
		if not bool(spec["grounded"]):
			continue
		var actor := await _instantiate_actor(spec)
		var collider := actor.get_node("CollisionShape2D") as CollisionShape2D
		var sprite := actor.get_node(spec["sprite"]) as Sprite2D
		var visual := actor.get_node(spec["visual"]) as Node2D
		var body_bottom := collider.position.y + _shape_half_height(collider.shape)
		var visible_bottom := _visible_bottom(sprite, visual)
		assert_float(visible_bottom).is_equal_approx(body_bottom, 1.0)


func test_active_actor_visible_height_matches_authored_role() -> void:
	var player := await _instantiate_actor(ACTORS["player"])
	var player_height := _visible_height(
		player.get_node("Sprite") as Sprite2D,
		player as Node2D)
	for actor_name: String in ACTORS:
		var spec: Dictionary = ACTORS[actor_name]
		var actor := await _instantiate_actor(spec)
		var height := _visible_height(
			actor.get_node(spec["sprite"]) as Sprite2D,
			actor.get_node(spec["visual"]) as Node2D)
		var ratio := height / player_height
		var band: Vector2 = spec["height_band"]
		assert_float(ratio).is_between(band.x, band.y)


func test_player_animation_timelines_have_valid_frame_mappings() -> void:
	var player := await _instantiate_actor(ACTORS["player"]) as PlayerController
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	var sprite := player.get_node("Sprite") as Sprite2D
	var frame_count := sprite.hframes * sprite.vframes
	for animation_name: StringName in animation_player.get_animation_list():
		var frames: Array = player.get_sprite_animation_frames(animation_name)
		assert_array(frames).is_not_empty()
		for frame: int in frames:
			assert_int(frame).is_between(0, frame_count - 1)


func test_player_slide_and_combo_finisher_use_action_sheet() -> void:
	var player := await _instantiate_actor(ACTORS["player"]) as PlayerController
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	var sprite := player.get_node("Sprite") as Sprite2D
	var primary_texture := sprite.texture

	animation_player.play(&"slide")
	animation_player.seek(0.0, true)
	player._update_sprite_frame()
	assert_object(sprite.texture).is_equal(player.secondary_sprite_texture)
	assert_int(sprite.vframes).is_equal(7)
	assert_int(sprite.frame).is_equal(16)

	animation_player.play(&"attack3")
	animation_player.seek(0.0, true)
	player._update_sprite_frame()
	assert_object(sprite.texture).is_equal(player.secondary_sprite_texture)
	assert_int(sprite.frame).is_equal(32)

	animation_player.play(&"idle")
	animation_player.seek(0.0, true)
	player._update_sprite_frame()
	assert_object(sprite.texture).is_equal(primary_texture)
	assert_int(sprite.vframes).is_equal(11)


func test_player_walk_fall_and_wall_use_authored_action_rows() -> void:
	var player := await _instantiate_actor(ACTORS["player"]) as PlayerController
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	var sprite := player.get_node("Sprite") as Sprite2D
	var primary_texture := sprite.texture

	animation_player.play(&"walk")
	animation_player.seek(0.0, true)
	player._update_sprite_frame()
	assert_object(sprite.texture).is_equal(player.secondary_sprite_texture)
	assert_int(sprite.vframes).is_equal(7)
	assert_int(sprite.frame).is_equal(0)
	animation_player.seek(0.49, true)
	player._update_sprite_frame()
	assert_int(sprite.frame).is_equal(7)

	animation_player.play(&"fall")
	animation_player.seek(0.0, true)
	player._update_sprite_frame()
	assert_object(sprite.texture).is_equal(primary_texture)
	assert_int(sprite.vframes).is_equal(11)
	assert_int(sprite.frame).is_equal(32)
	animation_player.seek(0.39, true)
	player._update_sprite_frame()
	assert_int(sprite.frame).is_equal(37)

	animation_player.play(&"wall")
	animation_player.seek(0.0, true)
	player._update_sprite_frame()
	assert_object(sprite.texture).is_equal(player.secondary_sprite_texture)
	assert_int(sprite.vframes).is_equal(7)
	assert_int(sprite.frame).is_equal(24)
	animation_player.seek(0.39, true)
	player._update_sprite_frame()
	assert_int(sprite.frame).is_equal(27)


func test_player_skill_slash_uses_spell_cast_frames() -> void:
	var player := await _instantiate_actor(ACTORS["player"]) as PlayerController
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	var sprite := player.get_node("Sprite") as Sprite2D
	var primary_texture := sprite.texture

	animation_player.play(&"skill_slash")
	animation_player.seek(0.0, true)
	player._update_sprite_frame()
	assert_object(sprite.texture).is_equal(primary_texture)
	assert_int(sprite.vframes).is_equal(11)
	assert_int(sprite.frame).is_equal(64)

	animation_player.seek(0.4, true)
	player._update_sprite_frame()
	assert_int(sprite.frame).is_equal(69)


func test_player_extended_actions_use_authored_sprite_rows() -> void:
	var player := await _instantiate_actor(ACTORS["player"]) as PlayerController
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	var sprite := player.get_node("Sprite") as Sprite2D
	var primary_texture := sprite.texture
	var expected := {
		&"land": [primary_texture, 11, 38, 39],
		&"crouch": [primary_texture, 11, 72, 74],
		&"heal": [primary_texture, 11, 64, 71],
		&"block": [primary_texture, 11, 80, 82],
		&"climb": [player.secondary_sprite_texture, 7, 40, 47],
	}
	for animation_name: StringName in expected:
		var contract: Array = expected[animation_name]
		var animation := animation_player.get_animation(animation_name)
		animation_player.play(animation_name)
		animation_player.seek(0.0, true)
		player._update_sprite_frame()
		assert_object(sprite.texture).is_equal(contract[0])
		assert_int(sprite.vframes).is_equal(contract[1])
		assert_int(sprite.frame).is_equal(contract[2])
		animation_player.seek(animation.length - 0.01, true)
		player._update_sprite_frame()
		assert_int(sprite.frame).is_equal(contract[3])


func test_boar_animations_use_authored_frame_counts() -> void:
	var boar := await _instantiate_actor(ACTORS["boar"])
	var animation_player := boar.get_node("AnimationPlayer") as AnimationPlayer
	var sprite := boar.get_node("Visual/Sprite2D") as Sprite2D

	for animation_name in [&"idle", &"hurt"]:
		animation_player.play(animation_name)
		animation_player.seek(0.0, true)
		assert_int(sprite.hframes).is_equal(4)
	for animation_name in [&"walk", &"run"]:
		animation_player.play(animation_name)
		animation_player.seek(0.0, true)
		assert_int(sprite.hframes).is_equal(6)


func test_boar_scene_separates_body_and_attack_colliders() -> void:
	var boar := await _instantiate_actor(ACTORS["boar"])
	var body_shape := boar.get_node("CollisionShape2D") as CollisionShape2D
	var attack := boar.get_node("AttackBox") as Attack
	var attack_shape := attack.get_node("CollisionShape2D") as CollisionShape2D

	assert_object(body_shape.shape).is_not_null()
	assert_object(attack_shape.shape).is_not_null()
	assert_object(body_shape.shape).is_not_same(attack_shape.shape)


func test_boss_animation_player_owns_frame_tracks() -> void:
	var boss := await _instantiate_actor(ACTORS["boss"])
	var animation_player := boss.get_node("AnimationPlayer") as AnimationPlayer
	for animation_name in [&"idle", &"chase", &"skill_windup", &"skill_active", &"skill_recovery"]:
		var animation := animation_player.get_animation(animation_name)
		assert_object(animation).is_not_null()
		assert_int(animation.get_track_count()).is_greater(0)
		assert_str(String(animation.track_get_path(0))).is_equal("Visual/Sprite2D:frame")


func _instantiate_actor(spec: Dictionary) -> Node2D:
	var packed := load(spec["scene"]) as PackedScene
	assert_object(packed).is_not_null()
	var actor := auto_free(packed.instantiate()) as Node2D
	add_child(actor)
	await get_tree().process_frame
	return actor


func _shape_half_height(shape: Shape2D) -> float:
	if shape is CapsuleShape2D:
		return (shape as CapsuleShape2D).height * 0.5
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size.y * 0.5
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius
	return 0.0


func _visible_bottom(sprite: Sprite2D, visual: Node2D) -> float:
	var used := _frame_used_rect(sprite)
	var frame_size := _frame_size(sprite)
	var local_bottom := float(used.end.y) - frame_size.y * 0.5 + sprite.position.y
	return visual.position.y + local_bottom * absf(visual.scale.y)


func _visible_height(sprite: Sprite2D, visual: Node2D) -> float:
	return float(_frame_used_rect(sprite).size.y) * absf(visual.scale.y)


func _frame_used_rect(sprite: Sprite2D) -> Rect2i:
	var image := sprite.texture.get_image()
	var size := Vector2i(_frame_size(sprite))
	var frame_coords := Vector2i(sprite.frame % sprite.hframes, sprite.frame / sprite.hframes)
	return image.get_region(Rect2i(frame_coords * size, size)).get_used_rect()


func _frame_size(sprite: Sprite2D) -> Vector2:
	return sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
