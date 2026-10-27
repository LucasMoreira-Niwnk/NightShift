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
		if kind == "tile": scuff_floor(material)
	else:
		material.albedo_color = Color(0.16, 0.21, 0.2)
		material.metallic = 0.55
		material.roughness = 0.72
	return material


# O piso do Vesper e lajota velha: encerada ha anos demais, riscada por cadeira
# e carrinho de limpeza. A luz tem que abrir num borrao opaco, nunca num ponto
# especular limpo. Sem SSR no renderizador Compatibility, quem vende isso e a
# rugosidade alta somada a uma camada de sujeira que quebra a repeticao da UV.
static func scuff_floor(material: StandardMaterial3D) -> void:
	material.roughness = 0.94
	material.metallic = 0.0
	material.metallic_specular = 0.18
	material.albedo_color = Color(0.56, 0.57, 0.53)
	material.detail_enabled = true
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_albedo = grime_texture()
	material.detail_normal = scratch_normal_texture()
	material.uv2_scale = Vector3.ONE * 0.11
	material.uv2_triplanar = true
	material.uv2_world_triplanar = true
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2

# Manchas largas de encardido, em escala bem maior que a lajota.
static func grime_texture() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.009
	noise.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.noise = noise
	# cinza sujo a branco: multiplicado, so escurece, nunca estoura o albedo
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.42, 0.41, 0.38))
	ramp.set_color(1, Color(1.0, 1.0, 0.98))
	texture.color_ramp = ramp
	return texture

# Riscos finos: ruido esticado em uma direcao, lido como normal map.
static func scratch_normal_texture() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.16
	noise.fractal_octaves = 2
	var texture := NoiseTexture2D.new()
	# textura achatada esticada sobre UV quadrada: o ruido vira risco alongado
	texture.width = 512
	texture.height = 32
	texture.seamless = true
	texture.as_normal_map = true
	texture.bump_strength = 1.4
	texture.noise = noise
	return texture
