extends RefCounted

const Building = preload("res://scripts/building_layout.gd")

const Data = preload("res://scripts/chapter_two_data.gd")
var game: Node
var future_timer := -1.0
var step_distance := 0.0
var last_point := Vector3.ZERO
var finish_pending := false

func begin() -> void:
	game.ui.reset_ending()
	game.world.doors.stairs.restore_open(false)
	game.chapter.advance(9)
	game.chapter.say("01:00 — Registros Incompletos\nDaniel: 'O relatório tem meu nome. Preciso falar com alguém.'")

func objective() -> String:
	var chapter: Node = game.chapter
	match chapter.stage:
		9:
			if not chapter.has_flag("c2_report_reviewed"): return "Reexamine o relatório impossível na impressora da segurança."
			if not chapter.has_flag("c2_call_failed"): return "Tente contatar a central pelo telefone da recepção."
			return "Verifique o alerta CAM-04 no terminal e confirme a autorização de acesso."
		10: return "Use o crachá na escadaria e suba ao segundo andar."
		11: return "Examine a CAM-04, sua luz de alimentação e a etiqueta do cabeamento no corredor."
		12: return "Sala de TI: cruze a etiqueta da câmera com o rack e restabeleça a conexão."
		13:
			if not chapter.has_flag("future_recording_watched"): return "No terminal da TI, reproduza o buffer recuperado da CAM-04."
			return "Saia da TI. Você pode segurar a porta ao vê-la se fechar ou permitir o evento."
		14: return "Sala de reuniões: compare a ata, o controle de acesso e o arquivo CAM-05. Identifique quem não entrou."
		15: return "A escadaria principal está bloqueada. Consulte a planta e procure a escada de serviço pela administração."
		16: return "Retorne à segurança pela passagem de serviço. Examine o arquivo de 15/11 e tente apagá-lo."
		17: return "Leia o novo relatório na impressora e confronte Augusto."
	return "Registros Incompletos — concluído."

func interact(id: String) -> bool:
	var chapter: Node = game.chapter
	match id:
		"report":
			if chapter.stage == 9:
				chapter.flags.c2_report_reviewed = true
				chapter.collect_document("report", "Relatório impossível — 11/11", preload("res://scripts/chapter_data.gd").REPORT)
			elif chapter.stage == 17:
				chapter.flags.c2_final_report_read = true
				chapter.collect_document("report2", "Ocorrência 002 — Divergência temporal", Data.report(chapter.has_flag("future_event_resisted")))
			else: chapter.say("A impressora aguarda uma nova ocorrência.")
		"phone":
			if chapter.stage == 9 and chapter.has_flag("c2_report_reviewed"):
				chapter.flags.c2_call_failed = true
				game.world.phone_display.text = "SEM CONEXÃO"
				game.sound.play("static", game.world.objects.phone.position, -19)
				chapter.collect_document("failed_call", "Ligação não completada / rádio", Data.CALL)
				game.world.set_time("01:01")
			else: chapter.say("A ligação não pode ser completada. Não há conexão com a central.")
		"cam04":
			chapter.flags.cam04_label = true
			if chapter.stage in [10, 11]:
				chapter.flags.cam04_inspected = true
				chapter.advance(12)
			chapter.collect_document("cam04_label", "CAM-04 — inspeção física", "LED aceso. Cabo conectado. Alimentação presente.\nEtiqueta: RACK 2B — PORTA 07.\n\nO problema está no encaminhamento do sinal, não na energia.")
		"network_patch":
			if chapter.stage < 12: chapter.say("O diagnóstico de rede depende da autorização de inspeção da CAM-04.")
			else: game.ui.show_network_patch()
		"it_terminal", "meeting_terminal", "cam05":
			game.computer.interact()
			game.computer.select_camera(3 if id == "it_terminal" else 4)
		"knock_door":
			var count := int(chapter.flags.get("answer_knocks", 0))
			if count < 2:
				chapter.flags.answer_knocks = count + 1
				answer_knocks(count)
			else: chapter.say("[Silêncio atrás da porta.]")
		"meeting_minutes": chapter.collect_document("meeting_minutes", "Ata da reunião", Data.MINUTES)
		"access_log": chapter.collect_document("access_log", "Controle de acesso", Data.ACCESS)
		"henrique_photo":
			if chapter.has_flag("henrique_identified"): chapter.collect_document("henrique_photo", "Henrique Almeida", Data.PHOTO)
			else: chapter.say("Uma fotografia sem identificação. Primeiro compare os registros da reunião.")
		"emergency_map":
			chapter.flags.emergency_map_read = true
			show_map()
		"voice_door":
			if chapter.stage == 15: voice_event()
			else: chapter.say("Porta fechada. Vidro opaco por dentro.")
		_: return false
	return true

