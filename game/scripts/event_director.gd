extends Node

var game: Node
var generation := 0
var chair_wait := -1.0
var final_wait := -1.0
var ring_wait := 0.0
var warning_wait := 0.0
var final_started := false

func claim(id: String) -> bool:
	if game.chapter.has_flag(id): return false
	game.chapter.flags[id] = true
	return true

func reset() -> void:
	generation += 1
	chair_wait = 0 if game.chapter.has_flag("chair_inspected") and not game.chapter.has_flag("chair_moved") and game.chapter.stage == 3 else -1
	final_wait = 0 if game.chapter.has_flag("report_read") and game.chapter.stage == 7 else -1
	final_started = false
	game.world.phone_display.text = "RAMAL 000" if final_wait >= 0 else "SEM LINHA"
	if game.chapter.stage == 4 and game.chapter.has_flag("power") and not game.chapter.has_flag("technical_complete"):
		call_deferred("technical_knocks")

func arrival() -> void:
	if not claim("C1_S1_ENTER"): return
	game.chapter.say("Daniel: 'Vesper. Setor administrativo. Vamos terminar esse turno.'")
	game.chapter.save_game()

func envelope_event() -> void:
	if not claim("C1_S1_CLOCK"): return
	var token := generation
	game.world.set_time("23:59")
	await get_tree().create_timer(0.7, false).timeout
	if token != generation: return
	game.world.set_time("00:00")
	game.sound.play("ring", game.world.objects.phone.global_position, -16)
	game.chapter.say("[O telefone toca uma única vez. O ponteiro permanece imóvel.]\nDaniel: 'Certo. Só uma noite de trabalho.'")

func patrol() -> void:
	if not claim("patrol_event"): return
	var token := generation
	for index in range(3):
		game.world.set_corridor_power(false)
		if index == 2:
			game.sound.play("step", game.player.position + game.player.transform.basis.z * 2, -13)
		await get_tree().create_timer(0.32, false).timeout
		if token != generation: return
		game.world.set_corridor_power(true)
		await get_tree().create_timer(0.65, false).timeout
		if token != generation: return
	game.chapter.say("[Passos atrás de você. O corredor está vazio.]")
	game.chapter.save_game()

func inspect_chair() -> void:
	if chair_wait >= 0 or game.chapter.has_flag("chair_moved"): return
	chair_wait = 0
	game.chapter.say("[Marcas recentes cortam o piso. Algo foi arrastado até a porta.]")

func move_chair() -> void:
	chair_wait = -1
	if not claim("chair_moved"): return
	game.sound.play("drag", game.world.chair.global_position, -10)
	var tween := create_tween()
	game.chapter.event_tweens.append(tween)
	tween.tween_property(game.world.chair, "position:x", 3.7, 1.5)
	game.chapter.say("[A cadeira se arrasta lentamente.]\nDaniel: 'Eu vi isso se mexer.'")
	game.chapter.refresh()
	game.chapter.save_game()

func technical_knocks() -> void:
	if game.chapter.has_flag("technical_complete"): return
	game.chapter.flags.technical_knocks = true
	var token := generation
	for index in range(int(game.chapter.flags.get("knock_count", 0)), 3):
		game.sound.play("knock", game.world.doors.technical.global_position, -5)
		game.chapter.flags.knock_count = index + 1
		game.chapter.save_game()
		await get_tree().create_timer(0.65, false).timeout
		if token != generation: return
	game.sound.play("static", Vector3(-7, 1.5, -10), -13)
	game.chapter.say("Rádio: 'Não devia ter ligado a luz.'")
	game.chapter.flags.technical_complete = true
	game.chapter.save_game()

func report_read() -> void:
	if final_wait >= 0: return
	final_wait = 0
	ring_wait = 0
	game.world.phone_display.text = "RAMAL 000"
	game.chapter.say("[O telefone da recepção está tocando. No visor: RAMAL 000.]\nVocê pode investigar ou permanecer na segurança.")

func finish() -> void:
	if final_started: return
	final_started = true
	var token := generation
	game.sound.play("static", Vector3.ZERO, -23, false)
	game.world.set_time("01:00")
	game.chapter.say("Augusto: 'Primeira hora concluída, Daniel.'")
	await get_tree().create_timer(3.5, false).timeout
	if token != generation: return
	game.chapter.say("Augusto: 'O sistema registrou algumas inconsistências, mas não se preocupe.'")
	await get_tree().create_timer(5.0, false).timeout
	if token != generation: return
	game.chapter.say("Augusto: 'Isso aconteceu da última vez também.'")
	await get_tree().create_timer(3.0, false).timeout
	if token != generation: return
	game.chapter.complete()

func _process(delta: float) -> void:
	var chapter: Node = game.chapter
	var point: Vector3 = game.player.position
	if chapter.stage == 0 and point.z < 11.5: arrival()
	if chapter.stage == 2 and chapter.has_flag("emergency") and chapter.has_flag("logbook") and point.x < 2 and point.z > -7:
		patrol()
	if chair_wait >= 0 and chapter.stage == 3 and not game.ui.modal:
		chair_wait += delta
		var direction: Vector3 = (game.world.chair.global_position + Vector3.UP * 0.6 - game.player.camera.global_position).normalized()
		var looking: bool = (-game.player.camera.global_transform.basis.z).dot(direction) > 0.82
		if (not looking and chair_wait > 0.7) or chair_wait > 9.0: move_chair()
	if chapter.stage == 6:
		warning_wait += delta
		if warning_wait > 14:
			warning_wait = 0
			game.sound.play("static", Vector3.ZERO, -20, false)
			chapter.say("Augusto: 'Daniel... desligue a câmera.'")
	if final_wait >= 0 and chapter.stage == 7 and not game.ui.modal and not final_started:
		final_wait += delta
		ring_wait -= delta
		var near_phone := point.distance_to(game.world.objects.phone.global_position) < 2.5
		if near_phone or chapter.has_flag("phone_ignored") or chapter.has_flag("phone_stopped") or final_wait > 24:
			chapter.flags.phone_stopped = true
			finish()
		elif ring_wait <= 0:
			ring_wait = 4
			game.sound.play("ring", game.world.objects.phone.global_position, -13)
