extends CanvasLayer

const Style = preload("res://scripts/ui_style.gd")
var chapter_label: Label
var zone_label: Label
var time_label: Label
var light_label: Label
var inventory_label: Label
var progress_segments: Array = []
var prompt_card: PanelContainer
var caption_card: PanelContainer
var modal_shade: ColorRect
var reticle: Control
var message_age := 0.0

var game: Node
var objective_label: Label
var subtitle: Label
var hint: Label
var panel: PanelContainer
var column: VBoxContainer
var modal := false
var paused := false
var ending := false
var final_document := false
var breaker_buttons: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Style.theme()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mission := hud_card(root)
	mission.name = "MissionData"
	mission.hide()
	mission.position = Vector2(24, 24)
	mission.size = Vector2(540, 148)
	var mission_column := VBoxContainer.new()
	mission_column.add_theme_constant_override("separation", 8)
	mission.add_child(mission_column)
	var brand := label_at(mission_column, Vector2.ZERO, "VESPER  /  VIGILÂNCIA NOTURNA", 12)
	brand.modulate = Style.ACCENT
	chapter_label = label_at(mission_column, Vector2.ZERO, "", 15)
	chapter_label.modulate = Style.MUTED
	objective_label = label_at(mission_column, Vector2.ZERO, "", 18)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation", 6)
	mission_column.add_child(progress)
	for index in range(9):
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(0, 3)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress.add_child(segment)
		progress_segments.append(segment)
	var status := hud_card(root)
	status.anchor_left = 1
	status.anchor_right = 1
	status.offset_left = -244
	status.offset_right = -24
	status.offset_top = 24
	status.offset_bottom = 126
	var status_column := VBoxContainer.new()
	status.add_child(status_column)
	zone_label = label_at(status_column, Vector2.ZERO, "RECEPÇÃO", 12)
	zone_label.modulate = Style.MUTED
	time_label = label_at(status_column, Vector2.ZERO, "23:57", 28)
	light_label = label_at(status_column, Vector2.ZERO, "LANTERNA / NÃO COLETADA", 11)
	light_label.modulate = Style.ACCENT
	inventory_label = Label.new()
	var inventory := hud_card(root)
	inventory.anchor_top = 1
	inventory.anchor_bottom = 1
	inventory.offset_left = 24
	inventory.offset_right = 270
	inventory.offset_top = -96
	inventory.offset_bottom = -40
	inventory.add_child(inventory_label)
	inventory_label.add_theme_font_size_override("font_size", 12)
	inventory_label.modulate = Style.MUTED
	var controls := label_at(root, Vector2.ZERO, "[WASD] Mover    [F] Lanterna    [Tab] Tablet / Mapa    [F1] HUDs    [J] Diário    [Esc] Menu", 11)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 24
	controls.offset_top = -26
	controls.modulate = Style.MUTED
	prompt_card = hud_card(root)
	prompt_card.anchor_left = 0.5
	prompt_card.anchor_right = 0.5
	prompt_card.anchor_top = 0.5
	prompt_card.anchor_bottom = 0.5
	prompt_card.offset_left = -235
	prompt_card.offset_right = 235
	prompt_card.offset_top = 38
	prompt_card.offset_bottom = 84
	var prompt_row := HBoxContainer.new()
	prompt_row.add_theme_constant_override("separation", 14)
	prompt_card.add_child(prompt_row)
	var key := label_at(prompt_row, Vector2.ZERO, "[E]", 20)
	key.modulate = Style.ACCENT
	hint = label_at(prompt_row, Vector2.ZERO, "", 18)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reticle = preload("res://scripts/reticle.gd").new()
	root.add_child(reticle)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caption_card = hud_card(root)
	caption_card.anchor_left = 0.25
	caption_card.anchor_right = 0.82
	caption_card.anchor_top = 1
	caption_card.anchor_bottom = 1
	caption_card.offset_top = -128
	caption_card.offset_bottom = -48
	caption_card.offset_left = 0
	caption_card.offset_right = 0
	var caption_column := VBoxContainer.new()
	caption_column.add_theme_constant_override("separation", 5)
	caption_card.add_child(caption_column)
	var caption_title := label_at(caption_column, Vector2.ZERO, "REGISTRO DO TURNO", 11)
	caption_title.modulate = Style.ACCENT
	subtitle = label_at(caption_column, Vector2.ZERO, "", 18)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_shade = ColorRect.new()
	modal_shade.color = Color(0.005, 0.012, 0.012, 0.78)
	root.add_child(modal_shade)
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_shade.hide()
	panel = PanelContainer.new()
	root.add_child(panel)
	panel.anchor_left = 0.15
	panel.anchor_right = 0.85
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.88
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	panel.hide()
	if not OS.get_cmdline_user_args().has("--smoke-test"):
		opening()

