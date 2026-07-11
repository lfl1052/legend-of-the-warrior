extends GdUnitTestSuite

const GENERATED_ENEMIES := {
	"ThornSprout": {
		"scene": "res://scenes/enemy/thorn_sprout.tscn",
		"texture": "res://art/processed/enemies/generated/thorn_sprout/thorn_sprout_sheet.png",
		"body_size": Vector2(42, 48),
		"body_position": Vector2(0, -14),
		"attack_size": Vector2(70, 36),
		"attack_position": Vector2(0, -12),
		"damage": 1,
		"active_on_ready": false,
	},
	"SporeShroom": {
		"scene": "res://scenes/enemy/spore_shroom.tscn",
		"texture": "res://art/processed/enemies/generated/spore_shroom/spore_shroom_sheet.png",
		"body_size": Vector2(64, 44),
		"body_position": Vector2(0, -10),
		"attack_size": Vector2(88, 42),
		"attack_position": Vector2(0, -12),
		"damage": 1,
		"active_on_ready": false,
	},
	"RootStalker": {
		"scene": "res://scenes/enemy/root_stalker.tscn",
		"texture": "res://art/processed/enemies/generated/root_stalker/root_stalker_sheet.png",
		"body_size": Vector2(76, 84),
		"body_position": Vector2(0, -20),
		"attack_size": Vector2(132, 56),
		"attack_position": Vector2(0, -22),
		"damage": 2,
		"active_on_ready": true,
	},
}


func test_generated_enemy_scenes_load_with_core_combat_nodes() -> void:
	for enemy_name in GENERATED_ENEMIES.keys():
		var spec: Dictionary = GENERATED_ENEMIES[enemy_name]
		var packed := load(spec["scene"]) as PackedScene
		assert_object(packed).is_not_null()

		var enemy: Node = auto_free(packed.instantiate())
		add_child(enemy)
		await get_tree().process_frame

		assert_bool(enemy.is_in_group(&"enemy")).is_true()
		assert_object(enemy.get_node_or_null("Character")).is_not_null()
		assert_object(enemy.get_node_or_null("CollisionShape2D")).is_not_null()
		assert_object(enemy.get_node_or_null("AttackBox/CollisionShape2D")).is_not_null()
		assert_object(enemy.get_node_or_null("PhysicsCheck")).is_not_null()


func test_generated_enemy_scenes_expose_required_animations() -> void:
	for enemy_name in GENERATED_ENEMIES.keys():
		var spec: Dictionary = GENERATED_ENEMIES[enemy_name]
		var packed := load(spec["scene"]) as PackedScene
		var enemy: Node = auto_free(packed.instantiate())
		add_child(enemy)
		await get_tree().process_frame

		var animation_player := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
		assert_object(animation_player).is_not_null()
		assert_bool(animation_player.has_animation("idle")).is_true()
		assert_bool(animation_player.has_animation("walk")).is_true()
		assert_bool(animation_player.has_animation("hurt")).is_true()
		assert_bool(animation_player.has_animation("dead")).is_true()


func test_generated_enemy_textures_are_standardized_sprite_sheets() -> void:
	for enemy_name in GENERATED_ENEMIES.keys():
		var spec: Dictionary = GENERATED_ENEMIES[enemy_name]
		var texture := load(spec["texture"]) as Texture2D
		assert_object(texture).is_not_null()
		assert_vector(texture.get_size()).is_equal(Vector2(768, 768))


func test_level_2_places_generated_enemies() -> void:
	var packed := load("res://scenes/levels/level_2.tscn") as PackedScene
	assert_object(packed).is_not_null()

	var level: Node = auto_free(packed.instantiate())
	add_child(level)
	await get_tree().process_frame

	assert_object(level.get_node_or_null("ThornSproutA")).is_not_null()
	assert_object(level.get_node_or_null("SporeShroomA")).is_not_null()
	assert_object(level.get_node_or_null("RootStalkerA")).is_not_null()


