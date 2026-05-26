extends GdUnitTestSuite

const TEST_SCENE := preload("res://tests/integration/boss_skill_state_test.tscn")


func test_boss_skill_state_cycles_chase_to_skill_to_chase() -> void:
	# Arrange
	var scene: Node = auto_free(TEST_SCENE.instantiate())
	add_child(scene)
	await get_tree().process_frame
	var boss := scene.get_node("BossEnemy") as BossEnemy
	var player := scene.get_node("Player") as PlayerController
	assert_object(boss).is_not_null()
	assert_object(player).is_not_null()
	player.set_gameplay_input_active(false)
	boss.attacker = player
	boss.switch_state(Enums.NPCState.CHASE)

	# Act / Assert: CHASE -> SKILL
	var saw_skill := await _wait_for_state(boss, Enums.NPCState.SKILL, 0.6)
	assert_bool(saw_skill).is_true()

	# Act / Assert: SKILL -> CHASE
	var returned_to_chase := await _wait_for_state(boss, Enums.NPCState.CHASE, 0.8)
	assert_bool(returned_to_chase).is_true()
	assert_float(boss.get_skill_cooldown_ratio(boss.skill_id)).is_greater(0.0)


func _wait_for_state(boss: BossEnemy, expected_state: int, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if boss.current_state == expected_state:
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return false
