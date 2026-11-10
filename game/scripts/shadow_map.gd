extends Node
## ============================================================================
## NIGHTSHIFT — MAPA DE SOMBRAS
## ============================================================================
## FAMÍLIA: Ferramenta (res://scripts/shadow_map.gd)
## QUEM CRIA: main.gd, só com `--map-shadows` (tools/godot.ps1 -Mode shadows).
## OBJETIVO DO AGENTE:
##   Separa o cenário em duas listas: o que nunca se mexe (sombra fixa, podendo
##   ser assada) e o que a história move (sombra tem de ser calculada ao vivo).
##   Rode depois de mexer no ambiente: o resumo em docs/ é versionado, então o
##   `git diff` mostra o que mudou de categoria sem ninguém precisar caçar.
## AVISO: só classifica e relata. Não altera `cast_shadow` de nada, e não assa
##   sombra nenhuma — o Godot 4.0 não desdobra UV2 em tempo de execução.
## ============================================================================

const Door = preload("res://scripts/door.gd")
const Item = preload("res://scripts/interactable.gd")
const SUMMARY := "res://../docs/shadow-map.md"
const FULL := "res://../.local/shadow-map.json"

var game: Node

# `authored_door.gd` herda de `door.gd`: comparar o script direto deixava as
# portas montadas na cena passarem por fixas. Segue a cadeia de herança.
func derives(script: Script, base: Script) -> bool:
	var current := script
	while current != null:
		if current == base: return true
		current = current.get_base_script()
	return false

# Por que uma malha fica dinâmica. A ordem importa: o primeiro motivo que
# casar é o que vale.
func reason(mesh: MeshInstance3D) -> String:
	var node: Node = mesh
	while node != null and node != game.world:
		if derives(node.get_script(), Door): return "porta (gira ao abrir)"
		if derives(node.get_script(), Item): return "objeto interativo da história"
		if node == game.world.get("figure"): return "vulto de névoa"
		if node == game.world.get("figure_volume"): return "vulto volumétrico"
		if node == game.world.get("figure_mesh"): return "Mêmesis de malha (anda)"
		if node == game.world.get("drifting_fog"): return "bolha de névoa"
		node = node.get_parent()
	return ""

# Identidade estável: o nome automático do Godot (@@102) muda a cada execução e
# faria o diff inteiro piscar. Portas e objetos já têm id no dicionário do
# mundo; o resto responde pelo script de quem o construiu.
func ids() -> Dictionary:
	var map: Dictionary = {}
	for id in game.world.doors: map[game.world.doors[id]] = "porta: " + str(id)
	for id in game.world.objects: map[game.world.objects[id]] = "objeto: " + str(id)
	return map

func owner_label(mesh: MeshInstance3D, known: Dictionary) -> String:
	var node: Node = mesh
	while node != null:
		if known.has(node): return known[node]
		var script: Script = node.get_script()
		if script != null: return script.resource_path.get_file()
		if node == game.world: break
		node = node.get_parent()
	return "(sem dono)"

func run() -> void:
	await get_tree().process_frame
	var known := ids()
	var fixed: Array = []
	var moving: Array = []
	for mesh in game.world.find_children("*", "MeshInstance3D", true, false):
		var why := reason(mesh)
		var entry := {"dono": owner_label(mesh, known), "em": str(mesh.global_position.round())}
		if why.is_empty():
			fixed.append(entry)
		else:
			entry["motivo"] = why
			moving.append(entry)
	write_full(fixed, moving)
	write_summary(fixed, moving)
	print("SHADOW_MAP: %d fixas, %d dinamicas" % [fixed.size(), moving.size()])
	print("SHADOW_MAP_DONE")
	get_tree().quit(0)

func write_full(fixed: Array, moving: Array) -> void:
	var file := FileAccess.open(FULL, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"fixas": fixed, "dinamicas": moving}, "	"))

func tally(entries: Array, key: String) -> Dictionary:
	var totals: Dictionary = {}
	for entry in entries:
		var label: String = str(entry["dono"]) + ("" if key.is_empty() else " — " + str(entry[key]))
		totals[label] = int(totals.get(label, 0)) + 1
	return totals

func table(lines: Array, totals: Dictionary, header: String) -> void:
	lines.append("| %s | malhas |" % header)
	lines.append("|---|---|")
	var labels: Array = totals.keys()
	labels.sort()
	for label in labels:
		lines.append("| %s | %d |" % [label, totals[label]])
	lines.append("")

func write_summary(fixed: Array, moving: Array) -> void:
	var lines: Array = []
	lines.append("# Mapa de sombras")
	lines.append("")
	lines.append("Gerado por `tools/godot.ps1 -Mode shadows`, depois de mexer no ambiente.")
	lines.append("Confira o diff: uma malha que a história move e que apareça como fixa")
	lines.append("perderia a sombra ao ser assada; uma fixa listada como dinâmica paga")
	lines.append("sombra em tempo real à toa.")
	lines.append("")
	lines.append("| | malhas |")
	lines.append("|---|---|")
	lines.append("| sombra fixa (assável) | %d |" % fixed.size())
	lines.append("| sombra dinâmica | %d |" % moving.size())
	lines.append("")
	lines.append("## Fixas, por quem construiu")
	lines.append("")
	table(lines, tally(fixed, ""), "dono")
	lines.append("## Dinâmicas, por motivo")
	lines.append("")
	table(lines, tally(moving, "motivo"), "dono — motivo")
	var file := FileAccess.open(SUMMARY, FileAccess.WRITE)
	if file == null:
		print("SHADOW_MAP: nao consegui escrever %s" % SUMMARY)
		return
	file.store_string("
".join(lines))
