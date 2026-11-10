extends Node3D

## ==============================================================================
## NIGHTSHIFT — MÊMESIS DA FOTO EM NÉVOA (terceiro vulto, comparação)
## ==============================================================================
## RELACIONADOS:
##   - shaders/memesis_massa.gdshader (a massa preta de cada pedaço do corpo)
##   - shaders/memesis_puff.gdshader (as nuvens brancas que escapam)
##   - shaders/memesis.gdshader (as fagulhas brancas)
##   - assets/memesis_foto/completo.png (a referência, como campo de densidade)
##   - memesis.gd (o vulto de névoa do jogo, F3)
##   - main.gd (F5 invoca este), chapter_world.gd (cria os três)
## OBJETIVO DO AGENTE:
##   A pose da referência refeita em volume. A silhueta não é modelada à mão:
##   a própria foto entra no shader como campo de densidade, e é ela que diz
##   onde há névoa e onde há vazio. Montar aquela pose com elipsoides nunca ia
##   bater com a imagem — foi a primeira tentativa, e não bateu.
##   No eixo, por dentro da silhueta, vai a coluna de névoa preta do memesis.gd:
##   a laje da foto é fina e some de perfil, e é a coluna que sustenta a massa
##   quando se anda em volta. Em cima de tudo vêm as nuvens brancas e as
##   fagulhas.
##   Limitação honesta: a foto é plana, então o corpo é uma laje extrudada.
##   De frente bate com a referência; de lado, afina.
const CCTV_LAYER := 4
const OLHO_NU := 1
const DISTANCIA_TESTE := 2.6          # metros à frente do jogador, no F5

# Tamanho da laje que contém a figura, em metros. A proporção acompanha a da
# foto (1024x559), senão o vulto sai esticado ou achatado.
const CORPO_LARGURA := 3.30
const CORPO_ALTURA := 1.80
const CORPO_FUNDO := 0.90

const MASSA_DENSIDADE := 14.0
# A coluna central, herdada do vulto de névoa: mesmo shader, mesmos números.
const COLUNA_ALTURA := 2.2
const COLUNA_LARGURA := 1.0
const COLUNA_DENSIDADE := 9.0
# Raio da cavidade que a névoa abre em volta dos olhos, em metros. Precisa
# passar da meia-largura do par (0,30 m), senão a névoa come as pontas.
const COVA_OLHOS := 0.46
# Adiantada em relação ao plano da foto: a laje é fina, e a coluna à frente
# dela dá o degrau de profundidade que faz o vulto ter frente e fundo.
const COLUNA_AVANCO := 0.48
const NUVENS := 8
# Pequenas: nuvem grande come a silhueta por baixo e apaga o desenho da foto.
const NUVEM_TAMANHO := 0.26
const NUVEM_VIDA := Vector2(2.2, 3.8)
const NUVEM_DERIVA := Vector2(0.25, 0.70)   # para fora, em m/s
const NUVEM_SUBIDA := Vector2(0.40, 0.95)   # para cima, em m/s
const FAGULHAS := 70
# Com que rapidez a cor alcança o corpo, por segundo. Baixo demais e ela nunca
# chega; alto demais e o atraso some.
const ARRASTO := 2.1
# Teto do quanto a cor pode ficar para trás, em metros. Sem ele, uma corrida
# longa deixaria as nuvens a meio corredor do vulto.
const ARRASTO_MAX := 0.75

var _nuvens: Array[FogVolume] = []
var _nuvem_origem: Array[Vector3] = []
var _nuvem_deriva: Array[Vector3] = []
var _nuvem_duracao: Array[float] = []
var _nuvem_idade: Array[float] = []
var _corpo: FogVolume
var _retrato: Image
var _massa: ShaderMaterial
var _brilho: OmniLight3D
var _coluna: FogVolume
var _coluna_pele: ShaderMaterial
var _olhar: Node3D
var _ambiente_tint := Vector3(0.6, 0.85, 1.0)
var _ambiente_level := 0.04
var _rng := RandomNumberGenerator.new()
# Posição global atrasada: a cor persegue o corpo sem nunca alcançá-lo em
# movimento, e só o encontra quando ele para.
var _rastro := Vector3.ZERO
var _atraso := Vector3.ZERO
var _corpo_base := Vector3.ZERO       # lugar da laje antes do arrasto

func _ready() -> void:
	montar_coluna()
	montar_corpo()
	montar_nuvens()
	montar_fagulhas()
	montar_brilho()
	# Escondido, _process sai cedo e o rastro congela; ao reaparecer em outro
	# lugar a cor viria voando do lugar antigo. Reatar ao surgir resolve.
	visibility_changed.connect(func() -> void:
		if visible:
			_rastro = global_position
			_atraso = Vector3.ZERO)
	if str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility":
		push_warning("Mêmesis corpo: FogVolume exige Forward+; aqui o vulto não aparece.")
	hide()

