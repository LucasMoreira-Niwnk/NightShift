extends Node3D

const Art = preload("res://scripts/art.gd")
var world: Node3D
var warning: Label3D

func _ready() -> void:
	name = "Stairwells"
	main_stair()
	service_stair()

func box(point: Vector3, size: Vector3, kind: String = "metal", collision: bool = true) -> MeshInstance3D:
	return world.box(self, point, size, kind, collision)

func landing(center: Vector3, size: Vector2) -> void:
	# Concrete soffit and a thin finish keep floor tiles off the underside.
	box(center - Vector3.UP * 0.09, Vector3(size.x, 0.14, size.y), "ceiling")
	box(center - Vector3.UP * 0.01, Vector3(size.x, 0.02, size.y), "floor_concrete")
	for x in [-size.x * 0.5 + 0.1, size.x * 0.5 - 0.1]:
		Art.box(self, center + Vector3(x, 0.008, 0), Vector3(0.08, 0.015, size.y - 0.1), Color(0.65, 0.48, 0.15))

func pipe(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = a.distance_to(b)
	cylinder.radial_segments = 12
	mesh.mesh = cylinder
	mesh.position = (a + b) / 2
	mesh.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.65
	material.roughness = 0.32
	mesh.material_override = material
	add_child(mesh)

func flight(x: float, start_z: float, end_z: float, start_y: float, end_y: float) -> void:
	var run := absf(end_z - start_z)
	var rise := end_y - start_y
	# Use a continuous collision ramp underneath twelve visible stair treads.
	var slope := -atan2(rise, end_z - start_z)
	if absf(slope) > PI / 2: slope += PI if slope < 0 else -PI
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.1, 0.12, sqrt(run * run + rise * rise))
	collision.shape = shape
	body.add_child(collision)
	body.position = Vector3(x, (start_y + end_y) / 2 - 0.06 * cos(slope), (start_z + end_z) / 2 - 0.06 * sin(slope))
	body.rotation.x = slope
	add_child(body)
	for index in range(12):
		var t := (index + 0.5) / 12.0
		var height := lerpf(start_y, end_y, (index + 1.0) / 12.0)
		var z := lerpf(start_z, end_z, t)
		box(Vector3(x, height - 0.1, z), Vector3(2.1, 0.2, run / 12), "metal", false)
		Art.box(self, Vector3(x, height + 0.007, z), Vector3(2.04, 0.012, 0.045), Color(0.58, 0.49, 0.24))
	for side in [-1.0, 1.0]:
		var edge: float = x + side * 1.03
		var a := Vector3(edge, start_y + 1.0, start_z)
		var b := Vector3(edge, end_y + 1.0, end_z)
		pipe(a, b, 0.032, Color(0.32, 0.36, 0.33))
		pipe(a - Vector3.UP * 0.45, b - Vector3.UP * 0.45, 0.018, Color(0.19, 0.24, 0.21))
		for index in range(6):
			var t := index / 5.0
			var foot := Vector3(edge, lerpf(start_y, end_y, t), lerpf(start_z, end_z, t))
			pipe(foot, foot + Vector3.UP, 0.023, Color(0.2, 0.25, 0.22))
		var rail_body := StaticBody3D.new()
		var rail_shape := CollisionShape3D.new()
		var rail_box := BoxShape3D.new()
		rail_box.size = Vector3(0.09, 1.1, sqrt(run * run + rise * rise))
		rail_shape.shape = rail_box
		rail_body.add_child(rail_shape)
		rail_body.position = Vector3(edge, (start_y + end_y) / 2 + 0.53, (start_z + end_z) / 2)
		rail_body.rotation.x = slope
		add_child(rail_body)

func light(point: Vector3, caption: String) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = point
	lamp.light_color = Color(0.65, 0.77, 0.68)
	lamp.light_energy = 0.75
	lamp.omni_range = 6.5
	lamp.shadow_enabled = true
	add_child(lamp)
	Art.box(self, point + Vector3(0, 0.1, 0), Vector3(0.7, 0.08, 0.22), Color(0.5, 0.6, 0.53))
	var sign_point := point - Vector3(0, 0.35, 0)
	Art.box(self, sign_point, Vector3(1.65, 0.3, 0.06), Color(0.045, 0.09, 0.075))
	for side in [-1.0, 1.0]:
		var label: Label3D = world.add_sign(caption, sign_point + Vector3(0, 0, side * 0.04), PI if side < 0 else 0.0)
		label.pixel_size = 0.0012

