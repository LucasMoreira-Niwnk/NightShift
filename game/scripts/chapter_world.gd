extends Node3D

const Item = preload("res://scripts/interactable.gd")
const Door = preload("res://scripts/door.gd")
const Materials = preload("res://scripts/materials.gd")
const Art = preload("res://scripts/art.gd")
var game: Node
var objects: Dictionary = {}
var doors: Dictionary = {}
var corridor_lights: Array = []
var interior_lights: Array = []
var room_lights: Array = []
var building_lights: Array = []
var powered_materials: Array = []

# Reator velho das lampadas do corredor: '-' apagado, '*' aceso. Gagueja em
# rajadas curtas e passa trechos longos no escuro.
const CORRIDOR_RHYTHM := "---*---*-*---**--*-*--------*----"
const RHYTHM_STEP := 0.12
# As salas seguem o mesmo compasso invertido, e nunca apagam de fato: a queda
# vai so ate metade da energia nominal, como uma reatancia oscilando.
const ROOM_DIP := 0.5

var corridor_powered := false
var interior_powered := true
var rhythm_time := 0.0
var chair: StaticBody3D
var figure: Node3D
var figure_volume: Node3D
var double: Node3D
var clocks: Array = []
var floor_plans: Array = []
var materials: Dictionary = {}
var dressing: RefCounted
var phone_display: Label3D
var chair_marks: Node3D
var architecture: Node3D
var staircases: Node3D
var upper: Node3D
var fuse_visual: Node3D
var camera_mounts: Array = []
var drifting_fog: Node3D

# Camada visual exclusiva do 2o andar. O andar sai do cull_mask da camera do
# jogador em vez de `visible = false`, porque o feed do CCTV compartilha o
# mesmo World3D (cull_mask 5) e precisa continuar enxergando a CAM-04.
const UPPER_LAYER := 8
# Acima disto o jogador esta no 2o andar. Escadas contam como comodo proprio:
# de dentro do vao os dois niveis aparecem juntos.
const UPPER_FLOOR_Y := 2.0