func acknowledge_alert() -> bool:
	var chapter: Node = game.chapter
	if chapter.stage != 9: return false
	if not chapter.has_flag("c2_report_reviewed") or not chapter.has_flag("c2_call_failed"):
		chapter.say("Reexamine o relatório e tente contatar a central antes de aceitar uma nova inspeção.")
		return false
	chapter.flags.C2_S1_CAMERA_ALERT_ACKNOWLEDGED = true
	chapter.advance(10)
	chapter.say("CAM-04 OFFLINE — ÚLTIMA TRANSMISSÃO: 01:03:17\nAugusto: 'Seu crachá libera a escada. É apenas uma câmera.'")
	return true

func restore_network(port: int) -> bool:
	var chapter: Node = game.chapter
	if chapter.stage != 12: return false
	chapter.flags.patch_port = port
	if not chapter.has_flag("cam04_inspected") or not chapter.has_flag("cam04_label") or port != 7:
		chapter.say("Sem retorno do gravador. Confira o rack e a porta indicados na etiqueta do equipamento.")
		chapter.save_game()
		return false
	chapter.flags.cam04_restored = true
	chapter.history.append("003 — CAM-04 / Conectividade restaurada")
	game.sound.play("switch", game.world.objects.network_patch.position)
	chapter.advance(13)
	chapter.say("STREAM RECOVERED — PLAYBACK BUFFER AVAILABLE\nO log indica 01:03:17. Ainda são 01:02.")
	game.ui.close_modal()
	return true

func available_recording() -> String:
	match game.chapter.stage:
		13: return "future"
		14: return "meeting"
		16: return "tomorrow"
	return ""

func watch_recording(kind: String) -> bool:
	if kind != available_recording() or not game.computer.active: return false
	if kind == "tomorrow" and not game.world.in_security(game.player.position):
		game.chapter.say("O arquivo protegido só está disponível na estação de segurança.")
		return false
	game.computer.play_recording(kind)
	return true

func recording_finished(kind: String) -> void:
	var chapter: Node = game.chapter
	match kind:
		"future":
			chapter.flags.future_recording_watched = true
			chapter.say("Daniel: 'Isso não aconteceu... Eu ainda estou aqui.'\n[O buffer mostra a saída da TI e a porta se fechando.]")
		"meeting":
			chapter.flags.meeting_recording_watched = true
			chapter.say("CAM-05 / 23h35–23h39 — cinco entradas registradas. A ata lista seis participantes.")
		"tomorrow":
			chapter.flags.tomorrow_recording_watched = true
			chapter.say("15/11/2008 — 00:00\nFuncionário: 'Alô? Tem alguém aqui?'\nAugusto: 'Boa noite. Seu turno começa à meia-noite.'")
	chapter.refresh()
	chapter.save_game()

func resolve_future(resisted: bool) -> void:
	var chapter: Node = game.chapter
	if chapter.stage != 13 or not chapter.has_flag("future_recording_watched"): return
	if not chapter.has_flag("future_door_pending"): return
	future_timer = -1
	chapter.flags.future_door_pending = false
	chapter.flags.future_event_resisted = resisted
	chapter.flags.future_event_resolved = true
	game.world.doors.it.custom_prompt = ""
	game.world.doors.it.restore_open(resisted)
	game.sound.play("knock", game.world.doors.it.position, -10)
	chapter.advance(14)
	chapter.say("INCONSISTÊNCIA REGISTRADA — evento alterado pelo operador." if resisted else "[A porta bate exatamente como no buffer. Evento previsto reproduzido.]")

