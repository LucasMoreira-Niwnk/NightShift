extends Node
## ============================================================================
## NIGHTSHIFT — QUALIDADE DE LUZ (oclusão de lâmpadas)
## ============================================================================
## FAMÍLIA: Render (res://scripts/light_culling.gd)
## QUEM CRIA: chapter_world.gd, depois de montar os dois andares.
## OBJETIVO DO AGENTE:
##   O prédio tem 28 lâmpadas com sombra e 4400 malhas; cada lâmpada visível
##   custa uma passada de sombra, e o SubViewport do CCTV paga a conta de novo.
##   Aqui cada lâmpada ganha uma caixa do volume que ela realmente ilumina,
##   recortada nas paredes uma vez só. A cada quadro, uma fatia das lâmpadas é
##   reavaliada: se nenhum canto do volume estiver no quadro E sem parede no
##   caminho, a lâmpada para de iluminar e de projetar sombra.
## AVISO: não mexe em `visible`. Quem decide se a lâmpada está acesa é o
##   capítulo (ritmo do corredor, blecaute, energia) — este nó só desliga a
##   contribuição de quem ninguém está vendo.
## ============================================================================

# Testar a caixa no frustum não adianta nada (medido: 20,1 -> 20,0 fps): num
# prédio quase toda lâmpada está dentro do campo de visão, atrás de uma parede.
# O que paga é o raio. A caixa serve para o raio ter o que mirar além do centro
# da lâmpada: assim o facho que escapa por uma porta aberta mantém a luz acesa.

# Lâmpadas revistas por quadro. 28 lâmpadas = ciclo completo a cada 4 quadros.
const SLICE := 7
# Quadros de tolerância antes de apagar: evita piscar ao cruzar uma porta.
const GRACE := 2
const FULL_MASK := 0xFFFFF
# Alem disto a lampada continua acesa, mas para de projetar sombra: a sombra de
# um poste a 20 m nao se le e custa uma passada inteira sobre o cenario. Medido
# na entrada olhando a rua: 67,7 -> 80,0 fps. Apagar a luz distante em vez da
# sombra nao rendeu nada e escureceria a rua, entao nao se faz.
var shadow_range := 14.0
const CCTV_ONLY := 4
# O frustum sozinho e estreito demais para luz: uma lampada logo fora do canto
# da tela ainda ilumina o que esta na tela, e apagava. O teste aceita um cone
# mais largo que o campo de visao.
var extra_angulo := 40.0
# Alcance de desenho dos objetos pequenos. Parede, piso, escada e luminaria
# nao entram: so o que e miudo o bastante para nao fazer falta de longe. Vale
# tambem para a escadaria, onde as paredes e as luzes ficam e os objetos so
# aparecem de perto. O motor corta por distancia sozinho, sem custo por quadro.
# Medido no mundo, nao na malha: o modelo importado vem com a escala no no, e
# um arbusto de 0,33 m em cena tem 2,63 m de malha. Media errado, ficava de
# fora. O limiar tambem subiu: o extintor da 0,80 m e caia bem na borda.
const PROP_MAX := 1.2
var prop_range := 14.0: set = set_prop_range
const PROP_FADE := 2.0

var game: Node
var enabled := true: set = set_enabled
# Sombra do cenario. Desligada (o padrao), so personagens, portas e objetos da
# historia projetam: dobra o FPS e achata a cena. A classificacao vem do mesmo lugar que escreve
# docs/shadow-map.md, para o menu e o mapa nunca discordarem.
var static_shadows := false: set = set_static_shadows
var static_meshes: Array = []
# Vidros do predio. Servem de gatilho para o exterior: sem nenhum no campo de
# visao, a fachada e o estacionamento nao tem como aparecer, e sao 4000 draw
# calls. Medido no corredor do 2o andar olhando para a entrada: 71 -> 200 fps.
var panes: Array = []
# Distancia abaixo da qual uma vidraca conta mesmo fora do campo de visao.
const PERTO_DO_VIDRO := 3.0
# O cenario termina de nascer depois das preferencias serem aplicadas: no
# arranque a lista pegava 2796 das 3737 malhas e deixava metade do ganho na
# mesa. Por isso a revisita nos primeiros segundos. Depois disso so o menu
# remonta a lista: varrer 4400 malhas nao e coisa de fazer em laco.
const REFRESH_AT := [30, 120, 300]
var ticks := 0

