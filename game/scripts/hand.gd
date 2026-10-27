extends Node3D

const Art = preload("res://scripts/art.gd")
const PALM_AXIS := Vector3(0, 1, 0)
const WRIST_ROLL := 1.5
const FINGER_CURL := [0.75, 1.1, 0.8]
const THUMB_CURL := [-0.25, 0.7, 0.3]
const GRIP_OFFSET := Vector3(-0.018, -0.03, -0.025)
var time := 0.0
var walking := false
var light: SpotLight3D
var rig: Node3D
var skeleton: Skeleton3D
var torch: Node3D
var lens_point := Vector3.ZERO
var base := Vector3(0.22, -0.14, -0.34)

func _ready() -> void:
	position = base
	var packed := load("res://assets/models/wrad_arms/right_arm.glb") as PackedScene
	rig = packed.instantiate() as Node3D
	rig.set_meta("source_scene", packed)
	add_child(rig)
	skeleton = rig.find_child("Skeleton3D", true, false) as Skeleton3D
	Art.preserve_pbr(rig)
	var wrist := skeleton.find_bone("wrist.r")
	var wrist_rest := rig.global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_rest(wrist)
	# Align the authored wrist, not the mesh bounds, to the first-person grip.
	var palm_axis := PALM_AXIS.normalized()
	# Upright forearm entering from below; fingertips wrap around the barrel.
	var grip_basis := Basis(palm_axis.cross(Vector3.FORWARD), palm_axis, Vector3.FORWARD).rotated(palm_axis, WRIST_ROLL).scaled(Vector3.ONE * 0.095)
	rig.transform = Transform3D(grip_basis, Vector3.ZERO) * wrist_rest.affine_inverse()
	for finger in ["index", "middle", "ring", "pinky"]:
		for joint in range(1, 4):
			var index := skeleton.find_bone("finger_%s%d.r" % [finger, joint])
			var curl: float = FINGER_CURL[joint - 1]
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.BACK, curl))
	for joint in range(1, 4):
		var thumb := skeleton.find_bone("finger_thumb%d.r" % joint)
		# Oppose the thumb at its base before curling the pad around the barrel.
		if thumb >= 0: skeleton.set_bone_pose_rotation(thumb, Quaternion(Vector3.BACK, THUMB_CURL[joint - 1]))
	skeleton.force_update_all_bone_transforms()
	build_sleeve()
	var socket := skeleton.find_bone("socket.r")
	var grip: Vector3 = global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(socket).origin
	torch = Art.flashlight(self, grip + GRIP_OFFSET, 0.22)
	fpv_layer(rig)
	fpv_layer(torch)
	lens_point = find_lens(torch)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-0.14, 0.18, 0.25)
	fill.light_cull_mask = 2
	fill.light_color = Color(0.78, 0.84, 0.83)
	fill.light_energy = 0.5
	fill.omni_range = 1.2
	add_child(fill)
	light = SpotLight3D.new()
	light.position = lens_point + Vector3(0, 0, -0.008)
	light.light_color = Color(1, 0.94, 0.8)
	light.light_energy = 3.0
	light.spot_range = 18
	# Facho de 20 graus: cai exponencialmente com a distancia e tambem do eixo
	# ate a borda do cone, onde chega a zero.
	light.spot_angle = 20
	light.spot_attenuation = 2.0
	light.spot_angle_attenuation = 2.0
	light.visible = false
	add_child(light)
	light.look_at(get_parent().to_global(Vector3(0, 0, -15)), Vector3.UP)

func find_lens(node: Node3D) -> Vector3:
	if node is MeshInstance3D and "front lens" in node.name.to_lower().replace("_", " "):
		return global_transform.affine_inverse() * node.global_transform * node.get_aabb().get_center()
	for child in node.get_children():
		if child is Node3D:
			var result := find_lens(child)
			if result != Vector3.ZERO: return result
	return Vector3.ZERO

func fpv_layer(node: Node) -> void:
	if node is MeshInstance3D:
		node.layers = 2
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): fpv_layer(child)

func _process(delta: float) -> void:
	time += delta * (7.5 if walking else 1.5)
	var amplitude := 0.005 if walking else 0.0012
	position = base + Vector3(sin(time) * amplitude, cos(time * 2) * amplitude, 0)

func build_sleeve() -> void:
	# Extend the cropped source forearm into a uniform sleeve past the right edge.
	# The viewmodel remains on layer 2, outside CCTV and the world shadow pass.
	var wrist := skeleton.find_bone("wrist.r")
	var forearm := skeleton.get_bone_parent(wrist)
	var toward_elbow: Vector3 = global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(forearm).origin
	var axis := toward_elbow.normalized()
	var side := axis.cross(Vector3.UP).normalized()
	var up := axis.cross(side).normalized()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(12):
		var t0 := ring / 12.0
		var t1 := (ring + 1) / 12.0
		for segment in range(20):
			var a0 := segment * TAU / 20.0
			var a1 := (segment + 1) * TAU / 20.0
			for sample in [Vector2(t0,a0),Vector2(t1,a0),Vector2(t1,a1),Vector2(t0,a0),Vector2(t1,a1),Vector2(t0,a1)]:
				var t: float = sample.x
				var angle: float = sample.y
				var radial := side * cos(angle) + up * sin(angle) * 0.86
				var radius := 0.058 + t * 0.025 + sin(t * PI * 10) * 0.0018
				tool.set_normal(radial.normalized())
				tool.add_vertex(axis * (0.15 + t * 0.95) + radial * radius)
	var sleeve := MeshInstance3D.new()
	sleeve.name = "UniformSleeve"
	sleeve.mesh = tool.commit()
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.1, 0.125, 0.15)
	cloth.roughness = 0.97
	cloth.metallic_specular = 0.08
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	sleeve.material_override = cloth
	add_child(sleeve)
	fpv_layer(sleeve)
