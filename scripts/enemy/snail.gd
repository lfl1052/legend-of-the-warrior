class_name Snail
extends EnemyMinion
## 蜗牛（替代 Unity 项目里的 Snail.cs）
##
## 缓慢巡逻，发现玩家时缩进壳里（Skill）获得短时间无敌。

@export var attack_damage: int = 1


func _setup_states() -> void:
	patrol_state = SnailPatrolState.new()
	skill_state = SnailSkillState.new()
	chase_state = SnailPatrolState.new()
