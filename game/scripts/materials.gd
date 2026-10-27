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
		if kind == "wall": weather_wall(material)
	else:
		material.albedo_color = Color(0.16, 0.21, 0.2)
		material.metallic = 0.55
		material.roughness = 0.72
	return material


# O piso do Vesper e lajota velha: encerada ha anos demais, riscada por cadeira
# e carrinho de limpeza. A luz tem que abrir num borrao opaco, nunca num ponto
# especular limpo. Sem SSR no renderizador Compatibility, quem vende isso e a
# rugosidade alta somada a uma camada de sujeira que nao cobre o piso inteiro.
static func scuff_floor(material: StandardMaterial3D) -> void:
	material.roughness = 1.0
	material.metallic = 0.0
	# praticamente sem especular: a poca da lanterna fica chapada no chao
	material.metallic_specular = 0.05
	material.albedo_color = Color(0.56, 0.57, 0.53)
	material.detail_enabled = true
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_albedo = grime_texture()
	material.detail_normal = scratch_normal_texture()
	material.uv2_scale = Vector3.ONE * 0.42
	material.uv2_triplanar = true
	material.uv2_world_triplanar = true
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2

# Parede de pintura velha: casca de tinta soltando e um mofo discreto, raro.
static func weather_wall(material: StandardMaterial3D) -> void:
	material.roughness = 0.92
	material.metallic_specular = 0.12
	material.detail_enabled = true
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_albedo = peeling_texture()
	material.detail_normal = scratch_normal_texture()
	material.uv2_scale = Vector3.ONE * 0.12
	material.uv2_triplanar = true
	material.uv2_world_triplanar = true
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2

# Manchas largas de encardido, em escala bem maior que a lajota.
static func grime_texture() -> NoiseTexture2D:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.42, 0.41, 0.38))
	ramp.set_color(1, Color(1.0, 1.0, 0.98))
	return noise_texture(0.009, 4, 512, 512, ramp)

# Tinta descascando e mofo, ambos raros: a rampa fica branca (neutra no MUL)
# em quase toda a faixa do ruido e so pinta na ponta, o que mantem a parede
# limpa fora de umas poucas placas.
static func peeling_texture() -> NoiseTexture2D:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.78, 0.84, 0.93, 0.97, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0),
		Color(0.80, 0.77, 0.70),
		Color(0.72, 0.70, 0.63),
		Color(0.47, 0.54, 0.44),
		Color(0.33, 0.42, 0.32),
	])
	return noise_texture(0.016, 3, 512, 512, ramp)

# Riscos finos: ruido em textura achatada, esticada sobre UV quadrada, o que
# alonga o padrao numa direcao so e faz ele ler como arranhao. A rampa fica
# chapada no meio e so varia nas pontas, entao o relevo aparece em manchas,
# nao no piso inteiro.
static func scratch_normal_texture() -> NoiseTexture2D:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.74, 0.86, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.2, 0.2, 0.2),
		Color(0.5, 0.5, 0.5),
		Color(0.5, 0.5, 0.5),
		Color(0.78, 0.78, 0.78),
		Color(1.0, 1.0, 1.0),
	])
	var texture := noise_texture(0.9, 3, 512, 20, ramp)
	texture.as_normal_map = true
	texture.bump_strength = 0.7
	return texture

static func noise_texture(frequency: float, octaves: int, width: int, height: int, ramp: Gradient) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	var texture := NoiseTexture2D.new()
	texture.width = width
	texture.height = height
	texture.seamless = true
	texture.noise = noise
	if ramp != null: texture.color_ramp = ramp
	return texture
