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

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--smoke-test"):
		save_path = "user://chapter1-test.json"

func has_flag(id: String) -> bool:
	return bool(flags.get(id, false))

func objective() -> String:
	match stage:
		0: return "Recepção: encontre o envelope sobre o balcão e recolha seu crachá/chave." if not has_flag("badge") else "Entre na sala de segurança — primeira porta à esquerda no corredor."
		1:
			if not has_flag("flashlight"): return "Pegue a lanterna sobre a mesa da segurança."
			if not has_flag("recording"): return "Reproduza a gravação 001 sobre a mesa da segurança."
			return "No computador: confira relógio, porta e cadeira. Confirme cada câmera (%d/3)." % verified.size()
		2: return "Ronda: inspecione a saída de emergência e leia o livro no arquivo. Depois retorne ao terminal."
		3:
			if not has_flag("chair_report"): return "CAM-03: encontre a alteração e reporte 'Objeto deslocado'."
			if not has_flag("chair_inspected"): return "Vá ao arquivo e examine a cadeira deslocada junto à porta."
			return "Retorne ao terminal para conferir a cadeira."
		4:
			if not has_flag("power"): return "Sala técnica: leia o diagrama e restaure os circuitos A/B/C. Mantenha D desligado."
			return "Volte à segurança e confira a CAM-02 no terminal."
		5:
			if not has_flag("entity_report"): return "CAM-02: reporte 'Presença não autorizada'."
			return "Observe a CAM-02 e alterne com outras câmeras. Permaneça na segurança."
		6: return "CAM-01 mostra você na recepção. Siga o protocolo: DESLIGUE O MONITOR."
		7: return "Leia o relatório impresso ao lado do computador. O telefone da recepção é opcional."
	return "O Primeiro Turno — concluído."

func say(text: String) -> void:
	game.ui.say(text)

func interact(id: String) -> void:
	match id:
		"envelope":
			var first_read := not has_flag("badge")
			flags.badge = true
			game.world.set_time("00:00")
			game.ui.document("Protocolo de Vigilância", Data.PROTOCOL)
			if first_read: say("[Telefone: um único toque. O relógio salta para 00:00.]\nDaniel: 'Certo. Só uma noite de trabalho.'")
		"flashlight":
			if has_flag("flashlight"): return
			flags.flashlight = true
			game.player.equip_flashlight(true)
			game.world.objects.flashlight.hide()
			game.world.objects.flashlight.collision_layer = 0
			say("Lanterna equipada. Pressione F para ligar ou desligar.")
		"recorder":
			flags.recording = true
			game.ui.document("Gravação 001 — legendada", Data.SUPERVISOR)
		"logbook":
			if stage >= 2: flags.logbook = true
			game.ui.document("Livro de registros", Data.LOGBOOK)
		"maintenance": game.ui.document("Manutenção", Data.MAINTENANCE)
		"emergency":
			if stage >= 2: flags.emergency = true
			say("Saída de emergência: fechada. Barra de segurança intacta. Inspeção registrada.")
		"stairs": say("Acesso à escada bloqueado. Não tente acessar o subsolo.")
		"diagram": game.ui.document("Diagrama elétrico", Data.DIAGRAM)
		"breakers":
			if stage < 4:
				say("Quadro sob controle da manutenção. Nenhuma falha detectada.")
				return
			game.ui.show_breakers()
		"chair":
			if stage == 3 and has_flag("chair_report") and not has_flag("chair_inspected"):
				flags.chair_inspected = true
				var tween := create_tween()
				event_tweens.append(tween)
				tween.tween_property(game.world.chair, "position:x", 3.7, 1.5)
				say("[A cadeira se arrasta alguns centímetros. Marcas recentes cortam o piso.]\nDaniel: 'Eu vi isso se mexer.'")
			else: say("Cadeira do arquivo. Há riscos antigos no piso.")
		"phone":
			if stage >= 7: say("RAMAL 000. [A ligação termina antes de ser atendida.]")
			else: say("Telefone sem linha. O visor está apagado.")
		"report":
			if stage != 7: return
			flags.report_read = true
			game.ui.document("Relatório impossível", Data.REPORT, true)
			game.world.set_time("01:00")
			say("[Telefone da recepção: RAMAL 000.]\nAugusto: 'Primeira hora concluída. Isso aconteceu da última vez também.'")
	refresh()
	save_game()

func can_open(id: String) -> bool:
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
	if stage == 0 and has_flag("badge") and game.world.in_security(game.player.position):
		advance(1)
	if stage == 2 and has_flag("emergency") and has_flag("logbook") and not has_flag("patrol_event"):
		flags.patrol_event = true
		say("[Na volta, a luz oscila. Passos atrás de você. O corredor está vazio.]")
		flicker()
	if stage == 5 and entity_steps >= 3 and not pending_threat:
		threat()

func use_terminal() -> void:
	if stage == 0:
		say("Encontre o envelope e entre pela porta da segurança.")
		return
	if stage == 2 and has_flag("emergency") and has_flag("logbook"):
		advance(3)
	elif stage == 3 and has_flag("chair_inspected"):
		advance(4)
	elif stage == 4 and has_flag("power"):
		advance(5)
	refresh()

