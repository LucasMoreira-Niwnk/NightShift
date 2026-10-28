extends Node3D

## ==============================================================================
## NIGHTSHIFT — MÊMESIS (coluna de névoa que anda pelo mapa)
## ==============================================================================
## RELACIONADOS:
##   - shaders/memesis_fog.gdshader (o corpo: um cilindro de fumaça)
##   - memesis_puffs.gd (versão anterior, por partículas — mantida para consulta)
##   - chapter_world.gd (cria como `figure`, e liga a névoa volumétrica)
##   - chapter.gd (posiciona e revela o vulto por etapa)
## OBJETIVO DO AGENTE:
##   O corpo não é malha nem sprite: é um FogVolume. O vulto existe como uma
##   densidade no ar, então nunca tem contorno fechado nem lado de trás — lê
##   igual de qualquer ângulo e não precisa de billboard.
## AVISO DE COMPATIBILIDADE:
##   FogVolume só desenha no renderizador Forward+, e só com
##   volumetric_fog_enabled no Environment (ligado em chapter_world.gd). O
##   projeto migrou para Forward+, mas o preset mobile segue em
##   gl_compatibility: lá o vulto é invisível, e o aviso abaixo existe para
##   dizer isso em vez de deixar procurando o bug.
## ==============================================================================

## ---------------------------------------------------------------------------
## RONDA DE TESTE — não faz parte do jogo
## ---------------------------------------------------------------------------
## Com RONDA_TESTE ligado o vulto anda sozinho pelo mapa, para dar pra conferir
## o efeito em movimento sem jogar o capítulo inteiro. Desligue antes de valer:
## com `false` este script volta a obedecer só o chapter.gd, que é quem
## posiciona e revela o vulto por etapa.
##
## Fica desligado por padrão porque a ronda briga com o F3: ela arrasta o vulto
## de volta para a rota no quadro seguinte à invocação.
const RONDA_TESTE := false
const DISTANCIA_TESTE := 2.4          # metros à frente do jogador, no F3

const ALTURA := 2.2                   # altura da coluna em metros
const LARGURA := 1.0                  # diâmetro da caixa que contém o cilindro
# O preto vai até o diâmetro cheio da caixa: 1 m, sem halo cinza em volta.
const NUCLEO_DENSIDADE := 9.0
const NUCLEO_RAIO := 0.5
# Raio da cavidade que a névoa abre em volta dos olhos, em metros. Precisa
# passar da meia-largura do par (0,30 m), senão a névoa come as pontas.
const COVA_OLHOS := 0.46
const PASSO := 0.85                   # metros por segundo da ronda
const ESPERA := 1.4                   # segundos parado em cada ponto

# Pontos no piso, seguindo o corredor e entrando em cada sala. São à mão porque
# o mapa não tem NavigationRegion: construir um navmesh só para a ronda de
# teste custaria mais que a lista.
const RONDA := [
	Vector2(0, 2), Vector2(-2, 1), Vector2(-5, 1), Vector2(-2, 1),
	Vector2(0, -5), Vector2(2, -5), Vector2(5, -6), Vector2(2, -5),
	Vector2(0, -10), Vector2(-2, -10), Vector2(-5, -10), Vector2(-2, -10),
	Vector2(0, -15), Vector2(0, -18), Vector2(0, -15),
	Vector2(0, -5), Vector2(0, 6),
]

const CCTV_LAYER := 4                 # camada que só a câmera de segurança vê
const OLHO_NU := 1                    # camada que a câmera do jogador vê

var _coluna: FogVolume
var _haze: ShaderMaterial
var _brilho: OmniLight3D
var _olhar: Node3D
var _ambiente_tint := Vector3.ZERO
var _ambiente_level := 0.0
var _alvo := 0
var _parado := 0.0

func _ready() -> void:
	var shader: Shader = load("res://shaders/memesis_fog.gdshader")
	if shader == null:
		push_warning("Mêmesis: shader da névoa ausente")
		return
	_coluna = FogVolume.new()
	_coluna.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	_coluna.size = Vector3(LARGURA, ALTURA, LARGURA)
	# O FogVolume é centrado na própria origem; subir meia altura apoia a
	# coluna no piso em vez de deixar metade enterrada.
	_coluna.position = Vector3(0.0, ALTURA * 0.5, 0.0)
	var haze := ShaderMaterial.new()
	haze.shader = shader
	haze.set_shader_parameter("core_density", NUCLEO_DENSIDADE)
	haze.set_shader_parameter("core_radius", NUCLEO_RAIO)
	haze.set_shader_parameter("caixa", Vector3(LARGURA, ALTURA, LARGURA))
	haze.set_shader_parameter("olhos_raio", COVA_OLHOS)
	_haze = haze
	_coluna.material = haze
	add_child(_coluna)
	add_olhos()
	add_brilho()
	if str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility":
		push_warning("Mêmesis: FogVolume exige Forward+; em gl_compatibility o vulto não aparece.")
	if RONDA_TESTE:
		position = Vector3(RONDA[0].x, 0.0, RONDA[0].y)
		show()

