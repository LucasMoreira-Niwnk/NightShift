extends Node3D

## ==============================================================================
## NIGHTSHIFT — MÊMESIS (vulto de fumaça que anda pelo mapa)
## ==============================================================================
## RELACIONADOS:
##   - shaders/memesis.gdshader (aberração cromática de cada sopro)
##   - chapter_world.gd (cria como `figure`), chapter.gd (posiciona por etapa)
## OBJETIVO DO AGENTE:
##   O corpo não é malha: são nuvens de partículas empilhadas na silhueta de uma
##   pessoa. O contorno nunca fecha, então o vulto lê como presença, não como
##   boneco. Mexa em PUFFS para mudar a postura.
## ==============================================================================

# posição local, raio da nuvem, quantidade de sopros, tamanho do sopro
const PUFFS := [
	[Vector3(0.0, 1.72, 0.0), 0.10, 18, 0.40],
	[Vector3(0.0, 1.20, 0.0), 0.18, 34, 0.52],
	[Vector3(-0.30, 1.10, 0.0), 0.08, 14, 0.32],
	[Vector3(0.30, 1.10, 0.0), 0.08, 14, 0.32],
	[Vector3(-0.14, 0.45, 0.0), 0.09, 16, 0.34],
	[Vector3(0.14, 0.45, 0.0), 0.09, 16, 0.34],
]

const CCTV_LAYER := 4

func _ready() -> void:
	var material := load("res://shaders/memesis.gdshader")
	var skin: ShaderMaterial = null
	if material != null:
		skin = ShaderMaterial.new()
		skin.shader = material
	var quad := QuadMesh.new()
	for data in PUFFS:
		add_child(cloud(data[0], data[1], data[2], data[3], quad, skin))

func cloud(spot: Vector3, radius: float, amount: int, size: float, quad: QuadMesh, skin: ShaderMaterial) -> CPUParticles3D:
	var puffs := CPUParticles3D.new()
	puffs.position = spot
	puffs.amount = amount
	puffs.lifetime = 2.6
	puffs.randomness = 0.9
	puffs.local_coords = true
	puffs.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	puffs.emission_sphere_radius = radius
	# Sobe quase parado: fumaça presa, não fumaça de chaminé.
	puffs.direction = Vector3.UP
	puffs.spread = 180.0
	puffs.gravity = Vector3(0, 0.05, 0)
	puffs.initial_velocity_min = 0.02
	puffs.initial_velocity_max = 0.12
	puffs.scale_amount_min = size * 0.7
	puffs.scale_amount_max = size
	puffs.mesh = quad
	puffs.layers = CCTV_LAYER
	if skin != null: puffs.material_override = skin
	return puffs