func main_stair() -> void:
	landing(Vector3(0, 0, -17), Vector2(5.8, 2.4))
	landing(Vector3(0, 2.1, -23.35), Vector2(5.8, 1.7))
	landing(Vector3(0, 4.2, -16), Vector2(5.8, 4.0))
	# Seal the full storey/plenum around the 1.5 m doorway, up to the soffit.
	for x in [-1.85, 1.85]: box(Vector3(x, 2.02, -15.8), Vector3(2.2, 4.04, 0.2), "wall")
	box(Vector3(0, 3.32, -15.8), Vector3(1.5, 1.44, 0.2), "wall")
	flight(-1.4, -18, -22.5, 0, 2.1)
	flight(1.4, -22.5, -18, 2.1, 4.2)
	for x in [-2.95, 2.95]:
		for level in [0.0, 4.2]: world.architecture.window_wall(self, Vector3(x, level + 1.5, -19.15), Vector3(0.2, 3, 10.3), [-2.55, 1.65], 1.5)
		box(Vector3(x, 3.6, -19.15), Vector3(0.2, 1.2, 10.3), "wall")
	box(Vector3(0, 3.65, -24.3), Vector3(6.1, 7.3, 0.2), "wall")
	box(Vector3(0, 7.35, -19.15), Vector3(6.1, 0.2, 10.5), "ceiling")
	light(Vector3(-1.3, 2.8, -17.3), "TÉRREO / RECEPÇÃO →")
	light(Vector3(0, 4.7, -23.4), "PATAMAR / 2º ANDAR →")
	light(Vector3(1.4, 6.8, -16.3), "02 / ADMINISTRAÇÃO")

func service_stair() -> void:
	landing(Vector3(-11.15, 0, -3.75), Vector2(6.3, 13.5))
	landing(Vector3(-11.1, 2.1, -2.5), Vector2(5.5, 2.0))
	landing(Vector3(-11.1, 4.2, -9.25), Vector2(5.5, 2.5))
	flight(-12.3, -8, -3.5, 0, 2.1)
	flight(-9.7, -3.5, -8, 2.1, 4.2)
	for level in [0.0, 4.2]: world.architecture.window_wall(self, Vector3(-14.35, level + 1.5, -3.75), Vector3(0.2, 3, 13.5), [-3.7, 1.5, 4.3], 1.4)
	box(Vector3(-14.35, 3.6, -3.75), Vector3(0.2, 1.2, 13.5), "wall")
	box(Vector3(-11.15, 3.65, -10.6), Vector3(6.5, 7.3, 0.2), "wall")
	box(Vector3(-11.15, 3.65, 3.1), Vector3(6.5, 7.3, 0.2), "wall")
	box(Vector3(-11.15, 7.35, -3.75), Vector3(6.5, 0.2, 13.7), "ceiling")
	box(Vector3(-8, 1.5, -4), Vector3(0.2, 3, 4), "wall")
	box(Vector3(-8, 5.7, -4), Vector3(0.2, 3, 2), "wall")
	warning = world.add_sign("VOCÊ SEMPRE VOLTA\nPELO MESMO CAMINHO.", Vector3(-11.6, 5.9, -10.45))
	warning.pixel_size = 0.0019
	light(Vector3(-11.1, 6.9, -9), "ESCADA DE SERVIÇO / DESÇA")
	light(Vector3(-11.1, 4.7, -2), "01 / PATAMAR")
	light(Vector3(-9.4, 2.6, 1), "SEGURANÇA →")

func is_main(point: Vector3) -> bool:
	return point.x > -2.9 and point.x < 2.9 and point.z < -15.7 and point.z > -24.3

func is_service(point: Vector3) -> bool:
	return point.x < -8.2 and point.x > -14.3 and point.z > -10.5 and point.z < 3
