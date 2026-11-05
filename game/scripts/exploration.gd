extends Node
# Optional early exploration, required spare-parts route once F1 fails.
var game: Node
var objects := {}
var doors := {}
const PROMPTS := {"personnel_key":"Recolher chave de pessoal", "it_key":"Recolher chave TI", "handover":"Ler livro de entrega de chaves", "staff_register":"Ler escala do plantão", "it_cabinet_note":"Ler aviso do estoque", "it_cabinet":"Examinar fechadura / ler aviso"}
const HANDOVER := "ENTREGA DE CHAVES — 14/11/2008\n\nA sala de pessoal guarda o armário de pertences da manutenção. A chave dessa sala ficou no almoxarifado do térreo, sobre a bancada de conferência.\n\nA chave pequena com etiqueta TI pertence ao armário de peças. Devolvam-na à sala de pessoal após o serviço. — Augusto"
const CABINET_NOTE := "ESTOQUE CONTROLADO / F1\n\nReposição de 20 A no armário trancado da TI. A chave etiquetada TI está na sala de pessoal, neste pavimento.\n\nSe pessoal estiver fechada, consulte o livro de entrega de chaves na copa do térreo. Não force a fechadura nem utilize o cartucho de 10 A da bancada."

func bind() -> void:
	for node in game.world.find_children("*", "Node3D", true, false):
		if node.has_meta("exploration_light"):
			node.bind(node.get_node(node.get_meta("exploration_light")),game.world)
			game.world.lighting_fixtures.append(node)
			game.world.interior_lights.append(node.source)
			game.world.pulse_light(node.source)
		if not node.has_meta("exploration_id"): continue
		var id: String = node.get_meta("exploration_id")
		if node.has_meta("exploration_door"):
			doors[id] = node
			game.world.doors[id] = node
			node.access = allow_door.bind(id)
			node.operated.connect(play_door.bind(id))
		else:
			objects[id] = node
			game.world.objects[id] = node
			node.prompt = PROMPTS.get(id,"Examinar")
			node.action = game.chapter.interact.bind(id)
	# Keep the original fuse reference for old checkpoints/tests, inside the cabinet.
	var socket := Transform3D(Basis.IDENTITY,Vector3(0,0.27,-0.25))
	var marker: Node3D = objects.it_cabinet.get_node_or_null("FuseSocket")
	game.world.objects.fuse20.global_transform = marker.global_transform if marker != null else objects.it_cabinet.global_transform*socket
	# Ambientacao2Andar: objetos de cenas/ambientacao.tscn no segundo andar.
	for group_name in ["SalaPessoal","ArmarioTI","Ambientacao2Andar"]:
		var group: Node = game.world.find_child(group_name,true,false)
		if group != null: game.world.tag_upper_layer(group)
	apply_state()

func play_door(opened: bool, id: String) -> void:
	game.sound.play("door_open" if opened else "door_close",doors[id].global_position+Vector3.UP,-18)

func allow_door(id: String) -> bool:
	if id != "personnel" or game.chapter.has_flag("personnel_unlocked"): return true
	if game.chapter.has_flag("personnel_key"):
		game.chapter.flags.personnel_unlocked = true
		game.chapter.flags.personnel_key = false
		game.chapter.say("Chave de pessoal utilizada. A porta permanece destrancada.")
		game.chapter.save_game()
		return true
	game.chapter.say("Sala de pessoal trancada. O livro de entrega de chaves fica na copa do térreo.")
	return false

func interact(id: String) -> bool:
	var chapter: Node = game.chapter
	match id:
		"it_cabinet_note": chapter.collect_document(id,"Estoque controlado — TI",CABINET_NOTE)
		"handover": chapter.collect_document(id,"Livro de entrega de chaves",HANDOVER)
		"personnel_key", "it_key":
			if chapter.has_flag(id+"_taken"): return true
			chapter.flags[id] = true
			chapter.flags[id+"_taken"] = true
			chapter.say("Chave de pessoal guardada. A sala fica no segundo andar, após a sala de reuniões." if id == "personnel_key" else "Chave TI guardada. Retorne ao armário de peças na sala de TI.")
		"it_cabinet":
			if chapter.has_flag("it_cabinet_open"):
				chapter.say("Armário destrancado. Retire o cartucho de 20 A da prateleira.")
			elif chapter.has_flag("it_key"):
				chapter.flags.it_key = false
				chapter.flags.it_cabinet_open = true
				game.sound.play("switch",objects[id].global_position,-20)
				chapter.say("Armário TI aberto. Fusível de 20 A disponível na prateleira.")
			else:
				chapter.collect_document("it_cabinet_note","Estoque controlado — TI",CABINET_NOTE)
		"staff_register": chapter.collect_document(id,"Pessoal — plantão de novembro","14/11 — Daniel Reis, portaria, 00h–06h.\n\nA coluna de turnos anteriores foi rasurada. Há uma impressão profunda de assinatura sob a folha atual.\n\nAnexo de manutenção: devolver chaves ao responsável e manter o circuito do subsolo isolado.")
		_: return false
	apply_state()
	chapter.refresh()
	chapter.save_game()
	return true

func apply_state() -> void:
	if objects.is_empty(): return
	for id in ["personnel_key","it_key"]:
		var available: bool = not game.chapter.has_flag(id+"_taken")
		objects[id].visible = available
		objects[id].collision_layer = 1 if available else 0
	var opened: bool = game.chapter.has_flag("it_cabinet_open") or game.chapter.has_flag("fuse20_taken") or game.chapter.has_flag("fuse_replaced")
	var leaf := objects.it_cabinet.get_node("Leaf") as Node3D
	objects.it_cabinet.prompt = "Examinar armário aberto — reposição F1" if opened else "Examinar fechadura / ler aviso"
	leaf.rotation.y = 1.7 if opened else 0.0
	if objects.it_cabinet.has_node("ClosedLeaf"):
		objects.it_cabinet.get_node("ClosedLeaf").set_deferred("disabled",opened)
	var fuse: Node3D = game.world.objects.fuse20
	fuse.visible = opened and not game.chapter.has_flag("fuse20_taken")
	fuse.collision_layer = 1 if fuse.visible else 0

func objective() -> String:
	var c: Node = game.chapter
	if c.has_flag("it_cabinet_open"): return "Retire a reposição de 20 A do armário aberto na TI."
	if c.has_flag("it_key"): return "Use a chave TI no armário de peças do segundo andar."
	if c.has_flag("personnel_unlocked"): return "Procure a chave etiquetada TI na sala de pessoal."
	if c.has_flag("personnel_key"): return "Abra a sala de pessoal no segundo andar com a chave do almoxarifado."
	if c.documents.has("handover"): return "Busque a chave de pessoal na bancada do almoxarifado, térreo."
	if c.documents.has("it_cabinet_note"): return "Consulte o livro de entrega de chaves na copa do térreo."
	return "Busque a reposição no armário de peças da TI. Leia o aviso preso à porta."

func zone(point: Vector3) -> String:
	if point.y > 3.5 and point.x > 1.7 and point.x < 8 and point.z > 5: return "2º / PESSOAL"
	if point.y < 1 and point.x < -2 and point.x > -8 and point.z > -6 and point.z < -2: return "ALMOXARIFADO"
	if point.y < 1 and point.x > 2 and point.x < 8 and point.z > -2 and point.z < 4: return "COPA / FUNCIONÁRIOS"
	return ""