func _ready() -> void:
	dressing = preload("res://scripts/set_dressing.gd").new()
	for kind in ["tile", "wall", "metal", "wood", "ceiling"]:
		materials[kind] = Materials.surface(kind)
	for kind in ["floor_reception", "floor_security", "floor_archive", "floor_concrete", "upper_floor", "wall_cream", "wall_green", "wall_concrete", "facade", "asphalt", "pavers", "ceiling"]:
		materials[kind] = Materials.architectural(kind)
	materials.wall = materials.wall_cream
	architecture = preload("res://scripts/building_exterior.gd").new()
	architecture.world = self
	add_child(architecture)
	room("Recepção", Vector3(0, 0, 8), Vector2(16, 8))
	room("Corredor", Vector3(0, 0, -6), Vector2(4, 20))
	room("Segurança", Vector3(-5, 0, 1), Vector2(6, 6))
	room("Arquivo", Vector3(5, 0, -6), Vector2(6, 8))
	room("Sala técnica", Vector3(-5, 0, -10), Vector2(6, 8))
	# Outer walls and partitions. Each opening is 1.5 m wide and has a door.
	for x in [-8, 8]: architecture.window_wall(self, Vector3(x, 1.5, 8), Vector3(0.2, 3, 8), [-1.8, 1.8], 2.1)
	for x in [-4.375, 4.375]: architecture.window_wall(self, Vector3(x, 1.5, 12), Vector3(7.25, 3, 0.2), [0.0], 4.6)
	wall(Vector3(0, 2.75, 12), Vector3(1.5, 0.5, 0.2))
	room("Marquise", Vector3(0, 0, 14), Vector2(6, 4))

	make_door("entrance", Vector3(0, 0, 12), "entrada do Vesper")
	doors.entrance.rotation.y = 0
	add_sign("VESPER\nSETOR ADMINISTRATIVO", Vector3(0, 2.8, 12.15)).pixel_size = 0.0011
	wall(Vector3(-4, 1.5, 4), Vector3(4, 3, 0.2))
	# Security extends two metres beyond reception: seal its exposed rear edge.
	wall(Vector3(-7, 1.5, 4), Vector3(2, 3, 0.2))
	wall(Vector3(5, 1.5, 4), Vector3(6, 3, 0.2))
	partition(-8, -2, 4, 1)
	wall(Vector3(-5, 1.5, -2), Vector3(6, 3, 0.2))
	wall(Vector3(-8, 1.5, -10), Vector3(0.2, 3, 8))
	wall(Vector3(-5, 1.5, -6), Vector3(6, 3, 0.2))
	wall(Vector3(-5, 1.5, -14), Vector3(6, 3, 0.2))
	architecture.window_wall(self, Vector3(8, 1.5, -6), Vector3(0.2, 3, 8), [-1.8, 1.0], 0.9)
	wall(Vector3(5, 1.5, -2), Vector3(6, 3, 0.2))
	wall(Vector3(5, 1.5, -10), Vector3(6, 3, 0.2))
	wall(Vector3(2, 1.5, 1), Vector3(0.2, 3, 6))
	wall(Vector3(2, 1.5, -13), Vector3(0.2, 3, 6))
	wall(Vector3(-2, 1.5, -4), Vector3(0.2, 3, 4))
	wall(Vector3(-2, 1.5, -15), Vector3(0.2, 3, 2))
	make_door("stairs", Vector3(0, 0, -15.8), "acesso ao segundo andar")
	doors.stairs.rotation.y = 0
	make_door("service_exit", Vector3(-8, 0, 1), "saída de serviço")
	partition(-2, -2, 4, 1)
	partition(2, -10, -2, -5)
	partition(-2, -14, -6, -10)
	make_door("security", Vector3(-2, 0, 1), "segurança")
	make_door("archive", Vector3(2, 0, -5), "arquivo")
	make_door("technical", Vector3(-2, 0, -10), "sala técnica")
	# Furniture and interactable evidence.
	table(Vector3(-3.3, 0, 7.5), Vector2(3, 1.1))
	table(Vector3(-6.5, 0, 0), Vector2(2.2, 1.3))
	table(Vector3(-4.4, 0, -0.2), Vector2(1, 1))
	Art.rounded_box(self, Vector3(-4.4, 1.23, -0.36), Vector3(0.72, 0.3, 0.45), Color(0.28, 0.29, 0.24), 0.04)
	Art.rounded_box(self, Vector3(-4.4, 1.39, -0.36), Vector3(0.61, 0.035, 0.35), Color(0.12, 0.15, 0.13), 0.012)
	Art.box(self, Vector3(-4.4, 1.16, -0.125), Vector3(0.5, 0.035, 0.02), Color(0.025, 0.035, 0.03))
	table(Vector3(5.5, 0, -7.8), Vector2(2.4, 1.2))
	item("envelope", "Ler envelope e recolher crachá/chave", Vector3(-3.2, 1.086, 7.5), Vector3(0.6, 0.08, 0.4), Color(0.8, 0.72, 0.48))
	item("flashlight", "Pegar lanterna", Vector3(-5.75, 1.11, -0.32), Vector3(0.07, 0.06, 0.25), Color(0.55, 0.58, 0.3))
	item("recorder", "Ouvir gravação 001", Vector3(-7.25, 1.17, 0.3), Vector3(0.32, 0.18, 0.3), Color(0.3, 0.4, 0.42))
	item("logbook", "Ler livro de registros", Vector3(5.8, 1.125, -7.7), Vector3(0.5, 0.09, 0.4), Color(0.38, 0.17, 0.12))
	item("maintenance", "Ler registro de manutenção", Vector3(4.9, 1.105, -7.7), Vector3(0.35, 0.05, 0.4), Color(0.72, 0.75, 0.62))
	item("emergency", "Inspecionar saída de emergência", Vector3(1.84, 1.1, -13.4), Vector3(0.12, 2.2, 1.3), Color(0.17, 0.36, 0.25))
	item("breakers", "Abrir quadro elétrico", Vector3(-7.72, 1.5, -11), Vector3(0.3, 1, 1.1), Color(0.45, 0.45, 0.3))
	item("diagram", "Ler aviso de manutenção", Vector3(-7.75, 1.6, -9.6), Vector3(0.15, 0.6, 0.4), Color(0.8, 0.8, 0.65))
	var fuse := item("fuse_slot", "Examinar cartucho F1 / substituir fusível", Vector3(-7.48, 1.25, -10.65), Vector3(0.15, 0.2, 0.28), Color(0.08, 0.07, 0.05), false)
	Art.rounded_box(fuse, Vector3.ZERO, Vector3(0.15, 0.2, 0.28), Color(0.08, 0.07, 0.05))
	item("phone", "Examinar telefone", Vector3(-2.4, 1.18, 7.5), Vector3(0.34, 0.2, 0.3), Color(0.15, 0.16, 0.15))
	phone_display = add_sign("SEM LINHA", Vector3(-2.4, 1.31, 7.55))
	phone_display.pixel_size = 0.00045
	phone_display.font_size = 24
	item("report", "Ler relatório impresso", Vector3(-4.4, 1.086, 0.15), Vector3(0.36, 0.06, 0.28), Color(0.85, 0.86, 0.75))
	objects.report.hide()
	objects.report.collision_layer = 0
	chair = item("chair", "Examinar cadeira e marcas no piso", Vector3(5.5, 0, -6.5), Vector3(0.7, 0.55, 0.7), Color(0.26, 0.16, 0.1), false)
	Art.external(chair, "SchoolChair_01", Vector3.ZERO, Vector3(0.65, 1.2, 0.65), PI)
	chair_marks = Node3D.new()
	add_child(chair_marks)
	for x in [3.05, 3.45]:
		Art.box(chair_marks, Vector3(x, 0.008, -5.6), Vector3(0.025, 0.008, 1.45), Color(0.045, 0.035, 0.025))
	chair_marks.hide()
	for z in [-3.5, -6.5, -9.0]:
		box(self, Vector3(7.4, 1, z), Vector3(0.9, 2, 1.1), "metal").hide()
		dressing.shelf(self, Vector3(7.4, 0, z), -PI / 2, int(abs(z) * 10))
	# Rolled back from the console so a standing operator has a clear view.
	Art.model(self, "chairDesk", Vector3(-6.1, 0, 2.65), Vector3(0.6, 1.1, 0.6), PI)
	box(self, Vector3(-6.1, 0.35, 2.65), Vector3(0.55, 0.7, 0.55), "metal").hide()
	Art.external(self, "drawer_cabinet", Vector3(-4.1, 0, 3.55), Vector3(1.2, 1.25, 0.65), PI)
	box(self, Vector3(-4.1, 0.625, 3.55), Vector3(1.2, 1.25, 0.65), "metal").hide()
	Art.external(self, "desk_lamp_arm_01", Vector3(-7.25, 1.08, -0.3), Vector3(0.4, 0.65, 0.35))
	var task_light := OmniLight3D.new()
	task_light.position = Vector3(-7.15, 1.65, 0.1)
	task_light.light_color = Color(1, 0.8, 0.53)
	task_light.light_energy = 0.55
	task_light.omni_range = 2.0
	add_child(task_light)
	interior_lights.append(task_light)
	dressing.plant(self, Vector3(4.8, 0, 10.8), 1.0, 12)
	box(self, Vector3(4.8, 0.3, 10.8), Vector3(0.5, 0.6, 0.5), "metal").hide()
	Art.model(self, "trashcan", Vector3(-7.35, 0, 2.9), Vector3(0.38, 0.65, 0.38))
	Art.model(self, "coatRackStanding", Vector3(4.8, 0, 5), Vector3(0.6, 1.8, 0.6))
	box(self, Vector3(4.8, 0.8, 5), Vector3(0.35, 1.6, 0.35), "metal").hide()
	for index in range(3):
		Art.model(self, "cardboardBoxClosed", Vector3(-6.8 + index * 0.7, 0, -13.55), Vector3(0.55, 0.6, 0.55))
		box(self, Vector3(-6.8 + index * 0.7, 0.3, -13.55), Vector3(0.55, 0.6, 0.55), "metal").hide()
	add_floor_plan(Vector3(-4.8, 1.55, 4.14), 0, "reception")
	add_floor_plan(Vector3(-4.4, 1.55, -1.86), 0, "security")
	add_clock(Vector3(-2.9, 2.28, 4.14))
	add_clock(Vector3(-3.2, 2.28, -1.86))
	add_clock(Vector3(1.86, 2.28, -1), -PI / 2)
	Art.box(self, Vector3(-4.8, 2.6, 4.14), Vector3(1.5, 0.25, 0.05), Color(0.06, 0.1, 0.085))
	var reception_sign := add_sign("VESPER / RECEPÇÃO", Vector3(-4.8, 2.6, 4.18))
	reception_sign.pixel_size = 0.0013
	var direction_plaque := Art.box(self, Vector3(3.5,2.25,4.14),Vector3(2.2,0.35,0.05),Color(0.06,0.1,0.085))
	direction_plaque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var direction_sign := add_sign("SEGURANÇA ←   |   ARQUIVO →\nTÉCNICA ← / FUNDO", Vector3(3.5,2.25,4.18))
	direction_sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	direction_sign.pixel_size = 0.0013
	add_sign("ARQUIVO", Vector3(5, 2.6, -9.8))
	add_sign("SEGURANÇA", Vector3(-5, 2.6, -1.8))
	add_sign("SALA TÉCNICA", Vector3(-5, 2.6, -13.8))
	figure = preload("res://scripts/memesis.gd").new()
	add_child(figure)
	figure.position = Vector3(0, 0, -13)
	figure.hide()
	# Segundo vulto, so para comparacao: a foto refeita em nevoa volumetrica.
	# O F5 o traz; o capitulo nao sabe que ele existe.
	figure_volume = preload("res://scripts/memesis_corpo.gd").new()
	add_child(figure_volume)
	figure_volume.position = Vector3(0, 0, -13)
	figure_volume.hide()
	double = humanoid(Color(0.19, 0.28, 0.24))
	double.position = Vector3(0, 0, 8)
	var badge := Art.box(double, Vector3(-0.13, 1.3, 0.14), Vector3(0.09, 0.12, 0.012), Color(0.75, 0.72, 0.6))
	badge.layers = 4
	var duplicate_envelope := Node3D.new()
	double.add_child(duplicate_envelope)
	duplicate_envelope.position = Vector3(0.4, 0.95, 0.1)
	Art.paper(duplicate_envelope, Vector3(0.28, 0.02, 0.18), true)
	for mesh in duplicate_envelope.find_children("*", "MeshInstance3D", true, false): mesh.layers = 4
	duplicate_envelope.hide()
	double.set_meta("envelope", duplicate_envelope)
	double.hide()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.006, 0.008, 0.011)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# ponytail: SSAO nao existe no renderizador Compatibility (4.0); o escuro vem
	# do ambiente fraco e frio, que afunda quinas e vaos sem luz direta
	environment.environment.ambient_light_color = Color(0.18, 0.26, 0.30)
	environment.environment.ambient_light_energy = 0.04
	# Sem isto nenhum FogVolume desenha, nem no Forward+: o Mêmesis (memesis.gd)
	# e um corpo de nevoa, e e esta chave que liga o sistema que o renderiza.
	# Em gl_compatibility a propriedade existe mas nao faz nada.
	environment.environment.volumetric_fog_enabled = true
	environment.environment.volumetric_fog_density = 0.0
	# Glow so para a franja do Memesis sangrar um pouco no ar. O limiar alto e
	# o que segura o resto da cena de fora: as lampadas do predio ficam abaixo
	# dele, e so a franja, empurrada acima de 1.0 pelo shader, acende o bloom.
	environment.environment.glow_enabled = true
	environment.environment.glow_hdr_threshold = 1.1
	environment.environment.glow_intensity = 0.55
	environment.environment.glow_bloom = 0.05
	add_child(environment)
	# Bolhas de nevoa vagando num raio de 10 m do jogador: clima sem custo de
	# geometria. Depende do volumetric_fog_enabled ligado acima.
	drifting_fog = preload("res://scripts/drifting_fog.gd").new()
	drifting_fog.game = game
	add_child(drifting_fog)
	staircases = preload("res://scripts/folded_stairs.gd").new()
	staircases.world = self
	add_child(staircases)
	upper = preload("res://scripts/second_floor.gd").new()
	upper.game = game
	upper.world = self
	add_child(upper)
	fuse_visual = Node3D.new()
	objects.fuse_slot.add_child(fuse_visual)
	fuse_visual.position.x = 0.09
	fuse_visual.rotation.y = PI / 2
	upper.fuse_model(fuse_visual, Color(0.13, 0.09, 0.065))
	preload("res://scripts/security_camera_layout.gd").install(self)
	architecture.build()
	capture_building_power()
	tag_upper_layer(upper)

