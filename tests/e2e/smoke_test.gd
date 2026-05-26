extends Node
## 端到端冒烟测试（替代 Unity 项目里的 PlayMode 自动化用例）
##
## 不是单元测试 —— 这是一个状态机式 e2e 脚本，按顺序串联以下步骤：
##   1. test_menu_new_game_loads_level_demo
##   2. test_level_demo_world_nodes_present
##   3. test_player_automation_attack_damages_enemy
##   4. test_save_point_writes_save_file_to_disk
##   5. test_teleport_to_menu_returns_to_main_menu
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
	if not await test_teleport_to_menu_returns_to_main_menu():
		_finish(false, "回菜单 Teleport 失败"); return
	_finish(true, "全部步骤通过")


# ---------------------------------------------------------------------------
# 用例
# ---------------------------------------------------------------------------

func test_menu_new_game_loads_level_demo() -> bool:
	_log("[1/5] menu_new_game_loads_level_demo")
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
	_log("[2/5] level_demo_world_nodes_present")
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
	_log("  OK  关卡节点齐备")
	return true


func test_player_automation_attack_damages_enemy() -> bool:
	_log("[3/5] player_automation_attack_damages_enemy")
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
	_log("[4/5] save_point_writes_save_file_to_disk")
	# Arrange ----------------------------------------------------------------
	var root := get_tree().current_scene
	var save_point := root.get_node_or_null("SavePoint")
	if save_point == null or not save_point.has_method("trigger_action"):
		_log("  ERR  SavePoint 没有 trigger_action")
		return false
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
	_log("[5/5] teleport_to_menu_returns_to_main_menu")
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
	return await _await_node_in_scene(expected_name) != null


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
	get_tree().quit(0 if ok else 1)
