extends Node

const Data = preload("res://scripts/chapter_data.gd")
const SAVE_VERSION := 1
var game: Node
var stage := 0
var flags: Dictionary = {}
var verified: Array = []
var history: Array = []
var breakers: Array = [true, false, true, false]
var entity_steps := 0
var elapsed := 0.0
var save_path := "user://chapter1.json"
var pending_threat := false
var event_generation := 0
var event_tweens: Array = []
var documents: Array = []
var transcript: Array = []
var act_two = preload("res://scripts/chapter_two.gd").new()

func collect_document(id: String, heading: String, content: String) -> void:
	if not documents.has(id): documents.append(id)
	game.ui.document(heading, content)

func _ready() -> void:
	act_two.game = game
	if OS.get_cmdline_user_args().has("--smoke-test"):
		save_path = "user://chapter1-test.json"

func has_flag(id: String) -> bool:
	return bool(flags.get(id, false))

func objective() -> String:
	if stage >= 9: return act_two.objective()
	match stage:
		0:
			if not has_flag("C1_S1_ENTER"): return "Entre no Edifício Vesper pela porta à sua frente."
			return "Recepção: encontre o envelope sobre o balcão e recolha seu crachá/chave." if not has_flag("badge") else "Entre na sala de segurança — primeira porta à esquerda no corredor."
		1:
			if not has_flag("flashlight"): return "Pegue a lanterna sobre a mesa da segurança."
			if not has_flag("recording"): return "Reproduza a gravação 001 sobre a mesa da segurança."
			return "No computador: confira relógio, porta e cadeira. Confirme cada câmera (%d/3)." % verified.size()
		2: return "Ronda: inspecione a saída de emergência e leia o livro no arquivo. Depois retorne ao terminal."
		3:
			if not has_flag("chair_report"): return "Investigue a alteração na CAM-03 e registre a ocorrência no terminal."
			if not has_flag("chair_inspected"): return "Vá ao arquivo e examine a cadeira deslocada junto à porta."
			return "Examine as marcas e observe o arquivo." if not has_flag("chair_moved") else "Retorne ao terminal para conferir a cadeira."
		4:
			if not has_flag("fault_inspected"): return "Sala técnica: inspecione o quadro e identifique a falha."
			if not has_flag("repair_note_read"): return "A ordem de manutenção foi arquivada na administração do segundo andar. Use o crachá na escada."
			if not has_flag("fuse20_owned") and not has_flag("fuse_replaced"): return "Busque na sala de TI um fusível compatível com a ordem de manutenção."
			if not has_flag("fuse_replaced"): return "Retorne ao quadro, isole os circuitos, retire o cartucho queimado e instale a reposição."
			if not has_flag("power"): return "Rearme os circuitos na ordem descrita na nota de manutenção."
			return "Volte à segurança e confira a CAM-02 no terminal."
		5:
			if not has_flag("entity_report"): return "Há alguém na CAM-02. Investigue e registre a ocorrência sem sair da segurança."
			return "Observe a CAM-02 e alterne com outras câmeras. Permaneça na segurança."
		6: return "CAM-01 mostra você na recepção. Siga o protocolo: DESLIGUE O MONITOR."
		7: return "Leia o relatório impresso ao lado do computador." if not has_flag("report_read") else "O ramal 000 está tocando. Investigue a recepção ou permaneça na segurança."
	return "O Primeiro Turno — concluído."

func say(text: String) -> void:
	if transcript.is_empty() or transcript.back() != text:
		transcript.append(text)
		if transcript.size() > 80: transcript.pop_front()
	game.ui.say(text)

