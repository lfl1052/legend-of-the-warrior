extends GdUnitTestSuite

const SAVE_POINT_SCENE := preload("res://scenes/props/save_point.tscn")
const TEST_SAVE_DIR := "user://TEST_SAVE_POINT/"

var _save_point: SavePoint


func before_test() -> void:
	DataManager.override_save_paths_for_test(TEST_SAVE_DIR)
	_save_point = auto_free(SAVE_POINT_SCENE.instantiate()) as SavePoint
	_save_point.save_id_prefix = "test_save_point"
	add_child(_save_point)


func after_test() -> void:
	DataManager.clear_test_overrides()
	_clean_test_dir()
	_save_point = null


func test_successful_save_activates_visual_and_first_reward_only_once() -> void:
	var first_count := {"value": 0}
	var activation_count := {"value": 0}
	var reward_ids: Array[StringName] = []
	var on_first := func() -> void: first_count.value += 1
	var on_activated := func() -> void: activation_count.value += 1
	var on_reward := func(id: StringName, _payload: Dictionary) -> void: reward_ids.append(id)
	_save_point.first_activation.connect(on_first)
	_save_point.activated.connect(on_activated)
	GameEvents.reward_notification.connect(on_reward)

	_save_point.trigger_action()
	_save_point.trigger_action()

	if GameEvents.reward_notification.is_connected(on_reward):
		GameEvents.reward_notification.disconnect(on_reward)
	assert_bool(_save_point.is_activated()).is_true()
	assert_bool(_save_point.is_saving()).is_false()
	assert_int(first_count.value).is_equal(1)
	assert_int(activation_count.value).is_equal(2)
	assert_int(reward_ids.count(&"power-refill")).is_equal(1)
	assert_int(reward_ids.count(&"save-success")).is_equal(2)
	assert_float(DataManager.get_float("test_save_point_done")).is_equal(1.0)
	assert_bool((_save_point.get_node("Visual/InactiveSign") as Sprite2D).visible).is_false()
	assert_bool((_save_point.get_node("Visual/ActiveSign") as Sprite2D).visible).is_true()


func test_failed_first_save_rolls_back_and_never_grants_first_reward() -> void:
	var failed_count := {"value": 0}
	var reward_ids: Array[StringName] = []
	var on_failed := func() -> void: failed_count.value += 1
	var on_reward := func(id: StringName, _payload: Dictionary) -> void: reward_ids.append(id)
	_save_point.save_failed.connect(on_failed)
	GameEvents.reward_notification.connect(on_reward)
	_save_point.set("_activated", true)
	_save_point.set("_activated_before_save", false)
	_save_point.set("_pending_first_activation", true)
	_save_point.set("_saving", true)

	_save_point.call("_on_save_completed", false)

	if GameEvents.reward_notification.is_connected(on_reward):
		GameEvents.reward_notification.disconnect(on_reward)
	assert_bool(_save_point.is_activated()).is_false()
	assert_int(failed_count.value).is_equal(1)
	assert_bool(reward_ids.has(&"save-failed")).is_true()
	assert_bool(reward_ids.has(&"power-refill")).is_false()


func test_load_supports_legacy_key_and_restores_active_visual() -> void:
	_save_point.legacy_save_ids = ["/root/LevelDemo/SavePoint"]
	var data := {"float_data": {"/root/LevelDemo/SavePoint_done": 1.0}}

	_save_point.load_save_data(data)

	assert_bool(_save_point.is_activated()).is_true()
	assert_bool((_save_point.get_node("Visual/InactiveSign") as Sprite2D).visible).is_false()
	assert_bool((_save_point.get_node("Visual/ActiveSign") as Sprite2D).visible).is_true()


func test_prefab_exposes_interaction_area_contract() -> void:
	assert_bool(_save_point.is_in_group(&"interactable")).is_true()
	assert_int(_save_point.collision_layer).is_equal(32)
	assert_int(_save_point.collision_mask).is_equal(0)
	assert_bool(_save_point.monitorable).is_true()
	assert_object(_save_point.get_node_or_null("CollisionShape2D")).is_not_null()
	assert_bool(_save_point.get_node("Visual") is CanvasGroup).is_true()


func _clean_test_dir() -> void:
	if not DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		return
	var dir := DirAccess.open(TEST_SAVE_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)
	DirAccess.remove_absolute(TEST_SAVE_DIR)
