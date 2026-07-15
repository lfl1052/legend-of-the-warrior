extends Node
## 端到端冒烟测试（替代 Unity 项目里的 PlayMode 自动化用例）
##
## 不是单元测试 —— 这是一个状态机式 e2e 脚本，按顺序串联以下步骤：
##   1. test_menu_new_game_loads_level_demo
##   2. test_level_demo_world_nodes_present
##   3. test_player_automation_attack_damages_enemy
##   4. test_save_point_writes_save_file_to_disk
##   5. test_demo_and_level_2_round_trip
##   6. test_teleport_to_menu_returns_to_main_menu
##   7. test_continue_restores_saved_player_state
##
## 每一步遵循 Arrange / Act / Assert 写法（在注释里标注）。
## 用例之间彼此隔离：开始前 _purge_save_dir() 清掉 user://SAVE_DATA/，
## 结束后再清一次，避免外部状态串扰。
##
## 运行方式：
##   editor: 把 main_scene 临时切到 tests/smoke_test.tscn 后按 F5
##   cli  : godot --headless --verbose --path . --scene res://tests/e2e/smoke_test.tscn

const STEP_TIMEOUT := 12.0
const ATTACK_BURST_DURATION := 1.6
const MENU_SCENE_PATH := "res://scenes/levels/warrior_menu.tscn"
var _logs: Array[String] = []


func _ready() -> void:
	add_to_group(&"smoke_test")
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 必须在场景切换前 reparent 到 SceneTree.root，否则 change_scene_*
	# 会把当前根连带 SmokeTest 一起释放。
	call_deferred("_bootstrap")


func _bootstrap() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if get_parent() != tree.root:
		var parent := get_parent()
		parent.remove_child(self)
		tree.root.add_child(self)

	_purge_save_dir()                              # 用例前清理外部状态

	var err := tree.change_scene_to_file(MENU_SCENE_PATH)
	if err != OK:
		_finish(false, "change_scene_to_file 失败: %d" % err)
		return
	await tree.process_frame
	await tree.process_frame
	_run()


func _run() -> void:
	_log("Smoke test 启动 ...")
	if not await test_menu_new_game_loads_level_demo():
		_finish(false, "主菜单 → 关卡 跳转失败"); return
	if not await test_level_demo_world_nodes_present():
		_finish(false, "关卡内节点缺失"); return
	if not await test_player_automation_attack_damages_enemy():
		_finish(false, "玩家自动化输入未触发预期行为"); return
	if not await test_save_point_writes_save_file_to_disk():
		_finish(false, "存档点未能写出存档"); return
	if not await test_demo_and_level_2_round_trip():
		_finish(false, "Demo 与 level_2 往返失败"); return
	if not await test_teleport_to_menu_returns_to_main_menu():
		_finish(false, "回菜单 Teleport 失败"); return
	if not await test_continue_restores_saved_player_state():
		_finish(false, "Continue 未完整恢复玩家状态"); return
	_finish(true, "全部步骤通过")


# ---------------------------------------------------------------------------
# 用例
# ---------------------------------------------------------------------------

func test_menu_new_game_loads_level_demo() -> bool:
	_log("[1/7] menu_new_game_loads_level_demo")
	# Arrange ----------------------------------------------------------------
	var menu := await _await_node_in_scene("WarriorMenu")
	if menu == null:
		_log("  ERR  无法找到 WarriorMenu 根节点")
		return false
	var btn := menu.get_node_or_null("UI/MainMenu/Center/Buttons/NewGameButton") as Button
	if btn == null:
		_log("  ERR  没找到 NewGameButton")
		return false
	# Act --------------------------------------------------------------------
	btn.emit_signal("pressed")
	await get_tree().process_frame
	# Assert -----------------------------------------------------------------
	return await _await_scene_root_named("LevelDemo")


func test_level_demo_world_nodes_present() -> bool:
	_log("[2/7] level_demo_world_nodes_present")
	# Arrange ----------------------------------------------------------------
	await get_tree().process_frame
	var root := get_tree().current_scene
	if root == null:
		_log("  ERR  current_scene == null")
		return false
	var required: Array[String] = [
		"Player",
		"Camera2D",
		"Snail",
		"Bee",
		"TrainingLadder",
		"SavePoint",
		"TeleportToMenu",
		"UI/HUD/PlayerStatBar",
		"UI/HUD/RewardNotification",
		"FadeCanvas",
	]
	# Act / Assert -----------------------------------------------------------
	for path in required:
		if root.get_node_or_null(NodePath(path)) == null:
			_log("  ERR  缺少节点 %s" % path)
			return false
	var player := root.get_node_or_null("Player") as PlayerController
	if player == null or absf(player.global_position.y - 492.0) > 0.5:
		_log("  ERR  玩家出生点未落在 Demo 地面高度 y=492（实际 %s）" % player.global_position.y if player != null else "  ERR  Player 缺失")
		return false
	await get_tree().physics_frame
	if not player.is_on_floor():
		_log("  ERR  玩家出生后未站在地面碰撞上")
		return false
	_log("  OK  关卡节点齐备")
	return true


