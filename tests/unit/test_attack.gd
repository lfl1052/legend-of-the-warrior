extends GdUnitTestSuite
## Attack 攻击冷却逻辑单元测试
##
## 测试范围：
##   - per_target_one_hit = true (玩家)：每个目标只命中一次
##   - per_target_one_hit = false (敌人)：按 attack_rate 周期触发
##   - 目标退出范围后冷却被清除
##
## 注意：Attack 是 Area2D，本测试只直接驱动其内部命中函数
## (_try_apply_damage / _on_target_exited)，不依赖物理回调。

const ATTACK_SCRIPT := "res://scripts/general/attack.gd"

var _attack: Attack
var _target: TestTarget


func before_test() -> void:
	_attack = auto_free(Attack.new())
	_attack.damage = 1
	_attack.attack_rate = 1.0
	_attack.per_target_one_hit = false
	add_child(_attack)
	_target = auto_free(TestTarget.new())
	add_child(_target)


func after_test() -> void:
	_attack = null
	_target = null


# ----- one-shot 模式（玩家攻击） ----------------------------------------------

func test_attack_one_shot_hits_target_only_once() -> void:
	# Arrange
	_attack.per_target_one_hit = true
	# Act：连续 5 次"重叠"
	for i in 5:
		_attack._try_apply_damage(_target)
	# Assert
	assert_int(_target.hit_count).is_equal(1)


# ----- repeat 模式（敌人攻击） -----------------------------------------------

func test_attack_repeat_respects_attack_rate() -> void:
	# Arrange：节奏 = 10 秒，连续触发的第二次必须被冷却拦截
	_attack.per_target_one_hit = false
	_attack.attack_rate = 10.0
	# Act
	_attack._try_apply_damage(_target)
	_attack._try_apply_damage(_target)
	# Assert：第二次被冷却拦下
	assert_int(_target.hit_count).is_equal(1)


# ----- 目标离开后冷却清除 -----------------------------------------------------

func test_attack_target_exit_clears_cooldown() -> void:
	# Arrange：触发一次后 _cooldowns 应当存在该目标记录
	_attack.per_target_one_hit = true
	_attack._try_apply_damage(_target)
	assert_int(_target.hit_count).is_equal(1)
	# Act：模拟离开范围
	_attack._on_target_exited(_target)
	# Assert：冷却被清空，再次触发可以命中
	_attack._try_apply_damage(_target)
	assert_int(_target.hit_count).is_equal(2)


func test_attack_uses_hurtbox_as_single_damage_receiver() -> void:
	var receiver := auto_free(TestTarget.new()) as TestTarget
	var hurtbox := HurtBox.new()
	hurtbox.name = "HurtBox"
	receiver.add_child(hurtbox)
	add_child(receiver)
	await get_tree().process_frame
	_attack.per_target_one_hit = true

	_attack._try_apply_damage(receiver)
	_attack._try_apply_damage(hurtbox)
	_attack._try_apply_damage(hurtbox)

	assert_int(receiver.hit_count).is_equal(1)


# ----- 内部 fake 目标 ----------------------------------------------------------

class TestTarget extends Node2D:
	var hit_count: int = 0

	func take_damage(_attacker: Node, _amount: float = 1.0) -> void:
		hit_count += 1
