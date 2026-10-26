extends Control

var hovering := false:
	set(value):
		if hovering != value:
			hovering = value
			queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var color := Color(0.82, 0.86, 0.79, 0.7)
	if hovering: color = Color(0.87, 0.76, 0.44)
	draw_circle(Vector2.ZERO, 2.0 if hovering else 1.3, color)
	if hovering:
		draw_arc(Vector2.ZERO, 9, 0, TAU, 32, Color(color, 0.6), 1, true)
