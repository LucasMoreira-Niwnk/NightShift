extends RefCounted

const Art = preload("res://scripts/art.gd")
const Materials = preload("res://scripts/materials.gd")
var cache: Dictionary = {}
var leaf_material: StandardMaterial3D

func surface(color: Color, metal: bool = false, wood: bool = false) -> StandardMaterial3D:
	var key := color.to_html() + str(metal) + str(wood)
	if cache.has(key): return cache[key]
	var material: StandardMaterial3D = Materials.surface("wood") if wood else StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	material.metallic = 0.42 if metal else 0.0
	if not wood:
		if not cache.has("grain"):
			var ramp := Gradient.new()
			ramp.set_color(0, Color(0.38, 0.36, 0.3))
			ramp.set_color(1, Color(1, 0.98, 0.9))
			cache.grain = Materials.noise_texture(0.12, 3, 128, 128, ramp)
		material.albedo_texture = cache.grain
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE * 3
	cache[key] = material
	return material

func block(parent: Node3D, point: Vector3, size: Vector3, color: Color, metal: bool = false, wood: bool = false, bevel: float = 0) -> MeshInstance3D:
	var mesh: MeshInstance3D = Art.rounded_box(parent, point, size, color, bevel) if bevel > 0 else Art.box(parent, point, size, color)
	mesh.material_override = surface(color, metal, wood)
	return mesh

func label(parent: Node3D, text: String, point: Vector3, scale: float = 0.001) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = point
	tag.font_size = 32
	tag.pixel_size = scale
	tag.outline_size = 0
	tag.shaded = true
	tag.modulate = Color(0.66, 0.62, 0.46)
	parent.add_child(tag)
	return tag

func cylinder(parent: Node3D, point: Vector3, radius: float, height: float, color: Color, top: float = -1) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius if top < 0 else top
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 24
	mesh.mesh = shape
	mesh.position = point
	mesh.material_override = surface(color)
	parent.add_child(mesh)
	return mesh

