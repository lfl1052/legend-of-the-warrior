class_name BaseState
extends RefCounted
## 敌人状态基类（替代 Unity 项目里的 BaseState 抽象类）
##
## 子类需要重写 on_enter / logic_update / physics_update / on_exit。
## current_enemy 由状态机持有者注入（通常是 Enemy 节点）。

var current_enemy: Node = null


func on_enter(enemy: Node) -> void:
	current_enemy = enemy


func logic_update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func on_exit() -> void:
	current_enemy = null
