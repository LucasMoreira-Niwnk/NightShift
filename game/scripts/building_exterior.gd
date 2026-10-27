extends Node3D

const Art = preload("res://scripts/art.gd")
var world: Node3D
var window_count := 0
var building_shell := false
var glass: StandardMaterial3D

func _ready() -> void:
	name = "VesperExterior"
	glass = StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.21, 0.32, 0.33, 0.18)
	glass.roughness = 0.21
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED

func box(point: Vector3, size: Vector3, color: Color, collision: bool = true) -> MeshInstance3D:
	return world.box(self, point, size, "facade" if building_shell else "exterior", collision, color)

# Walls are built around apertures; the transparent pane owns its own collider.
func window_wall(parent: Node3D, center: Vector3, size: Vector3, openings: Array, width: float) -> void:
	var along_x := size.x > size.z
	var length: float = size.x if along_x else size.z
	var direction := Vector3.RIGHT if along_x else Vector3.BACK
	var normal := Vector3.BACK if along_x else Vector3.RIGHT
	var low := center.y - size.y / 2
	var sill := low + 0.85
	var head := low + 2.65
	var cursor := -length / 2
	for value in openings:
		var left: float = float(value) - width / 2
		var right: float = float(value) + width / 2
		if left > cursor:
			wall_piece(parent, center + direction * ((cursor + left) / 2), size, left - cursor, size.y)
		wall_piece(parent, center + direction * float(value) + Vector3.UP * (0.85 / 2 - size.y / 2), size, width, 0.85)
		wall_piece(parent, center + direction * float(value) + Vector3.UP * ((2.65 + size.y) / 2 - size.y / 2), size, width, size.y - 2.65)
		var middle := center + direction * float(value)
		middle.y = (sill + head) / 2
		var frame := Color(0.12, 0.17, 0.16)
		for edge in [-1.0, 1.0]:
			Art.box(parent, middle + direction * (edge * width / 2), Vector3(0.085, head - sill + 0.14, 0.085), frame)
		for height in [sill, head]:
			var point := middle
			point.y = height
			Art.box(parent, point, Vector3(width + 0.16, 0.09, 0.22) if along_x else Vector3(0.22, 0.09, width + 0.16), frame)
		var pane_size := Vector3(width, head - sill, 0.025) if along_x else Vector3(0.025, head - sill, width)
		var pane: MeshInstance3D = world.box(parent, middle, pane_size, "glass", true)
		pane.material_override = glass
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Art.box(parent, middle, Vector3(0.04, head - sill, 0.065) if along_x else Vector3(0.065, head - sill, 0.04), frame)
		Art.box(parent, middle - Vector3.UP * 0.2, Vector3(width, 0.035, 0.065) if along_x else Vector3(0.065, 0.035, width), frame)
		# Projecting stone sill, drip edge and discreet grime streaks.
		Art.box(parent, middle + Vector3.UP * (sill - middle.y - 0.08), Vector3(width + 0.28, 0.12, 0.38) if along_x else Vector3(0.38, 0.12, width + 0.28), Color(0.29, 0.31, 0.28))
		for index in range(9):
			var offset := -width / 2 + (index + 0.5) * width / 9
			Art.box(parent, middle + direction * offset + normal * 0.018, Vector3(0.006, 0.18 + (index % 4) * 0.17, 0.006), Color(0.13, 0.2, 0.19, 0.6))
		window_count += 1
		cursor = right
	if cursor < length / 2:
		wall_piece(parent, center + direction * ((cursor + length / 2) / 2), size, length / 2 - cursor, size.y)

func wall_piece(parent: Node3D, point: Vector3, size: Vector3, length: float, height: float) -> void:
	if height <= 0 or length <= 0: return
	world.box(parent, point, Vector3(length, height, size.z) if size.x > size.z else Vector3(size.x, height, length), "wall_cream")

