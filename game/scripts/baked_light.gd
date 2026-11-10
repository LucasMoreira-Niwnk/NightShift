extends Node
## ============================================================================
## NIGHTSHIFT — LUZ ASSADA
## ============================================================================
## FAMÍLIA: Render (res://scripts/baked_light.gd)
## QUEM CRIA: chapter_world.gd, junto do resto do render.
## OBJETIVO DO AGENTE:
##   Aplica no prédio montado em código o lightmap que foi assado a partir da
##   cena exportada. O `LightmapGIData` guarda, por malha, o caminho dela na
##   cena do bake — que não existe aqui. Então o vínculo é refeito pela
##   POSIÇÃO: o exportador grava a posição de cada malha na ordem exportada, e
##   aqui cada fatia do atlas é reapontada para a malha que está naquele ponto.
## AVISO: se o cenário mudar depois do bake, as posições deixam de casar. O nó
##   conta quantas casaram e recusa aplicar se for pouco — luz assada pela
##   metade é pior que nenhuma.
## ============================================================================

const DADOS := "res://scenes/bake/predio.lmbake"
const INDICE := "res://scenes/bake/predio-malhas.json"
# Metade do cenário é modelo importado, que não tem UV2 e por isso fica de fora
# — continua recebendo luz real. Abaixo deste piso é que o bake está velho
# demais para o cenário, e aí aplicar seria pior que não aplicar.
const MINIMO := 0.4
# Tolerância ao casar posição, em metros.
const TOLERANCIA := 0.02

var game: Node
var aplicado := false
var casadas := 0
var total := 0
var lightmap: LightmapGI

func disponivel() -> bool:
	return ResourceLoader.exists(DADOS) and FileAccess.file_exists(ProjectSettings.globalize_path(INDICE))

func estado() -> String:
	if not disponivel(): return "Nenhum bake em disco. Gere com tools/godot.ps1 -Mode export e asse no editor."
	if not aplicado: return "Bake em disco, desligado. %d de %d malhas casariam." % [casadas, total]
	return "Luz assada ativa em %d de %d malhas." % [casadas, total]

func aplicar(ligado: bool) -> void:
	if ligado == aplicado: return
	if not ligado:
		limpar()
		return
	if not disponivel(): return
	montar()

func limpar() -> void:
	aplicado = false
	if lightmap != null and is_instance_valid(lightmap):
		lightmap.queue_free()
		lightmap = null

# Posição gravada pelo exportador -> FILA de índices da fatia no atlas. Fila, e
# não um índice só: 380 das 3559 malhas dividem a posição com outra (peças
# empilhadas no mesmo ponto), e guardar uma só perdia o resto.
var exportadas := 0

func indice_por_posicao() -> Dictionary:
	var mapa: Dictionary = {}
	exportadas = 0
	var arquivo := FileAccess.open(INDICE, FileAccess.READ)
	if arquivo == null: return mapa
	var lista = JSON.parse_string(arquivo.get_as_text())
	if lista == null: return mapa
	exportadas = lista.size()
	for i in range(lista.size()):
		var ponto: Array = lista[i]
		var k := chave(Vector3(ponto[0], ponto[1], ponto[2]))
		if not mapa.has(k): mapa[k] = []
		mapa[k].append(i)
	return mapa

func chave(ponto: Vector3) -> String:
	return "%.2f|%.2f|%.2f" % [ponto.x, ponto.y, ponto.z]

func montar() -> void:
	var dados = load(DADOS)
	if dados == null: return
	var users: Array = dados.get("user_data")
	if users == null or users.is_empty(): return
	var mapa := indice_por_posicao()
	total = exportadas
	# O indice e o bake precisam vir da MESMA exportacao: a ordem dos usuarios
	# no recurso e a ordem dos nos na cena exportada. Contagem diferente quer
	# dizer que o cenario mudou depois de assar, e aplicar assim poria a fatia
	# errada em cada malha — pior que nao aplicar.
	var quantos_usuarios: int = users.size() / 4
	if quantos_usuarios != total:
		print("LUZ ASSADA: bake tem %d malhas e o cenario tem %d. Reexporte e asse de novo." % [quantos_usuarios, total])
		return
	# Cada usuário ocupa quatro posições: caminho, escala de UV, fatia e
	# sub-instância. É assim que o recurso guarda em disco.
	var por_indice: Dictionary = {}
	for i in range(0, users.size(), 4):
		por_indice[i / 4] = [users[i + 1], users[i + 2], users[i + 3]]
	lightmap = LightmapGI.new()
	lightmap.name = "LuzAssada"
	game.world.add_child(lightmap)
	# Recurso novo, nao `duplicate()`: duplicar LightmapGIData derruba o Godot
	# 4.0 na hora, sem mensagem. Aqui so a textura do atlas e reaproveitada.
	var novo := LightmapGIData.new()
	novo.light_texture = dados.light_texture
	casadas = 0
	for mesh in game.world.find_children("*", "MeshInstance3D", true, false):
		var k := chave(mesh.global_position)
		if not mapa.has(k) or mapa[k].is_empty(): continue
		# Consome a fila: a mesma varredura, na mesma ordem, dá o mesmo pareamento
		# para as malhas que dividem o ponto.
		var indice: int = mapa[k].pop_front()
		if not por_indice.has(indice): continue
		# So malha parametrica tem UV2 aqui (ligada no box()). A importada
		# precisaria de desdobramento, que so existe no editor — fica de fora.
		if not (mesh.mesh is PrimitiveMesh): continue
		var entrada: Array = por_indice[indice]
		mesh.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		novo.add_user(lightmap.get_path_to(mesh), entrada[0], int(entrada[1]), int(entrada[2]))
		casadas += 1
	if total > 0 and float(casadas) / float(total) < MINIMO:
		print("LUZ ASSADA: só %d de %d malhas casaram; o bake está velho para este cenário." % [casadas, total])
		limpar()
		return
	lightmap.light_data = novo
	aplicado = true