var lamps: Array = []
var volumes: Array = []
var grace: Array = []
# Camada original de cada lampada. Uma lampada que so o CCTV enxerga vai para a
# camada do CCTV: continua alimentando a CAM-04 e para de iluminar o jogador.
# Sem isto, 22 lampadas ficavam acesas por causa da camera de seguranca e
# atravessavam parede na vista do jogador, com a sombra do cenario desligada.
var base_layers: Array = []
# Sombra como o cenario autorou. O corte por distancia so pode TIRAR sombra de
# quem tinha; nunca dar sombra a quem foi feito sem ela.
var base_shadow: Array = []
# Porta aberta abre a sala: enquanto estiver aberta, o alcance dos objetos do
# outro lado nao vale, senao o movel some justamente quando se olha de fora.
const VAO_RAIO := 9.0
# Lista propria dos objetos que receberam alcance. `static_meshes` nao serve:
# ela e esvaziada quando a sombra do cenario esta ligada, e a porta precisa
# liberar objeto nos dois modos.
var com_alcance: Array = []
var liberados: Dictionary = {}
# Lampadas cuja luz ja esta no lightmap assado: ficam apagadas enquanto a luz
# assada estiver ligada, senao a sala recebe a mesma luz duas vezes e nao ha
# ganho nenhum de desempenho.
var cobertas_pelo_bake: Dictionary = {}
var assinatura_portas := ""
var cursor := 0

func _ready() -> void:
	name = "LightCulling"

# Idempotente de proposito: metade das lampadas nasce depois do _ready do
# mundo, entao isto roda de novo nos primeiros segundos e so acrescenta o que
# ainda nao esta na lista.
func build() -> void:
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	for lamp in game.world.find_children("*", "Light3D", true, false):
		if lamps.has(lamp): continue
		if lamp is DirectionalLight3D: continue
		# Antes so entravam as que projetam sombra, e as outras dez nunca eram
		# apagadas: com a sombra do cenario desligada, elas atravessam parede.
		# Fora ficam so as dos vultos, que andam — o volume delas e calculado
		# uma vez e deixaria de valer no primeiro passo.
		if vulto(lamp): continue
		lamps.append(lamp)
		volumes.append(lit_volume(space, lamp))
		grace.append(GRACE)
		base_layers.append(lamp.layers)
		base_shadow.append(lamp.shadow_enabled)

# Luz presa a uma criatura que anda: nao entra na oclusao.
func vulto(lamp: Node) -> bool:
	for nome in ["figure", "figure_volume", "figure_mesh"]:
		var dono = game.world.get(nome)
		if dono != null and (dono == lamp or dono.is_ancestor_of(lamp)): return true
	return false

func reach(lamp: Light3D) -> float:
	if lamp is OmniLight3D: return lamp.omni_range
	if lamp is SpotLight3D: return lamp.spot_range
	return 0.0

func lit_volume(space: PhysicsDirectSpaceState3D, lamp: Light3D) -> AABB:
	# A caixa do alcance recortada na primeira parede de cada eixo. A geometria
	# é estática, então isto roda uma vez e nunca mais.
	var origin: Vector3 = lamp.global_position
	var radius := reach(lamp)
	var box := AABB(origin, Vector3.ZERO)
	for axis in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]:
		var target: Vector3 = origin + axis * radius
		var query := PhysicsRayQueryParameters3D.create(origin, target)
		query.collision_mask = 1
		var hit: Dictionary = space.intersect_ray(query)
		box = box.expand(hit["position"] if hit.has("position") else target)
	return box

