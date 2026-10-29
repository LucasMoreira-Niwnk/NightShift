extends RefCounted

# Evaluate skinned thumb vertices against the flashlight's cylindrical body.
# This catches intersections which an axis/bone-only check would miss.
static func thumb_clearance(hand: Node3D) -> Dictionary:
	var skeleton: Skeleton3D = hand.get_node("ArmRig/arms/Skeleton3D")
	var mesh: MeshInstance3D = skeleton.get_node("arms_mesh")
	var torch: Node3D = hand.get_node("Lanterna")
	var center := hand.to_local(torch.to_global(Vector3(0, 0.027, 0)))
	var body := torch.find_child("Flashlight body*", true, false) as MeshInstance3D
	var body_transform := hand.global_transform.affine_inverse() * body.global_transform
	var profile := {}
	for surface in range(body.mesh.get_surface_count()):
		for vertex in body.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			var point: Vector3 = body_transform * vertex
			var z := snappedf(point.z, 0.001)
			var radius := Vector2(point.x - center.x, point.y - center.y).length()
			profile[z] = maxf(profile.get(z, 0), radius)
	var palette := []
	for bind in range(mesh.skin.get_bind_count()):
		var bone := skeleton.find_bone(mesh.skin.get_bind_name(bind))
		palette.append(skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind))
	var frame := hand.global_transform.affine_inverse() * skeleton.global_transform
	var arrays := mesh.mesh.surface_get_arrays(0)
	var clearance := INF
	var samples := 0
	for vertex in range(arrays[Mesh.ARRAY_VERTEX].size()):
		var thumb_weight := 0.0
		var point := Vector3.ZERO
		for influence in range(4):
			var index: int = vertex * 4 + influence
			var weight: float = arrays[Mesh.ARRAY_WEIGHTS][index]
			var bind: int = arrays[Mesh.ARRAY_BONES][index]
			point += (palette[bind] * arrays[Mesh.ARRAY_VERTEX][vertex]) * weight
			if "thumb" in str(mesh.skin.get_bind_name(bind)): thumb_weight += weight
		if thumb_weight <= 0.45: continue
		point = frame * point
		var nearest := INF
		var radius := 0.0
		for z in profile:
			var distance := absf(point.z - z)
			if distance < nearest:
				nearest = distance
				radius = profile[z]
		clearance = minf(clearance, Vector2(point.x - center.x, point.y - center.y).length() - radius)
		samples += 1
	return {"clearance": clearance, "samples": samples}
