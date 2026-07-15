class_name RadialAttackTelegraph
extends Node2D

@export var radius: float = 72.0
@export var windup_color: Color = Color(1.0, 0.78, 0.18, 0.16)
@export var active_color: Color = Color(1.0, 0.24, 0.12, 0.28)

var _active: bool = false
var _phase_color: Color


func _ready() -> void:
	visible = false
	show_behind_parent = true


func show_windup() -> void:
	_active = false
	_phase_color = windup_color
	visible = true
	queue_redraw()


func show_active() -> void:
	_active = true
	_phase_color = active_color
	visible = true
	queue_redraw()


func hide_telegraph() -> void:
	visible = false


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, _phase_color)
	var outline := Color(_phase_color, 0.95 if _active else 0.75)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, outline, 2.0, true)
