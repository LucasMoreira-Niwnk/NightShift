extends Node3D

var time := 0.0
var walking := false
var light: SpotLight3D
var rig: Node3D
var skeleton: Skeleton3D
var torch: Node3D
var lens_point := Vector3.ZERO
var base := Vector3.ZERO
var standalone_preview := false

func _ready() -> void:
	rig = $ArmRig
	skeleton = $ArmRig/arms/Skeleton3D
	torch = $Lanterna
	light = $FlashlightBeam
	base = position
	# Play the pose authored in the 3D editor once. Never rebuild the scene's
	# bones, meshes or flashlight transform here: visual edits must survive.
	var pose: AnimationPlayer = $PoseAnimation
	pose.play("Pegada")
	pose.advance(0)
	pose.stop(true)
	skeleton.force_update_all_bone_transforms()
	var view := get_parent() as Camera3D
	standalone_preview = view == null
	if standalone_preview:
		view = $Preview/PreviewCamera
		# Match the player's camera origin even after editing the root placement.
		view.global_transform = Transform3D.IDENTITY
		view.make_current()
	else:
		# Authoring lights/environment must never leak into the actual level/CCTV.
		$Preview.free()
	lens_point = find_lens(torch)
	light.position = lens_point + Vector3(0, 0, -0.008)
	light.look_at(view.to_global(Vector3(0, 0, -15)), Vector3.UP)
	light.visible = standalone_preview

func find_lens(node: Node3D) -> Vector3:
	if node is MeshInstance3D and "front lens" in node.name.to_lower().replace("_", " "):
		return global_transform.affine_inverse() * node.global_transform * node.get_aabb().get_center()
	for child in node.get_children():
		if child is Node3D:
			var result := find_lens(child)
			if result != Vector3.ZERO: return result
	return Vector3.ZERO

func _process(delta: float) -> void:
	if standalone_preview: return
	time += delta * (7.5 if walking else 1.5)
	var amplitude := 0.005 if walking else 0.0012
	position = base + Vector3(sin(time) * amplitude, cos(time * 2) * amplitude, 0)
