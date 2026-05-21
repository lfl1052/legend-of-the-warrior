class_name PlayerStatBar
extends Control
## 玩家状态条（替代 Unity 项目里的 PlayerStatBar.cs）
##
## 显示生命/能量条。Unity 版还有低血量危险描边、能量蓄满徽章等表现层动画，
## 此处保留核心数据驱动；视觉细节由 Inspector 中的颜色变量控制。
##
## - target_character 直接绑定到玩家身上的 Character；为空时尝试从 &"player" 组里查找
## - health_fill / health_delay_fill / power_fill：建议使用 TextureProgressBar，
##   通过 .value 表示填充比 (0..max_value)
## - 能量蓄满（power 比例 >= 1）时给 power_fill 加一个色相调制

@export_node_path("Range") var health_fill_path: NodePath
@export_node_path("Range") var health_delay_fill_path: NodePath
@export_node_path("Range") var power_fill_path: NodePath

@export var health_delay_speed: float = 0.9
@export var power_lerp_speed: float = 3.5
@export var low_health_threshold: float = 0.35
@export var critical_health_threshold: float = 0.18
@export var hit_flash_duration: float = 0.28

@export var base_health_color: Color = Color(0.95, 0.95, 0.95, 1)
@export var critical_health_color: Color = Color(0.95, 0.19, 0.17, 1)
@export var base_power_color: Color = Color(0.95, 0.95, 0.95, 1)
@export var power_ready_color: Color = Color(0.68, 0.9, 1, 1)

var target_character: Character

var _health_fill: Range
var _health_delay_fill: Range
var _power_fill: Range
var _last_health_ratio: float = -1.0
var _last_power_ratio: float = -1.0
var _hit_flash_timer: float = 0.0


func _ready() -> void:
	_health_fill = get_node_or_null(health_fill_path) as Range
	_health_delay_fill = get_node_or_null(health_delay_fill_path) as Range
	_power_fill = get_node_or_null(power_fill_path) as Range
	if not GameEvents.character_health_changed.is_connected(_on_character_health):
		GameEvents.character_health_changed.connect(_on_character_health)
	if not GameEvents.character_took_damage.is_connected(_on_character_took_damage):
		GameEvents.character_took_damage.connect(_on_character_took_damage)


func _process(delta: float) -> void:
	if target_character == null:
		_resolve_target()
	if target_character == null:
		return

	var hp_ratio := target_character.get_health_ratio()
	var pw_ratio := target_character.get_power_ratio()

	if _last_health_ratio >= 0.0 and hp_ratio < _last_health_ratio - 0.001:
		_hit_flash_timer = hit_flash_duration

	_update_bars(delta, hp_ratio, pw_ratio)
	_apply_visuals(hp_ratio, pw_ratio)

	_last_health_ratio = hp_ratio
	_last_power_ratio = pw_ratio
	_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)


func bind_character(character: Character) -> void:
	target_character = character


func _resolve_target() -> void:
	for player in get_tree().get_nodes_in_group(&"player"):
		for child in player.get_children():
			if child is Character:
				target_character = child
				return


func _on_character_health(character: Character) -> void:
	if character == target_character:
		# 立即拉一次值，避免下一帧 _process 之前 UI 滞后
		_update_bars(0.0, character.get_health_ratio(), character.get_power_ratio())


func _on_character_took_damage(character: Character, _attacker: Node) -> void:
	if character == target_character:
		_hit_flash_timer = hit_flash_duration


func _update_bars(delta: float, hp_ratio: float, pw_ratio: float) -> void:
	if _health_fill != null:
		_health_fill.value = hp_ratio * _health_fill.max_value
	if _health_delay_fill != null:
		var goal := hp_ratio * _health_delay_fill.max_value
		if delta <= 0.0 or _health_delay_fill.value <= goal:
			_health_delay_fill.value = goal
		else:
			_health_delay_fill.value = move_toward(_health_delay_fill.value, goal, health_delay_speed * _health_delay_fill.max_value * delta)
	if _power_fill != null:
		var goal_p := pw_ratio * _power_fill.max_value
		if delta <= 0.0:
			_power_fill.value = goal_p
		else:
			_power_fill.value = move_toward(_power_fill.value, goal_p, power_lerp_speed * _power_fill.max_value * delta)


func _apply_visuals(hp_ratio: float, pw_ratio: float) -> void:
	var critical := clampf(1.0 - inverse_lerp(critical_health_threshold, low_health_threshold, hp_ratio), 0.0, 1.0)
	if hp_ratio >= low_health_threshold:
		critical = 0.0
	var hit_blend := 0.0 if hit_flash_duration <= 0.0 else clampf(_hit_flash_timer / hit_flash_duration, 0.0, 1.0)

	if _health_fill != null:
		var c := base_health_color.lerp(critical_health_color, critical)
		c = c.lerp(Color.WHITE, hit_blend * 0.4)
		_health_fill.modulate = c
	if _power_fill != null:
		var ready_blend := 1.0 if pw_ratio >= 0.999 else 0.0
		_power_fill.modulate = base_power_color.lerp(power_ready_color, ready_blend)