func box(parent: Node3D, location: Vector3, size: Vector3, kind: String = "wall", collision: bool = true, color: Color = Color.WHITE) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.position = location
	if materials.has(kind):
		mesh.material_override = materials[kind]
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		mesh.material_override = material
	parent.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.position = location
		body.add_child(collider)
		parent.add_child(body)
	return mesh

func wall(location: Vector3, size: Vector3) -> void:
	var kind := "wall_cream" if location.z > 4 else ("wall_concrete" if location.x < -2 and location.z < -6 else "wall_green")
	box(self, location, size, kind)
	if size.y > 2.9:
		var lower := Vector3(size.x + 0.012, 1.05, size.z + 0.012)
		var panel := Materials.architectural("wall_green")
		panel.set_shader_parameter("tint", Color(0.3, 0.4, 0.35))
		Art.box(self, Vector3(location.x, 0.525, location.z), lower, Color.WHITE, panel)
		Art.box(self, Vector3(location.x, 0.08, location.z), Vector3(size.x + 0.035, 0.16, size.z + 0.035), Color(0.065, 0.085, 0.075))
		Art.box(self, Vector3(location.x, 1.07, location.z), Vector3(size.x + 0.025, 0.055, size.z + 0.025), Color(0.09, 0.13, 0.12))