func montar_coluna() -> void:
	var shader: Shader = load("res://shaders/memesis_fog.gdshader")
	if shader == null:
		push_warning("Mêmesis corpo: shader da coluna ausente")
		return
	var coluna := FogVolume.new()
	coluna.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	coluna.size = Vector3(COLUNA_LARGURA, COLUNA_ALTURA, COLUNA_LARGURA)
	coluna.position = Vector3(0.0, COLUNA_ALTURA * 0.5, COLUNA_AVANCO)
	var pele := ShaderMaterial.new()
	pele.shader = shader
	pele.set_shader_parameter("core_density", COLUNA_DENSIDADE)
	pele.set_shader_parameter("core_radius", 0.5)
	pele.set_shader_parameter("caixa", Vector3(COLUNA_LARGURA, COLUNA_ALTURA, COLUNA_LARGURA))
	pele.set_shader_parameter("olhos_raio", COVA_OLHOS)
	coluna.material = pele
	add_child(coluna)
	_coluna = coluna
	_coluna_pele = pele
	# Na altura da cabeça da foto, e adiantados junto com a coluna: atrás da
	# laje eles ficariam encobertos pela própria silhueta.
	var olhar: Node3D = preload("res://scripts/memesis_olhos.gd").new()
	# Na casca da coluna, não no eixo: no centro a névoa preta fica por cima
	# dos pontos de todo ângulo e eles só aparecem de frente.
	# Na altura dos olhos de quem observa, limitada ao que a figura comporta.
	olhar.altura = 1.6
	olhar.altura_min = CORPO_ALTURA * 0.55
	olhar.altura_max = CORPO_ALTURA * 0.95
	# Orbita o eixo da coluna, que está adiantado, e não a origem do vulto:
	# senão o par descreveria um círculo largo em volta da figura inteira.
	olhar.centro = Vector3(0.0, 0.0, COLUNA_AVANCO)
	# Na metade do raio da coluna: colado no miolo, não orbitando longe dela.
	olhar.raio = COLUNA_LARGURA * 0.25
	_olhar = olhar
	add_child(olhar)

func montar_corpo() -> void:
	var shader: Shader = load("res://shaders/memesis_massa.gdshader")
	var foto: Texture2D = load("res://assets/memesis_foto/completo.png")
	if shader == null or foto == null:
		push_warning("Mêmesis corpo: shader ou foto de referência ausente")
		return
	_corpo = FogVolume.new()
	_corpo.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	_corpo.size = Vector3(CORPO_LARGURA, CORPO_ALTURA, CORPO_FUNDO)
	# A caixa é centrada na origem; subir meia altura apoia a figura no piso.
	_corpo_base = Vector3(0.0, CORPO_ALTURA * 0.5, 0.0)
	_corpo.position = _corpo_base
	_massa = ShaderMaterial.new()
	_massa.shader = shader
	_massa.set_shader_parameter("foto", foto)
	# A mesma imagem, lida na CPU: é dela que as nuvens tiram a cor enquanto
	# atravessam a silhueta. Uma amostra por nuvem por quadro não pesa.
	_retrato = foto.get_image()
	# O importador manda a textura comprimida para a VRAM quando ela é usada em
	# 3D, e get_pixel não lê formato comprimido: sem descompactar, a cor das
	# nuvens vira erro a cada quadro.
	if _retrato != null and _retrato.is_compressed():
		_retrato.decompress()
	_massa.set_shader_parameter("densidade", MASSA_DENSIDADE)
	_corpo.material = _massa
	add_child(_corpo)

func montar_nuvens() -> void:
	var shader: Shader = load("res://shaders/memesis_puff.gdshader")
	if shader == null:
		push_warning("Mêmesis corpo: shader das nuvens ausente")
		return
	_nuvem_origem.resize(NUVENS)
	_nuvem_deriva.resize(NUVENS)
	_nuvem_duracao.resize(NUVENS)
	_nuvem_idade.resize(NUVENS)
	for index in NUVENS:
		var nuvem := FogVolume.new()
		nuvem.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
		nuvem.size = Vector3.ONE * NUVEM_TAMANHO
		var pele := ShaderMaterial.new()
		pele.shader = shader
		pele.set_shader_parameter("seed", _rng.randf())
		nuvem.material = pele
		add_child(nuvem)
		_nuvens.append(nuvem)
		# Vida já espalhada no nascimento: as oito em uníssono fariam o vulto
		# piscar em vez de fumegar.
		nascer_nuvem(index, _rng.randf())

