extends GdUnitTestSuite


class PatrolPhysicsCheck:
	extends PhysicsCheck

	var turn_required: bool = true

	func should_turn_for_patrol(_direction: int) -> bool:
		return turn_required


func test_boar_wait_uses_idle_then_returns_to_walk() -> void:
	var boar := await _instantiate_enemy("res://scenes/enemy/boar.tscn") as Boar
	var check := auto_free(PatrolPhysicsCheck.new()) as PatrolPhysicsCheck
	boar.physics_check = check

	boar.patrol_state.logic_update(0.01)
	assert_str(boar.anim.current_animation).is_equal("idle")

	check.turn_required = false
	boar.patrol_state.logic_update(0.5)
	boar.patrol_state.logic_update(0.01)
	assert_str(boar.anim.current_animation).is_equal("walk")


func test_boar_chase_restores_run_after_hurt_animation() -> void:
	var boar := await _instantiate_enemy("res://scenes/enemy/boar.tscn") as Boar
	var target := auto_free(Node2D.new()) as Node2D
	add_child(target)
	target.global_position = boar.global_position + Vector2.RIGHT * 80.0
	boar.attacker = target
	boar.switch_state(Enums.NPCState.CHASE)
	boar.anim.play(&"hurt")

	boar.chase_state.logic_update(0.01)
	assert_str(boar.anim.current_animation).is_equal("run")


func test_ground_enemy_contact_attacks_damage_player() -> void:
	var scene_paths := [
		"res://scenes/enemy/boar.tscn",
		"res://scenes/enemy/snail.tscn",
	]
	for index in scene_paths.size():
		var enemy := await _instantiate_enemy(scene_paths[index])
		enemy.global_position.x = float(index) * 500.0
		var player_packed := load("res://scenes/player/player.tscn") as PackedScene
		var player := auto_free(player_packed.instantiate()) as PlayerController
		add_child(player)
		player.set_physics_process(false)
		var character := player.get_node("Character") as Character
		character.invulnerable_duration = 0.0
		player.global_position = (enemy.get_node("AttackBox") as Attack).global_position
		await get_tree().physics_frame
		await get_tree().physics_frame
		assert_float(character.current_health).is_equal(character.max_health - 1.0)


func test_bee_attack_window_enables_and_disables_attack_monitoring() -> void:
	var bee := await _instantiate_enemy("res://scenes/enemy/bee.tscn") as Bee
	var attack := bee.get_node("AttackBox") as Attack
	assert_bool(attack.monitoring).is_false()

	bee.queue_attack_window()
	bee.tick_attack_window(bee.attack_startup_delay - 0.01)
	bee.tick_attack_window(0.02)
	await get_tree().physics_frame
	assert_bool(attack.monitoring).is_true()

	bee.tick_attack_window(bee.attack_active_duration + 0.01)
	await get_tree().physics_frame
	assert_bool(attack.monitoring).is_false()


func test_bee_active_window_damages_player_through_attack_contract() -> void:
	var bee := await _instantiate_enemy("res://scenes/enemy/bee.tscn") as Bee
	var player_packed := load("res://scenes/player/player.tscn") as PackedScene
	var player := auto_free(player_packed.instantiate()) as PlayerController
	add_child(player)
	player.set_physics_process(false)
	var character := player.get_node("Character") as Character
	character.invulnerable_duration = 0.0
	player.global_position = (bee.get_node("AttackBox") as Attack).global_position
	await get_tree().physics_frame

	bee.queue_attack_window()
	bee.tick_attack_window(bee.attack_startup_delay - 0.01)
	bee.tick_attack_window(0.02)
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_float(character.current_health).is_equal(character.max_health - bee.attack_damage)


