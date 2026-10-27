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
	for x in [-0.51, 0.51]:
		for z in [-0.24, 0.24]:
			block(root, Vector3(x, 1.04, z), Vector3(0.035, 2.08, 0.035), Color(0.25, 0.26, 0.19), true, false, 0.008)
			for y in [0.18, 0.65, 1.12, 1.59, 2.03]:
				cylinder(root, Vector3(x, y - 0.035, z), 0.022, 0.025, Color(0.23, 0.12, 0.055))
	cable(root, [Vector3(-0.5, 0.1, -0.25), Vector3(0.5, 1.98, -0.25)], 0.009)
	cable(root, [Vector3(0.5, 0.1, -0.25), Vector3(-0.5, 1.98, -0.25)], 0.009)
	for level in range(4):
		var y := 0.18 + level * 0.47
		block(root, Vector3(0, y, 0), Vector3(1.05, 0.045, 0.51), Color(0.31, 0.28, 0.19), false, true)
		var x := -0.43
		for index in range(10):
			var width := rng.randf_range(0.045, 0.076)
			var height := rng.randf_range(0.23, 0.38)
			var palette := [Color(0.27,0.19,0.12), Color(0.19,0.26,0.2), Color(0.29,0.14,0.12), Color(0.22,0.23,0.23), Color(0.35,0.3,0.18)]
			var book := Node3D.new()
			root.add_child(book)
			book.position = Vector3(x, y + 0.024, rng.randf_range(-0.02, 0.04))
			book.rotation.y = rng.randf_range(-0.05, 0.05)
			bound_volume(book, Vector3(width, height, rng.randf_range(0.22, 0.28)), palette[index % 5], "%02d/%02d" % [level + 1, index + 1])
			x += width + 0.013
	label(root, "ARQUIVO / %02d\n1968 — 2008" % seed_value, Vector3(0, 1.94, 0.268), 0.00065)
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
	var root := Node3D.new()
	root.name = "NeglectedPlant"
	parent.add_child(root)
	root.position = point
	root.scale = Vector3.ONE * scale_value
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base := 0.0
	if pot:
		cylinder(root, Vector3(0, 0.2, 0), 0.18, 0.4, Color(0.28,0.23,0.16), 0.26)
		cylinder(root, Vector3(0, 0.39, 0), 0.27, 0.06, Color(0.34,0.29,0.21))
		cylinder(root, Vector3(0, 0.425, 0), 0.23, 0.01, Color(0.065,0.055,0.03))
		base = 0.43
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(9):
		var angle := i * 2.4
		var tip := Vector3(sin(angle) * 0.45, base + rng.randf_range(0.6,1.1), cos(angle) * 0.45)
		cable(root, [Vector3(0,base,0), tip * Vector3(0.6,1,0.6)], 0.007, Color(0.21,0.22,0.1))
		for j in range(3):
			var start := Vector3(0,base,0).lerp(tip, 0.45 + j * 0.15)
			var end := start + Vector3(sin(angle+j)*0.42,-0.06 + j*0.08,cos(angle+j)*0.42)
			var color := Color(0.18,0.24,0.105) if (i+j)%4 != 0 else Color(0.32,0.25,0.11)
			add_leaf(tool, start, end, 0.08, 0.1, color)
	leaf_mesh(root, tool)
	return root

