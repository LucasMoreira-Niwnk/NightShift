extends Node3D

## ==============================================================================
## NIGHTSHIFT — MÊMESIS DE MALHA (quarto vulto, teste de caminhada)
## ==============================================================================
## RELACIONADOS:
##   - assets/models/criatura.glb (a malha, exportada por tools/webgpu-fog)
##   - memesis.gd (coluna de névoa, F3), memesis_corpo.gd (a foto em volume)
##   - main.gd (lista do F5), chapter_world.gd (cria os quatro)
## OBJETIVO DO AGENTE:
##   Os outros três vultos são névoa calculada em tempo real e não têm corpo:
##   não dá para fazê-los andar, só deslizar. Este é o caminho oposto — uma
##   malha de verdade, com Skeleton3D e o ciclo de caminhada dentro do próprio
##   .glb. Serve para medir se vale trocar névoa volumétrica por malha animada
##   antes de decidir como o Mêmesis se move pelo prédio.
##   Limitação honesta: a malha nasce de um desenho de frente, então o perfil
##   lateral é um palpite inflado — de lado ela engorda.

const CAMINHO := "res://assets/models/criatura.glb"

## O .glb sai com 1 metro de altura; o vulto precisa olhar o jogador de cima.
const ALTURA := 2.3
const VELOCIDADE := 1.05               # m/s, passo arrastado
const CHEGOU := 0.25                   # metros; perto disto, troca de destino
const GIRO := 2.5                      # rad/s ao virar para o próximo ponto

## Ronda pelo térreo: corredor, segurança, arquivo e sala técnica, pelas portas.
## Entra nas salas em vez de só percorrer o corredor, senão não dá para ver o
## vulto cruzando um vão — que é justamente o que este teste quer mostrar.
const RONDA: Array[Vector3] = [
	Vector3(0, 0, 4),        # boca do corredor, vindo da recepção
	Vector3(0, 0, 1),        # porta da segurança
	Vector3(-5, 0, 1),       # dentro da segurança
	Vector3(0, 0, 1),
	Vector3(0, 0, -5),       # porta do arquivo
	Vector3(5, 0, -6),       # dentro do arquivo
	Vector3(0, 0, -5),
	Vector3(0, 0, -10),      # porta da sala técnica
	Vector3(-5, 0, -10),     # dentro da sala técnica
	Vector3(0, 0, -10),
]

var corpo: Node3D = null
var tocador: AnimationPlayer = null
var rondando := false
var _destino := 0

func _ready() -> void:
	var cena := load(CAMINHO) as PackedScene
	if cena == null:
		push_warning("memesis_malha: %s não encontrado; o vulto de malha fica fora." % CAMINHO)
		return
	corpo = cena.instantiate()
	corpo.scale = Vector3.ONE * ALTURA
	corpo.position.y = ALTURA * 0.5     # o .glb tem origem no centro, não nos pés
	add_child(corpo)
	tocador = corpo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if tocador != null and tocador.has_animation("andar"):
		# O glTF não carrega o laço; sem isto o ciclo toca uma vez e congela.
		tocador.get_animation("andar").loop_mode = Animation.LOOP_LINEAR
	hide()

func _process(delta: float) -> void:
	if not rondando or corpo == null or not visible:
		return
	var alvo: Vector3 = RONDA[_destino]
	var rumo := alvo - global_position
	rumo.y = 0.0
	if rumo.length() < CHEGOU:
		_destino = (_destino + 1) % RONDA.size()
		return
	global_position += rumo.normalized() * VELOCIDADE * delta
	# A frente da malha é -Z, igual à do Godot, então basta girar para o rumo.
	var desejado := atan2(-rumo.x, -rumo.z)
	global_rotation.y = lerp_angle(global_rotation.y, desejado, delta * GIRO)

## Teste de arte: planta o vulto na frente de quem olha, parado.
func chamar_para_frente(olho: Camera3D) -> void:
	if olho == null or corpo == null:
		return
	var frente := -olho.global_transform.basis.z
	frente.y = 0.0
	if frente.length_squared() < 0.0001:
		frente = Vector3.FORWARD
	global_position = olho.global_position + frente.normalized() * 2.8
	global_position.y = 0.0
	look_at(Vector3(olho.global_position.x, global_position.y, olho.global_position.z))
	rondando = false
	_parar_passos()
	show()

## O teste que interessa: andando de sala em sala, com o ciclo tocando.
func rondar() -> void:
	if corpo == null:
		return
	_destino = 0
	global_position = RONDA[0]
	rondando = true
	if tocador != null and tocador.has_animation("andar"):
		tocador.play("andar")
	show()

func parar() -> void:
	rondando = false
	_parar_passos()
	hide()

func _parar_passos() -> void:
	if tocador != null and tocador.is_playing():
		tocador.stop()