func identify_participant(index: int) -> bool:
	var chapter: Node = game.chapter
	if chapter.stage != 14: return false
	if not chapter.documents.has("meeting_minutes") or not chapter.documents.has("access_log") or not chapter.has_flag("meeting_recording_watched"):
		chapter.say("Compare a ata, o registro de acesso e a gravação antes de concluir a investigação.")
		return false
	if index != 5:
		chapter.say("Essa pessoa possui registro de entrada. Confira novamente as evidências.")
		return false
	chapter.flags.henrique_identified = true
	chapter.history.append("004 — Reunião / Henrique Almeida sem entrada registrada")
	if game.computer.recording.active: game.computer.stop_recording()
	chapter.advance(15)
	var ghost: Node3D = game.world.upper.camera_chair
	ghost.position = Building.upper_point(Vector3(7.2, 0, -39.7))
	var tween := game.create_tween()
	chapter.event_tweens.append(tween)
	tween.tween_property(ghost, "position:z", 0.35, 2.0)
	chapter.collect_document("henrique_photo", "Henrique Almeida — fotografia", Data.PHOTO)
	chapter.say("Augusto: 'Onde você ouviu esse nome? Daniel, saia do segundo andar. Agora.'\n[A alimentação da escadaria cai. Na CAM-05, a sexta cadeira recua; na sala, ela não se move.]")
	chapter.save_game()
	return true

func delete_tomorrow() -> bool:
	var chapter: Node = game.chapter
	if chapter.stage != 16 or not chapter.has_flag("tomorrow_recording_watched"): return false
	chapter.flags.mimesis_discovered = true
	chapter.history.append("005 — Arquivo protegido / ORIGEM: MÍMESIS")
	game.computer.close()
	chapter.advance(17)
	chapter.say("ARQUIVO PROTEGIDO — ORIGEM: MÍMESIS\n[A impressora começa a trabalhar.]")
	game.sound.play("printer", game.world.objects.report.position, -12)
	return true

func show_map() -> void:
	game.ui.show_floor_plan(load("res://assets/signage/second_floor.svg"), "2º ANDAR — 1 Administração / 2 TI / 3 Reuniões", "Escada principal ao norte. A rota vermelha indica a saída oeste da administração e a escada de serviço, que desemboca na segurança.")

func apply_world() -> void:
	game.world.upper.apply_state()
	if game.chapter.stage >= 15:
		game.world.doors.upper_gate.restore_open(false)
	game.world.doors.it.override_action = func() -> bool:
		if game.chapter.has_flag("future_door_pending"):
			resolve_future(true)
			return true
		return false
	game.world.doors.it.custom_prompt = "E — Segurar a porta" if game.chapter.has_flag("future_door_pending") else ""
	future_timer = 3.5 if game.chapter.has_flag("future_door_pending") else -1
	finish_pending = false