func test_bee_returns_to_chase_animation_after_attack_window() -> void:
	var bee := await _instantiate_enemy("res://scenes/enemy/bee.tscn") as Bee
	var target := auto_free(Node2D.new()) as Node2D
	add_child(target)
	target.global_position = bee.global_position + Vector2(0.0, bee.attack_hover_height)
	bee.attacker = target
	bee.lost_time_counter = 10.0
	bee.switch_state(Enums.NPCState.CHASE)

	bee.chase_state.logic_update(0.01)
	assert_str(bee.anim.current_animation).is_equal("attack")

	bee.cancel_attack_window()
	bee.chase_state.logic_update(0.01)
	assert_str(bee.anim.current_animation).is_equal("chase")


func test_snail_uses_complete_authored_action_strips() -> void:
	var snail := await _instantiate_enemy("res://scenes/enemy/snail.tscn") as Snail
	var expected := {
		&"walk": [0, 1, 2, 3, 4, 5, 6, 7],
		&"hide": [0, 1, 2, 3],
		&"unhide": [4, 5, 6, 7],
		&"dead": [0, 1, 2, 3, 4, 5, 6, 7],
	}
	for animation_name: StringName in expected:
		assert_array(_frame_values(snail.anim, animation_name)).is_equal(expected[animation_name])
	assert_int(SnailSkillState.HIDDEN_FRAME).is_equal(3)


func test_snail_contact_attack_follows_facing_direction() -> void:
	var snail := await _instantiate_enemy("res://scenes/enemy/snail.tscn") as Snail
	var attack := snail.get_node("AttackBox") as Attack
	var hitbox := attack.get_node("CollisionShape2D") as CollisionShape2D
	var initial_distance := absf(hitbox.position.x)
	assert_float(initial_distance).is_greater(0.0)

	snail.face_direction(1.0)
	assert_float(hitbox.position.x).is_equal(initial_distance)
	snail.face_direction(-1.0)
	assert_float(hitbox.position.x).is_equal(-initial_distance)


func test_boar_contact_attack_is_forward_only_and_stops_while_waiting() -> void:
	var boar := await _instantiate_enemy("res://scenes/enemy/boar.tscn") as Boar
	var attack := boar.get_node("AttackBox") as Attack
	var hitbox := attack.get_node("CollisionShape2D") as CollisionShape2D
	boar.face_direction(1.0)
	assert_float(hitbox.position.x).is_greater(0.0)
	boar.face_direction(-1.0)
	assert_float(hitbox.position.x).is_less(0.0)

	var check := auto_free(PatrolPhysicsCheck.new()) as PatrolPhysicsCheck
	boar.physics_check = check
	boar.patrol_state.logic_update(0.01)
	await get_tree().physics_frame
	assert_bool(attack.monitoring).is_false()


func test_snail_shell_state_disables_contact_attack() -> void:
	var snail := await _instantiate_enemy("res://scenes/enemy/snail.tscn") as Snail
	var attack := snail.get_node("AttackBox") as Attack
	snail.switch_state(Enums.NPCState.SKILL)
	await get_tree().physics_frame
	assert_bool(attack.monitoring).is_false()


func test_bee_death_uses_complete_hit_vanish_strip() -> void:
	var bee := await _instantiate_enemy("res://scenes/enemy/bee.tscn") as Bee
	assert_array(_frame_values(bee.anim, &"dead")).is_equal([0, 1, 2, 3])


func _instantiate_enemy(scene_path: String) -> Enemy:
	var packed := load(scene_path) as PackedScene
	var enemy := auto_free(packed.instantiate()) as Enemy
	add_child(enemy)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	await get_tree().process_frame
	return enemy


func _frame_values(animation_player: AnimationPlayer, animation_name: StringName) -> Array:
	var animation := animation_player.get_animation(animation_name)
	assert_object(animation).is_not_null()
	for track_index in animation.get_track_count():
		if String(animation.track_get_path(track_index)).ends_with(":frame"):
			var values: Array = []
			for key_index in animation.track_get_key_count(track_index):
				values.append(animation.track_get_key_value(track_index, key_index))
			return values
	return []