func test_generated_enemy_collision_shapes_match_sprite_scale() -> void:
	for enemy_name in GENERATED_ENEMIES.keys():
		var spec: Dictionary = GENERATED_ENEMIES[enemy_name]
		var enemy: Node = await _instantiate_enemy(spec)

		var body_shape_node := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
		assert_object(body_shape_node).is_not_null()
		assert_vector(body_shape_node.position).is_equal(spec["body_position"])

		var body_shape := body_shape_node.shape as RectangleShape2D
		assert_object(body_shape).is_not_null()
		assert_vector(body_shape.size).is_equal(spec["body_size"])

		var visual := enemy.get_node_or_null("Visual") as Node2D
		var sprite := enemy.get_node_or_null("Visual/Sprite2D") as Sprite2D
		assert_object(visual).is_not_null()
		assert_object(sprite).is_not_null()

		var frame_size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
		var visual_size := Vector2(frame_size.x * visual.scale.x, frame_size.y * visual.scale.y)
		assert_bool(body_shape.size.x <= visual_size.x).is_true()
		assert_bool(body_shape.size.y <= visual_size.y).is_true()


func test_generated_enemy_attack_boxes_match_authored_damage_roles() -> void:
	for enemy_name in GENERATED_ENEMIES.keys():
		var spec: Dictionary = GENERATED_ENEMIES[enemy_name]
		var enemy: Node = await _instantiate_enemy(spec)

		var attack := enemy.get_node_or_null("AttackBox") as Attack
		assert_object(attack).is_not_null()
		assert_vector(attack.position).is_equal(spec["attack_position"])
		assert_int(attack.damage).is_equal(spec["damage"])
		assert_int(attack.collision_layer).is_equal(16)
		assert_int(attack.collision_mask).is_equal(2)
		assert_bool(attack.active_on_ready == bool(spec["active_on_ready"])).is_true()

		var attack_shape_node := enemy.get_node_or_null("AttackBox/CollisionShape2D") as CollisionShape2D
		assert_object(attack_shape_node).is_not_null()
		var attack_shape := attack_shape_node.shape as RectangleShape2D
		assert_object(attack_shape).is_not_null()
		assert_vector(attack_shape.size).is_equal(spec["attack_size"])
		assert_bool(attack_shape.size.x >= spec["body_size"].x).is_true()


func test_thorn_sprout_uses_telegraphed_guard_attack_window() -> void:
	var spec: Dictionary = GENERATED_ENEMIES["ThornSprout"]
	var thorn: Node = await _instantiate_enemy(spec)
	assert_object(thorn).is_not_null()
	assert_bool(thorn.has_method("tick_guard_attack")).is_true()
	var hitbox := thorn.get_node("AttackBox/CollisionShape2D") as CollisionShape2D
	assert_bool(hitbox.disabled).is_true()

	thorn.set("_windup_timer", 0.01)
	thorn.call("tick_guard_attack", 0.02)
	thorn.call("tick_guard_attack", 0.01)
	await get_tree().process_frame

	assert_bool(bool(thorn.call("is_guard_attack_active"))).is_true()
	assert_bool(hitbox.disabled).is_false()


func test_spore_shroom_uses_telegraphed_pulse_window() -> void:
	var spec: Dictionary = GENERATED_ENEMIES["SporeShroom"]
	var spore: Node = await _instantiate_enemy(spec)
	assert_bool(spore.has_method("is_spore_pulse_active")).is_true()
	var hitbox := spore.get_node("AttackBox/CollisionShape2D") as CollisionShape2D
	assert_bool(hitbox.disabled).is_true()

	spore.set("_pulse_windup_timer", 0.01)
	spore.call("_tick_spore_pulse", 0.02)
	spore.call("_tick_spore_pulse", 0.01)
	await get_tree().process_frame

	assert_bool(bool(spore.call("is_spore_pulse_active"))).is_true()
	assert_bool(hitbox.disabled).is_false()


func _instantiate_enemy(spec: Dictionary) -> Node:
	var packed := load(spec["scene"]) as PackedScene
	assert_object(packed).is_not_null()
	var enemy: Node = auto_free(packed.instantiate())
	add_child(enemy)
	await get_tree().process_frame
	return enemy
