extends SceneTree
# One-time additive migration. Never rebake the user's existing scenery.
const Art = preload("res://scripts/art.gd")
var game: Node
var scene: Node3D
var addition: Node3D
var room: Node3D

func _initialize() -> void: call_deferred("run")

func own(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner = owner_root
		if child.scene_file_path.is_empty(): own(child,owner_root)

func block(point: Vector3, size: Vector3, kind: String = "wall_cream") -> MeshInstance3D:
	var mesh: MeshInstance3D = game.world.box(room,point,size,kind)
	# Keep authored collision together with its visual when moved in the editor.
	var body: Node3D = room.get_child(room.get_child_count()-1)
	body.reparent(mesh,true)
	return mesh

func item(id: String, point: Vector3, size: Vector3, prompt: String) -> Node3D:
	var body: Node3D = game.world.item(id,prompt,point,size,Color.WHITE,false)
	body.reparent(room,true)
	body.set_meta("exploration_id",id)
	return body

func paper(id: String, point: Vector3, prompt: String) -> void:
	var body := item(id,point,Vector3(0.36,0.04,0.26),prompt)
	Art.paper(body,Vector3(0.36,0.04,0.26),false)

func desk(point: Vector3, width: float = 1.8) -> void:
	var model := Art.external(room,"metal_office_desk",point,Vector3(width,1.08,0.8))
	var mesh := block(point+Vector3(0,0.52,0),Vector3(width,1.04,0.8),"metal")
	mesh.hide()
	model.name = "Bancada"

func label(text: String, point: Vector3, angle: float = 0) -> void:
	var sign := Label3D.new()
	sign.text = text
	sign.position = point
	sign.rotation.y = angle
	sign.font_size = 38
	sign.pixel_size = 0.0014
	sign.modulate = Color(0.7,0.73,0.62)
	sign.outline_size = 0
	room.add_child(sign)

func door(id: String, point: Vector3, caption: String) -> void:
	game.world.make_door(id,point,caption)
	var body: Node3D = game.world.doors[id]
	body.reparent(room,true)
	body.set_meta("exploration_id",id)
	body.set_meta("exploration_door",true)
	body.set_meta("door_caption",caption)
	body.set_script(load("res://scripts/authored_door.gd"))

func key(id: String, point: Vector3) -> void:
	var body := item(id,point,Vector3(0.28,0.065,0.18),"Recolher chave — "+("Pessoal" if id == "personnel_key" else "TI"))
	Art.rounded_box(body,Vector3(-0.055,0,0),Vector3(0.09,0.025,0.09),Color(0.55,0.49,0.31),0.025)
	Art.box(body,Vector3(0.035,0,0),Vector3(0.12,0.018,0.024),Color(0.55,0.49,0.31))
	Art.box(body,Vector3(0.075,0,0.025),Vector3(0.025,0.02,0.05),Color(0.55,0.49,0.31))
	Art.box(body,Vector3(-0.1,-0.005,0.055),Vector3(0.1,0.014,0.09),Color(0.55,0.59,0.47))

func start_room(title: String, center: Vector3, size: Vector2, floor_kind: String, slab: bool) -> void:
	room = Node3D.new()
	room.name = title
	addition.add_child(room)
	if slab:
		block(center-Vector3.UP*0.15,Vector3(size.x,0.3,size.y),floor_kind)
		block(center+Vector3.UP*3.1,Vector3(size.x,0.2,size.y),"ceiling")
	var light := OmniLight3D.new()
	light.position = center+Vector3.UP*2.6
	light.light_color = Color(0.78,0.77,0.63)
	light.light_energy = 0.65
	light.omni_range = 4.3
	light.shadow_enabled = true
	room.add_child(light)
	var fixture: Node3D = game.world.install_fixture(room,center+Vector3.UP*2.8,light)
	fixture.set_script(load("res://scripts/authored_fixture.gd"))
	fixture.set_meta("exploration_light",fixture.get_path_to(light))

func cut_opening(x: float, y: float, z: float) -> void:
	# Cut only thin wall boxes crossing this door. Duplicate preserves materials,
	# transforms and attached collisions from the user's authored scene.
	for mesh in scene.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh is BoxMesh or mesh.get_meta("vesper_gameplay_reference",false): continue
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		if absf(bounds.get_center().x-x)>0.16 or bounds.size.x>0.4: continue
		if bounds.end.y < y+0.1 or bounds.position.y > y+2.65: continue
		if bounds.end.z <= z-0.83 or bounds.position.z >= z+0.83: continue
		var low := bounds.position.z
		var high := bounds.end.z
		for limits in [[low,minf(z-0.83,high)],[maxf(z+0.83,low),high]]:
			if limits[1]-limits[0] < 0.02: continue
			var part: MeshInstance3D = mesh.duplicate(15)
			mesh.get_parent().add_child(part)
			part.global_transform = mesh.global_transform
			part.scale.z *= (limits[1]-limits[0])/bounds.size.z
			part.global_position.z = (limits[0]+limits[1])*0.5
			# Existing IDs: first segment updates original; second becomes independent.
		mesh.free()
	# Lintel above the door retains a continuous load-bearing wall. It starts at
	# 2.5 m like chapter_world.partition: the door frame ends at 2.6 m, and a 2.7 m
	# lintel left a visible gap above every new door (fixed in novas_salas.tscn).
	block(Vector3(x,y+2.75,z),Vector3(0.2,0.5,1.66),"wall_green")

func run() -> void:
	if not OS.get_cmdline_user_args().has("--create-exploration"):
		push_error("Explicit --create-exploration required")
		quit(1)
		return
	if FileAccess.file_exists("res://scenes/novas_salas.tscn"):
		push_error("Migration already applied; edit novas_salas.tscn manually")
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	scene = load("res://scenes/cenario_editavel.tscn").instantiate()
	root.add_child(scene)
	addition = Node3D.new()
	addition.name = "NovasSalas"
	root.add_child(addition)
	start_room("Almoxarifado",Vector3(-5,0,-4),Vector2(6,4),"floor_concrete",true)
	cut_opening(-2,0,-4)
	block(Vector3(-8,1.5,-4),Vector3(0.2,3,4),"wall_concrete")
	door("stores",Vector3(-2,0,-4),"almoxarifado")
	label("ALMOXARIFADO",Vector3(-1.86,2.7,-4),PI/2)
	desk(Vector3(-6.2,0,-5.4),2.1)
	key("personnel_key",Vector3(-5.8,1.12,-5.3))
	Art.external(room,"wooden_bookshelf_worn",Vector3(-7.35,0,-3.5),Vector3(1.3,2.1,0.5),PI/2)
	block(Vector3(-7.35,1.05,-3.5),Vector3(0.5,2.1,1.3),"metal").hide()
	for p in [Vector3(-6.8,0,-2.6),Vector3(-6.1,0,-2.6),Vector3(-7,1.1,-5.4)]:
		Art.external(room,"cardboard_box_01",p,Vector3(0.5,0.45,0.45))
	Art.external(room,"plastic_broom",Vector3(-7.6,0,-5.5),Vector3(0.35,1.4,0.2))
	start_room("CopaFuncionarios",Vector3(5,0,1),Vector2(6,6),"floor_reception",true)
	cut_opening(2,0,1)
	block(Vector3(7.82,1.5,1),Vector3(0.2,3,6),"wall_cream")
	door("break_room",Vector3(2,0,1),"copa / funcionários")
	label("COPA / FUNCIONÁRIOS",Vector3(1.86,2.7,1),-PI/2)
	desk(Vector3(6.3,0,2.9),2.1)
	paper("handover",Vector3(6.1,1.11,2.8),"Ler livro de entrega de chaves")
	Art.external(room,"vintage_radio_transceiver",Vector3(7,1.08,2.9),Vector3(0.35,0.22,0.2))
	Art.model(room,"chair",Vector3(6.3,0,1.6),Vector3(0.6,1,0.6),PI)
	Art.model(room,"trashcan",Vector3(7.4,0,-1.3),Vector3(0.5,0.7,0.5))
	Art.model(room,"coatRackStanding",Vector3(3.1,0,3.1),Vector3(0.65,1.8,0.65))
	Art.external(room,"drawer_cabinet",Vector3(6.7,0,-1.3),Vector3(1.4,1.15,0.65))
	block(Vector3(6.7,0.55,-1.3),Vector3(1.4,1.1,0.65),"metal").hide()
	start_room("SalaPessoal",Vector3(4.8,4.2,7.5),Vector2(6.4,5),"upper_floor",false)
	cut_opening(1.6,4.2,7.5)
	door("personnel",Vector3(1.6,4.2,7.5),"pessoal")
	label("PESSOAL / PLANTÕES",Vector3(1.46,6.9,7.5),-PI/2)
	desk(Vector3(5.5,4.2,8.9),2.4)
	key("it_key",Vector3(5.9,5.32,8.8))
	paper("staff_register",Vector3(5.1,5.31,8.8),"Ler escala do plantão")
	Art.model(room,"chairDesk",Vector3(5.5,4.2,7.6),Vector3(0.6,1.1,0.6),PI)
	Art.external(room,"drawer_cabinet",Vector3(7.3,4.2,6.2),Vector3(1.1,1.8,0.6),PI/2)
	block(Vector3(7.3,5.1,6.2),Vector3(0.6,1.8,1.1),"metal").hide()
	Art.external(room,"office_notepads",Vector3(4.3,5.28,8.9),Vector3(0.35,0.09,0.3))
	# Cabinet on the free east side of the TI bench, independent of moved desks.
	room = Node3D.new()
	room.name = "ArmarioTI"
	addition.add_child(room)
	var cabinet := item("it_cabinet",Vector3(-6.6,5.05,6.0),Vector3(1.3,1.7,0.7),"Destrancar armário de peças / ler aviso")
	var fitting: Material = preload("res://scripts/materials.gd").fitting(Color(0.22,0.28,0.25))
	for x in [-0.62,0.62]: Art.box(cabinet,Vector3(x,0,0),Vector3(0.06,1.7,0.7),Color.WHITE,fitting)
	for y in [-0.82,0.2,0.82]: Art.box(cabinet,Vector3(0,y,0),Vector3(1.3,0.06,0.7),Color.WHITE,fitting)
	Art.box(cabinet,Vector3(0,0,0.32),Vector3(1.3,1.7,0.06),Color.WHITE,fitting)
	var leaf := Node3D.new()
	leaf.name = "Leaf"
	leaf.position = Vector3(-0.62,0,-0.38)
	cabinet.add_child(leaf)
	Art.box(leaf,Vector3(0.62,0,0),Vector3(1.25,1.65,0.05),Color.WHITE,fitting)
	Art.box(leaf,Vector3(1.1,0, -0.05),Vector3(0.035,0.22,0.06),Color(0.5,0.48,0.37))
	# No solid collision across the open shelf: interaction body is the lock,
	# physical sides are separate. Closed fuse is disabled by state.
	cabinet.get_child(0).shape.size = Vector3(0.18,0.22,0.12)
	cabinet.get_child(0).position = Vector3(0.48,0,-0.46)
	label("TI / PEÇAS — 20 A",Vector3(-6.6,5.7,5.58),PI)
	var note := item("it_cabinet_note",Vector3(-6.85,5.55,5.58),Vector3(0.3,0.35,0.04),"Ler aviso do estoque")
	Art.box(note,Vector3.ZERO,Vector3(0.3,0.35,0.02),Color(0.65,0.64,0.5))
	compact_models(addition)
	# Persist only the addition, keeping original scenery authoring data intact.
	own(addition,addition)
	var packed := PackedScene.new()
	packed.pack(addition)
	assert(ResourceSaver.save(packed,"res://scenes/novas_salas.tscn")==OK)
	addition.free()
	var instance: Node3D = load("res://scenes/novas_salas.tscn").instantiate()
	scene.add_child(instance)
	instance.owner = scene
	# Preserve owners after splitting nodes, but keep imported scene ownership.
	for node in scene.find_children("*","Node",true,false):
		if node.owner == null: node.owner = scene
	var authored := PackedScene.new()
	authored.pack(scene)
	assert(ResourceSaver.save(authored,"res://scenes/cenario_editavel.tscn")==OK)
	print("EXPLORATION_ROOMS_CREATED")
	quit()


func compact_models(node: Node) -> void:
	for child in node.get_children():
		if not child is Node3D: continue
		if not child.scene_file_path.is_empty():
			var path: String = child.scene_file_path
			if "mounted_fluorescent" in path: path = "res://scenes/scenery_models/variant_c565bc4e1639d968.tscn"
			# Keep only this model's selected variants; existing variant resources
			# are shared with the original editor scenery.
			var fresh: Node3D = load(path).instantiate()
			node.add_child(fresh)
			fresh.transform = child.transform
			fresh.visible = child.visible
			child.free()
		else: compact_models(child)