func _process(delta: float) -> void:
	seguir_ambiente()
	cavar_para_olhos()
	if RONDA_TESTE:
		rondar(delta)

## A franja do halo é tingida pela luz ambiente da sala, então o vulto puxa a
## cor do lugar onde está. Lido todo quadro de propósito: o capítulo troca a
## iluminação por etapa, e assim o Mêmesis acompanha sem ninguém avisar.
func seguir_ambiente() -> void:
	if _haze == null:
		return
	# O Environment nasce depois do vulto em chapter_world._ready, então não dá
	# para capturá-lo uma vez no _ready: aqui ele já existe.
	var mundo := get_viewport().find_world_3d()
	if mundo == null or mundo.environment == null:
		return
	var ambiente: Environment = mundo.environment
	var cor := ambiente.ambient_light_color
	# Só o matiz interessa; o brilho entra separado, senão a energia de 0.04 da
	# sala apagaria a franja inteira antes de ela aparecer.
	var pico: float = maxf(cor.r, maxf(cor.g, cor.b))
	if pico > 0.001:
		cor = Color(cor.r / pico, cor.g / pico, cor.b / pico)
	_ambiente_tint = Vector3(cor.r, cor.g, cor.b)
	_ambiente_level = ambiente.ambient_light_energy
	_haze.set_shader_parameter("ambient_tint", _ambiente_tint)
	_haze.set_shader_parameter("ambient_level", _ambiente_level)
	if _brilho != null:
		# A luz segue o mesmo matiz da franja: o que o vulto joga na parede é a
		# cor que ele roubou da sala, não uma segunda cor concorrendo com ela.
		_brilho.light_color = cor

## Os dois pontos vermelhos, na altura da cabeça. Ficam dentro da névoa, e é só
## isso que dá direção ao vulto: o resto do corpo lê igual de qualquer ângulo.
func add_olhos() -> void:
	var olhar: Node3D = preload("res://scripts/memesis_olhos.gd").new()
	# Na casca da coluna, não no eixo: no centro a névoa preta fica por cima
	# dos pontos e eles mal aparecem.
	# Na altura dos olhos de quem observa, limitada ao que a coluna comporta.
	olhar.altura = 1.6
	olhar.altura_min = ALTURA * 0.50
	olhar.altura_max = ALTURA * 0.90
	# Na metade do raio da coluna: colado no miolo, não orbitando longe dela.
	# Afastado, na câmera o olho entrava em quadro sozinho e o pilar ficava
	# para trás, como se fossem duas coisas.
	olhar.raio = LARGURA * 0.25
	_olhar = olhar
	add_child(olhar)

## A névoa abre uma cova em volta dos olhos, que se movem a cada quadro. Sem
## isto os pontos ficam enterrados no preto denso e somem da tela.
func cavar_para_olhos() -> void:
	if _haze == null or _olhar == null or _coluna == null:
		return
	# Em metros, relativo ao centro da caixa da névoa, que é o que o shader usa.
	_haze.set_shader_parameter("olhos_local", _olhar.position - _coluna.position)

## Névoa preta não devolve luz nenhuma; sem esta lâmpada fraca o vulto não
## marcaria presença alguma na parede nem no chão.
func add_brilho() -> void:
	_brilho = OmniLight3D.new()
	_brilho.position = Vector3(0.0, ALTURA * 0.45, 0.0)
	_brilho.light_energy = 0.38
	_brilho.omni_range = 2.8
	# Sem sombra de propósito: o vulto não tem corpo sólido para projetar, e a
	# sombra de uma luz dentro da névoa só criaria listras no chão.
	_brilho.shadow_enabled = false
	add_child(_brilho)

## Invocação de teste (F3 em main.gd): planta o vulto na frente de quem olha.
func chamar_para_frente(eye: Camera3D) -> void:
	if eye == null:
		return
	var ahead := -eye.global_transform.basis.z
	# Só a direção no plano importa: olhando para o chão ou para o teto, o vulto
	# ainda tem que nascer em pé no piso, não enterrado nem flutuando.
	ahead.y = 0.0
	if ahead.length_squared() < 0.0001:
		ahead = Vector3.FORWARD
	global_position = eye.global_position + ahead.normalized() * DISTANCIA_TESTE
	global_position.y = 0.0
	show()

func rondar(delta: float) -> void:
	# chapter.gd esconde o vulto a cada refresh (`visible = stage == 5`), então a
	# ronda precisa reafirmar isso todo quadro ou some no primeiro save/load.
	visible = true
	if _parado > 0.0:
		_parado -= delta
		return
	var alvo := Vector3(RONDA[_alvo].x, 0.0, RONDA[_alvo].y)
	position = position.move_toward(alvo, PASSO * delta)
	if position.distance_to(alvo) < 0.02:
		# Pausa em cada ponto: o vulto hesita antes de virar, em vez de deslizar
		# em curva contínua como um carrinho de trilho.
		_parado = ESPERA
		_alvo = (_alvo + 1) % RONDA.size()