func cameras() -> Array:
	var list: Array = []
	if game.player != null and game.player.camera != null: list.append(game.player.camera)
	# A câmera do CCTV olha outro lugar: sem ela no teste, a CAM-04 escurece.
	if game.computer != null and game.computer.security_camera != null and game.computer.feed.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		list.append(game.computer.security_camera)
	return list

# Os cantos da caixa nascem EM CIMA da parede: foi ali que o raio de recorte
# parou. Mirar neles faz todo raio bater na parede um triz antes de chegar, e a
# luz apagava com a area dela bem a vista. Encolhe a caixa antes de amostrar, e
# testa a propria lampada primeiro, que e o ponto mais barato de acertar.
const MARGEM := 0.5

func sample_points(index: int) -> Array:
	var pontos: Array = [lamps[index].global_position]
	var box: AABB = volumes[index].grow(-MARGEM)
	if box.size.x <= 0.0 or box.size.y <= 0.0 or box.size.z <= 0.0:
		return pontos
	pontos.append(box.get_center())
	for corner in range(8): pontos.append(box.get_endpoint(corner))
	# Centro das faces: pega o facho no chao e na parede, onde a luz aparece.
	for eixo in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		pontos.append(box.get_center() + eixo * box.size * 0.5)
		pontos.append(box.get_center() - eixo * box.size * 0.5)
	# Vao de porta aberta que da para este volume: e por ele que a luz da sala
	# chega a quem esta do lado de fora. Sem isto a sala so acendia depois de
	# entrar, porque a lampada e os cantos do volume ficam atras da parede.
	for id in game.world.doors:
		var porta = game.world.doors[id]
		if not is_instance_valid(porta) or not porta.is_open: continue
		var vao: Vector3 = porta.global_position + Vector3.UP * 1.2
		if volumes[index].grow(0.6).has_point(vao): pontos.append(vao)
	# Grade no piso do volume: a poca de luz no chao e o que se enxerga pelo vao
	# de uma porta aberta, enquanto a lampada e os cantos ficam atras da parede.
	var chao: float = box.position.y + 0.05
	for i in range(3):
		for j in range(3):
			pontos.append(Vector3(
				box.position.x + box.size.x * (0.5 + i) / 3.0,
				chao,
				box.position.z + box.size.z * (0.5 + j) / 3.0))
	return pontos

func seen_from(camera: Camera3D, index: int) -> bool:
	if camera == null: return false
	# Camera dentro do volume iluminado: a luz chega nela por definicao, mesmo
	# com o bulbo escondido atras de luminaria ou viga. Sem este teste a
	# lampada apagava com o jogador parado embaixo do proprio facho, porque os
	# pontos de amostra caem atras da camera ou contra o teto.
	if volumes[index].has_point(camera.global_position): return true
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	var eye: Vector3 = camera.global_position
	# O pedaco do volume mais perto do olho vai primeiro: e o que aparece pelo
	# vao de uma porta aberta. Sem ele, a lampada no fundo da sala so acendia
	# depois de entrar, porque os cantos da caixa ficam atras da parede.
	var box: AABB = volumes[index]
	var perto_do_olho := Vector3(
		clampf(eye.x, box.position.x, box.position.x + box.size.x),
		clampf(eye.y, box.position.y, box.position.y + box.size.y),
		clampf(eye.z, box.position.z, box.position.z + box.size.z))
	if no_cone(camera, perto_do_olho) and livre(space, eye, perto_do_olho): return true
	for point in sample_points(index):
		if not no_cone(camera, point): continue
		if livre(space, eye, point): return true
	return false

