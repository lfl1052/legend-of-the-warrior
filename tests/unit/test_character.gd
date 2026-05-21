extends GdUnitTestSuite
## Character 单元测试
##
## 测试范围：
##   - 属性初始化
##   - take_damage 行为
##   - heal 行为
##   - 无敌帧机制
##   - 能量消耗与恢复
##   - 信号触发验证

const CHARACTER_PATH := "res://scripts/general/character.gd"

var _character: Character


func before_test() -> void:
	_character = auto_free(Character.new())
	_character.max_health = 10.0
	_character.max_power = 100.0
	_character.power_recover_speed = 10.0
	_character.invulnerable_duration = 0.3
	add_child(_character)


func after_test() -> void:
	_character = null


# ----- 初始化 -----------------------------------------------------------------

func test_character_initial_state_correct() -> void:
	# Arrange
	# (done in before_test)
	# Act
	# (no action, checking initial state)
	# Assert
	assert_float(_character.current_health).is_equal(10.0)
	assert_float(_character.current_power).is_equal(100.0)
	assert_bool(_character.is_invulnerable).is_false()
	assert_bool(_character.is_dead()).is_false()


# ----- take_damage ------------------------------------------------------------

func test_character_take_damage_reduces_health() -> void:
	# Arrange
	var attacker := Node.new()
	add_child(attacker)
	auto_free(attacker)
	# Act
	_character.take_damage(attacker, 3.0)
	# Assert
	assert_float(_character.current_health).is_equal(7.0)


func test_character_take_damage_sets_invulnerable() -> void:
	# Arrange
	var attacker := Node.new()
	add_child(attacker)
	auto_free(attacker)
	# Act
	_character.take_damage(attacker, 1.0)
	# Assert
	assert_bool(_character.is_invulnerable).is_true()


func test_character_take_damage_ignored_while_invulnerable() -> void:
	# Arrange
	var attacker := Node.new()
	add_child(attacker)
	auto_free(attacker)
	_character.take_damage(attacker, 1.0)
	assert_float(_character.current_health).is_equal(9.0)
	# Act: 尝试第二次伤害（在无敌帧内）
	_character.take_damage(attacker, 5.0)
	# Assert: 血量不变
	assert_float(_character.current_health).is_equal(9.0)


func test_character_take_damage_stops_at_zero() -> void:
	# Arrange
	var attacker := Node.new()
	add_child(attacker)
	auto_free(attacker)
	# Act: 超量伤害
	_character.take_damage(attacker, 999.0)
	# Assert
	assert_float(_character.current_health).is_equal(0.0)
	assert_bool(_character.is_dead()).is_true()


func test_character_take_damage_emits_died_signal() -> void:
	# Arrange
	var attacker := Node.new()
	add_child(attacker)
	auto_free(attacker)
	# Act：用 call_deferred 让伤害发生在下一帧，await assert_signal 才能等到 emit
	_character.call_deferred("take_damage", attacker, 999.0)
	# Assert
	await assert_signal(_character).is_emitted("died")


# ----- heal -------------------------------------------------------------------

func test_character_heal_restores_health() -> void:
	# Arrange
	_character.current_health = 3.0
	# Act
	_character.heal(2.0)
	# Assert
	assert_float(_character.current_health).is_equal(5.0)


func test_character_heal_does_not_exceed_max() -> void:
	# Arrange
	_character.current_health = 9.0
	# Act
	_character.heal(5.0)
	# Assert
	assert_float(_character.current_health).is_equal(10.0)


func test_character_heal_ignored_when_dead() -> void:
	# Arrange
	_character.current_health = 0.0
	# Act
	_character.heal(5.0)
	# Assert
	assert_float(_character.current_health).is_equal(0.0)


# ----- 能量 -------------------------------------------------------------------

func test_character_consume_power_decreases() -> void:
	# Act
	var result := _character.consume_power(30.0)
	# Assert
	assert_bool(result).is_true()
	assert_float(_character.current_power).is_equal(70.0)


func test_character_consume_power_fails_when_insufficient() -> void:
	# Act
	var result := _character.consume_power(200.0)
	# Assert
	assert_bool(result).is_false()
	assert_float(_character.current_power).is_equal(100.0)


# ----- reset_to_full ----------------------------------------------------------

func test_character_reset_to_full_restores_all() -> void:
	# Arrange
	_character.current_health = 1.0
	_character.current_power = 10.0
	_character.is_invulnerable = true
	# Act
	_character.reset_to_full()
	# Assert
	assert_float(_character.current_health).is_equal(10.0)
	assert_float(_character.current_power).is_equal(100.0)
	assert_bool(_character.is_invulnerable).is_false()


# ----- 比例 -------------------------------------------------------------------

func test_character_get_health_ratio_correct() -> void:
	# Arrange
	_character.current_health = 5.0
	# Act & Assert
	assert_float(_character.get_health_ratio()).is_equal(0.5)


func test_character_get_health_ratio_zero_max_returns_zero() -> void:
	# Arrange
	_character.max_health = 0.0
	# Act & Assert
	assert_float(_character.get_health_ratio()).is_equal(0.0)


func test_character_get_power_ratio_correct() -> void:
	# Arrange
	_character.current_power = 25.0
	# Act & Assert
	assert_float(_character.get_power_ratio()).is_equal(0.25)
