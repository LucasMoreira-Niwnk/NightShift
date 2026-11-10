extends Control
var item_id := ""
const INK := Color(0.67,0.68,0.57)

func _ready() -> void:
	custom_minimum_size = Vector2(220,100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size*0.5
	if "key" in item_id:
		draw_arc(center-Vector2(45,0),17,0,TAU,40,INK,3,true)
		draw_line(center-Vector2(28,0),center+Vector2(50,0),INK,5,true)
		for x in [28,45]: draw_line(center+Vector2(x,0),center+Vector2(x,18),INK,5,true)
	elif "fuse" in item_id:
		draw_style_box(preload("res://scripts/ui_style.gd").card(Color(0.2,0.23,0.21),4),Rect2(center-Vector2(54,15),Vector2(108,30)))
		for x in [-62,46]: draw_rect(Rect2(center+Vector2(x,-18),Vector2(16,36)),INK)
		draw_line(center-Vector2(40,0),center+Vector2(40,0),INK,1,true)
	elif item_id == "badge":
		draw_rect(Rect2(center-Vector2(47,31),Vector2(94,62)),INK,false,2)
		draw_circle(center-Vector2(22,8),9,INK)
		draw_line(center+Vector2(0,-10),center+Vector2(33,-10),INK,2)
		draw_line(center+Vector2(0,3),center+Vector2(25,3),INK,2)
		draw_line(center-Vector2(34,-22),center+Vector2(33,22),INK,2)
	else:
		draw_rect(Rect2(center-Vector2(40,12),Vector2(90,24)),INK,false,2)
		draw_colored_polygon(PackedVector2Array([center+Vector2(-40,-12),center+Vector2(-60,-22),center+Vector2(-60,22),center+Vector2(-40,12)]),INK)
