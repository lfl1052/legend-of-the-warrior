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


func test_boss_telegraph_matches_skill_hit_radius() -> void:
	var scene: Node = auto_free(TEST_SCENE.instantiate())
	add_child(scene)
	await get_tree().process_frame
	var boss := scene.get_node("BossEnemy") as BossEnemy
	var telegraph := boss.get_node("SkillTelegraph") as RadialAttackTelegraph
	var skill_shape := boss.get_node("SkillAttack/CollisionShape2D") as CollisionShape2D

	boss.set_skill_telegraph_phase(&"windup")
	assert_bool(telegraph.visible).is_true()
	assert_float(telegraph.radius).is_equal((skill_shape.shape as CircleShape2D).radius)
	boss.set_skill_telegraph_phase(&"active")
	assert_bool(telegraph._active).is_true()
	boss.set_skill_telegraph_phase(&"off")
	assert_bool(telegraph.visible).is_false()


func test_boss_hurt_cancels_active_skill_collision_and_telegraph() -> void:
	var scene: Node = auto_free(TEST_SCENE.instantiate())
	add_child(scene)
	await get_tree().process_frame
	var boss := scene.get_node("BossEnemy") as BossEnemy
	var player := scene.get_node("Player") as PlayerController
	boss.set_process(false)
	boss.set_physics_process(false)
	boss.switch_state(Enums.NPCState.SKILL)
	boss.skill_state.logic_update(boss.skill_windup_duration + 0.01)
	await get_tree().physics_frame
	var attack := boss.get_node("SkillAttack") as Attack
	var telegraph := boss.get_node("SkillTelegraph") as RadialAttackTelegraph
	assert_bool(attack.monitoring).is_true()
	assert_bool(telegraph.visible).is_true()

	boss.take_damage(player, 1.0)
	await get_tree().physics_frame

	assert_int(boss.current_state).is_equal(Enums.NPCState.CHASE)
	assert_bool(attack.monitoring).is_false()
	assert_bool(telegraph.visible).is_false()


func _wait_for_state(boss: BossEnemy, expected_state: int, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if boss.current_state == expected_state:
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return false