func build() -> void:
	building_shell = true
	# Structural shell connects the occupied rooms into one two-storey volume.
	world.box(self, Vector3(0, -0.3, -2), Vector3(16.4, 0.4, 28.4), "wall")
	for x in [-8, 8]:
		box(Vector3(x, 1.5, -15), Vector3(0.2, 3, 2), Color(0.22, 0.25, 0.23))
		if x > 0:
			box(Vector3(x, 1.5, -12), Vector3(0.2, 3, 4), Color(0.22, 0.25, 0.23))
			box(Vector3(x, 1.5, 3), Vector3(0.2, 3, 2), Color(0.22, 0.25, 0.23))
	for x in [-5.5, 5.5]: box(Vector3(x, 1.5, -16), Vector3(5, 3, 0.2), Color(0.22, 0.25, 0.23))
	# Facade cornice is a perimeter trim, not a plate through the stairwell.
	for x in [-8.15, 8.15]: box(Vector3(x, 3.55, -2), Vector3(0.3, 0.25, 28.6), Color(0.12, 0.16, 0.16))
	box(Vector3(0, 3.55, 12.15), Vector3(16.6, 0.25, 0.3), Color(0.12, 0.16, 0.16))
	for x in [-5.65, 5.65]: box(Vector3(x, 3.55, -16.15), Vector3(5.3, 0.25, 0.3), Color(0.12, 0.16, 0.16))
	box(Vector3(0, 7.45, -2), Vector3(16.6, 0.25, 28.6), Color(0.12, 0.16, 0.16))
	# Roof parapets and flashings.
	for x in [-8.15, 8.15]: box(Vector3(x, 7.85, -2), Vector3(0.2, 0.7, 28.5), Color(0.24, 0.26, 0.23))
	for z in [-16.15, 12.15]: box(Vector3(0, 7.85, z), Vector3(16.5, 0.7, 0.2), Color(0.24, 0.26, 0.23))
	for x in [-7.8, -0.95, 0.95, 7.8]:
		box(Vector3(x, 3.7, 12.2), Vector3(0.18, 7.3, 0.22), Color(0.19, 0.23, 0.21))
	for x in [-8.25, 8.25]:
		for z in [-15.7, 11.7]:
			world.staircases.pipe(Vector3(x, 0.1, z), Vector3(x, 7.5, z), 0.055, Color(0.21, 0.24, 0.23))
	for x in [-4.5, 4.5]:
		box(Vector3(x, 7.9, -4), Vector3(2.1, 0.8, 1.4), Color(0.25, 0.29, 0.27))
		for z in range(7): Art.box(self, Vector3(x, 8.32, -4.55 + z * 0.18), Vector3(1.9, 0.015, 0.06), Color(0.09, 0.13, 0.12))
	box(Vector3(0, 3.05, 14), Vector3(6.5, 0.18, 4.5), Color(0.1, 0.15, 0.14))
	for x in [-2.9, 2.9]: box(Vector3(x, 1.45, 15.5), Vector3(0.16, 2.9, 0.16), Color(0.22, 0.28, 0.26))
	var sign: Label3D = world.add_sign("V E S P E R", Vector3(0, 6.5, 12.3))
	sign.pixel_size = 0.007
	sign.modulate = Color(0.53, 0.68, 0.61)
	world.add_sign("SETOR ADMINISTRATIVO / ACESSO RESTRITO", Vector3(0, 5.8, 12.3)).pixel_size = 0.0013
	building_shell = false
	world.dressing.decay(self)
	world.dressing.abandoned_site(self)
	grounds()
	street()
	weather()