func interact(id: String) -> void:
	if stage >= 9 and act_two.interact(id):
		refresh()
		save_game()
		return
	match id:
		"envelope":
			var first_read := not has_flag("badge")
			flags.badge = true
			flags.C1_S1_ENTER = true
			collect_document("protocol", "Protocolo de Vigilância", Data.PROTOCOL)
			if first_read: game.director.envelope_event()
		"flashlight":
			if has_flag("flashlight"): return
			flags.flashlight = true
			game.player.equip_flashlight(true)
			game.world.objects.flashlight.hide()
			game.world.objects.flashlight.collision_layer = 0
			say("Lanterna equipada. Pressione F para ligar ou desligar.")
		"recorder":
			flags.recording = true
			game.sound.play("switch", game.world.objects.recorder.global_position)
			collect_document("recording", "Gravação 001 — transcrição", Data.SUPERVISOR)
		"logbook":
			if stage >= 2: flags.logbook = true
			collect_document("logbook", "Livro de registros", Data.LOGBOOK)
		"maintenance": collect_document("maintenance", "Manutenção", Data.MAINTENANCE)
		"emergency":
			if stage >= 2: flags.emergency = true
			say("Saída de emergência: fechada. Barra de segurança intacta. Inspeção registrada.")
		"diagram":
			collect_document("diagram", "Quadro do térreo — aviso", "DIAGRAMA RETIRADO PARA AUDITORIA\n\nConsulte a ordem de manutenção arquivada na administração, segundo andar.\nEstoque de cartuchos: sala de TI. Não energize o subsolo.")
		"repair_note":
			flags.repair_note_read = true
			collect_document("repair_note", "Ordem de manutenção", preload("res://scripts/chapter_two_data.gd").REPAIR_NOTE)
		"admin_notice": collect_document("admin_notice", "Aviso administrativo", preload("res://scripts/chapter_two_data.gd").ADMIN_NOTICE)
		"network_log": collect_document("network_log", "Diagnóstico de rede", preload("res://scripts/chapter_two_data.gd").NETWORK_LOG)
		"fuse20":
			if has_flag("fuse20_taken"): return
			flags.fuse20_owned = true
			flags.fuse20_taken = true
			game.world.upper.apply_state()
			say("Fusível 20 A guardado. Compare o calibre com a ordem de manutenção antes da troca.")
		"fuse10":
			flags.fuse10_owned = true
			say("Fusível 10 A guardado. A etiqueta adverte: utilize somente o calibre especificado para F1.")
		"fuse_slot":
			if stage != 4 or not has_flag("fault_inspected"): say("Inspecione primeiro o quadro elétrico.")
			elif has_flag("fuse_replaced"): say("Cartucho novo instalado. Agora é necessário rearmar na sequência correta.")
			elif breakers != [false, false, false, false]: say("Isole todos os circuitos antes de tocar no cartucho.")
			elif not has_flag("burnt_fuse_removed"):
				flags.burnt_fuse_removed = true
				say("Cartucho queimado retirado. O suporte F1 está vazio; instale uma reposição compatível.")
			elif not has_flag("fuse20_owned"):
				say("O fusível de 10 A é incompatível. Procure o calibre indicado na ordem de manutenção." if has_flag("fuse10_owned") else "Você ainda não tem uma reposição para F1. Estoque na TI, segundo andar.")
			else:
				flags.fuse_replaced = true
				flags.fuse20_owned = false
				game.sound.play("switch", game.world.objects.fuse_slot.position)
				say("Fusível de 20 A instalado. Retorne ao painel e execute a partida a frio.")
		"breakers":
			if stage < 4:
				say("Quadro sob controle da manutenção. Nenhuma falha detectada.")
				return
			if not has_flag("fault_inspected"):
				flags.fault_inspected = true
				breakers = [false, false, false, false]
				flags.power_sequence = []
				say("F1 queimado. Circuitos desarmados. Crachá autorizado para manutenção no segundo andar.")
			game.ui.show_breakers()
		"chair":
			if stage == 3 and has_flag("chair_report") and not has_flag("chair_inspected"):
				flags.chair_inspected = true
				game.director.inspect_chair()
			else: say("Cadeira do arquivo. Há riscos antigos no piso.")
		"phone":
			if stage >= 7:
				flags.phone_visited = true
				say("RAMAL 000. [A ligação termina antes de ser atendida.]")
			else: say("Telefone sem linha. O visor está apagado.")
		"report":
			if stage != 7: return
			var first_read := not has_flag("report_read")
			flags.report_read = true
			if not documents.has("report"): documents.append("report")
			game.ui.document("Relatório impossível", Data.REPORT, true)
			if first_read: game.director.report_read()
		"cam04":
			flags.cam04_label = true
			collect_document("cam04_label", "CAM-04 — etiqueta", "Alimentação presente.\nRACK 2B — PORTA 07.\nO diagnóstico do sinal depende da autorização da central.")
		"it_terminal", "network_patch": say("Diagnóstico de rede reservado à inspeção da CAM-04. O estoque de fusíveis fica na bancada.")
		"emergency_map": act_two.show_map()
	if id == "fuse_slot": game.world.upper.apply_state()
	refresh()
	save_game()

