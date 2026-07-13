extends GdUnitTestSuite


func test_enemy_detects_player_with_clear_line_of_sight() -> void:
	var setup := await _create_perception_setup(false)
	var enemy: Enemy = setup["enemy"]

	assert_bool(enemy.found_player()).is_true()


func test_enemy_does_not_detect_player_through_world_collision() -> void:
	var setup := await _create_perception_setup(true)
	var enemy: Enemy = setup["enemy"]

	assert_bool(enemy.found_player()).is_false()


func _create_perception_setup(with_wall: bool) -> Dictionary:
	var root := auto_free(Node2D.new()) as Node2D
	add_child(root)

	var enemy := Enemy.new()
	enemy.check_distance = 200.0
	enemy.requires_line_of_sight = true
	enemy.global_position = Vector2.ZERO
	root.add_child(enemy)
	_add_body_shape(enemy, Vector2(20.0, 32.0))

	var player := CharacterBody2D.new()
	player.collision_layer = 2
	player.collision_mask = 1
	player.add_to_group(&"player")
	player.global_position = Vector2(100.0, 0.0)
	root.add_child(player)
	_add_body_shape(player, Vector2(20.0, 32.0))

	if with_wall:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		wall.global_position = Vector2(50.0, -12.0)
		root.add_child(wall)
		_add_body_shape(wall, Vector2(12.0, 80.0))

	await get_tree().physics_frame
	await get_tree().physics_frame
	return {"enemy": enemy, "player": player}


func _add_body_shape(body: CollisionObject2D, size: Vector2) -> void:
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
