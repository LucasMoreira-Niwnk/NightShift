extends Control

var game: Node
var floor_mode := -1
var zoom := 1.0
var origin := Vector2.ZERO
var scale_unit := 1.0
var rooms: Array = []
var upper := false

func _ready() -> void:
	custom_minimum_size = Vector2(360, 300)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if is_visible_in_tree(): queue_redraw()

func project(point: Vector3) -> Vector2:
	return origin + Vector2(point.z, -point.x) * scale_unit

func _draw() -> void:
	if game == null or game.player == null: return
	upper = game.player.position.y > 3.5 if floor_mode < 0 else floor_mode == 1
	var player_point: Vector3 = game.player.position
	var minimum := Vector2(-14, -26)
	var extent := Vector2(56, 28)
	scale_unit = minf((size.x - 48) / extent.x, (size.y - 48) / extent.y) * zoom
	var center := Vector2(0, 2)
	if zoom > 1.0: center = Vector2(player_point.x, player_point.z)
	origin = size * 0.5 - Vector2(center.y,-center.x) * scale_unit
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1418"))
	for x in range(-14, 15, 2):
		draw_line(project(Vector3(x,0,minimum.y)),project(Vector3(x,0,30)),Color(0.2,0.35,0.4,0.12))
	for z in range(-26,31,2):
		draw_line(project(Vector3(-14,0,z)),project(Vector3(14,0,z)),Color(0.2,0.35,0.4,0.12))
	rooms = [
		["RECEPÇÃO",Rect2(-8,4,16,8)], ["CORREDOR",Rect2(-2,-16,4,20)],
		["SEGURANÇA",Rect2(-8,-2,6,6)], ["ARQUIVO",Rect2(2,-10,6,8)],
		["TÉCNICA",Rect2(-8,-14,6,8)], ["MARQUISE",Rect2(-3,12,6,4)],
		["ESTACIONAMENTO",Rect2(-12,16,24,12)]]
	if upper:
		rooms = [["CORREDOR • 2º",Rect2(-1.6,-14,3.2,24)],
			["ADMINISTRAÇÃO",Rect2(-8,-13,6.4,8)], ["TI / REDE",Rect2(-8,-3,6.4,10)],
			["REUNIÕES",Rect2(1.6,-9,6.4,14)]]
	rooms.append(["ESCADA PRINCIPAL",Rect2(-2,-25,4,9)])
	rooms.append(["ESCADA SERVIÇO",Rect2(-12,-14,4,18)])
	var font := ThemeDB.fallback_font
	for room in rooms:
		var rect: Rect2 = room[1]
		var box := Rect2(origin + Vector2(rect.position.y,-rect.end.x) * scale_unit,Vector2(rect.size.y,rect.size.x) * scale_unit)
		draw_rect(box,Color(0.08,0.16,0.19,0.9))
		draw_rect(box,Color("507c89"),false,1.4)
		var title: String = room[0]
		if title == "SEGURANÇA": title = "VIGILÂNCIA"
		var font_size := 11 if box.size.x < 100 else 13
		var width := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(font,box.get_center()+Vector2(-width/2,4),title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("aec6cb"))
	for id in game.world.doors:
		var door: Node3D = game.world.doors[id]
		if (door.global_position.y > 3.5) != upper: continue
		var point := project(door.global_position)
		draw_circle(point,3.5,Color("58dbac") if door.is_open else Color("d5ad65"))
	var positions: Array = preload("res://scripts/security_camera_layout.gd").POSITIONS
	for i in range(positions.size()):
		if (i >= 3) != upper: continue
		var camera_point := project(positions[i])
		draw_rect(Rect2(camera_point-Vector2(3,3),Vector2(6,6)),Color("53aaff"))
		draw_string(font,camera_point+Vector2(7,3),"%02d" % (i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("53aaff"))
	if (player_point.y > 3.5) == upper:
		var dot := project(player_point)
		var forward := Vector2(-sin(game.player.rotation.y),-cos(game.player.rotation.y))
		forward = Vector2(forward.y,-forward.x)
		var side := Vector2(-forward.y,forward.x)
		draw_colored_polygon(PackedVector2Array([dot+forward*18,dot-forward*8+side*7,dot-forward*8-side*7]),Color("59f3af"))
		draw_arc(dot,12,0,TAU,32,Color(0.35,0.95,0.68,0.5),1.0)
		draw_string(font,dot+Vector2(14,19),"DANIEL",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("59f3af"))
	draw_string(font,Vector2(14,22),"N ←  /  VESPER / " + ("2º ANDAR" if upper else "TÉRREO E EXTERIOR"),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("81b9dc"))