func grounds() -> void:
	world.box(self, Vector3(0, -0.18, 0), Vector3(62, 0.3, 80), "asphalt")
	world.box(self, Vector3(0, -0.055, 17), Vector3(18, 0.1, 10), "pavers")
	for x in range(-8, 9):
		Art.box(self, Vector3(x, 0.001, 17), Vector3(0.018, 0.012, 10), Color(0.09, 0.12, 0.11))
	for z in range(13, 23): Art.box(self, Vector3(0, 0.003, z), Vector3(18, 0.014, 0.018), Color(0.09, 0.12, 0.11))
	for x in [-6.5, 6.5]:
		box(Vector3(x, 0.32, 14.5), Vector3(1.9, 0.64, 2.6), Color(0.19, 0.22, 0.2))
		box(Vector3(x, 0.65, 14.5), Vector3(1.65, 0.03, 2.35), Color(0.055, 0.07, 0.045), false)
		for index in range(6): world.dressing.plant(self, Vector3(x + (index % 2) * 0.5 - 0.25, 0.66, 13.8 + (index / 2) * 0.65), 0.65, index + 22, false)
	for x in [-23.0, -19.0, 14.0, 18.0, 22.0]:
		for offset in [-1.65, 1.65]:
			var marking := Art.box(self, Vector3(x + offset, 0.008, 20), Vector3(0.08, 0.016, 5.5), Color.WHITE)
			var paint := ShaderMaterial.new()
			paint.shader = preload("res://shaders/weathered_road_paint.gdshader")
			paint.set_shader_parameter("dirt",preload("res://scripts/materials.gd").decay_map("worn_asphalt","ao"))
			marking.material_override = paint
		box(Vector3(x, 0.075, 17.5), Vector3(2.5, 0.15, 0.18), Color(0.24, 0.26, 0.23))
	car(Vector3(-19, 0, 20), Color(0.19, 0.24, 0.22))
	car(Vector3(18, 0, 20), Color(0.12, 0.14, 0.18))
	for x in [-28.0, 28.0]:
		for z in [-30.0, -12.0, 7.0, 25.0]: tree(Vector3(x, 0, z))
	# Perimeter is physical, including behind the new stair towers.
	for x in [-30.0, 30.0]: fence(Vector3(x, 1.1, 0), 78, PI / 2)
	for z in [-39.0, 39.0]: fence(Vector3(0, 1.1, z), 60, 0)
	for x in [-11.0, 11.0]:
		for z in [16.5, 28.0]: lamp(Vector3(x, 0, z))
	details()
	for x in [-2.0, 2.0]:
		box(Vector3(x, 0.45, 17), Vector3(0.15, 0.9, 0.15), Color(0.13, 0.18, 0.16))
		Art.box(self, Vector3(x, 0.7, 17), Vector3(0.16, 0.05, 0.16), Color(0.65, 0.62, 0.4))

func car(point: Vector3, color: Color) -> void:
	world.dressing.vehicle(self, point, color, int(abs(point.x) * 10))
	world.box(self, point + Vector3.UP * 0.65, Vector3(1.9, 1.3, 4.2), "metal").hide()

func fence(point: Vector3, length: float, angle: float) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = point
	root.rotation.y = angle
	var instance := MultiMeshInstance3D.new()
	var bars := MultiMesh.new()
	bars.transform_format = MultiMesh.TRANSFORM_3D
	var bar := BoxMesh.new()
	bar.size = Vector3(0.025, 2.2, 0.025)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.11, 0.16, 0.15)
	metal.metallic = 0.6
	bar.material = metal
	bars.mesh = bar
	bars.instance_count = int(length / 0.32) + 1
	for index in range(bars.instance_count): bars.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(-length / 2 + index * 0.32, 0, 0)))
	instance.multimesh = bars
	root.add_child(instance)
	for y in [-0.8, 0.8]: Art.box(root, Vector3(0, y, 0), Vector3(length, 0.05, 0.05), Color(0.13, 0.18, 0.17))
	world.box(root, Vector3.ZERO, Vector3(length, 2.3, 0.1), "metal").hide()

func lamp(point: Vector3) -> void:
	world.staircases.pipe(point, point + Vector3.UP * 5.2, 0.075, Color(0.1, 0.14, 0.13))
	Art.rounded_box(self, point + Vector3.UP * 5.2, Vector3(0.65, 0.12, 0.4), Color(0.3, 0.35, 0.31), 0.05)
	var light := OmniLight3D.new()
	light.position = point + Vector3.UP * 4.9
	light.light_color = Color(0.8, 0.67, 0.44)
	light.light_energy = 3.8
	light.omni_range = 17
	light.shadow_enabled = true
	add_child(light)

func tree(point: Vector3) -> void:
	world.dressing.tree(self, point, int(abs(point.z) * 10))

func street() -> void:
	for index in range(7):
		var x := -54.0 + index * 18
		var height := 10.0 + (index % 3) * 4
		box(Vector3(x, height / 2, 49), Vector3(14, height, 13), Color(0.04, 0.055, 0.06), false)
		for floor in range(int(height / 3)):
			for column in range(5):
				Art.box(self, Vector3(x - 5 + column * 2.5, 2 + floor * 3, 42.45), Vector3(1.2, 1.4, 0.02), Color(0.11, 0.14, 0.13) if (floor + column + index) % 4 == 0 else Color(0.014, 0.025, 0.03))
	for z in [32.0, 34.0, 36.0]:
		for x in range(-26, 27, 4): Art.box(self, Vector3(x, -0.01, z), Vector3(2.2, 0.015, 0.08), Color(0.35, 0.34, 0.26))

