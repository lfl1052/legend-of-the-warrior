class_name LadderArea
extends Area2D

@export var ladder_size: Vector2 = Vector2(28.0, 92.0)
@export var rung_spacing: float = 14.0


func _ready() -> void:
	add_to_group(&"ladder")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _draw() -> void:
	var half_width := ladder_size.x * 0.5
	var half_height := ladder_size.y * 0.5
	var wood_shadow := Color(0.20, 0.11, 0.05, 1.0)
	var wood := Color(0.46, 0.28, 0.12, 1.0)
	for x in [-half_width + 3.0, half_width - 3.0]:
		draw_line(Vector2(x + 1.0, -half_height), Vector2(x + 1.0, half_height), wood_shadow, 5.0)
		draw_line(Vector2(x, -half_height), Vector2(x, half_height), wood, 3.0)
	var y := -half_height + 8.0
	while y < half_height:
		draw_line(Vector2(-half_width, y + 1.0), Vector2(half_width, y + 1.0), wood_shadow, 5.0)
		draw_line(Vector2(-half_width, y), Vector2(half_width, y), wood, 3.0)
		y += rung_spacing


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_ladder"):
		body.call("enter_ladder", self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_ladder"):
		body.call("exit_ladder", self)
