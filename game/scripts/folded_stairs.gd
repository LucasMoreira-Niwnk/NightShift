extends Node3D

const Art = preload("res://scripts/art.gd")
var world: Node3D
var warning: Label3D
var service_lights: Array = []

func _ready() -> void:
	name = "Stairwells"
	main_stair()
	service_stair()

func box(point: Vector3, size: Vector3, kind: String = "metal", collision: bool = true) -> MeshInstance3D:
	return world.box(self, point, size, "wall_concrete" if kind == "wall" else kind, collision)

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

func flight(x: float, start_z: float, end_z: float, start_y: float, end_y: float, structural: bool = false) -> void:
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
	if structural:
		# A continuous soffit makes the direction/read of the stair unambiguous
		# from below. It stays shallow enough to preserve the ground passage.
		var soffit := box(Vector3(x, (start_y + end_y) / 2 - 0.12, (start_z + end_z) / 2), Vector3(2.1, 0.16, sqrt(run * run + rise * rise)), "ceiling", false)
		soffit.rotation.x = slope
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

func landing_guard(a: Vector3, b: Vector3) -> void:
	var middle := (a + b) / 2
	var length := a.distance_to(b)
	var size := Vector3(absf(b.x - a.x) + 0.09, 1.1, absf(b.z - a.z) + 0.09)
	# A solid guard envelope closes the space between the visible uprights.
	box(middle + Vector3.UP * 0.55, size, "metal").hide()
	pipe(a + Vector3.UP * 1.05, b + Vector3.UP * 1.05, 0.032, Color(0.26, 0.3, 0.28))
	pipe(a + Vector3.UP * 0.55, b + Vector3.UP * 0.55, 0.02, Color(0.2, 0.24, 0.22))
	box(middle + Vector3.UP * 0.065, Vector3(size.x, 0.13, size.z), "metal", false)
	var count := maxi(1, int(ceil(length / 0.65)))
	for index in range(count + 1):
		var foot := a.lerp(b, float(index) / count)
		pipe(foot, foot + Vector3.UP * 1.05, 0.023, Color(0.2, 0.24, 0.22))

func service_lamp(point: Vector3, target: Vector3, yaw: float) -> void:
	var fixture := Node3D.new()
	fixture.name = "ServiceWallFixture%d" % service_lights.size()
	fixture.position = point
	fixture.rotation.y = yaw
	add_child(fixture)
	Art.box(fixture, Vector3.ZERO, Vector3(0.38, 0.5, 0.08), Color(0.1, 0.13, 0.12))
	var diffuser := Art.box(fixture, Vector3(0, 0, 0.065), Vector3(0.28, 0.34, 0.04), Color(0.7, 0.75, 0.67))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.7, 0.75, 0.67)
	glow.emission_enabled = true
	glow.emission = Color(0.32, 0.37, 0.28)
	diffuser.material_override = glow
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(0, 0, 0.13)
	lamp.light_color = Color(0.86, 0.88, 0.76)
	lamp.light_energy = 2.4
	lamp.spot_range = 7.0
	lamp.spot_angle = 70
	lamp.spot_attenuation = 1.0
	lamp.spot_angle_attenuation = 1.2
	lamp.shadow_enabled = true
	lamp.shadow_bias = 0.025
	fixture.add_child(lamp)
	lamp.look_at(target, Vector3.UP)
	service_lights.append(lamp)
	# A short-range bounce fills the fixture's own wall without the former
	# room-wide omni spill through the two stair flights.
	var bounce := OmniLight3D.new()
	bounce.position = Vector3(0, 0, 0.18)
	bounce.light_color = lamp.light_color
	bounce.light_energy = 0.35
	bounce.omni_range = 3.8
	bounce.shadow_enabled = true
	fixture.add_child(bounce)
	# O mesmo reator gagueja aqui: sem isto a escada de servico ficaria a unica
	# parte do predio com luz constante. Facho e fill juntos, senao o fill
	# sustenta o ambiente justo na batida em que o facho deveria cair.
	world.pulse_light(lamp)
	world.pulse_light(bounce)