func tree(parent: Node3D, point: Vector3, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	cylinder(parent, point + Vector3.UP * 2.5, 0.22, 5, Color(0.14,0.13,0.09), 0.1)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var angle := i*2.4
		var start := point + Vector3.UP * (2.5 + i * 0.17)
		var end := point + Vector3(sin(angle)*1.7,4.7+rng.randf(),cos(angle)*1.7)
		cable(parent, [start, start.lerp(end,0.65),end],0.045,Color(0.13,0.14,0.09))
		for j in range(14):
			var leaf_start := start.lerp(end,rng.randf_range(0.4,1.0)) + Vector3(rng.randf_range(-0.45,0.45),rng.randf_range(-0.2,0.5),rng.randf_range(-0.45,0.45))
			add_leaf(tool,leaf_start,leaf_start+Vector3(sin(j)*0.65,0.1,cos(j)*0.65),0.16,0.1,Color(0.09,0.16,0.075))
	leaf_mesh(parent,tool)

func terminal(root: Node3D) -> void:
	# Deep CRT shell: retain the feed quad and the original interaction collider.
	block(root, Vector3(0,0.45,-0.2),Vector3(1.04,0.67,0.55),Color(0.35,0.35,0.27),false,false,0.055)
	for side in [-1.0,1.0]:
		for index in range(9): block(root,Vector3(side*0.526,0.29+index*0.035,-0.22),Vector3(0.006,0.014,0.28),Color(0.055,0.06,0.05))
	for x in [-0.47,0.47]:
		for y in [0.18,0.72]: cylinder(root,Vector3(x,y,0.081),0.013,0.008,Color(0.12,0.13,0.1)).rotation.x=PI/2
	label(root,"VESPER / VT-08",Vector3(-0.26,0.153,0.104),0.0006)
	for i in range(4): cylinder(root,Vector3(0.31+i*0.038,0.153,0.104),0.009,0.009,Color(0.19,0.22,0.16)).rotation.x=PI/2
	block(root,Vector3(0,0.88,-0.24),Vector3(2.14,0.045,0.045),Color(0.2,0.23,0.2),true)
	for x in [-0.9,0.9]: block(root,Vector3(x,0.59,-0.24),Vector3(0.045,1.18,0.045),Color(0.18,0.22,0.2),true)
	for index in range(3):
		var x := -0.65+index*0.65
		block(root,Vector3(x,1.18,-0.22),Vector3(0.65,0.4,0.29),Color(0.27,0.29,0.23),false,false,0.035)
		cable(root,[Vector3(x,1.05,-0.3),Vector3(x,0.78,-0.36),Vector3(-0.55,0.05,-0.4),Vector3(-0.55,-0.7,-0.2)],0.009)
	for x in [-0.55,0.53]:
		block(root,Vector3(x,-0.74,0),Vector3(0.28,0.65,0.44),Color(0.28,0.3,0.24),false,false,0.025)
		for i in range(8): block(root,Vector3(x,-0.96+i*0.026,0.223),Vector3(0.19,0.009,0.004),Color(0.05,0.07,0.055))
	label(root,"NOBREAK\nCCTV / BATERIA",Vector3(0.53,-0.61,0.229),0.00055)
	label(root,"2008 / VSP-SEC",Vector3(-0.55,-0.55,0.229),0.00045)
	cable(root,[Vector3(0,0.3,-0.48),Vector3(0.17,0.1,-0.48),Vector3(0.35,-0.3,-0.38),Vector3(0.53,-0.6,-0.25)],0.015)

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
	var root := Node3D.new()
	root.name = "WeatheredSedan"
	parent.add_child(root)
	root.position = point
	block(root,Vector3(0,0.64,0),Vector3(1.85,0.56,4.2),color,true,false,0.15)
	block(root,Vector3(0,0.95,1.45),Vector3(1.72,0.09,1.12),color,true,false,0.045)
	block(root,Vector3(0,0.95,-1.56),Vector3(1.72,0.09,0.93),color,true,false,0.045)
	block(root,Vector3(0,1.48,-0.1),Vector3(1.4,0.09,1.55),color,true,false,0.045)
	# Slanted glazing and pillars define the cabin instead of a cuboid canopy.
	panel(root,[Vector3(-0.8,0.96,1.2),Vector3(0.8,0.96,1.2),Vector3(0.67,1.45,0.65),Vector3(-0.67,1.45,0.65)],Color(0.045,0.085,0.09))
	panel(root,[Vector3(0.8,0.96,-1.4),Vector3(-0.8,0.96,-1.4),Vector3(-0.67,1.45,-0.85),Vector3(0.67,1.45,-0.85)],Color(0.035,0.065,0.07))
	for sign_value in [-1.0,1.0]:
		var x: float = sign_value*0.81
		panel(root,[Vector3(x,0.96,-1.35),Vector3(x,0.96,1.15),Vector3(sign_value*0.68,1.45,0.63),Vector3(sign_value*0.68,1.45,-0.83)],Color(0.035,0.065,0.065))
		for z in [-1.35,0.0,1.15]: cable(root,[Vector3(x,0.95,z),Vector3(sign_value*0.69,1.46,clampf(z,-0.83,0.63))],0.027,color)
		cable(root,[Vector3(sign_value*0.938,0.86,-1.25),Vector3(sign_value*0.938,0.44,-1.25),Vector3(sign_value*0.938,0.44,1.25),Vector3(sign_value*0.938,0.86,1.25)],0.007,Color(0.045,0.05,0.04))
		cable(root,[Vector3(sign_value*0.94,0.88,-0.02),Vector3(sign_value*0.94,0.45,-0.02)],0.006)
		block(root,Vector3(sign_value*0.94,0.72,-0.48),Vector3(0.025,0.032,0.15),Color(0.32,0.34,0.29),true,false,0.009)
		block(root,Vector3(sign_value*0.94,0.72,0.67),Vector3(0.025,0.032,0.15),Color(0.32,0.34,0.29),true,false,0.009)
		block(root,Vector3(sign_value*1.01,0.99,0.93),Vector3(0.2,0.11,0.23),color,true,false,0.035)
		for z in [-1.34,1.34]:
			var tire := cylinder(root,Vector3(sign_value*0.9,0.35,z),0.34,0.2,Color(0.025,0.03,0.025))
			tire.rotation.z=PI/2
			var hub := cylinder(root,Vector3(sign_value*1.007,0.35,z),0.19,0.012,Color(0.27,0.29,0.24))
			hub.rotation.z=PI/2
			for i in range(8):
				var a := i*TAU/8
				block(root,Vector3(sign_value*1.017,0.35+sin(a)*0.125,z+cos(a)*0.125),Vector3(0.008,0.038,0.038),Color(0.055,0.065,0.05),false,false,0.012)
			for i in range(12):
				var a := i*TAU/12
				block(root,Vector3(sign_value*1.005,0.35+sin(a)*0.29,z+cos(a)*0.29),Vector3(0.004,0.017,0.017),Color(0.08,0.085,0.065))
		# Rust blooms collect below the doors and around wheel arches.
		for i in range(13):
			var z := -1.8+i*0.29
			block(root,Vector3(sign_value*0.939,0.44+(i%3)*0.035,z),Vector3(0.006,0.02+(i%4)*0.018,0.08),Color(0.22,0.12,0.055))
	for z in [-2.12,2.12]:
		block(root,Vector3(0,0.43,z),Vector3(1.75,0.12,0.08),Color(0.14,0.17,0.14),false,false,0.025)
		for x in [-0.63,0.63]:
			block(root,Vector3(x,0.72,z),Vector3(0.4,0.16,0.03),Color(0.48,0.46,0.31) if z>0 else Color(0.28,0.035,0.02),false,false,0.02)
		block(root,Vector3(0,0.51,z*1.006),Vector3(0.47,0.12,0.014),Color(0.57,0.57,0.42))
		var plate := label(root,"VSP %04d" % (1900+seed_value),Vector3(0,0.51,z*1.012),0.0007)
		plate.rotation.y=PI if z<0 else 0.0
	for x in [-0.35,0.35]: cable(root,[Vector3(x,0.975,1.19),Vector3(x+0.26,1.12,1.03)],0.009)
	for i in range(5): block(root,Vector3(-0.16+i*0.08,0.75,2.123),Vector3(0.035,0.12,0.015),Color(0.035,0.045,0.035))
	return root

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
