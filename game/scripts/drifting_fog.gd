extends Node3D
## ============================================================================
## NIGHTSHIFT — NÉVOA FLUTUANTE
## ============================================================================
## FAMÍLIA: Ambiente (res://scripts/drifting_fog.gd)
## QUEM CRIA: chapter_world.gd, depois do WorldEnvironment.
## OBJETIVO DO AGENTE:
##   Pequenas bolhas de névoa que vagam perto do jogador para dar clima. Cada
##   uma nasce num anel de 2..RAIO m ao redor dele, deriva devagar, e renasce
##   noutro ponto quando a vida acaba ou quando o jogador se afasta. Densidade
##   e tamanho sorteados baixos: é atmosfera, não fumaça.
## AVISO: FogVolume só desenha em Forward+ com volumetric_fog_enabled.
## ============================================================================

const QUANTIDADE := 10
const RAIO := 10.0
const RAIO_MIN := 2.0
# Além disto a bolha já está fora do alcance visível: renasce em vez de seguir.
const RAIO_DESCARTE := 12.0
const ALTURA := Vector2(0.4, 2.4)
const TAMANHO := Vector2(1.8, 4.2)
const DENSIDADE := Vector2(0.5, 1.2)
const VIDA := Vector2(8.0, 18.0)
const DERIVA := 0.12

# O jogador nasce depois do mundo em main.gd, então o alvo é resolvido no
# primeiro quadro a partir de `game` em vez de guardado no _ready.
var game: Node
var alvo: Node3D

var _bolhas: Array[FogVolume] = []
var _deriva: Array[Vector3] = []
var _vida: Array[float] = []
var _idade: Array[float] = []
var _densidade: Array[float] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	for i in QUANTIDADE:
		var bolha := FogVolume.new()
		bolha.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		var massa := FogMaterial.new()
		massa.albedo = Color(0.62, 0.70, 0.78)
		massa.emission = Color.BLACK
		# No maximo: a borda se dissolve ao longo de quase todo o elipsoide, que
		# e o que apaga o contorno de bolha. Por isso as bolhas sao largas e
		# ralas — com raio pequeno o degrade nao tem espaco para acontecer.
		massa.edge_fade = 1.0
		bolha.material = massa
		add_child(bolha)
		_bolhas.append(bolha)
		_deriva.append(Vector3.ZERO)
		_vida.append(1.0)
		_idade.append(0.0)
		_densidade.append(0.0)
		_renascer(i, true)

func _process(delta: float) -> void:
	var centro := _centro()
	for i in _bolhas.size():
		var bolha := _bolhas[i]
		_idade[i] += delta
		bolha.position += _deriva[i] * delta
		var fora := bolha.position.distance_to(centro) > RAIO_DESCARTE
		if fora or _idade[i] >= _vida[i]:
			_renascer(i, false)
			continue
		# Entra e sai por fade: sem isto a bolha pisca ao renascer.
		var fase: float = clampf(_idade[i] / _vida[i], 0.0, 1.0)
		var janela := sin(fase * PI)
		(bolha.material as FogMaterial).density = _densidade[i] * janela

func _centro() -> Vector3:
	if alvo == null and game != null:
		alvo = game.player
	if alvo != null and alvo.is_inside_tree():
		return alvo.global_position
	return global_position

func _renascer(i: int, inicial: bool) -> void:
	var centro := _centro()
	var angulo := _rng.randf_range(0.0, TAU)
	var distancia := _rng.randf_range(RAIO_MIN, RAIO)
	var lado := _rng.randf_range(TAMANHO.x, TAMANHO.y)
	_bolhas[i].size = Vector3(lado, lado * 0.6, lado)
	_bolhas[i].position = centro + Vector3(cos(angulo) * distancia, _rng.randf_range(ALTURA.x, ALTURA.y), sin(angulo) * distancia)
	_deriva[i] = Vector3(_rng.randf_range(-DERIVA, DERIVA), _rng.randf_range(-DERIVA, DERIVA) * 0.3, _rng.randf_range(-DERIVA, DERIVA))
	_vida[i] = _rng.randf_range(VIDA.x, VIDA.y)
	# Espalha as idades na largada, senão as dez bolhas pulsam em uníssono.
	_idade[i] = _rng.randf_range(0.0, _vida[i]) if inicial else 0.0
	_densidade[i] = _rng.randf_range(DENSIDADE.x, DENSIDADE.y)