func light(point: Vector3, caption: String) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = point
	lamp.light_color = Color(0.65, 0.77, 0.68)
	lamp.light_energy = 0.75
	lamp.omni_range = 6.5
	lamp.shadow_enabled = true
	add_child(lamp)
	world.pulse_light(lamp)
	Art.box(self, point + Vector3(0, 0.1, 0), Vector3(0.7, 0.08, 0.22), Color(0.5, 0.6, 0.53))
	var side := 1.0 if point.x > 0 else -1.0
	var sign_point := Vector3(side * 2.86, point.y - 0.55, point.z)
	var plaque := Art.box(self, sign_point, Vector3(0.04,0.3,1.65),Color(0.12,0.17,0.14))
	plaque.name = "WallWayfinding"
	plaque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label: Label3D = world.add_sign(caption, sign_point - Vector3(side * 0.03,0,0), -side * PI/2)
	label.pixel_size = 0.0012
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
	# Both landings now reach the facade and the administration threshold.
	# In particular, there must be no 35 cm slot before the upstairs door.
	landing(Vector3(-11.1, 2.1, -2.5), Vector2(6.2, 2.0))
	landing(Vector3(-11.1, 4.2, -9.25), Vector2(6.2, 2.5))
	flight(-12.3, -8, -3.5, 0, 2.1, true)
	flight(-9.7, -3.5, -8, 2.1, 4.2, true)
	# Upper landing: only the eastern flight remains open for descent.
	landing_guard(Vector3(-14.15, 4.2, -8), Vector3(-10.77, 4.2, -8))
	landing_guard(Vector3(-8.63, 4.2, -8), Vector3(-8.05, 4.2, -8))
	landing_guard(Vector3(-14.15, 4.2, -10.5), Vector3(-14.15, 4.2, -8))
	# Half landing: close its end, outer edges and the gap between the flights.
	landing_guard(Vector3(-14.15, 2.1, -1.55), Vector3(-8.05, 2.1, -1.55))
	landing_guard(Vector3(-14.15, 2.1, -3.5), Vector3(-14.15, 2.1, -1.55))
	landing_guard(Vector3(-8.05, 2.1, -3.5), Vector3(-8.05, 2.1, -1.55))
	landing_guard(Vector3(-11.27, 2.1, -3.5), Vector3(-10.73, 2.1, -3.5))
	for level in [0.0, 4.2]: world.architecture.window_wall(self, Vector3(-14.35, level + 1.5, -3.75), Vector3(0.2, 3, 13.5), [-3.7, 1.5, 4.3], 1.4)
	box(Vector3(-14.35, 3.6, -3.75), Vector3(0.2, 1.2, 13.5), "wall")
	box(Vector3(-11.15, 3.65, -10.6), Vector3(6.5, 7.3, 0.2), "wall")
	box(Vector3(-11.15, 3.65, 3.1), Vector3(6.5, 7.3, 0.2), "wall")
	box(Vector3(-11.15, 7.35, -3.75), Vector3(6.5, 0.2, 13.7), "ceiling")
	box(Vector3(-8, 1.5, -4), Vector3(0.2, 3, 4), "wall")
	box(Vector3(-8, 5.7, -4), Vector3(0.2, 3, 2), "wall")
	box(Vector3(-8, 3.57, -3.75), Vector3(0.2, 1.14, 13.5), "wall")
	box(Vector3(-8, 6.95, -9), Vector3(0.2, 0.5, 1.5), "wall")
	warning = world.add_sign("VOCÊ SEMPRE VOLTA\nPELO MESMO CAMINHO.", Vector3(-11.6, 5.9, -10.45))
	warning.pixel_size = 0.0019
	service_lamp(Vector3(-14.18, 6.3, -5.6), Vector3(-10, 3.7, -6), PI / 2)
	service_lamp(Vector3(-14.18, 3.9, -4.3), Vector3(-11.1, 2.2, -2.5), PI / 2)
	service_lamp(Vector3(-14.18, 2.55, 1.9), Vector3(-9.2, 0.7, 1), PI / 2)
	world.add_sign("ESCADA DE SERVIÇO\nTÉRREO / SEGURANÇA", Vector3(-10, 6.65, -10.45)).pixel_size = 0.0013
	world.add_sign("PATAMAR\nCONTINUE DESCENDO", Vector3(-14.17, 3.0, -4.3), PI / 2).pixel_size = 0.0011
	world.add_sign("SAÍDA / SEGURANÇA", Vector3(-14.17, 2.0, 1.9), PI / 2).pixel_size = 0.0012

func is_main(point: Vector3) -> bool:
	return point.x > -2.9 and point.x < 2.9 and point.z < -15.7 and point.z > -24.3

func is_service(point: Vector3) -> bool:
	return point.x < -8.2 and point.x > -14.3 and point.z > -10.5 and point.z < 3