func can_open(id: String) -> bool:
	if id == "stairs" or id == "upper_gate":
		if stage == 15 or (stage < 9 and not has_flag("fault_inspected")) or stage == 9:
			say("Leitor sem alimentação. Procure uma rota alternativa pela administração." if stage == 15 else "Acesso restrito. O crachá só libera a escada mediante ordem de manutenção ou inspeção.")
			return false
	if id == "meeting" and stage < 14:
		say("Sala de reuniões lacrada pela auditoria.")
		return false
	if id == "service_upper" and stage < 15:
		say("Escada de serviço sob controle da auditoria. Utilize a escadaria principal.")
		return false
	if id == "service_exit" and not has_flag("alternate_route_unlocked"):
		say("Porta de serviço bloqueada pelo setor administrativo.")
		return false
	if id == "security" and not has_flag("badge"):
		say("A segurança está trancada. A chave e o crachá estão no envelope da recepção.")
		return false
	if id == "technical" and stage < 4:
		say("Sala técnica trancada. A manutenção controla o acesso.")
		return false
	return true

func _process(delta: float) -> void:
	if game == null or game.player == null: return
	elapsed += delta
	act_two.tick(delta)
	if stage == 0 and has_flag("badge") and game.world.in_security(game.player.position):
		advance(1)
	if stage == 5 and entity_steps >= 3 and not pending_threat and game.computer.active and game.computer.selected == 1:
		threat()

func use_terminal() -> void:
	if stage >= 9:
		refresh()
		return
	if stage == 0:
		say("Encontre o envelope e entre pela porta da segurança.")
		return
	if stage == 2 and has_flag("emergency") and has_flag("logbook"):
		if not has_flag("patrol_event"): game.director.patrol()
		advance(3)
	elif stage == 3 and has_flag("chair_moved"):
		advance(4)
	elif stage == 4 and has_flag("power"):
		advance(5)
	refresh()

func verify_camera(index: int, observation: int = -1) -> void:
	if stage != 1:
		say("A verificação de inicialização já foi concluída.")
		return
	if not has_flag("recording") or not has_flag("flashlight"):
		say("Antes da inspeção, ouça a gravação e pegue a lanterna na mesa.")
		return
	if observation != index:
		say("Compare a imagem com o elemento solicitado. Sem penalidade; tente novamente.")
		return
	if not verified.has(index): verified.append(index)
	say(["CAM-01: relógio visível — confirmado.", "CAM-02: porta técnica fechada — confirmado.", "CAM-03: cadeira diante da mesa — confirmado."][index])
	if verified.size() == 3: advance(2)
	refresh()
	save_game()

func report_anomaly(camera: int, category: int) -> bool:
	if stage == 3 and camera == 2 and category == 0:
		if not has_flag("chair_report"):
			flags.chair_report = true
			history.append("001 — CAM-03 / Objeto deslocado")
			say("OCORRÊNCIA 001 REGISTRADA. Verificação presencial recomendada no arquivo.")
	elif stage == 5 and camera == 1 and category == 1:
		if not has_flag("entity_report"):
			flags.entity_report = true
			history.append("002 — CAM-02 / Presença não autorizada")
			say("PRESENÇA CONFIRMADA. Permaneça na sala de segurança. Compare as transmissões.")
	else:
		say("Ocorrência não confirmada. Confira a câmera e a categoria. Você pode tentar novamente.")
		return false
	refresh()
	save_game()
	return true

func camera_changed(index: int, previous: int) -> void:
	if stage == 5 and has_flag("entity_report") and previous == 1 and index != 1 and entity_steps < 3:
		entity_steps += 1
		game.world.figure.position = entity_position()
		save_game()
	if stage == 6 and index == 0 and not has_flag("double_seen"):
		flags.double_seen = true
		say("OPERADOR: DANIEL REIS\nLOCALIZAÇÃO: RECEPÇÃO / SALA DE SEGURANÇA — ERRO DE SINCRONIZAÇÃO")
		game.computer.show_reflection()
		save_game()

func power_off_monitor() -> void:
	if stage == 6 and has_flag("double_seen"):
		game.computer.close()
		advance(7)
	else:
		say("Monitor desligado. Pressione E no computador para religar.")
		game.computer.close()
	game.computer.set_monitor_power(false)

func toggle_breaker(index: int) -> void:
	if stage != 4 or has_flag("power"): return
	breakers[index] = not breakers[index]
	if not flags.has("power_sequence"): flags.power_sequence = []
	if breakers[index]: flags.power_sequence.append(index)
	else: flags.power_sequence = []
	if index == 3 and breakers[3]:
		breakers[3] = false
		breakers = [false, false, false, false]
		flags.power_sequence = []
		say("AVISO: circuito D proibido. Proteção desarmou o subsolo. Tente novamente.")
		flicker()
	refresh()
	save_game()