func test_player_automation_attack_damages_enemy() -> bool:
	_log("[3/7] player_automation_attack_damages_enemy")
	# Arrange ----------------------------------------------------------------
	var root := get_tree().current_scene
	var player := root.get_node_or_null("Player") as PlayerController
	if player == null:
		_log("  ERR  Player 不是 PlayerController（脚本未挂上）")
		return false
	# Act：右移 → 跳跃 → 连击 ---------------------------------------------
	var target := root.get_node_or_null("Bee") as Node2D
	if target == null:
		target = root.get_node_or_null("Snail") as Node2D
	if target != null:
		player.global_position = target.global_position + Vector2(-42, 0)
		player.velocity = Vector2.ZERO
	player.enable_automation(true)
	var burst := ATTACK_BURST_DURATION
	while burst > 0.0:
		player.automation_attack()
		await get_tree().create_timer(0.35).timeout
		burst -= 0.35
	player.automation_move(0.0)
	player.enable_automation(false)
	# Assert -----------------------------------------------------------------
	var any_damaged := _enemy_damaged(root.get_node_or_null("Snail")) \
			or _enemy_damaged(root.get_node_or_null("Bee"))
	if any_damaged:
		_log("  OK  至少一个敌人受到伤害")
	else:
		# 攻击命中是物理时序敏感的，CI 帧率不稳时给 soft fail
		_log("  WARN 未侦测到敌人受击，按宽松通过")
	return any_damaged


func test_save_point_writes_save_file_to_disk() -> bool:
	_log("[4/7] save_point_writes_save_file_to_disk")
	# Arrange ----------------------------------------------------------------
	var root := get_tree().current_scene
	var save_point := root.get_node_or_null("SavePoint")
	if save_point == null or not save_point.has_method("trigger_action"):
		_log("  ERR  SavePoint 没有 trigger_action")
		return false
	var player := root.get_node_or_null("Player") as PlayerController
	var character: Character = null
	if player != null:
		character = player.get_node_or_null("Character") as Character
	if player == null or character == null:
		_log("  ERR  存档前无法找到玩家规则状态")
		return false
	player.global_position = Vector2(340.0, 492.0)
	character.current_health = 3.0
	character.current_power = 42.0
	# Act --------------------------------------------------------------------
	save_point.call("trigger_action")
	await get_tree().create_timer(0.2).timeout
	# Assert -----------------------------------------------------------------
	if not DataManager.has_saved_game():
		_log("  ERR  存档文件没有被写出")
		return false
	_log("  OK  存档已写入 user://SAVE_DATA/data.sav")
	return true


func test_teleport_to_menu_returns_to_main_menu() -> bool:
	_log("[6/7] teleport_to_menu_returns_to_main_menu")
	# Arrange ----------------------------------------------------------------
	var root := get_tree().current_scene
	var teleport := root.get_node_or_null("TeleportToMenu")
	if teleport == null or not teleport.has_method("trigger_action"):
		_log("  ERR  TeleportToMenu 没有 trigger_action")
		return false
	# Act --------------------------------------------------------------------
	teleport.call("trigger_action")
	# Assert -----------------------------------------------------------------
	if not await _await_scene_root_named("WarriorMenu"):
		_log("  ERR  没能切回主菜单")
		return false
	_log("  OK  回到 WarriorMenu")
	return true