func partition(x: float, start: float, end: float, opening: float) -> void:
	wall(Vector3(x, 1.5, (start + opening - 0.75) / 2), Vector3(0.2, 3, opening - 0.75 - start))
	wall(Vector3(x, 1.5, (end + opening + 0.75) / 2), Vector3(0.2, 3, end - opening - 0.75))
	wall(Vector3(x, 2.75, opening), Vector3(0.2, 0.5, 1.5))

func room(label: String, center: Vector3, size: Vector2) -> void:
	var floor_kind := {"Recepção": "floor_reception", "Segurança": "floor_security", "Arquivo": "floor_archive", "Sala técnica": "floor_concrete", "Marquise": "floor_concrete", "Corredor": "floor_reception"}
	box(self, center + Vector3(0, -0.15, 0), Vector3(size.x, 0.3, size.y), floor_kind[label])
	box(self, center + Vector3(0, 3.1, 0), Vector3(size.x, 0.2, size.y), "ceiling")
	var light := OmniLight3D.new()
	light.position = center + Vector3(0, 2.6, 0)
	light.light_color = Color(0.66, 0.79, 0.72) if label == "Segurança" else Color(0.92, 0.79, 0.6)
	light.light_energy = 0.85
	light.omni_range = 5.6
	light.shadow_enabled = true
	light.shadow_bias = 0.04
	add_child(light)
	interior_lights.append(light)
	if label != "Corredor":
		pulse_light(light)
	if label == "Corredor":
		light.light_color = Color(0.46, 0.64, 0.66)
		light.light_energy = 0.3
		light.omni_range = 4.2
		corridor_lights.append(light)
		for z in [1.0, -12.0]:
			var extra := light.duplicate() as OmniLight3D
			extra.position.z = z
			add_child(extra)
			interior_lights.append(extra)
			corridor_lights.append(extra)
	var fixture := Art.model(self, "lampSquareCeiling", center + Vector3(0, 2.7, 0), Vector3(0.8, 0.3, 0.8))
	disable_fixture_shadows(fixture)

