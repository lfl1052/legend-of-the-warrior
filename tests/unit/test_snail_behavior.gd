extends GdUnitTestSuite

const SNAIL_SCENE := preload("res://scenes/enemy/snail.tscn")

var _snail: Snail
var _player: Node2D


func before_test() -> void:
	DataManager.override_save_paths_for_test("user://TEST_SNAIL_BEHAVIOR/")
	_snail = auto_free(SNAIL_SCENE.instantiate()) as Snail
	_snail.auto_register_save = false
	_snail.front_sight_distance = 120.0
	_snail.check_distance = 40.0
	# 本套件只验证前后方向窗口；世界遮挡由 test_enemy_perception 独立覆盖。
	_snail.requires_line_of_sight = false
	_snail.despawn_after_death = 0.0
	add_child(_snail)
	var player_body := CharacterBody2D.new()
	player_body.collision_layer = 2
	var player_collider := CollisionShape2D.new()
	var player_shape := RectangleShape2D.new()
	player_shape.size = Vector2(20.0, 32.0)
	player_collider.shape = player_shape
	player_body.add_child(player_collider)
	_player = auto_free(player_body)
	_player.add_to_group(&"player")
	add_child(_player)
	await get_tree().physics_frame


func after_test() -> void:
	_snail = null
	_player = null
	DataManager.clear_test_overrides()


func test_snail_detects_player_in_front() -> void:
	_snail.face_direction(1.0)
	_player.global_position = _snail.global_position + Vector2(60.0, 0.0)
	await get_tree().physics_frame

	assert_bool(_snail.found_player()).is_true()
	assert_object(_snail.attacker).is_equal(_player)


func test_snail_ignores_player_behind_for_backstab_window() -> void:
	_snail.face_direction(1.0)
	_player.global_position = _snail.global_position + Vector2(-60.0, 0.0)
	await get_tree().physics_frame

	assert_bool(_snail.found_player()).is_false()
	assert_object(_snail.attacker).is_null()


func test_snail_takes_damage_then_enters_shell_state() -> void:
	_player.global_position = _snail.global_position + Vector2(-60.0, 0.0)

	_snail.take_damage(_player, 1.0)
	await get_tree().process_frame

	assert_int(_snail.current_state).is_equal(Enums.NPCState.SKILL)