func confirm_breakers() -> bool:
	if stage != 4: return false
	if has_flag("power"): return true
	if not has_flag("repair_note_read") or not has_flag("fuse_replaced"):
		say("A alimentação não estabiliza. Confira a ordem de manutenção e substitua o cartucho F1.")
		return false
	if breakers != [true, true, true, false] or flags.get("power_sequence", []) != [2, 0, 1]:
		say("Sequência de partida inválida. Isole o quadro e consulte novamente a nota arquivada no diário.")
		return false
	flags.power = true
	game.world.set_corridor_power(true)
	game.world.doors.technical.restore_open(false)
	say("[Três batidas na porta técnica. O corredor está vazio.]\nRádio: 'Não devia ter ligado a luz.'")
	game.ui.close_modal()
	game.director.technical_knocks()
	refresh()
	save_game()
	return true

func flicker() -> void:
	var generation := event_generation
	game.world.set_interior_power(false)
	game.sound.play("static", Vector3.ZERO, -18, false)
	await get_tree().create_timer(3.0, false).timeout
	if generation != event_generation: return
	game.world.set_interior_power(true)
	game.world.set_corridor_power(stage != 4 or has_flag("power"))

func threat() -> void:
	var generation := event_generation
	pending_threat = true
	# Keep the third approach visible before the transmission drops.
	await get_tree().create_timer(1.1, false).timeout
	if generation != event_generation: return
	game.world.figure.hide()
	game.world.doors.security.restore_open(false)
	game.world.doors.security.forced_locked = true
	game.computer.signal_lost = true
	game.sound.play("static", Vector3.ZERO, -10, false)
	game.sound.play("step", game.world.doors.security.global_position, -11)
	say("MOVIMENTO DETECTADO — SALA DE SEGURANÇA\n[Passos. A maçaneta se move. Aguarde dentro da segurança.]")
	var tween := create_tween()
	event_tweens.append(tween)
	for i in range(3):
		tween.tween_property(game.world.doors.security.handle, "rotation:z", -0.25, 0.5)
		tween.tween_property(game.world.doors.security.handle, "rotation:z", 0.0, 0.5)
	await get_tree().create_timer(3.5, false).timeout
	if generation != event_generation: return
	game.world.doors.security.forced_locked = false
	game.sound.play("step", Vector3(0, 0.2, -4), -20)
	pending_threat = false
	advance(6)
	game.computer.select_camera(0)

func advance(next: int) -> void:
	stage = next
	apply_world()
	match stage:
		1: say("00:00 — Segurança liberada. Pegue a lanterna e ouça a gravação de Augusto.")
		2: say("INSPEÇÃO CONCLUÍDA — RONDA PRESENCIAL OBRIGATÓRIA.")
		3: say("Nova imagem na CAM-03. Compare a posição da cadeira com a inspeção inicial.")
		4: say("CAM-02: porta técnica aberta. Falha de iluminação. Verificação presencial solicitada.")
		5: say("CAM-02: há alguém no corredor. Não saia da segurança.")
		6: say("A CAM-01 voltou. Há alguém com seu uniforme na recepção. Desligue o monitor.")
		7: say("A impressora liberou um relatório. Há algo errado com a data.")
	if stage == 7: game.sound.play("printer", game.world.objects.report.global_position, -12)
	refresh()
	save_game()

func entity_position() -> Vector3:
	return [Vector3(0, 0, -13), Vector3(0.2, 0, -7), Vector3(0.6, 0, -2), Vector3(1.45, 0.9, 2.6)][clampi(entity_steps, 0, 3)]

func apply_world() -> void:
	game.world.set_interior_power(true)
	game.player.equip_flashlight(has_flag("flashlight"))
	game.world.objects.flashlight.visible = not has_flag("flashlight")
	game.world.objects.flashlight.collision_layer = 0 if has_flag("flashlight") else 1
	game.world.chair.position = Vector3(5.5, 0, -6.5)
	if stage == 3:
		game.world.chair.position = Vector3(3.7 if has_flag("chair_moved") else 3.25, 0, -5)
	game.world.chair_marks.visible = stage == 3
	game.world.set_corridor_power(stage != 4 or has_flag("power"))
	if stage >= 4:
		game.world.doors.technical.restore_open(not has_flag("power"))
	game.world.figure.visible = stage == 5
	game.world.figure.position = entity_position()
	game.world.double.visible = stage == 6
	if stage == 6:
		game.world.double.position = Vector3(0, 0, 8)
		game.world.double.get_meta("envelope").hide()
		var tween := create_tween()
		event_tweens.append(tween)
		tween.tween_property(game.world.double, "position", Vector3(-2.7, 0, 8.2), 3.0)
		tween.tween_callback(func(): game.world.double.get_meta("envelope").show())
		tween.tween_property(game.world.double, "rotation:y", 0.7, 0.8)
		tween.tween_callback(func():
			game.world.double.look_at(Vector3(5.5, 0, 11.4))
			game.world.double.rotate_y(PI))
	game.world.objects.report.visible = stage >= 7
	game.world.objects.report.collision_layer = 1 if stage >= 7 else 0
	game.world.set_time("01:00" if stage >= 8 or has_flag("phone_stopped") else ("00:59" if stage == 7 else ("00:00" if has_flag("badge") else "23:57")))
	game.computer.signal_lost = false
	game.computer.set_monitor_power((stage < 7 or stage >= 9) and has_flag("terminal_booted"))
	act_two.apply_world()
	if stage >= 9:
		game.world.set_time(["01:00", "01:01", "01:01", "01:02", "01:02", "01:23", "01:42", "01:51", "01:57", "02:00"][clampi(stage - 9, 0, 9)])