func tick(delta: float) -> void:
	var chapter: Node = game.chapter
	var point: Vector3 = game.player.position
	var distance := point.distance_to(last_point)
	last_point = point
	if game.world.staircases.is_main(point) and game.player.controls_enabled and distance < 0.5:
		step_distance += distance
		if step_distance > 1.65:
			step_distance = 0
			game.sound.play("step", point + Vector3(0, 2, -2), -16)
	if chapter.stage == 10 and point.y > 4 and point.z > -13.8 and absf(point.x) < 1.6:
		chapter.advance(11)
	if chapter.stage == 11 and point.distance_to(Building.upper_point(Vector3(-1.6, 4.2, -36))) < 2 and not chapter.has_flag("corridor_knocks"):
		chapter.flags.corridor_knocks = true
		answer_knocks(-1)
	if chapter.stage == 13 and chapter.has_flag("future_recording_watched") and not chapter.has_flag("future_event_resolved"):
		if future_timer < 0 and point.y > 4 and absf(point.z - 2) < 1.2 and point.x > -1.3 and point.x < 1.5 and not game.computer.active:
			chapter.flags.future_door_pending = true
			future_timer = 3.5
			game.world.doors.it.custom_prompt = "E — Segurar a porta"
			game.world.doors.it.restore_open(true)
			game.world.doors.it.set_open(false)
			chapter.say("[A porta começa a fechar.] Aproxime a mira e pressione E para segurá-la, ou afaste-se.")
			chapter.save_game()
		if future_timer >= 0 and game.player.controls_enabled:
			future_timer -= delta
			if future_timer <= 0: resolve_future(false)
	if chapter.stage == 15:
		if point.distance_to(game.world.objects.voice_door.position) < 3: voice_event()
		if point.x < -8.4 and point.y > 3.5 and game.world.staircases.is_service(point):
			chapter.flags.service_crossed = true
			var toward: Vector3 = (game.world.upper.warning.global_position - game.player.camera.global_position).normalized()
			var looking: float = (-game.player.camera.global_transform.basis.z).dot(toward)
			if looking > 0.75:
				if chapter.has_flag("service_looked_away"): chapter.flags.service_message_gone = true
				chapter.flags.service_message_seen = true
			elif chapter.has_flag("service_message_seen"): chapter.flags.service_looked_away = true
			game.world.upper.warning.visible = not chapter.has_flag("service_message_gone")
		if chapter.has_flag("service_crossed") and game.world.staircases.is_service(point) and point.y < 0.5 and point.z < -7:
			chapter.flags.alternate_route_unlocked = true
			chapter.advance(16)
	if chapter.stage == 17 and chapter.has_flag("c2_final_report_read") and not game.ui.modal and not finish_pending:
		finish_chapter()

func answer_knocks(attempt: int) -> void:
	var token: int = game.chapter.event_generation
	var point: Vector3 = game.world.objects.knock_door.position if attempt < 1 else game.world.doors.meeting.position
	for index in range(3):
		game.sound.play("knock", point, -12)
		await game.get_tree().create_timer(0.55, false).timeout
		if token != game.chapter.event_generation: return
	if attempt == 1:
		game.world.doors.meeting.restore_open(true)
		game.chapter.say("[A resposta veio da porta atrás de você. Ela está entreaberta.]")

func voice_event() -> void:
	if game.chapter.has_flag("voice_shadow_seen"): return
	game.chapter.flags.voice_shadow_seen = true
	game.chapter.say("Voz de Daniel, atrás da porta: 'Não abre. Eu já tentei.'")
	var shadow: MeshInstance3D = game.world.upper.window_shadow
	shadow.show()
	var tween := game.create_tween()
	game.chapter.event_tweens.append(tween)
	tween.tween_property(shadow, "position:x", 0.35, 0.45)
	tween.tween_callback(shadow.hide)
	game.chapter.save_game()

func finish_chapter() -> void:
	finish_pending = true
	var token: int = game.chapter.event_generation
	game.chapter.say("Augusto: 'Daniel, você fez um bom trabalho.'\nDaniel: 'O que é MÍMESIS? O que vocês estão fazendo comigo?'")
	await game.get_tree().create_timer(5.0, false).timeout
	if token != game.chapter.event_generation: return
	game.chapter.say("Augusto: 'Não deveria ter encontrado esse nome. Nós não estamos fazendo nada. Estamos apenas observando.'")
	await game.get_tree().create_timer(5.0, false).timeout
	if token != game.chapter.event_generation: return
	game.chapter.advance(18)
	game.computer.interact()
	game.computer.select_camera(3)
	game.computer.show_empty_security()
	game.world.figure.position = Vector3(-6.1, 0, 2.65)
	game.world.figure.show()
	game.chapter.say("PERFIL COMPORTAMENTAL ATUALIZADO — 68%\nREFERÊNCIA: HENRIQUE ALMEIDA\n[A CAM-04 mostra Henrique na cadeira da segurança.]")
	await game.get_tree().create_timer(3.0, false).timeout
	if token != game.chapter.event_generation: return
	game.computer.close()
	game.ui.show_ending(2)
