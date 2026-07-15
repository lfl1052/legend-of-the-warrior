class_name Boar
extends EnemyMinion
## 野猪（替代 Unity 项目里的 Boar.cs）
##
## 普通陆地杂兵：地面巡逻 + 直冲追击。攻击命中通过子节点 Attack 完成。

@export var attack_damage: int = 1

@onready var _contact_attack: Attack = get_node_or_null(^"AttackBox") as Attack
@onready var _contact_hitbox: CollisionShape2D = \
		get_node_or_null(^"AttackBox/CollisionShape2D") as CollisionShape2D
var _contact_attack_distance: float = 0.0


func _ready() -> void:
	if _contact_hitbox != null:
		_contact_attack_distance = absf(_contact_hitbox.position.x)
	super._ready()
	if _contact_attack != null:
		_contact_attack.damage = attack_damage
	hurt_started.connect(_on_hurt_started)


func _setup_states() -> void:
	patrol_state = BoarPatrolState.new()
	chase_state = BoarChaseState.new()


func face_direction(dir_x: float) -> void:
	super.face_direction(dir_x)
	if is_zero_approx(dir_x) or _contact_hitbox == null:
		return
	_contact_hitbox.position.x = _contact_attack_distance * (1.0 if dir_x > 0.0 else -1.0)


func set_contact_attack_active(active: bool) -> void:
	if _contact_attack != null:
		_contact_attack.set_active(active)


func _on_hurt_started(_attacker: Node) -> void:
	set_contact_attack_active(false)