func refresh() -> void:
	game.ui.update_objective(stage, objective())
	game.computer.update_status()

func complete() -> void:
	if stage != 7 or not has_flag("report_read"): return
	advance(8)
	game.ui.show_ending()

func serialize_state() -> Dictionary:
	var point: Vector3 = game.player.position
	var door_states := {}
	for id in game.world.doors: door_states[id] = game.world.doors[id].is_open
	return {"version": SAVE_VERSION, "stage": stage, "flags": flags.duplicate(true), "documents": documents.duplicate(), "transcript": transcript.duplicate(), "flashlight_on": game.player.flashlight.visible, "pitch": game.player.camera.rotation.x, "verified": verified.duplicate(), "history": history.duplicate(), "breakers": breakers.duplicate(), "entity_steps": entity_steps, "elapsed": elapsed, "position": [point.x, maxf(point.y, 0.05), point.z], "yaw": game.player.rotation.y, "doors": door_states}

func save_game() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		say("Não foi possível gravar o checkpoint.")
		return false
	file.store_string(JSON.stringify(serialize_state()))
	file.close()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		say("Nenhum checkpoint salvo. Inicie sua primeira noite.")
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null: return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("version") != SAVE_VERSION or not data.get("stage") is float:
		say("Checkpoint inválido. Use Nova partida para recomeçar.")
		return false
	if int(data.stage) < 0 or int(data.stage) > 18 or not data.get("flags") is Dictionary or not data.get("position") is Array or data.position.size() != 3:
		return false
	if not data.get("verified") is Array or not data.get("history") is Array or not data.get("breakers") is Array or data.breakers.size() != 4:
		return false
	if not data.get("documents", []) is Array or not data.get("transcript", []) is Array or not data.get("doors", {}) is Dictionary:
		return false
	event_generation += 1
	pending_threat = false
	for tween in event_tweens:
		if tween.is_valid(): tween.kill()
	event_tweens.clear()
	game.world.doors.security.forced_locked = false
	game.ui.close_modal()
	game.computer.close()
	stage = int(data.stage)
	flags = data.flags
	documents = data.get("documents", [])
	transcript = data.get("transcript", [])
	if not data.has("documents"):
		for pair in [["badge", "protocol"], ["recording", "recording"], ["logbook", "logbook"], ["diagram_read", "diagram"], ["report_read", "report"]]:
			if has_flag(pair[0]): documents.append(pair[1])
	verified = data.get("verified", [])
	history = data.get("history", [])
	breakers = data.get("breakers", [true, false, true, false])
	entity_steps = int(data.get("entity_steps", 0))
	elapsed = float(data.get("elapsed", 0))
	apply_world()
	game.director.reset()
	game.player.flashlight.visible = has_flag("flashlight") and bool(data.get("flashlight_on", true))
	var point := Vector3(float(data.position[0]), float(data.position[1]), float(data.position[2]))
	game.player.position = point
	game.player.velocity = Vector3.ZERO
	game.player.rotation.y = float(data.get("yaw", 0))
	game.player.camera.rotation.x = clampf(float(data.get("pitch", 0)), -1.4, 1.4)
	for id in data.get("doors", {}):
		if game.world.doors.has(id): game.world.doors[id].restore_open(bool(data.doors[id]))
	refresh()
	say("Checkpoint carregado — " + (preload("res://scripts/chapter_two_data.gd").TITLES[stage - 9] if stage >= 9 else Data.TITLES[stage]))
	if stage == 8: game.ui.show_ending()
	if stage == 18: game.ui.show_ending(2)
	return true