## O mesmo reator gagueja no predio inteiro: ter andar e escada no registro e o
## que faz a variacao existir fora do terreo.
func pulse_light(light: Light3D) -> void:
	room_lights.append({"light": light, "energy": light.light_energy})

func make_door(id: String, location: Vector3, label: String) -> void:
	var door := Door.new()
	door.position = location
	door.rotation.y = PI / 2
	door.display_name = label
	door.glazed = id == "entrance"
	door.access = func(): return game.chapter.can_open(id)
	add_child(door)
	doors[id] = door
	door.operated.connect(func(opened: bool):
		if game.sound != null:
			game.sound.play("door_open" if opened else "door_close", door.global_position + Vector3.UP, -18))

func table(location: Vector3, size: Vector2) -> void:
	box(self, location + Vector3(0, 1, 0), Vector3(size.x, 0.16, size.y), "wood").hide()
	for x in [-size.x * 0.4, size.x * 0.4]:
		box(self, location + Vector3(x, 0.46, 0), Vector3(0.12, 0.92, size.y * 0.8), "metal").hide()
	Art.external(self, "metal_office_desk", location, Vector3(size.x, 1.08, size.y))

func item(id: String, prompt: String, location: Vector3, size: Vector3, color: Color, visible_box: bool = true) -> StaticBody3D:
	var body := Item.new()
	body.name = id
	body.prompt = prompt
	body.action = func(): game.chapter.interact(id)
	body.position = location
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	if id == "chair":
		collider.position.y = 0.55
	body.add_child(collider)
	add_child(body)
	if visible_box:
		match id:
			"logbook", "maintenance": Art.external(body, "binder_notebook", Vector3(0, -size.y * 0.5, 0), size)
			"envelope", "report": Art.paper(body, size, id == "envelope")
			"diagram": Art.wall_diagram(body, size)
			"recorder": Art.external(body, "vintage_radio_transceiver", Vector3(0, -size.y * 0.5, 0), size)
			"flashlight": Art.flashlight(body, Vector3(0, -size.y * 0.5, 0), 0.24)
			"phone":
				Art.rounded_box(body, Vector3.ZERO, size, color, 0.045)
				decorate_item(body, id, size)
			_:
				box(body, Vector3.ZERO, size, "plain", false, color)
				decorate_item(body, id, size)
	objects[id] = body
	return body