func weather() -> void:
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, -28, 0)
	moon.light_color = Color(0.35, 0.49, 0.62)
	moon.light_energy = 0.28
	moon.shadow_enabled = true
	add_child(moon)
	# CPU particles work with Compatibility; rain stays outside the roof footprint.
	for data in [[Vector3(0, 7, 27.5), Vector3(27, 1, 10.5)], [Vector3(21, 7, -8), Vector3(11, 1, 25)], [Vector3(-24, 7, -8), Vector3(6, 1, 25)], [Vector3(0, 7, -32), Vector3(28, 1, 6)]]:
		var rain := CPUParticles3D.new()
		rain.position = data[0]
		rain.amount = 380
		rain.lifetime = 1.25
		rain.preprocess = 1.25
		rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		rain.emission_box_extents = data[1]
		rain.direction = Vector3(0.05, -1, 0.04)
		rain.spread = 3
		rain.initial_velocity_min = 8
		rain.initial_velocity_max = 10
		rain.gravity = Vector3(0, -2, 0)
		var drop := BoxMesh.new()
		drop.size = Vector3(0.008, 0.18, 0.008)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.23, 0.31, 0.35)
		drop.material = material
		rain.mesh = drop
		add_child(rain)


func details() -> void:
	# Drain channels, slatted benches and utility hardware reinforce human scale.
	for x in [-7.8, 7.8]:
		box(Vector3(x, 0.008, 19), Vector3(0.35, 0.018, 3.8), Color(0.025, 0.035, 0.032), false)
		for index in range(24): Art.box(self, Vector3(x, 0.022, 17.2 + index * 0.15), Vector3(0.3, 0.02, 0.035), Color(0.22, 0.25, 0.22))
	for x in [-5.0, 5.0]:
		for z in [18.3, 18.9]:
			for offset in [-0.8, 0.8]: box(Vector3(x + offset, 0.28, z), Vector3(0.09, 0.56, 0.09), Color(0.1, 0.14, 0.12))
		for index in range(5):
			Art.box(self, Vector3(x, 0.58, 18.25 + index * 0.16), Vector3(2.05, 0.07, 0.12), Color(0.18, 0.2, 0.14))
			Art.box(self, Vector3(x, 0.82 + index * 0.12, 18.15), Vector3(2.05, 0.08, 0.055), Color(0.18, 0.2, 0.14))
		world.box(self, Vector3(x, 0.48, 18.55), Vector3(2.1, 0.96, 0.85), "metal").hide()
	for point in [Vector3(3.5, 0.001, 24), Vector3(-14, 0.001, 23), Vector3(20, 0.001, 29)]:
		var puddle := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 1.7
		disc.bottom_radius = 1.7
		disc.height = 0.003
		disc.radial_segments = 48
		puddle.mesh = disc
		puddle.position = point
		puddle.scale.z = 0.45
		var wet := StandardMaterial3D.new()
		wet.albedo_color = Color(0.025, 0.044, 0.052)
		wet.roughness = 0.12
		wet.metallic = 0.25
		puddle.material_override = wet
		add_child(puddle)
	Art.model(self, "trashcan", Vector3(8.8, 0, 16), Vector3(0.65, 1.0, 0.65))
	box(Vector3(8.8, 0.45, 16), Vector3(0.55, 0.9, 0.55), Color(0.1, 0.15, 0.12)).hide()
	box(Vector3(8.22, 1.1, 5), Vector3(0.25, 1.1, 0.7), Color(0.2, 0.27, 0.23))
	for z in [4.78, 5.22]: world.staircases.pipe(Vector3(8.25, 0, z), Vector3(8.25, 2.7, z), 0.025, Color(0.25, 0.3, 0.26))
	var plaque: Label3D = world.add_sign("VESPER\nESTACIONAMENTO PRIVATIVO\nVISITANTES / IDENTIFIQUE-SE", Vector3(9, 1.7, 23))
	plaque.pixel_size = 0.0015
	Art.box(self, Vector3(9, 1.7, 22.95), Vector3(1.6, 0.65, 0.05), Color(0.07, 0.13, 0.11))
	world.staircases.pipe(Vector3(9, 0, 23), Vector3(9, 1.4, 23), 0.04, Color(0.18, 0.25, 0.2))