func opening() -> void:
	var shade := ColorRect.new()
	shade.color = Color.BLACK
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caption := Label.new()
	caption.text = "14 de novembro de 2008 — 23h57\nEdifício Vesper, Setor Administrativo."
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 24)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(shade, "modulate:a", 0.0, 2.5)
	tween.tween_callback(shade.queue_free)

func hud_card(parent: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(card)
	return card

func _process(delta: float) -> void:
	message_age += delta
	if game.player == null or game.chapter == null: return
	var point: Vector3 = game.player.position
	var zone := "CORREDOR PRINCIPAL"
	if game.world.is_outdoors(point): zone = "EXTERIOR / ESTACIONAMENTO"
	elif point.z > 4: zone = "RECEPÇÃO"
	elif point.x < -2 and point.z > -2: zone = "SEGURANÇA"
	elif point.x > 2: zone = "ARQUIVO"
	elif point.x < -2 and point.z < -6: zone = "SALA TÉCNICA"
	if game.world.staircases.is_service(point): zone = "ESCADA / PASSAGEM DE SERVIÇO"
	elif game.world.staircases.is_main(point): zone = "ESCADARIA PRINCIPAL"
	elif point.y > 3.5:
		zone = "2º / CORREDOR ADMINISTRATIVO"
		if point.x < -1.6: zone = "2º / ADMINISTRAÇÃO" if point.z < -4 else "2º / SALA DE TI"
		elif point.x > 1.6: zone = "2º / SALA DE REUNIÕES"
	zone_label.text = zone
	time_label.text = game.world.clocks[0].displayed_time
	light_label.text = "LANTERNA / NÃO COLETADA"
	if game.player.has_flashlight and game.player.flashlight:
		light_label.text = "LANTERNA / " + ("LIGADA" if game.player.flashlight.visible else "DESLIGADA")
	inventory_label.text = "SEM EQUIPAMENTO"
	if game.chapter.has_flag("badge"):
		inventory_label.text = "CRACHÁ  ·  CHAVE"
	if game.player.has_flashlight: inventory_label.text += "  ·  LANTERNA"
	if game.chapter.has_flag("fuse20_owned"): inventory_label.text += "\nFUSÍVEL 20 A"
	elif game.chapter.has_flag("fuse10_owned"): inventory_label.text += "\nFUSÍVEL 10 A"
	elif game.chapter.has_flag("burnt_fuse_removed") and not game.chapter.has_flag("fuse_replaced"): inventory_label.text += "\nCARTUCHO QUEIMADO"
	if not modal and not paused and not ending:
		# o prompt agora vive no hud_minimal; o card antigo some para nao duplicar
		reticle.hovering = not hint.text.is_empty()
		prompt_card.visible = reticle.hovering and game.hud_minimal == null
		caption_card.visible = not subtitle.text.is_empty() and message_age < 16
		caption_card.modulate.a = clampf((16 - message_age) / 2.0, 0, 1)

func label_at(parent: Node, location: Vector2, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = location
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func update_objective(stage: int, text: String) -> void:
	var second := stage >= 9
	var scene := stage - 9 if second else stage
	var titles: Array = preload("res://scripts/chapter_two_data.gd").TITLES if second else preload("res://scripts/chapter_data.gd").TITLES
	chapter_label.text = "CAPÍTULO %d  /  %02d — %s" % [2 if second else 1, mini(scene + 1, 9 if second else 8), titles[scene].to_upper()]
	objective_label.text = text
	for index in range(progress_segments.size()):
		progress_segments[index].visible = second or index < 8
		progress_segments[index].color = Style.ACCENT if index <= scene else Color(0.14, 0.2, 0.18)

func say(text: String) -> void:
	subtitle.text = text
	message_age = 0

func clear_panel() -> void:
	panel.anchor_left = 0.15
	panel.anchor_right = 0.85
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.88
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()

func title(text: String) -> void:
	label_at(column, Vector2.ZERO, text, 26)

func button(text: String, callback: Callable, parent: Node = null) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 36
	control.pressed.connect(callback)
	if parent == null: parent = column
	parent.add_child(control)
	return control

func text_body(text: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 20)
	scroll.add_child(label)

func open_modal() -> void:
	modal = true
	# CCTV hides the HUD root; showing a child panel alone cannot reveal it.
	panel.get_parent().show()
	for child in panel.get_parent().get_children():
		if child != panel and child is CanvasItem: child.hide()
	modal_shade.show()
	panel.show()
	game.set_player_control(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func document(heading: String, content: String, final: bool = false) -> void:
	clear_panel()
	title(heading)
	text_body(content)
	final_document = final
	button("Guardar relatório / continuar [E ou Esc]" if final else "Guardar / continuar [E ou Esc]", close_modal)
	if final:
		button("Ignorar a ligação e permanecer na segurança", func():
			game.chapter.flags.phone_ignored = true
			close_modal())
	open_modal()

func show_journal() -> void:
	clear_panel()
	title("Daniel Reis — Diário do turno")
	var entries := document_entries()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	button("Rever mensagens e diálogos", func(): document("Registro do turno", "\n\n".join(game.chapter.transcript)), list)
	button("Histórico de ocorrências", func(): document("Ocorrências", "\n".join(game.chapter.history)), list)
	for id in game.chapter.documents:
		if entries.has(id):
			var entry: Array = entries[id]
			button(entry[0], func(): document(entry[0], entry[1]), list)
	button("Voltar ao turno [E / Esc]", close_modal)
	open_modal()

func show_floor_plan(texture: Texture2D, heading: String = "VESPER — Planta do térreo", legend: String = "") -> void:
	clear_panel()
	panel.anchor_left = 0.04
	panel.anchor_right = 0.96
	panel.anchor_top = 0.02
	panel.anchor_bottom = 0.98
	title(heading)
	if not legend.is_empty():
		var info := label_at(column, Vector2.ZERO, legend, 18)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(image)
	button("Voltar [E / Esc]", close_modal)
	open_modal()

func close_modal() -> void:
	if ending: return
	modal = false
	panel.hide()
	for child in panel.get_parent().get_children():
		if child != panel and child is CanvasItem and child.name != "MissionData": child.show()
	modal_shade.hide()
	game.set_player_control(not game.computer.active)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if game.computer.active else Input.MOUSE_MODE_CAPTURED
	if game.computer.active: get_child(0).hide()
	final_document = false

func show_breakers() -> void:
	clear_panel()
	panel.anchor_top = 0.05
	panel.anchor_bottom = 0.95
	title("Quadro elétrico — Sala técnica")
	text_body("F1: " + ("reposição instalada" if game.chapter.has_flag("fuse_replaced") else "cartucho ausente/queimado") + ".\nA sequência de partida consta na ordem de manutenção arquivada na administração.\nIsole o quadro antes de substituir o cartucho físico ao lado do painel.")
	breaker_buttons.clear()
	for index in range(4):
		var control := button("", func():
			game.chapter.toggle_breaker(index)
			update_breakers())
		breaker_buttons.append(control)
	update_breakers()
	button("Isolar todos os circuitos / reiniciar sequência", func():
		if game.chapter.has_flag("power"): return
		game.chapter.breakers = [false, false, false, false]
		game.chapter.flags.power_sequence = []
		game.chapter.save_game()
		update_breakers())
	button("Confirmar circuitos", func(): game.chapter.confirm_breakers())
	button("Sair [Esc]", close_modal)
	open_modal()

func show_network_patch() -> void:
	clear_panel()
	title("Patch panel — RACK 2B")
	text_body("Selecione a porta que encaminha a CAM-04 ao gravador. Compare a etiqueta física no corredor com o log da TI.")
	var grid := GridContainer.new()
	grid.columns = 4
	column.add_child(grid)
	for port in range(1, 9):
		button("PORTA %02d" % port, func(): game.chapter.act_two.restore_network(port), grid)
	button("Voltar", close_modal)
	open_modal()

func show_participants() -> void:
	clear_panel()
	title("Reunião — participantes ausentes")
	text_body("Quem consta na ata, mas não possui registro de entrada? Compare os documentos e a gravação da CAM-05 no diário/terminal.")
	var grid := GridContainer.new()
	grid.columns = 2
	column.add_child(grid)
	for index in range(6):
		button(preload("res://scripts/chapter_two_data.gd").NAMES[index], func(): game.chapter.act_two.identify_participant(index), grid)
	button("Voltar", close_modal)
	open_modal()

func update_breakers() -> void:
	var names := ["A — Recepção", "B — Corredor", "C — Arquivo", "D — Subsolo"]
	for index in range(4):
		breaker_buttons[index].text = names[index] + ("  [LIGADO]" if game.chapter.breakers[index] else "  [DESLIGADO]")

func toggle_pause() -> void:
	if ending: return
	paused = not paused
	get_tree().paused = paused
	if not paused:
		panel.hide()
		for child in panel.get_parent().get_children():
			if child != panel and child is CanvasItem: child.show()
		modal_shade.hide()
		game.set_player_control(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	clear_panel()
	title("PAUSADO — O Primeiro Turno")
	for child in panel.get_parent().get_children():
		if child != panel and child is CanvasItem: child.hide()
	modal_shade.show()
	button("Continuar", toggle_pause)
	button("Salvar checkpoint", func():
		if game.chapter.save_game(): say("Checkpoint salvo."))
	button("Carregar checkpoint", func():
		toggle_pause()
		game.chapter.load_game())
	button("Nova partida", func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	button("Áudio e legendas", show_audio_settings)
	button("Dificuldade — desconforto", show_discomfort_settings)
	button("Sair do jogo", func(): get_tree().quit())
	panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.set_player_control(false)

func toggle_row(text: String, pressed: bool, callback: Callable) -> CheckButton:
	var control := CheckButton.new()
	control.text = text
	control.button_pressed = pressed
	control.toggled.connect(callback)
	column.add_child(control)
	return control

func slider_row(text: String, value: float, minimum: float, maximum: float, step: float, suffix: String, callback: Callable) -> HSlider:
	var caption := label_at(column, Vector2.ZERO, "%s: %s%s" % [text, snappedf(value, step), suffix], 18)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.value_changed.connect(func(changed: float):
		caption.text = "%s: %s%s" % [text, snappedf(changed, step), suffix]
		callback.call(changed))
	column.add_child(slider)
	return slider

func show_discomfort_settings() -> void:
	var effect = game.discomfort
	clear_panel()
	panel.anchor_top = 0.04
	panel.anchor_bottom = 0.96
	title("Dificuldade — desconforto")
	label_at(column, Vector2.ZERO, "Girar a câmera acima do limiar deixa um rastro curto na tela. Em teste: nenhuma opção está amarrada a um nível ainda.", 16)
	var presets := HBoxContainer.new()
	column.add_child(presets)
	for preset_name in effect.PRESETS:
		button(preset_name, func():
			effect.apply_preset(preset_name)
			show_discomfort_settings(), presets)
	toggle_row("Sistema de desconforto ativo", effect.enabled, func(on: bool): effect.enabled = on)
	toggle_row("Rastro temporal (ghosting)", effect.trail_enabled, func(on: bool): effect.trail_enabled = on)
	toggle_row("Rastro só em vermelho/azul (aberração dinâmica)", effect.chroma_only, func(on: bool): effect.chroma_only = on)
	toggle_row("Pico de frametime (experimental — atrasa o jogo)", effect.stutter_enabled, func(on: bool): effect.stutter_enabled = on)
	slider_row("Opacidade do rastro", effect.trail_alpha, 0.0, 0.8, 0.05, "", func(value: float): effect.trail_alpha = value)
	slider_row("Duração do rastro", effect.trail_ms, 50.0, 400.0, 10.0, " ms", func(value: float): effect.trail_ms = value)
	slider_row("Limiar de giro", effect.threshold, 120.0, 900.0, 10.0, " °/s", func(value: float): effect.threshold = value)
	slider_row("Atraso do pico", effect.stutter_ms, 0.0, 25.0, 1.0, " ms", func(value: float): effect.stutter_ms = value)
	button("Testar agora", func(): effect.test_pulse())
	button("Continuar", toggle_pause)

func show_audio_settings() -> void:
	clear_panel()
	title("Áudio — legendas sempre ativas")
	for bus_name in ["Ambiente", "Efeitos"]:
		label_at(column, Vector2.ZERO, bus_name, 18)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)))
		slider.value_changed.connect(func(value: float): game.sound.set_volume(bus_name, value))
		column.add_child(slider)
	button("Continuar", toggle_pause)

func reset_ending() -> void:
	ending = false
	paused = false
	modal = false
	get_tree().paused = false
	for child in get_children():
		if child.name == "EndingFade": child.queue_free()
	panel.hide()
	get_child(0).show()
	for child in panel.get_parent().get_children():
		if child != panel and child is CanvasItem: child.show()
	modal_shade.hide()
	game.set_player_control(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_ending(chapter_number: int = 1) -> void:
	ending = true
	modal = false
	game.set_player_control(false)
	var fade := ColorRect.new()
	fade.name = "EndingFade"
	fade.color = Color(0, 0, 0, 0)
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 1.5)
	await tween.finished
	move_child(panel.get_parent(), -1)
	for child in panel.get_parent().get_children():
		if child != panel and child is CanvasItem: child.hide()
	clear_panel()
	if chapter_number == 1:
		title("CAPÍTULO 1 CONCLUÍDO\nO Primeiro Turno")
		text_body("01:00\n\nAugusto: 'Isso aconteceu da última vez também.'\n\nA noite continua no segundo andar.")
		button("Continuar — Registros Incompletos", func(): game.chapter.act_two.begin())
	else:
		title("CAPÍTULO 2 CONCLUÍDO\nRegistros Incompletos")
		text_body("02:00\nPERFIL COMPORTAMENTAL: 68%\nREFERÊNCIA: HENRIQUE ALMEIDA\n\nAugusto: 'Estamos apenas observando.'\n\nPróximo capítulo: O Funcionário Ausente")
	button("Jogar novamente", func(): get_tree().reload_current_scene())
	button("Sair", func(): get_tree().quit())
	panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func document_entries() -> Dictionary:
	var data = preload("res://scripts/chapter_data.gd")
	var entries := {"protocol": ["Protocolo", data.PROTOCOL], "recording": ["Gravação 001", data.SUPERVISOR], "logbook": ["Livro de registros", data.LOGBOOK], "maintenance": ["Manutenção", data.MAINTENANCE], "diagram": ["Diagrama", data.DIAGRAM], "report": ["Relatório", data.REPORT]}
	var extra = preload("res://scripts/chapter_two_data.gd")
	entries.merge({"repair_note": ["Ordem de manutenção", extra.REPAIR_NOTE], "admin_notice": ["Aviso administrativo", extra.ADMIN_NOTICE], "network_log": ["Log de rede", extra.NETWORK_LOG], "meeting_minutes": ["Ata da reunião", extra.MINUTES], "access_log": ["Controle de acesso", extra.ACCESS], "henrique_photo": ["Henrique Almeida", extra.PHOTO], "failed_call": ["Ligação não completada", extra.CALL], "cam04_label": ["Etiqueta da CAM-04", "RACK 2B — PORTA 07"], "report2": ["Ocorrência 002", extra.report(game.chapter.has_flag("future_event_resisted"))]})
	for id in game.chapter.flags.get("document_records", {}):
		entries[id] = game.chapter.flags.document_records[id]
	return entries