func decorate_item(body: Node3D, id: String, size: Vector3) -> void:
	if id == "phone":
		Art.rounded_box(body, Vector3(0, size.y * 0.6, 0), Vector3(size.x * 1.1, 0.07, 0.09), Color(0.04, 0.055, 0.05))
		for index in range(9):
			Art.box(body, Vector3(-0.07 + (index % 3) * 0.06, size.y * 0.52, 0.03 + (index / 3) * 0.04), Vector3(0.035, 0.008, 0.025), Color(0.45, 0.46, 0.39))
	elif id == "breakers":
		for index in range(4):
			Art.box(body, Vector3(size.x * 0.51, -0.3 + index * 0.2, 0), Vector3(0.04, 0.12, 0.24), Color(0.06, 0.08, 0.075))
			Art.box(body, Vector3(size.x * 0.6, -0.3 + index * 0.2, 0), Vector3(0.06, 0.05, 0.08), Color(0.56, 0.24, 0.12))
	elif id == "emergency" or id == "stairs":
		var inset := size * 0.85
		Art.box(body, Vector3.ZERO, inset, Color(0.12, 0.2, 0.17))
		var bar := Vector3(0.05, 0.06, 0.9) if id == "emergency" else Vector3(1.15, 0.06, 0.05)
		var position := Vector3(-0.1, 0, 0) if id == "emergency" else Vector3(0, 0, 0.1)
		Art.box(body, position, bar, Color(0.42, 0.43, 0.35))

func add_sign(text: String, location: Vector3, angle: float = 0) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = location
	label.rotation.y = angle
	label.shaded = true
	label.font_size = 48
	label.pixel_size = 0.003
	label.outline_size = 0
	label.modulate = Color(0.64, 0.9, 0.75)
	add_child(label)
	return label

func humanoid(color: Color, parent: Node3D = null) -> Node3D:
	var root := Node3D.new()
	if parent == null: parent = self
	parent.add_child(root)
	for data in [[Vector3(0, 1.15, 0), Vector3(0.48, 0.65, 0.25)], [Vector3(-0.15, 0.42, 0), Vector3(0.18, 0.85, 0.2)], [Vector3(0.15, 0.42, 0), Vector3(0.18, 0.85, 0.2)], [Vector3(-0.33, 1.05, 0), Vector3(0.16, 0.7, 0.2)], [Vector3(0.33, 1.05, 0), Vector3(0.16, 0.7, 0.2)]]:
		var mesh := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.5
		capsule.height = 2
		capsule.radial_segments = 24
		mesh.mesh = capsule
		mesh.position = data[0]
		mesh.scale = Vector3(data[1].x, data[1].y / 2.0, data[1].z)
		var surface := StandardMaterial3D.new()
		surface.albedo_color = color
		mesh.material_override = surface
		root.add_child(mesh)
		mesh.layers = 4
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.17
	sphere.height = 0.36
	head.mesh = sphere
	head.position.y = 1.7
	head.layers = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	head.material_override = material
	root.add_child(head)
	return root

func set_corridor_power(powered: bool) -> void:
	corridor_powered = powered
	if not powered:
		for light in corridor_lights: light.visible = false

func set_interior_power(powered: bool) -> void:
	interior_powered = powered
	for entry in building_lights: entry.light.visible = powered and entry.enabled
	for entry in powered_materials: entry.material.emission_enabled = powered
	if game.computer != null and game.computer.monitor_glow != null:
		game.computer.monitor_glow.visible = powered and game.computer.monitor_power