func nascer_nuvem(index: int, idade: float) -> void:
	# Sai de um ponto qualquer dentro da silhueta, não de um ponto fixo: a
	# fumaça se desprende da figura inteira, como na referência.
	var angulo := _rng.randf() * TAU
	var lado := Vector3(cos(angulo), 0.0, sin(angulo))
	_nuvem_origem[index] = Vector3(
		_rng.randf_range(-0.42, 0.42) * CORPO_LARGURA * 0.5,
		_rng.randf_range(0.25, 0.92) * CORPO_ALTURA,
		_rng.randf_range(-0.18, 0.18)
	)
	_nuvem_deriva[index] = lado * _rng.randf_range(NUVEM_DERIVA.x, NUVEM_DERIVA.y) 		+ Vector3.UP * _rng.randf_range(NUVEM_SUBIDA.x, NUVEM_SUBIDA.y)
	_nuvem_duracao[index] = _rng.randf_range(NUVEM_VIDA.x, NUVEM_VIDA.y)
	_nuvem_idade[index] = idade * _nuvem_duracao[index]

func montar_fagulhas() -> void:
	var shader: Shader = load("res://shaders/memesis.gdshader")
	if shader == null:
		push_warning("Mêmesis corpo: shader das fagulhas ausente")
		return
	var pele := ShaderMaterial.new()
	pele.shader = shader
	pele.set_shader_parameter("aberration", 0.13)
	pele.set_shader_parameter("fringe_gain", 2.2)
	pele.set_shader_parameter("core_radius", 0.45)

	var faiscas := CPUParticles3D.new()
	faiscas.amount = FAGULHAS
	faiscas.lifetime = 2.6
	faiscas.randomness = 0.9
	faiscas.local_coords = false
	# Caixa, não esfera: as fagulhas precisam cobrir a figura inteira, dos
	# punhos à cabeça, e uma esfera deixaria as pontas de fora.
	faiscas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	faiscas.emission_box_extents = Vector3(CORPO_LARGURA * 0.34, CORPO_ALTURA * 0.40, 0.22)
	faiscas.position = Vector3(0.0, CORPO_ALTURA * 0.55, 0.0)
	faiscas.direction = Vector3.UP
	faiscas.spread = 70.0
	faiscas.gravity = Vector3(0.0, 0.12, 0.0)
	faiscas.initial_velocity_min = 0.05
	faiscas.initial_velocity_max = 0.35
	faiscas.scale_amount_min = 0.03
	faiscas.scale_amount_max = 0.09
	faiscas.scale_amount_curve = curva_sumico()
	faiscas.mesh = QuadMesh.new()
	faiscas.material_override = pele
	faiscas.layers = OLHO_NU | CCTV_LAYER
	add_child(faiscas)

func curva_sumico() -> Curve:
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.15))
	curva.add_point(Vector2(0.35, 1.0))
	curva.add_point(Vector2(1.0, 0.0))
	return curva

func montar_brilho() -> void:
	# A emissão das nuvens acende a névoa, mas não alcança parede nem chão; sem
	# esta luz o vulto não marcaria presença nenhuma na sala.
	_brilho = OmniLight3D.new()
	_brilho.position = Vector3(0.0, 1.10, 0.0)
	_brilho.light_energy = 0.42
	_brilho.omni_range = 3.2
	_brilho.shadow_enabled = false
	add_child(_brilho)

func _process(delta: float) -> void:
	if not visible:
		return
	seguir_ambiente()
	cavar_para_olhos()
	arrastar(delta)
	mover_nuvens(delta)
	encarar_camera()

## A inércia da cor. O rastro é uma posição global que persegue o corpo com
## atraso; enquanto o vulto anda, ela fica para trás, e quando ele para, ela
## chega depois — é a chegada atrasada que vende o peso da coisa.
func arrastar(delta: float) -> void:
	_rastro = _rastro.lerp(global_position, clampf(ARRASTO * delta, 0.0, 1.0))
	var sobra := _rastro - global_position
	if sobra.length() > ARRASTO_MAX:
		sobra = sobra.normalized() * ARRASTO_MAX
		_rastro = global_position + sobra
	# Convertido para o referencial do vulto, que gira: em global, o atraso
	# giraria junto com a figura e a cor orbitaria em vez de ficar para trás.
	_atraso = global_transform.basis.inverse() * sobra
	# A laje da foto arrasta junto com as nuvens. Quem fica parado é a coluna
	# preta e os olhos: é o contraste entre o miolo firme e a fumaça atrasada
	# que deixa o atraso legível — se tudo arrastasse junto, o vulto só pareceria
	# estar num lugar diferente.
	if _corpo != null:
		_corpo.position = _corpo_base + _atraso

