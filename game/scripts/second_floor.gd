extends Node3D

const Layout = preload("res://scripts/building_layout.gd")
const HEIGHT := 4.2
const Art = preload("res://scripts/art.gd")
var game: Node
var world: Node3D
var lights: Array = []
var emergency_lights: Array = []
var camera_chair: Node3D
var warning: Label3D
var window_shadow: MeshInstance3D

func _ready() -> void:
	name = "SecondFloor"
	position.y = HEIGHT
	room(Vector3(0, 0, -38), Vector2(4, 24))
	room(Vector3(-6, 0, -31), Vector2(8, 8))
	room(Vector3(-6, 0, -42), Vector2(8, 10))
	room(Vector3(6, 0, -38), Vector2(8, 14))
	wall(Vector3(0, 1.5, -50), Vector3(4, 3, 0.2))
	wall(Vector3(-6, 1.5, -27), Vector3(8, 3, 0.2))
	wall(Vector3(-6, 1.5, -35), Vector3(8, 3, 0.2))
	wall(Vector3(-6, 1.5, -37), Vector3(8, 3, 0.2))
	wall(Vector3(-6, 1.5, -47), Vector3(8, 3, 0.2))
	wall(Vector3(-10, 1.5, -42), Vector3(0.2, 3, 10))
	world.architecture.window_wall(self, Layout.upper_point(Vector3(10, 1.5, -38)), Vector3(0.2, 3, 14), [-4.8, -1.6, 1.6, 4.8], 2.1)
	wall(Vector3(6, 1.5, -31), Vector3(8, 3, 0.2))
	wall(Vector3(6, 1.5, -45), Vector3(8, 3, 0.2))
	partition(-2, -50, -36, -42)
	partition(-2, -36, -26, -31)
	partition(2, -50, -26, -38)
	partition(-10, -35, -27, -31)
	for x in [-5.46875, 5.46875]: wall(Vector3(x, 1.5, -26), Vector3(9.0625, 3, 0.2))
	block(Vector3(0, 2.8, -26), Vector3(1.875, 0.4, 0.2))
	door("upper_gate", Vector3(0, 0, -26), "palier / escadaria", 0)
	door("administration", Vector3(-2, 0, -31), "administração")
	door("it", Vector3(-2, 0, -42), "sala de TI")
	door("meeting", Vector3(2, 0, -38), "sala de reuniões")
	door("service_upper", Vector3(-10, 0, -31), "escada de serviço")
	world.table(Layout.upper_point(Vector3(-6.8, HEIGHT, -33)), Vector2(2.5, 1.2))
	world.table(Layout.upper_point(Vector3(-6.5, HEIGHT, -44.5)), Vector2(3, 1.3))
	world.table(Layout.upper_point(Vector3(6, HEIGHT, -38.5)), Vector2(3.2, 1.5))
	paper("repair_note", "Ler ordem de manutenção", Vector3(-6.6, 1.1, -33), true)
	paper("admin_notice", "Ler aviso administrativo", Vector3(-7.3, 1.1, -33))
	paper("network_log", "Ler log de rede", Vector3(-6.8, 1.1, -44.3))
	paper("meeting_minutes", "Ler ata da reunião", Vector3(5.3, 1.1, -38.4))
	paper("access_log", "Conferir registros de acesso", Vector3(6.5, 1.1, -38.4))
	paper("henrique_photo", "Examinar fotografia de Henrique", Vector3(6.8, 1.1, -38.7))
	for data in [["fuse20", 20, -5.8], ["fuse10", 10, -5.1]]:
		var fuse := item(data[0], "Pegar fusível %d A" % data[1], Vector3(data[2], 1.14, -44.3), Vector3(0.28, 0.12, 0.2))
		fuse_model(fuse, Color(0.8, 0.76, 0.57))
		add_label("%d A" % data[1], Vector3(data[2], 1.25, -44.35), 0, 0.0008)
	var panel := item("network_patch", "Examinar patch panel — Rack 2B", Vector3(-9.7, 1.45, -42), Vector3(0.3, 1.4, 1.4))
	Art.rounded_box(panel, Vector3.ZERO, Vector3(0.3, 1.4, 1.4), Color(0.055, 0.075, 0.07))
	for index in range(8):
		Art.box(panel, Vector3(0.16, -0.45 + (index / 4) * 0.4, -0.5 + (index % 4) * 0.32), Vector3(0.03, 0.13, 0.18), Color(0.12, 0.3, 0.23))
	add_label("RACK 2B — PATCH PANEL", Vector3(-9.45, 2.45, -42), PI / 2, 0.0012)
	var diagnostic := item("it_terminal", "Usar terminal de diagnóstico / gravações", Vector3(-7.2, 1.45, -44.7), Vector3(0.8, 0.65, 0.2))
	diagnostic.rotation.y = PI
	Art.rounded_box(diagnostic, Vector3.ZERO, Vector3(0.8, 0.65, 0.2), Color(0.035, 0.055, 0.05))
	Art.box(diagnostic, Vector3(0, 0, 0.11), Vector3(0.7, 0.5, 0.015), Color(0.1, 0.3, 0.22))
	for index in range(6):
		var point := Vector3(4.8 + (index % 3) * 1.2, 0, -37.3 if index < 3 else -39.7)
		var chair := Art.external(self, "SchoolChair_01", Layout.upper_point(point), Vector3(0.65, 1.2, 0.65), 0.0 if index < 3 else PI)
		block(point + Vector3(0, 0.45, 0), Vector3(0.55, 0.9, 0.55), "metal").hide()
		if index == 5:
			mesh_layers(chair, 2)
			camera_chair = chair.duplicate()
			add_child(camera_chair)
			mesh_layers(camera_chair, 4)
	item("meeting_terminal", "Usar projetor / arquivo da reunião", Vector3(8.7, 1.1, -38), Vector3(0.45, 0.3, 0.4))
	Art.rounded_box(world.objects.meeting_terminal, Vector3.ZERO, Vector3(0.45, 0.3, 0.4), Color(0.22, 0.25, 0.21))
	item("emergency_map", "Consultar planta de emergência do segundo andar", Vector3(1.84, 1.6, -27.8), Vector3(0.12, 1.2, 1.2))
	Art.box(world.objects.emergency_map, Vector3.ZERO, Vector3(0.08, 1.1, 1.1), Color(0.15, 0.33, 0.25))
	var map_image := MeshInstance3D.new()
	var map_quad := QuadMesh.new()
	map_quad.size = Vector2(1.02, 1.02)
	map_image.mesh = map_quad
	map_image.position.x = -0.06
	map_image.rotation.y = -PI / 2
	var map_material := StandardMaterial3D.new()
	map_material.albedo_texture = load("res://assets/signage/second_floor.svg")
	map_material.albedo_color = Color(0.72, 0.72, 0.68)
	map_image.material_override = map_material
	world.objects.emergency_map.add_child(map_image)
	add_label("PLANTA / EMERGÊNCIA", Vector3(1.75, 2.35, -27.8), -PI / 2, 0.001)
	var responding := item("knock_door", "Bater na porta fechada", Vector3(-1.85, 1.2, -36), Vector3(0.15, 2.4, 1.4))
	Art.rounded_box(responding, Vector3.ZERO, Vector3(0.15, 2.4, 1.4), Color(0.16, 0.2, 0.17))
	var voice := item("voice_door", "Examinar porta com janela", Vector3(-6, 1.2, -34.82), Vector3(1.5, 2.4, 0.12))
	voice.rotation.y = PI
	Art.rounded_box(voice, Vector3.ZERO, Vector3(1.5, 2.4, 0.12), Color(0.1, 0.17, 0.15))
	Art.box(voice, Vector3(0, 0.6, 0.07), Vector3(0.85, 0.5, 0.025), Color(0.26, 0.32, 0.29))
	window_shadow = Art.box(voice, Vector3(-0.35, 0.6, 0.09), Vector3(0.17, 0.4, 0.01), Color(0.01, 0.018, 0.015))
	window_shadow.hide()
	for entry in [["ADMINISTRAÇÃO", Vector3(-4.5, 2.5, -34.8)], ["TI / COMPONENTES", Vector3(-6.5, 2.5, -46.8)], ["SALA DE REUNIÕES", Vector3(6, 2.5, -44.8)], ["2º ANDAR\nADMINISTRAÇÃO →  |  ← REUNIÕES\nTI — FUNDO À DIREITA", Vector3(0, 2.5, -27.0)]]:
		add_label(entry[0], entry[1], 0, 0.0015)
	# Continuous slabs and facade close unused service voids between rooms.
	block(Vector3(0, -0.15, -38), Vector3(20, 0.3, 24), "upper_floor")
	block(Vector3(0, 3.1, -38), Vector3(20, 0.2, 24), "ceiling")
	world.architecture.window_wall(self, Vector3(0, 1.5, 10), Vector3(16, 3, 0.2), [-5.5, -2.2, 2.2, 5.5], 2.0)
	for x in [-8, 8]:
		world.box(self, Vector3(x, 1.5, 8.5), Vector3(0.2, 3, 3), "wall")
	world.box(self, Vector3(8, 1.5, 6), Vector3(0.2, 3, 2), "wall")
	world.box(self, Vector3(8, 1.5, -11.5), Vector3(0.2, 3, 5), "wall")
	world.box(self, Vector3(-8, 1.5, -13.5), Vector3(0.2, 3, 1), "wall")
	service_route()

