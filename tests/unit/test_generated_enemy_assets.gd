extends GdUnitTestSuite

const GENERATED_ENEMIES := {
	"ThornSprout": {
		"scene": "res://scenes/enemy/thorn_sprout.tscn",
		"texture": "res://art/processed/enemies/generated/thorn_sprout/thorn_sprout_sheet.png",
	},
	"SporeShroom": {
		"scene": "res://scenes/enemy/spore_shroom.tscn",
		"texture": "res://art/processed/enemies/generated/spore_shroom/spore_shroom_sheet.png",
	},
	"RootStalker": {
		"scene": "res://scenes/enemy/root_stalker.tscn",
		"texture": "res://art/processed/enemies/generated/root_stalker/root_stalker_sheet.png",
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
