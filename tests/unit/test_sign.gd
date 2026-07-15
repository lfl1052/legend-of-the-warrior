extends GdUnitTestSuite

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _player: PlayerController
var _sign: Sign


func before_test() -> void:
	_player = auto_free(PLAYER_SCENE.instantiate()) as PlayerController
	add_child(_player)
	_sign = _player.get_node("Sign") as Sign


func after_test() -> void:
	get_tree().paused = false
	_player = null
	_sign = null


func test_sign_keeps_remaining_candidate_when_current_target_exits() -> void:
	var near_target := _make_target(Vector2(4.0, 0.0))
	var far_target := _make_target(Vector2(24.0, 0.0))
	_sign._try_capture_target(far_target)
	_sign._try_capture_target(near_target)

	assert_object(_sign.get("_target")).is_same(near_target)

	_sign._on_area_exited(near_target)

	assert_object(_sign.get("_target")).is_same(far_target)
	assert_bool(_sign.get("_can_press")).is_true()


func test_sign_chooses_nearest_candidate_independent_of_entry_order() -> void:
	var near_target := _make_target(Vector2(3.0, 0.0))
	var far_target := _make_target(Vector2(30.0, 0.0))
	_sign._try_capture_target(near_target)
	_sign._try_capture_target(far_target)

	assert_object(_sign.get("_target")).is_same(near_target)


func test_player_scene_configures_prompt_animation_without_scaling_tracks() -> void:
	var animation_player := _sign.get_node("PromptAnimationPlayer") as AnimationPlayer
	assert_object(animation_player).is_not_null()
	assert_bool(animation_player.has_animation(&"show")).is_true()
	assert_bool(animation_player.has_animation(&"hide")).is_true()
	for animation_name in [&"show", &"hide"]:
		var animation := animation_player.get_animation(animation_name)
		for track_index in animation.get_track_count():
			assert_bool(String(animation.track_get_path(track_index)).contains("scale")).is_false()


func test_sign_hides_prompt_while_scene_tree_is_paused() -> void:
	var target := _make_target(Vector2(3.0, 0.0))
	_sign._try_capture_target(target)
	_sign._process(0.0)
	assert_bool(_sign.get("_prompt_shown")).is_true()

	get_tree().paused = true
	_sign._process(0.0)

	assert_bool(_sign.get("_prompt_shown")).is_false()


func _make_target(position: Vector2) -> Area2D:
	var target := auto_free(Area2D.new()) as Area2D
	target.add_to_group(&"interactable")
	target.global_position = position
	add_child(target)
	return target
