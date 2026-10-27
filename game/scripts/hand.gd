extends Node3D

const Art = preload("res://scripts/art.gd")
var time := 0.0
var walking := false
var light: SpotLight3D
var rig: Node3D
var skeleton: Skeleton3D
var torch: Node3D
var lens_point := Vector3.ZERO
var base := Vector3(0.32, -0.29, -0.58)

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
	var palm_axis := Vector3(-0.6, 0.8, 0)
	var grip_basis := Basis(palm_axis.cross(Vector3.FORWARD), palm_axis, Vector3.FORWARD).rotated(palm_axis, 0.45).scaled(Vector3.ONE * 0.095)
	rig.transform = Transform3D(grip_basis, Vector3.ZERO) * wrist_rest.affine_inverse()
	for finger in ["index", "middle", "ring", "pinky"]:
		for joint in range(1, 4):
			var index := skeleton.find_bone("finger_%s%d.r" % [finger, joint])
			var curl: float = [0.5, 0.9, 0.65][joint - 1]
			skeleton.set_bone_pose_rotation(index, Quaternion(Vector3.BACK, curl))
	var thumb := skeleton.find_bone("finger_thumb2.r")
	skeleton.set_bone_pose_rotation(thumb, Quaternion(Vector3.BACK, 0.25))
	var socket := skeleton.find_bone("socket.r")
	var grip: Vector3 = global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(socket).origin
	torch = Art.flashlight(self, grip - Vector3(0, 0.027, 0), 0.22)
	fpv_layer(rig)
	fpv_layer(torch)
	lens_point = find_lens(torch)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-0.14, 0.18, 0.25)
	fill.light_cull_mask = 2
	fill.light_color = Color(0.78, 0.84, 0.83)
	fill.light_energy = 0.65
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