func cable(parent: Node3D, points: Array, radius: float = 0.012, color: Color = Color(0.035, 0.042, 0.035)) -> void:
	for i in range(points.size() - 1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var mesh := cylinder(parent, (a + b) / 2, radius, a.distance_to(b), color)
		mesh.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func shelf(parent: Node3D, point: Vector3, angle: float, seed_value: int) -> Node3D:
	var root := Node3D.new()
	root.name = "AgedArchiveShelf"
	parent.add_child(root)
	root.position = point
	root.rotation.y = angle
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	Art.external(root,"wooden_bookshelf_worn",Vector3.ZERO,Vector3(1.05,2.08,0.55))
	for level in range(4):
		Art.model(root,"books",Vector3(0,0.2+level*0.47,0),Vector3(0.85,0.3,0.3))
	return root

func bound_volume(root: Node3D, size: Vector3, color: Color, code: String) -> void:
	block(root, Vector3(0, size.y / 2, -0.005), size * Vector3(0.76, 0.94, 0.93), Color(0.59, 0.55, 0.4))
	for x in [-1.0, 1.0]: block(root, Vector3(x * size.x * 0.47, size.y / 2, 0), Vector3(size.x * 0.12, size.y, size.z), color)
	block(root, Vector3(0, size.y / 2, size.z * 0.48), Vector3(size.x, size.y, 0.017), color, false, false, 0.007)
	for y in [0.06, size.y - 0.04]: block(root, Vector3(0, y, size.z * 0.52), Vector3(size.x, 0.007, 0.005), Color(0.42, 0.36, 0.2))
	block(root, Vector3(0, size.y * 0.42, size.z * 0.525), Vector3(size.x * 0.8, 0.065, 0.003), Color(0.65, 0.59, 0.43))
	label(root, code, Vector3(0, size.y * 0.42, size.z * 0.54), 0.00027)

func add_leaf(tool: SurfaceTool, start: Vector3, end: Vector3, width: float, bend: float, color: Color) -> void:
	var side := (end - start).cross(Vector3.UP).normalized()
	if side.length_squared() < 0.1: side = Vector3.RIGHT
	for i in range(5):
		var t0 := i / 5.0
		var t1 := (i + 1) / 5.0
		var c0 := start.lerp(end, t0) + Vector3.UP * sin(t0 * PI) * bend
		var c1 := start.lerp(end, t1) + Vector3.UP * sin(t1 * PI) * bend
		for sign_value in [-1.0, 1.0]:
			var e0: Vector3 = c0 + side * sin(t0 * PI) * width * sign_value - Vector3.UP * 0.007
			var e1: Vector3 = c1 + side * sin(t1 * PI) * width * sign_value - Vector3.UP * 0.007
			for vertex in [c0, e0, e1, c0, e1, c1]:
				tool.set_color(color.lightened(0.12) if vertex == c0 or vertex == c1 else color)
				tool.add_vertex(vertex)

func leaf_mesh(parent: Node3D, tool: SurfaceTool) -> void:
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	if leaf_material == null:
		leaf_material = StandardMaterial3D.new()
		leaf_material.vertex_color_use_as_albedo = true
		leaf_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		leaf_material.roughness = 0.88
	mesh.material_override = leaf_material
	parent.add_child(mesh)

func plant(parent: Node3D, point: Vector3, scale_value: float, seed_value: int, pot: bool = true) -> Node3D:
	return Art.external(parent,"potted_plant_01" if pot else "shrub_01",point,Vector3(0.55,1.0,0.55)*scale_value,seed_value*0.7)

func tree(parent: Node3D, point: Vector3, seed_value: int) -> void:
	Art.external(parent,"pine_sapling_small",point,Vector3(3.5,5.5,3.5),seed_value*0.7)

func terminal(root: Node3D) -> void:
	Art.imported(root,"desktop_pc",Vector3(0.72,-1.08,-0.1),Vector3(0.24,0.55,0.45))
	# Supports for the three elevated CCTV monitors.
	for x in [-0.9,0.9]: block(root,Vector3(x,0.75,-0.4),Vector3(0.04,1.5,0.04),Color(0.18,0.22,0.2),true)
	cable(root,[Vector3(0,0.4,-0.45),Vector3(0.2,-0.4,-0.45),Vector3(0.6,-0.95,-0.3)],0.012)

func panel(parent: Node3D, points: Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,1,2,0,2,3]: tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = surface(color)
	parent.add_child(mesh)

func vehicle(parent: Node3D, point: Vector3, color: Color, seed_value: int) -> Node3D:
	return Art.imported(parent,"sedan",point,Vector3(4.2,1.45,1.9),PI/2)

func decay(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "AbandonedFacadeDetails"
	parent.add_child(root)
	# A few boarded panes retain long views through the other windows.
	for x in [-5.5,5.5]:
		for index in range(2):
			var plank := block(root,Vector3(x,5.15+index*0.5,10.15),Vector3(2.15,0.18,0.055),Color(0.27,0.23,0.14),false,true)
			plank.rotation.z = 0.13 if index==0 else -0.15
			for offset in [-0.85,0.85]:
				var nail := cylinder(root,Vector3(x+offset,5.15+index*0.5,10.19),0.013,0.01,Color(0.17,0.13,0.075))
				nail.rotation.x=PI/2
	var leaves := SurfaceTool.new()
	leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-7.65,7.65]:
		var vine: Array = []
		for i in range(20):
			var point := Vector3(x+sin(i*1.4)*0.14,0.2+i*0.27,12.3)
			vine.append(point)
			add_leaf(leaves,point,point+Vector3(sin(i*2.4)*0.33,0.13,0.06),0.09,0.035,Color(0.12,0.2,0.08))
		cable(root,vine,0.012,Color(0.13,0.16,0.07))
	leaf_mesh(root,leaves)
	# Asphalt fractures, tufts of dry growth and fallen leaves remain cosmetic.
	for i in range(18):
		var x := -24.0+fmod(i*7.1,49.0)
		var z := 23.5+fmod(i*2.3,11.0)
		cable(root,[Vector3(x,-0.012,z),Vector3(x+0.3,-0.012,z+0.8),Vector3(x+0.15,-0.012,z+1.35)],0.012,Color(0.012,0.018,0.012))
		plant(root,Vector3(x,-0.02,z),0.22,100+i,false)
	for i in range(30):
		var scrap := block(root,Vector3(-8+fmod(i*3.7,16.0),0.014,16.5+fmod(i*1.7,5.0)),Vector3(0.08,0.004,0.14),Color(0.27,0.22,0.105))
		scrap.rotation.y=i*2.4
	# Maintenance notice and exposed roofline utilities show neglect, not a ruin.
	block(root,Vector3(-4.8,1.45,12.15),Vector3(0.7,0.45,0.02),Color(0.58,0.52,0.35))
	label(root,"IMÓVEL INTERDITADO\nACESSO SÓ À MANUTENÇÃO\n11 / 2008",Vector3(-4.8,1.45,12.17),0.00065)

func abandoned_site(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "FoundationNeglect"
	parent.add_child(root)
	var stone: StandardMaterial3D = Materials.photographic("concrete_floor_worn_001",1.2)
	var brick: StandardMaterial3D = Materials.photographic("damaged_plaster",1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20081114
	# Keep the entrance, maintenance route and all door clearances free.
	for side in [-1.0,1.0]:
		for z in [-13.0,-9.5,-6.0,-2.5,1.0,4.5,8.0,11.0]:
			plant(root,Vector3(side*(14.6 if side<0 and z<3 else 8.45),0,z),rng.randf_range(0.35,0.65),int(abs(z)*30)+19,false)
		for z in [16.0,20.5,26.5]:
			plant(root,Vector3(side*9.2,-0.02,z),0.55,int(z*20),false)
		for center in [Vector3(side*7.6,0.02,12.6),Vector3(side*9.0,0.01,21.3),Vector3(side*20.5,-0.01,25.2)]:
			for index in range(18):
				var mesh := MeshInstance3D.new()
				var piece := PrismMesh.new()
				piece.size = Vector3(rng.randf_range(0.08,0.28),rng.randf_range(0.035,0.15),rng.randf_range(0.09,0.24))
				mesh.mesh = piece
				mesh.position = center + Vector3(rng.randf_range(-0.55,0.55),piece.size.y/2,rng.randf_range(-0.45,0.45))
				mesh.rotation = Vector3(rng.randf_range(-0.2,0.2),rng.randf()*TAU,rng.randf_range(-0.1,0.1))
				mesh.material_override = stone if index%3 else brick
				root.add_child(mesh)
		# Discarded warped timber by the service perimeter, outside the main walk.
		for index in range(3):
			var board := block(root,Vector3(side*13.8,0.045+index*0.022,25+index*0.18),Vector3(1.4,0.05,0.16),Color(0.24,0.19,0.115),false,true)
			board.rotation.y = index*0.23+side*0.4