func test_continue_restores_saved_player_state() -> bool:
	_log("[7/7] continue_restores_saved_player_state")
	# current_scene 会早于 SceneLoader 的淡出收尾就绪，等待加载锁释放。
	await get_tree().create_timer(0.5).timeout
	var menu := get_tree().current_scene
	var continue_button := menu.get_node_or_null("UI/MainMenu/Center/Buttons/ContinueButton") as Button
	if continue_button == null or continue_button.disabled:
		_log("  ERR  有合法存档时 Continue 不可用")
		return false
	continue_button.emit_signal("pressed")
	if not await _await_scene_root_named("LevelDemo"):
		_log("  ERR  Continue 未返回保存场景")
		return false
	await get_tree().create_timer(0.6).timeout
	var root := get_tree().current_scene
	var player := root.get_node_or_null("Player") as PlayerController
	var character: Character = null
	if player != null:
		character = player.get_node_or_null("Character") as Character
	if player == null or character == null:
		_log("  ERR  Continue 后玩家规则节点缺失")
		return false
	if player.global_position.distance_to(Vector2(340.0, 492.0)) > 1.0:
		_log("  ERR  Continue 位置未恢复，实际 %s" % player.global_position)
		return false
	if not is_equal_approx(character.current_health, 3.0):
		_log("  ERR  Continue 生命未恢复，实际 %.2f" % character.current_health)
		return false
	if character.current_power < 42.0 or character.current_power >= 70.0:
		_log("  ERR  Continue 能量未恢复到保存区间，实际 %.2f" % character.current_power)
		return false
	var health_bar := root.get_node_or_null("UI/HUD/PlayerStatBar/HealthBar") as Range
	var power_bar := root.get_node_or_null("UI/HUD/PlayerStatBar/PowerBar") as Range
	if health_bar == null or power_bar == null or absf(health_bar.value - 60.0) > 1.0 or power_bar.value >= 75.0:
		_log("  ERR  Continue 后 HUD 未同步")
		return false
	_log("  OK  场景、位置、生命、能量与 HUD 均已恢复")
	return true


func test_demo_and_level_2_round_trip() -> bool:
	_log("[5/7] demo_and_level_2_round_trip")
	var demo := get_tree().current_scene
	var to_level_2 := demo.get_node_or_null("TeleportToLevel2")
	if to_level_2 == null or not to_level_2.has_method("trigger_action"):
		_log("  ERR  TeleportToLevel2 不可用")
		return false
	to_level_2.call("trigger_action")
	if not await _await_scene_root_named("Level2"):
		_log("  ERR  未进入 Level2")
		return false

	var level_2 := get_tree().current_scene
	if level_2.get_node_or_null("MapVisuals/GeometryTiles") == null:
		_log("  ERR  Level2 缺少 GeometryTiles")
		return false
	# 场景根节点先于 SceneLoader 的淡出收尾出现，等待加载锁释放后再触发返程。
	await get_tree().create_timer(0.5).timeout
	var to_demo := level_2.get_node_or_null("TeleportToDemo")
	if to_demo == null or not to_demo.has_method("trigger_action"):
		_log("  ERR  TeleportToDemo 不可用")
		return false
	to_demo.call("trigger_action")
	if not await _await_scene_root_named("LevelDemo"):
		_log("  ERR  未返回 LevelDemo")
		return false
	await get_tree().create_timer(0.5).timeout
	_log("  OK  Demo ↔ Level2 往返成功")
	return true


# ---------------------------------------------------------------------------
# 工具方法
# ---------------------------------------------------------------------------

func _enemy_damaged(enemy: Node) -> bool:
	if enemy == null:
		return false
	var character := enemy.get_node_or_null("Character") as Character
	if character == null:
		return false
	return character.current_health < character.max_health - 0.001


func _await_node_in_scene(scene_name: String) -> Node:
	var t := 0.0
	while t < STEP_TIMEOUT:
		var current := get_tree().current_scene
		if current != null and current.name == StringName(scene_name):
			return current
		await get_tree().process_frame
		t += get_process_delta_time()
	return null


func _await_scene_root_named(expected_name: String) -> bool:
	var t := 0.0
	while t < STEP_TIMEOUT:
		var current := get_tree().current_scene
		var transition_active := SceneLoader.is_transition_active()
		if current != null and current.name == StringName(expected_name) and not transition_active:
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false


func _purge_save_dir() -> void:
	# 用例隔离：删掉 user://SAVE_DATA/data.sav，避免 has_saved_game() 受外部影响
	var dir := DirAccess.open("user://SAVE_DATA")
	if dir == null:
		return
	for fname in dir.get_files():
		dir.remove(fname)


func _log(msg: String) -> void:
	_logs.append(msg)
	print("[smoke] " + msg)


func _finish(ok: bool, summary: String) -> void:
	_log("=========================================")
	_log("结果：%s — %s" % ["PASS" if ok else "FAIL", summary])
	_log("=========================================")
	_purge_save_dir()                              # 用例后再清一次
	if is_instance_valid(AudioManager) and AudioManager.has_method("shutdown_for_tests"):
		AudioManager.shutdown_for_tests()
	call_deferred("_quit_after_cleanup", ok)


func _quit_after_cleanup(ok: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.current_scene != null:
		tree.current_scene.queue_free()
	for _frame in range(3):
		await tree.process_frame
	queue_free()
	tree.quit(0 if ok else 1)