func no_cone(camera: Camera3D, point: Vector3) -> bool:
	if camera.is_position_in_frustum(point): return true
	var direcao: Vector3 = point - camera.global_position
	if direcao.length_squared() < 0.0001: return true
	# -Z e a frente da camera no Godot.
	var frente: Vector3 = -camera.global_transform.basis.z
	var angulo := rad_to_deg(frente.angle_to(direcao.normalized()))
	return angulo < camera.fov * 0.5 + extra_angulo

func seen(index: int) -> bool:
	for camera in cameras():
		if seen_from(camera, index): return true
	return false

# Caminho livre do olho ate o ponto, atravessando vidro. Tres saltos bastam:
# janela da sala, janela da fachada e a porta envidracada da entrada.
const SALTOS := 3

func livre(space: PhysicsDirectSpaceState3D, eye: Vector3, point: Vector3) -> bool:
	var origem := eye
	for salto in range(SALTOS):
		var query := PhysicsRayQueryParameters3D.create(origem, point)
		query.collision_mask = 1
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty(): return true
		var corpo = hit.get("collider")
		if corpo == null or not corpo.has_meta("transparente"): return false
		# Recomeca logo depois do vidro, senao o proximo raio bate nele de novo.
		origem = hit["position"] + (point - origem).normalized() * 0.05
	return false

# O alcance da propria lampada entra na conta: um poste de rua com 10 m de
# alcance ainda ilumina area visivel a 20 m, e cortar a sombra dele pela
# distancia nua apagava a sombra da rua inteira.
func perto(lamp: Light3D) -> bool:
	var limite: float = shadow_range + reach(lamp)
	for camera in cameras():
		if lamp.global_position.distance_to(camera.global_position) < limite: return true
	return false

func light_on(index: int, on: bool) -> void:
	var lamp: Light3D = lamps[index]
	lamp.light_cull_mask = FULL_MASK if on else 0
	lamp.shadow_enabled = on and bool(base_shadow[index]) and perto(lamp)

func set_enabled(value: bool) -> void:
	enabled = value
	if value: return
	# Devolve tudo, inclusive a sombra das distantes: quem desliga a oclusao
	# quer o estado original de volta, nao um meio-termo.
	for index in range(lamps.size()):
		grace[index] = GRACE
		lamps[index].light_cull_mask = FULL_MASK
		lamps[index].shadow_enabled = bool(base_shadow[index])
		lamps[index].layers = int(base_layers[index])

# So a conta do frustum, sem raio: se o vidro esta no quadro o exterior fica,
# mesmo que uma parede esteja na frente dele. Perde um pouco de otimizacao e
# nao arrisca sumir com a rua que o jogador esta vendo.
func update_exterior() -> void:
	if game.world.architecture == null or game.player == null: return
	var mostra: bool = game.world.is_outdoors(game.player.global_position)
	if not mostra:
		for body in panes:
			if not is_instance_valid(body): continue
			var ponto: Vector3 = body.global_position
			for camera in cameras():
				# Colado no vidro ele sai do campo de visao e o exterior sumia.
				# Vidraca a menos de PERTO_DO_VIDRO vale independente do angulo.
				if camera.global_position.distance_to(ponto) < PERTO_DO_VIDRO or no_cone(camera, ponto):
					mostra = true
					break
			if mostra: break
	game.world.architecture.visible = mostra

# Quais portas estao abertas agora. So refaz a liberacao quando o conjunto
# muda, entao andar pelo predio nao custa nada.
func update_doorways() -> void:
	if game.world.doors.is_empty(): return
	var assinatura := ""
	for id in game.world.doors:
		var porta = game.world.doors[id]
		if is_instance_valid(porta) and porta.is_open: assinatura += str(id) + ","
	if assinatura == assinatura_portas: return
	assinatura_portas = assinatura
	for mesh in liberados:
		if is_instance_valid(mesh): mesh.visibility_range_end = float(liberados[mesh])
	liberados.clear()
	for id in game.world.doors:
		var porta = game.world.doors[id]
		if not is_instance_valid(porta) or not porta.is_open: continue
		for mesh in com_alcance:
			if not is_instance_valid(mesh) or mesh.visibility_range_end <= 0.0: continue
			if mesh.global_position.distance_to(porta.global_position) > VAO_RAIO: continue
			liberados[mesh] = mesh.visibility_range_end
			mesh.visibility_range_end = 0.0