func block(point: Vector3, size: Vector3, kind: String = "wall", collision: bool = true) -> MeshInstance3D:
	return world.box(self, Layout.upper_point(point), Vector3(size.x * 0.8, size.y, size.z), kind, collision)

func wall(point: Vector3, size: Vector3) -> void:
	block(point, size, "wall_cream" if point.z > -36 else "wall_green")
	var panel := preload("res://scripts/materials.gd").architectural("wall_green")
	panel.set_shader_parameter("tint", Color(0.3,0.4,0.35))
	Art.box(self, Layout.upper_point(Vector3(point.x, 0.5, point.z)), Vector3(size.x * 0.8 + 0.015, 1, size.z + 0.015), Color(0.13, 0.2, 0.18), panel)

func partition(x: float, start: float, end: float, opening: float) -> void:
	wall(Vector3(x, 1.5, (start + opening - 0.75) / 2), Vector3(0.2, 3, opening - 0.75 - start))
	wall(Vector3(x, 1.5, (end + opening + 0.75) / 2), Vector3(0.2, 3, end - opening - 0.75))
	block(Vector3(x, 2.8, opening), Vector3(0.2, 0.4, 1.5))

func room(point: Vector3, size: Vector2) -> void:
	# One continuous slab/ceiling is shared by all rooms; no coplanar overlays.
	var light := OmniLight3D.new()
	light.position = Layout.upper_point(point + Vector3(0, 2.65, 0))
	light.light_color = Color(0.59, 0.73, 0.68)
	light.light_energy = 0.9
	light.omni_range = 6.3
	light.shadow_enabled = true
	add_child(light)
	lights.append(light)
	world.interior_lights.append(light)
	world.pulse_light(light)
	var fixture := Art.model(self, "lampSquareCeiling", Layout.upper_point(point + Vector3.UP * 2.8), Vector3(0.8, 0.2, 0.8))
	world.disable_fixture_shadows(fixture)
	var emergency := OmniLight3D.new()
	emergency.position = Layout.upper_point(point + Vector3.UP * 2.4)
	emergency.light_color = Color(1, 0.1, 0.04)
	emergency.light_energy = 0.4
	emergency.omni_range = 6.5
	emergency.visible = false
	add_child(emergency)
	emergency_lights.append(emergency)