func verify_camera(index: int) -> void:
	if stage != 1:
		say("A verificação de inicialização já foi concluída.")
		return
	if not has_flag("recording") or not has_flag("flashlight"):
		say("Antes da inspeção, ouça a gravação e pegue a lanterna na mesa.")
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
		game.world.figure.position = Vector3(0, 0, -13 + entity_steps * 4.5)
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
	if index == 3 and breakers[3]:
		breakers[3] = false
		say("AVISO: circuito D proibido. Proteção desarmou o subsolo. Tente novamente.")
		flicker()
	refresh()
	save_game()

func confirm_breakers() -> bool:
	if stage != 4: return false
	if breakers != [true, true, true, false]:
		say("Circuitos incorretos. Consulte o diagrama ao lado: A/B/C ligados; D desligado.")
		return false
	flags.power = true
	game.world.set_corridor_power(true)
	game.world.doors.technical.restore_open(false)
	say("[Três batidas na porta técnica. O corredor está vazio.]\nRádio: 'Não devia ter ligado a luz.'")
	game.ui.close_modal()
	refresh()
	save_game()
	return true

func flicker() -> void:
	game.world.set_corridor_power(false)
	await get_tree().create_timer(0.65, false).timeout
	game.world.set_corridor_power(stage != 4 or has_flag("power"))

func threat() -> void:
	var generation := event_generation
	pending_threat = true
	game.world.figure.hide()
	game.world.doors.security.restore_open(false)
	game.world.doors.security.forced_locked = true
	game.computer.signal_lost = true
	say("MOVIMENTO DETECTADO — SALA DE SEGURANÇA\n[Passos. A maçaneta se move. Aguarde dentro da segurança.]")
	var tween := create_tween()
	event_tweens.append(tween)
	for i in range(3):
		tween.tween_property(game.world.doors.security.pivot, "rotation:y", 0.07, 0.3)
		tween.tween_property(game.world.doors.security.pivot, "rotation:y", 0.0, 0.3)
	await get_tree().create_timer(3.5, false).timeout
	if generation != event_generation: return
	game.world.doors.security.forced_locked = false
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
	refresh()
	save_game()

func apply_world() -> void:
	game.player.equip_flashlight(has_flag("flashlight"))
	game.world.objects.flashlight.visible = not has_flag("flashlight")
	game.world.objects.flashlight.collision_layer = 0 if has_flag("flashlight") else 1
	game.world.chair.position = Vector3(5.5, 0, -6.5)
	if stage == 3:
		game.world.chair.position = Vector3(3.7 if has_flag("chair_inspected") else 3.25, 0, -5)
	game.world.set_corridor_power(stage != 4 or has_flag("power"))
	if stage >= 4:
		game.world.doors.technical.restore_open(not has_flag("power"))
	game.world.figure.visible = stage == 5 and entity_steps < 3
	game.world.figure.position = Vector3(0, 0, -13 + entity_steps * 4.5)
	game.world.double.visible = stage == 6
	if stage == 6:
		game.world.double.position = Vector3(0, 0, 8)
		var tween := create_tween()
		event_tweens.append(tween)
		tween.tween_property(game.world.double, "position", Vector3(-2.7, 0, 8.2), 3.0)
	game.world.objects.report.visible = stage >= 7
	game.world.objects.report.collision_layer = 1 if stage >= 7 else 0
	game.world.set_time("01:00" if stage >= 7 else ("00:00" if has_flag("badge") else "23:57"))
	game.computer.signal_lost = false
	game.computer.set_monitor_power(stage < 7)

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
	return {"version": SAVE_VERSION, "stage": stage, "flags": flags.duplicate(true), "verified": verified.duplicate(), "history": history.duplicate(), "breakers": breakers.duplicate(), "entity_steps": entity_steps, "elapsed": elapsed, "position": [point.x, maxf(point.y, 0.05), point.z], "yaw": game.player.rotation.y, "doors": door_states}

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
	if int(data.stage) < 0 or int(data.stage) > 8 or not data.get("flags") is Dictionary or not data.get("position") is Array or data.position.size() != 3:
		return false
	if not data.get("verified") is Array or not data.get("history") is Array or not data.get("breakers") is Array or data.breakers.size() != 4:
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
	verified = data.get("verified", [])
	history = data.get("history", [])
	breakers = data.get("breakers", [true, false, true, false])
	entity_steps = int(data.get("entity_steps", 0))
	elapsed = float(data.get("elapsed", 0))
	apply_world()
	var point := Vector3(float(data.position[0]), float(data.position[1]), float(data.position[2]))
	game.player.position = point
	game.player.velocity = Vector3.ZERO
	game.player.rotation.y = float(data.get("yaw", 0))
	game.player.camera.rotation.x = 0
	for id in data.get("doors", {}):
		if game.world.doors.has(id): game.world.doors[id].restore_open(bool(data.doors[id]))
	refresh()
	say("Checkpoint carregado — " + Data.TITLES[stage])
	if stage == 8: game.ui.show_ending()
	return true
