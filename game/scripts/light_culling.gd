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
const PROP_MAX := 0.8
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
var cursor := 0

func _ready() -> void:
	name = "LightCulling"

func build() -> void:
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	for lamp in game.world.find_children("*", "Light3D", true, false):
		if lamp is DirectionalLight3D or not lamp.shadow_enabled: continue
		lamps.append(lamp)
		volumes.append(lit_volume(space, lamp))
		grace.append(GRACE)
		base_layers.append(lamp.layers)

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

func perto(lamp: Light3D) -> bool:
	for camera in cameras():
		if lamp.global_position.distance_to(camera.global_position) < shadow_range: return true
	return false

func light_on(lamp: Light3D, on: bool) -> void:
	lamp.light_cull_mask = FULL_MASK if on else 0
	lamp.shadow_enabled = on and perto(lamp)

func set_enabled(value: bool) -> void:
	enabled = value
	if value: return
	# Devolve tudo, inclusive a sombra das distantes: quem desliga a oclusao
	# quer o estado original de volta, nao um meio-termo.
	for index in range(lamps.size()):
		grace[index] = GRACE
		lamps[index].light_cull_mask = FULL_MASK
		lamps[index].shadow_enabled = true
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
			for camera in cameras():
				if camera.is_position_in_frustum(body.global_position):
					mostra = true
					break
			if mostra: break
	game.world.architecture.visible = mostra

func _process(_delta: float) -> void:
	ticks += 1
	update_exterior()
	# O alcance dos objetos vale com a sombra do cenario ligada ou desligada,
	# entao a varredura roda nos dois casos.
	if REFRESH_AT.has(ticks):
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
		light_on(lamp, grace[cursor] > 0)
		# So o CCTV enxerga: sai da vista do jogador em vez de atravessar parede.
		lamp.layers = CCTV_ONLY if so_cctv else int(base_layers[cursor])

# A lista e montada na hora de desligar, nao no _ready do mundo: ali metade do
# cenario ainda nao nasceu, e malhas efemeras (nevoa, puffs) morrem no meio do
# turno, deixando referencia podre para tras.
# Roda junto da coleta: mesma varredura, custo zero a mais.
func apply_prop_range(mesh: MeshInstance3D) -> void:
	if mesh.mesh == null: return
	if mesh.mesh.get_aabb().size.length() > PROP_MAX: return
	mesh.visibility_range_end = prop_range
	mesh.visibility_range_end_margin = PROP_FADE

# Mudar o alcance pelo menu tem de alcancar o que ja esta em cena.
func set_prop_range(value: float) -> void:
	prop_range = value
	if game == null or game.world == null or lamps.is_empty(): return
	collect_static()

func collect_static() -> void:
	static_meshes.clear()
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
		if body.has_meta("transparente"): panes.append(body)

func set_static_shadows(value: bool) -> void:
	static_shadows = value
	if not value: collect_static()
	var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if value else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for mesh in static_meshes:
		if is_instance_valid(mesh): mesh.cast_shadow = mode
	if value: static_meshes.clear()