func door(id: String, point: Vector3, label: String, angle: float = PI / 2) -> void:
	world.make_door(id, Layout.upper_point(point) + Vector3.UP * HEIGHT, label)
	world.doors[id].rotation.y = angle

func item(id: String, prompt: String, point: Vector3, size: Vector3) -> StaticBody3D:
	return world.item(id, prompt, Layout.upper_point(point) + Vector3.UP * HEIGHT, size, Color.WHITE, false)

func paper(id: String, prompt: String, point: Vector3, envelope: bool = false) -> void:
	var body := item(id, prompt, point, Vector3(0.4, 0.055, 0.3))
	Art.paper(body, Vector3(0.4, 0.055, 0.3), envelope)

func add_label(text: String, point: Vector3, angle: float, scale: float) -> Label3D:
	var label: Label3D = world.add_sign(text, Layout.upper_point(point) + Vector3.UP * HEIGHT, PI - angle)
	label.pixel_size = scale
	return label

func fuse_model(parent: Node3D, color: Color) -> void:
	for index in range(3):
		var mesh := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.035 if index == 0 else 0.041
		cylinder.bottom_radius = cylinder.top_radius
		cylinder.height = 0.18 if index == 0 else 0.035
		cylinder.radial_segments = 24
		mesh.mesh = cylinder
		mesh.rotation.z = PI / 2
		mesh.position.x = 0 if index == 0 else (-0.09 if index == 1 else 0.09)
		var material := StandardMaterial3D.new()
		material.albedo_color = color if index == 0 else Color(0.5, 0.52, 0.47)
		material.metallic = 0.0 if index == 0 else 0.7
		mesh.material_override = material
		parent.add_child(mesh)

func mesh_layers(node: Node, layers: int) -> void:
	if node is MeshInstance3D: node.layers = layers
	for child in node.get_children(): mesh_layers(child, layers)

func service_route() -> void:
	warning = world.staircases.warning

func apply_state() -> void:
	var blackout: bool = game.chapter.stage == 15
	for light in lights: light.visible = world.interior_powered and not blackout
	for light in emergency_lights: light.visible = false
	warning.visible = not game.chapter.has_flag("service_message_gone")
	if world.fuse_visual != null:
		world.fuse_visual.visible = not game.chapter.has_flag("burnt_fuse_removed") or game.chapter.has_flag("fuse_replaced")
		world.fuse_visual.get_child(0).material_override.albedo_color = Color(0.8, 0.76, 0.57) if game.chapter.has_flag("fuse_replaced") else Color(0.13, 0.09, 0.065)
	world.objects.fuse20.visible = not game.chapter.has_flag("fuse20_taken")
	world.objects.fuse20.collision_layer = 0 if game.chapter.has_flag("fuse20_taken") else 1
	var origin := Layout.upper_point(Vector3(7.2, 0, -39.7))
	camera_chair.position = origin + (Vector3(0, 0, 0.65) if game.chapter.has_flag("henrique_identified") else Vector3.ZERO)
