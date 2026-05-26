extends GdUnitTestSuite


func test_physics_check_patrol_turns_on_wall_in_current_direction() -> void:
	var check: PhysicsCheck = auto_free(PhysicsCheck.new()) as PhysicsCheck
	add_child(check)
	await get_tree().process_frame
	check.is_ground = true
	check.touch_right = true

	assert_bool(check.should_turn_for_patrol(1)).is_true()


func test_physics_check_patrol_turns_when_front_ground_missing() -> void:
	var check: PhysicsCheck = auto_free(PhysicsCheck.new()) as PhysicsCheck
	add_child(check)
	await get_tree().process_frame
	check.is_ground = true

	assert_bool(check.should_turn_for_patrol(1)).is_true()


func test_physics_check_patrol_continues_when_ground_ahead_exists() -> void:
	var root: Node2D = auto_free(Node2D.new()) as Node2D
	add_child(root)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	root.add_child(body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64.0, 8.0)
	shape.shape = rect
	shape.position = Vector2(16.0, 24.0)
	body.add_child(shape)
	var check := PhysicsCheck.new()
	check.auto_derive_offsets = false
	check.bottom_offset = Vector2(0.0, 24.0)
	check.front_ground_offset = Vector2(16.0, 24.0)
	root.add_child(check)
	await get_tree().physics_frame

	assert_bool(check.should_turn_for_patrol(1)).is_false()