func _process(_delta: float) -> void:
	ticks += 1
	update_doorways()
	update_exterior()
	# O alcance dos objetos vale com a sombra do cenario ligada ou desligada,
	# entao a varredura roda nos dois casos.
	if REFRESH_AT.has(ticks):
		build()
		if static_shadows: collect_static()
		else: set_static_shadows(false)
	if not enabled or lamps.is_empty(): return
	var cams := cameras()
	var olho: Camera3D = cams[0] if cams.size() > 0 else null
	var cctv: Camera3D = cams[1] if cams.size() > 1 else null
	for step in range(SLICE):
		cursor = (cursor + 1) % lamps.size()
		var pelo_jogador := seen_from(olho, cursor)
		var so_cctv: bool = not pelo_jogador and seen_from(cctv, cursor)
		if pelo_jogador or so_cctv:
			grace[cursor] = GRACE
		else:
			grace[cursor] = maxi(grace[cursor] - 1, 0)
		var lamp: Light3D = lamps[cursor]
		if cobertas_pelo_bake.has(lamp):
			light_on(cursor, false)
			continue
		light_on(cursor, grace[cursor] > 0)
		# So o CCTV enxerga: sai da vista do jogador em vez de atravessar parede.
		lamp.layers = CCTV_ONLY if so_cctv else int(base_layers[cursor])

# A lista e montada na hora de desligar, nao no _ready do mundo: ali metade do
# cenario ainda nao nasceu, e malhas efemeras (nevoa, puffs) morrem no meio do
# turno, deixando referencia podre para tras.
# Roda junto da coleta: mesma varredura, custo zero a mais.
func apply_prop_range(mesh: MeshInstance3D) -> void:
	if mesh.mesh == null: return
	if (mesh.global_transform * mesh.mesh.get_aabb()).size.length() > PROP_MAX: return
	mesh.visibility_range_end = prop_range
	mesh.visibility_range_end_margin = PROP_FADE
	com_alcance.append(mesh)

# Mudar o alcance pelo menu tem de alcancar o que ja esta em cena.
func set_prop_range(value: float) -> void:
	prop_range = value
	if game == null or game.world == null or lamps.is_empty(): return
	collect_static()

func collect_static() -> void:
	static_meshes.clear()
	com_alcance.clear()
	# A liberacao precisa ser refeita contra a lista nova.
	liberados.clear()
	assinatura_portas = ""
	if game.world == null: return
	var classifier := preload("res://scripts/shadow_map.gd").new()
	classifier.game = game
	# So malha de cenario entra: porta e objeto da historia nunca podem sumir
	# por distancia. O alcance e aplicado aqui mesmo, na mesma varredura.
	for mesh in game.world.find_children("*", "MeshInstance3D", true, false):
		if not classifier.reason(mesh).is_empty(): continue
		apply_prop_range(mesh)
		static_meshes.append(mesh)
	classifier.free()
	panes.clear()
	for body in game.world.find_children("*", "StaticBody3D", true, false):
		if not body.has_meta("transparente"): continue
		# O ponto de teste e o centro do colisor, nao a origem do corpo: a porta
		# de vidro nasce no chao, e um ponto no pe do jogador cai fora do campo
		# de visao mesmo com a porta inteira na frente dele.
		var ponto: Node3D = body
		for filho in body.get_children():
			if filho is CollisionShape3D:
				ponto = filho
				break
		panes.append(ponto)

func set_static_shadows(value: bool) -> void:
	static_shadows = value
	if not value: collect_static()
	var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if value else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for mesh in static_meshes:
		if is_instance_valid(mesh): mesh.cast_shadow = mode
	if value: static_meshes.clear()
