extends Node
## ============================================================================
## NIGHTSHIFT — EXPORTAR O PRÉDIO COMO CENA (para assar luz)
## ============================================================================
## FAMÍLIA: Ferramenta (res://scripts/scene_export.gd)
## QUEM CRIA: main.gd, só com `--export-scene` (tools/godot.ps1 -Mode export).
## OBJETIVO DO AGENTE:
##   O prédio nasce em código, e o `LightmapGI.bake()` não é exposto a script:
##   assar é ação do editor, e o editor só assa o que está salvo numa cena.
##   Esta ferramenta roda o mundo uma vez e grava a parte estática dele como
##   `.tscn`, com UV2 e `gi_mode = STATIC`, pronta para abrir no editor e
##   apertar "Bake Lightmaps". É o passo que o TrackMania faz uma vez por mapa.
## AVISO: a cena gravada é só para assar. Ela não é o jogo: porta, objeto da
##   história e vulto ficam de fora de propósito, porque se movem.
## ============================================================================

# Binario, nao `.tscn`: em texto a primeira tentativa gravou 2,35 GB, porque
# cada malha vira array escrito por extenso.
const DESTINO := "res://scenes/bake/predio.scn"
# Tamanho de texel do desdobramento. Menor = lightmap mais fino e bake mais
# lento. 0,2 m dá um mapa grosseiro e rápido para a primeira tentativa.
const TEXEL := 0.2
# Posicao de cada malha exportada, na ordem em que foi exportada. E por ela que
# o jogo reencontra, em tempo de execucao, qual malha corresponde a cada fatia
# do lightmap: a ordem da varredura nao se repete, a posicao sim.
const INDICE := "res://scenes/bake/predio-malhas.json"

var game: Node
# Malhas preparadas, por recurso de origem: sem isto cada uma das 3737 copias
# carregava a sua propria, e o arquivo explodia.
var prontas: Dictionary = {}

func run() -> void:
	await get_tree().process_frame
	# Espera o cenário terminar de nascer: no _ready do mundo metade não existe.
	for quadro in range(400): await get_tree().process_frame
	acender_tudo()
	var raiz := Node3D.new()
	raiz.name = "PredioParaAssar"
	var classificador := preload("res://scripts/shadow_map.gd").new()
	classificador.game = game
	var malhas := 0
	var sem_uv2 := 0
	var posicoes: Array = []
	for mesh in game.world.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.visible: continue
		if not classificador.reason(mesh).is_empty(): continue
		var copia := MeshInstance3D.new()
		var chave: int = mesh.mesh.get_instance_id()
		if not prontas.has(chave): prontas[chave] = preparar(mesh.mesh)
		copia.mesh = prontas[chave]
		if copia.mesh == null:
			sem_uv2 += 1
			continue
		copia.material_override = mesh.material_override
		copia.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		raiz.add_child(copia)
		copia.owner = raiz
		copia.global_transform = mesh.global_transform
		posicoes.append([
			snappedf(mesh.global_position.x, 0.001),
			snappedf(mesh.global_position.y, 0.001),
			snappedf(mesh.global_position.z, 0.001)])
		malhas += 1
	classificador.free()
	var luzes := 0
	for lamp in game.world.find_children("*", "Light3D", true, false):
		if lamp is DirectionalLight3D: continue
		if not lamp.visible: continue
		var copia: Light3D = lamp.duplicate(0) as Light3D
		if copia == null: continue
		raiz.add_child(copia)
		copia.owner = raiz
		copia.global_transform = lamp.global_transform
		copia.visible = true
		# Sem isto o bake ignora a luz: no Godot 4 o padrao e dinamica.
		copia.light_bake_mode = Light3D.BAKE_STATIC
		copia.shadow_enabled = true
		copia.layers = 1
		copia.light_cull_mask = 0xFFFFF
		luzes += 1
	var assador := LightmapGI.new()
	assador.name = "LightmapGI"
	# Primeira tentativa em qualidade baixa: 3558 malhas em alta levaria horas,
	# e o que se quer saber primeiro e se o resultado presta.
	assador.quality = LightmapGI.BAKE_QUALITY_LOW
	assador.bounces = 1
	assador.max_texture_size = 2048
	raiz.add_child(assador)
	assador.owner = raiz
	var indice := FileAccess.open(INDICE, FileAccess.WRITE)
	if indice != null: indice.store_string(JSON.stringify(posicoes))
	conferir(raiz)
	gravar(raiz, malhas, luzes, sem_uv2)
	print("EXPORT_DONE")
	get_tree().quit(0)

# UV2 é a condição do lightmap. BoxMesh gera sozinho com `add_uv2`; o resto
# precisa do desdobrador, que existe no binário do editor.
# O bake tem de pegar o predio aceso. Rodando, o que existe e o estado do
# capitulo 1: corredor sem energia, ritmo piscando as lampadas e a oclusao
# apagando tudo o que a camera nao ve. Nada disso pode ir para o lightmap.
func acender_tudo() -> void:
	if game.world.light_culling != null:
		game.world.light_culling.enabled = false
		game.world.light_culling.static_shadows = true
	game.world.set_interior_power(true)
	game.world.corridor_powered = true
	if game.world.upper != null: game.world.upper.apply_state()
	# O ritmo do corredor reescreve `visible` todo quadro: para o relogio.
	game.world.set_process(false)
	# Respeita o estado autorado de cada luminaria: forcar todas acendia tambem
	# a luz vermelha de emergencia do segundo andar, que nunca acende em jogo,
	# e o bake sairia com as salas em vermelho.
	for entrada in game.world.building_lights: entrada.light.visible = bool(entrada.enabled)
	for luz in game.world.corridor_lights: luz.visible = true
	if game.world.upper != null:
		for luz in game.world.upper.emergency_lights:
			if is_instance_valid(luz): luz.visible = false

func preparar(origem: Mesh) -> Mesh:
	if origem is PrimitiveMesh:
		var copia: PrimitiveMesh = origem.duplicate() as PrimitiveMesh
		copia.set("add_uv2", true)
		return copia
	var arrays := ArrayMesh.new()
	for superficie in range(origem.get_surface_count()):
		arrays.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, origem.surface_get_arrays(superficie))
	if arrays.lightmap_unwrap(Transform3D(), TEXEL) != OK: return null
	return arrays

func gravar(raiz: Node3D, malhas: int, luzes: int, sem_uv2: int) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DESTINO).get_base_dir())
	var pacote := PackedScene.new()
	if pacote.pack(raiz) != OK:
		print("EXPORT: nao consegui empacotar a cena")
		return
	var erro := ResourceSaver.save(pacote, DESTINO)
	if erro != OK:
		print("EXPORT: falha ao gravar %s (erro %d)" % [DESTINO, erro])
		return
	print("EXPORT: %s | %d malhas estaticas, %d luzes assaveis, %d malhas sem UV2" % [DESTINO, malhas, luzes, sem_uv2])

func conferir(raiz: Node3D) -> void:
	var acesas := 0
	var assaveis := 0
	for luz in raiz.find_children("*", "Light3D", true, false):
		if luz.visible: acesas += 1
		if luz.light_bake_mode == Light3D.BAKE_STATIC: assaveis += 1
	print("EXPORT conferencia: %d luzes acesas, %d marcadas para assar" % [acesas, assaveis])
