extends RefCounted

static func surface(kind: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var source := ""
	match kind:
		"tile": source = "Tiles074"
		"wall", "ceiling": source = "PaintedPlaster017"
		"wood": source = "Wood051"
	if source != "":
		var prefix := "res://assets/textures/%s/%s_1K-JPG_" % [source, source]
		material.albedo_texture = load(prefix + "Color.jpg")
		material.normal_enabled = true
		material.normal_texture = load(prefix + "NormalGL.jpg")
		material.normal_scale = 0.65 if kind == "wall" else 0.8
		material.roughness_texture = load(prefix + "Roughness.jpg")
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		var scale := 0.48 if kind == "tile" else 0.65
		material.uv1_scale = Vector3.ONE * scale
		material.albedo_color = Color(0.68, 0.72, 0.65) if kind == "wall" else Color(0.72, 0.73, 0.67)
		if kind == "wood":
			material.albedo_color = Color(0.52, 0.43, 0.32)
			material.uv1_scale = Vector3.ONE * 1.3
		if kind == "ceiling": material.albedo_color = Color(0.36, 0.39, 0.36)
	else:
		material.albedo_color = Color(0.16, 0.21, 0.2)
		material.metallic = 0.55
		material.roughness = 0.72
	return material
