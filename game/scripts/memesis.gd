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
# Miolo denso e estreito: a fumaça fica opaca no eixo e o vazamento para fora
# vira só um halo. Com o raio grande do shader a coluna lia como poste de névoa.
const NUCLEO_DENSIDADE := 6.0
const NUCLEO_RAIO := 0.16
const BORDA_RAIO := 0.46
const FAISCAS := 46                   # partículas de aberração saindo do miolo
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
var _faiscas: CPUParticles3D
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
	haze.set_shader_parameter("edge_radius", BORDA_RAIO)
	_coluna.material = haze
	add_child(_coluna)
	add_faiscas()
	if str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility":
		push_warning("Mêmesis: FogVolume exige Forward+; em gl_compatibility o vulto não aparece.")
	if RONDA_TESTE:
		position = Vector3(RONDA[0].x, 0.0, RONDA[0].y)
		show()

func _process(delta: float) -> void:
	if RONDA_TESTE:
		rondar(delta)

## Fagulhas que escapam do miolo, cada uma com a aberração cromática do sopro.
## Reaproveita shaders/memesis.gdshader, que já faz exatamente isso e tinha
## ficado órfão quando o corpo virou névoa.
func add_faiscas() -> void:
	var shader: Shader = load("res://shaders/memesis.gdshader")
	if shader == null:
		push_warning("Mêmesis: shader das fagulhas ausente")
		return
	var skin := ShaderMaterial.new()
	skin.shader = shader
	# A franja precisa ser mais larga que a do corpo antigo: aqui cada fagulha
	# aparece sozinha no ar, sem dezenas de irmãs empilhadas para somar cor.
	skin.set_shader_parameter("aberration", 0.14)
	skin.set_shader_parameter("fringe_gain", 2.4)
	skin.set_shader_parameter("core_radius", 0.45)

	_faiscas = CPUParticles3D.new()
	_faiscas.amount = FAISCAS
	_faiscas.lifetime = 2.2
	_faiscas.randomness = 0.85
	_faiscas.local_coords = false
	_faiscas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	# Nascem no eixo, não na casca: é do miolo denso que elas escapam.
	_faiscas.emission_sphere_radius = NUCLEO_RAIO
	_faiscas.position = Vector3(0.0, ALTURA * 0.45, 0.0)
	_faiscas.direction = Vector3.UP
	_faiscas.spread = 55.0
	_faiscas.gravity = Vector3(0.0, 0.18, 0.0)
	_faiscas.initial_velocity_min = 0.10
	_faiscas.initial_velocity_max = 0.45
	_faiscas.scale_amount_min = 0.05
	_faiscas.scale_amount_max = 0.14
	# Somem antes de chegar longe: fagulha que persiste vira confete.
	_faiscas.scale_amount_curve = fade_curve()
	_faiscas.mesh = QuadMesh.new()
	_faiscas.material_override = skin
	_faiscas.layers = OLHO_NU | CCTV_LAYER
	add_child(_faiscas)

func fade_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.2))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

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