## A névoa abre uma cova em volta dos olhos, que se movem a cada quadro. Sem
## isto os pontos ficam enterrados no preto denso e somem da tela.
func cavar_para_olhos() -> void:
	if _coluna_pele == null or _olhar == null or _coluna == null:
		return
	# Em metros, relativo ao centro da caixa da névoa, que é o que o shader usa.
	_coluna_pele.set_shader_parameter("olhos_local", _olhar.position - _coluna.position)

func seguir_ambiente() -> void:
	var mundo := get_viewport().find_world_3d()
	if mundo == null or mundo.environment == null:
		return
	var cor: Color = mundo.environment.ambient_light_color
	# Só o matiz interessa; o brilho entra separado, senão a energia baixa da
	# sala apagaria a franja antes de ela aparecer.
	var pico: float = maxf(cor.r, maxf(cor.g, cor.b))
	if pico > 0.001:
		cor = Color(cor.r / pico, cor.g / pico, cor.b / pico)
	_ambiente_tint = Vector3(cor.r, cor.g, cor.b)
	_ambiente_level = mundo.environment.ambient_light_energy
	if _massa != null:
		_massa.set_shader_parameter("ambient_tint", _ambiente_tint)
		_massa.set_shader_parameter("ambient_level", _ambiente_level)
	if _brilho != null:
		_brilho.light_color = cor

func mover_nuvens(delta: float) -> void:
	for index in _nuvens.size():
		_nuvem_idade[index] += delta
		if _nuvem_idade[index] >= _nuvem_duracao[index]:
			nascer_nuvem(index, 0.0)
		var vida: float = _nuvem_idade[index] / _nuvem_duracao[index]
		var nuvem: FogVolume = _nuvens[index]
		nuvem.position = _nuvem_origem[index] + _nuvem_deriva[index] * _nuvem_idade[index] + _atraso
		# Incha enquanto se afasta: fumaça que sobe sem se abrir lê como bolha.
		nuvem.size = Vector3.ONE * NUVEM_TAMANHO * (0.5 + vida)
		var pele: ShaderMaterial = nuvem.material
		pele.set_shader_parameter("life", vida)
		pele.set_shader_parameter("ambient_tint", _ambiente_tint)
		pele.set_shader_parameter("ambient_level", _ambiente_level)
		pele.set_shader_parameter("smoke_color", cor_da_silhueta(nuvem.position))

## A cor da foto no ponto onde a nuvem está. Enquanto ela sobe e se afasta, vai
## passando por partes diferentes da silhueta e mudando de cor junto — é a
## imagem que manda, não uma paleta inventada.
func cor_da_silhueta(ponto: Vector3) -> Vector3:
	if _retrato == null:
		return Vector3(0.82, 0.85, 0.90)
	var u := ponto.x / CORPO_LARGURA + 0.5
	var v := 1.0 - ponto.y / CORPO_ALTURA
	# Fora da moldura não há foto para ler: a nuvem volta ao branco frio.
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return Vector3(0.82, 0.85, 0.90)
	var x := clampi(int(u * float(_retrato.get_width())), 0, _retrato.get_width() - 1)
	var y := clampi(int(v * float(_retrato.get_height())), 0, _retrato.get_height() - 1)
	var cor := _retrato.get_pixel(x, y)
	# Mistura em vez de degrau: o miolo da foto é escuro, e um corte seco faria
	# a nuvem saltar para o branco ao cruzar a massa preta em vez de ir mudando.
	# Névoa preta também seria invisível, então o escuro puxa para o branco frio
	# e só o que é claro na foto empresta a própria cor.
	var pico: float = maxf(cor.r, maxf(cor.g, cor.b))
	var peso: float = clampf(pico / 0.55, 0.0, 1.0)
	var frio := Vector3(0.82, 0.85, 0.90)
	return frio.lerp(Vector3(cor.r, cor.g, cor.b), peso)

## Invocação de teste (F5 em main.gd): planta o vulto na frente de quem olha.
func chamar_para_frente(eye: Camera3D) -> void:
	if eye == null:
		return
	var frente := -eye.global_transform.basis.z
	frente.y = 0.0
	if frente.length_squared() < 0.0001:
		frente = Vector3.FORWARD
	global_position = eye.global_position + frente.normalized() * DISTANCIA_TESTE
	global_position.y = 0.0
	# Zera o rastro no teleporte: sem isto a cor viria voando do lugar antigo.
	_rastro = global_position
	_atraso = Vector3.ZERO
	show()

func encarar_camera() -> void:
	# A pose tem frente: de lado a silhueta some, porque os elipsoides estão
	# arranjados para serem lidos de frente, como a foto.
	var olho := get_viewport().get_camera_3d()
	if olho == null:
		return
	var rumo := olho.global_position - global_position
	rumo.y = 0.0
	if rumo.length_squared() < 0.0001:
		return
	global_rotation.y = atan2(rumo.x, rumo.z)
