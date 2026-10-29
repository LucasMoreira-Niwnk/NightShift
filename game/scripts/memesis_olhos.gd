extends Node3D

## ==============================================================================
## NIGHTSHIFT — O OLHAR DO MÊMESIS
## ==============================================================================
## RELACIONADOS:
##   - shaders/memesis_olhos.gdshader (a brasa de cada ponto)
##   - memesis.gd (coluna, F3), memesis_corpo.gd (coluna + foto, F5)
## OBJETIVO DO AGENTE:
##   Dois pontos vermelhos dentro da névoa. São a única parte do vulto que tem
##   direção — o corpo é uma densidade sem frente nem costas, e é o olhar que
##   diz que a coisa sabe onde você está.
##   Dois níveis de rotação, e os dois são necessários: este nó gira no eixo Y
##   para o PAR ficar lado a lado seja qual for o ângulo, e o shader faz o
##   billboard de CADA ponto para nenhum deles aparecer de perfil. Só o nó
##   deixaria os quads tortos; só o shader deixaria o par enfileirado quando
##   visto de lado, parecendo um olho só.
## ==============================================================================

## O par orbita o eixo do vulto em vez de ficar num ponto fixo: a coluna é um
## cilindro e não gira, então um offset fixo deixaria os olhos parados de um
## lado só, encobertos pela névoa para quem chegasse por trás.
var raio := 0.54                      # distância do eixo, em metros
var altura := 1.6                     # altura corrente dos olhos, em metros
var altura_min := 1.15                # até onde eles descem
var altura_max := 1.95                # até onde eles sobem
var centro := Vector3.ZERO            # eixo que o par orbita, em local do pai

const SUBIDA := 2.4                   # m/s com que os olhos acompanham a altura

var _vigia: Node = null               # o computador de segurança, quando existe
var _procurou := false

# Afastados junto com o tamanho: triplicar só o quad faria os dois se fundirem
# num borrão só, que é de onde viemos.
const SEPARACAO := 0.34               # distância entre os dois olhos, em metros
const TAMANHO := 0.255                # lado do quad de cada olho, em metros
const CCTV_LAYER := 4
const OLHO_NU := 1

func _ready() -> void:
	var shader: Shader = load("res://shaders/memesis_olhos.gdshader")
	if shader == null:
		push_warning("Mêmesis: shader dos olhos ausente")
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(TAMANHO, TAMANHO)
	for lado in [-1.0, 1.0]:
		add_child(montar_olho(quad, shader, lado))

func montar_olho(quad: QuadMesh, shader: Shader, lado: float) -> MeshInstance3D:
	var olho := MeshInstance3D.new()
	olho.mesh = quad
	olho.position = Vector3(SEPARACAO * 0.5 * lado, 0.0, 0.0)
	olho.layers = OLHO_NU | CCTV_LAYER
	# A névoa não ocluiria o ponto, mas o quad do irmão sim; sem isto os dois
	# brigam pela ordem de desenho quando vistos quase de perfil.
	olho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pele := ShaderMaterial.new()
	pele.shader = shader
	# Sementes diferentes: com a mesma, os dois tremem juntos e piscam como um
	# par de LEDs sincronizados.
	pele.set_shader_parameter("seed", 0.0 if lado < 0.0 else 0.37)
	olho.material_override = pele
	return olho

## Quem o vulto encara. Se o jogador está no monitor, é a câmera de segurança
## que ele usa — olhar para o corpo dele, parado na sala, deixaria o vulto de
## lado justamente na imagem que o jogador está vendo.
func observador() -> Camera3D:
	if not _procurou:
		# Uma busca só, guardada: o nó se nomeia em computer.gd, e varrer a
		# árvore todo quadro para achá-lo seria desperdício.
		_procurou = true
		_vigia = get_tree().root.find_child("SecurityComputer", true, false)
	if is_instance_valid(_vigia) and _vigia.get("active") and _vigia.get("security_camera") != null:
		return _vigia.security_camera
	return get_viewport().get_camera_3d()

func _process(delta: float) -> void:
	var eye := observador()
	if eye == null:
		return
	var pai := get_parent_node_3d()
	if pai == null:
		return
	# Em local do pai, não em global: o vulto da foto gira para encarar a
	# câmera, e uma direção global entraria em conta duas vezes, fazendo o par
	# orbitar o dobro do ângulo.
	var rumo := pai.to_local(eye.global_position) - centro
	rumo.y = 0.0
	# Em cima do eixo o vetor zera e a direção fica indefinida; nesse quadro o
	# par simplesmente mantém onde estava.
	if rumo.length_squared() < 0.0001:
		return
	# Na altura dos olhos de quem observa, dentro do que o corpo comporta: a
	# câmera de segurança fica alta, e sem o limite os pontos subiriam para
	# fora do vulto e flutuariam soltos no ar.
	var mira := clampf(pai.to_local(eye.global_position).y, altura_min, altura_max)
	# Sobe e desce devagar: ao trocar entre o jogador e o monitor, um salto
	# entregaria o truque.
	altura = move_toward(altura, mira, SUBIDA * delta)

	rumo = rumo.normalized()
	# Sai pela casca do vulto, do lado de quem olha, e encara de volta.
	position = centro + rumo * raio + Vector3.UP * altura
	rotation.y = atan2(rumo.x, rumo.z)
