class_name Boar
extends EnemyMinion
## 野猪（替代 Unity 项目里的 Boar.cs）
##
## 普通陆地杂兵：地面巡逻 + 直冲追击。攻击命中通过子节点 Attack 完成。

@export var attack_damage: int = 1


func _setup_states() -> void:
	patrol_state = BoarPatrolState.new()
	chase_state = BoarChaseState.new()
