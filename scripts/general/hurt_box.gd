class_name HurtBox
extends Area2D
## 独立受击区域。身体碰撞负责移动阻挡，HurtBox 只把伤害转发给规则角色。

@export_node_path("Node") var damage_receiver_path: NodePath = ^".."


func _ready() -> void:
	monitoring = false
	monitorable = true


func get_damage_receiver() -> Node:
	return get_node_or_null(damage_receiver_path)


func take_damage(attacker: Node, amount: float = 1.0) -> void:
	var receiver := get_damage_receiver()
	if receiver != null and receiver.has_method("take_damage"):
		receiver.call("take_damage", attacker, amount)