func _process(delta: float) -> void:
	update_floor_culling()
	if corridor_lights.is_empty(): return
	rhythm_time += delta
	var step := int(rhythm_time / RHYTHM_STEP) % CORRIDOR_RHYTHM.length()
	var beat := CORRIDOR_RHYTHM[step] == "*"
	for light in corridor_lights:
		light.visible = beat and corridor_powered and interior_powered
	# Invertido em relacao ao corredor: onde o corredor acende, a sala cai.
	for entry in room_lights:
		entry.light.light_energy = entry.energy * (ROOM_DIP if beat else 1.0)

func in_security(point: Vector3) -> bool:
	return point.y < 1.0 and point.x < -2.3 and point.x > -7.8 and point.z > -1.8 and point.z < 3.8

func add_clock(location: Vector3, angle: float = 0) -> void:
	var clock := preload("res://scripts/wall_clock.gd").new()
	clock.position = location
	clock.rotation.y = angle
	add_child(clock)
	clocks.append(clock)

func set_time(value: String) -> void:
	for clock in clocks: clock.set_time(value)

func add_floor_plan(location: Vector3, angle: float, id: String) -> void:
	var board := Item.new()
	board.prompt = "Consultar planta do térreo"
	board.position = location
	board.rotation.y = angle
	var texture := load("res://assets/signage/floor_plan_" + id + ".svg") as Texture2D
	board.action = func(): game.ui.show_floor_plan(texture)
	add_child(board)
	Art.box(board, Vector3.ZERO, Vector3(1.16, 1.66, 0.055), Color(0.085, 0.12, 0.1))
	var image := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.07, 1.55)
	image.mesh = quad
	image.position.z = 0.03
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color(0.75, 0.75, 0.7)
	image.material_override = material
	board.add_child(image)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.16, 1.66, 0.055)
	collision.shape = shape
	board.add_child(collision)
	floor_plans.append(board)


func tag_upper_layer(node: Node) -> void:
	# Malhas e luzes ja movidas de proposito para a camada do jogador (2) ou do
	# CCTV (4) ficam como estao; so o que esta no padrao ganha a camada do andar.
	for child in node.get_children():
		if child is VisualInstance3D and child.layers == 1:
			child.layers |= UPPER_LAYER
		tag_upper_layer(child)

func update_floor_culling() -> void:
	if game.player == null: return
	var point: Vector3 = game.player.global_position
	# Visivel da rua tambem, senao as janelas do 2o andar ficariam vazias.
	var sees_upper: bool = point.y > UPPER_FLOOR_Y or staircases.is_main(point) or staircases.is_service(point) or is_outdoors(point)
	var mask: int = game.player.camera.cull_mask
	game.player.camera.cull_mask = (mask | UPPER_LAYER) if sees_upper else (mask & ~UPPER_LAYER)

func is_outdoors(point: Vector3) -> bool:
	if absf(point.x) < 8.15 and point.z > -16.15 and point.z < 12: return false
	if absf(point.x) < 3.05 and point.z > -24.4 and point.z < -14: return false
	if point.x > -14.5 and point.x < -8 and point.z > -10.7 and point.z < 3.2: return false
	return true

func capture_building_power() -> void:
	# Capture fixtures once, after both floors, stairs and exterior are built.
	# Moonlight and the colleague's autonomous Mêmesis are not mains fixtures.
	for lamp in find_children("*", "Light3D", true, false):
		if lamp is DirectionalLight3D or independent_effect(lamp): continue
		building_lights.append({"light": lamp, "enabled": lamp.visible})
	var known: Dictionary = {}
	for mesh in find_children("*", "MeshInstance3D", true, false):
		if independent_effect(mesh) or mesh.mesh == null: continue
		for index in range(mesh.mesh.get_surface_count()):
			var material: Material = mesh.get_active_material(index)
			if material is StandardMaterial3D and material.emission_enabled and not known.has(material.get_instance_id()):
				known[material.get_instance_id()] = true
				powered_materials.append({"material": material})

func independent_effect(node: Node) -> bool:
	return figure.is_ancestor_of(node) or (figure_volume != null and figure_volume.is_ancestor_of(node))

func disable_fixture_shadows(fixture: Node3D) -> void:
	# The point light sits inside this decorative housing. Its mesh must not
	# occlude the emitter and project an oversized black patch on the ceiling.
	for part in fixture.find_children("*", "GeometryInstance3D", true, false):
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
