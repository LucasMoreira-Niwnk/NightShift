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
	for index in range(8):
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
	inventory.offset_top = -76
	inventory.offset_bottom = -40
	inventory.add_child(inventory_label)
	inventory_label.add_theme_font_size_override("font_size", 12)
	inventory_label.modulate = Style.MUTED
	var controls := label_at(root, Vector2.ZERO, "[WASD] Mover    [F] Lanterna    [J] Protocolo    [Esc] Menu", 12)
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
	if point.z > 4: zone = "RECEPÇÃO"
	elif point.x < -2 and point.z > -2: zone = "SEGURANÇA"
	elif point.x > 2: zone = "ARQUIVO"
	elif point.x < -2 and point.z < -6: zone = "SALA TÉCNICA"
	zone_label.text = zone
	time_label.text = game.world.clocks[0].displayed_time
	light_label.text = "LANTERNA / NÃO COLETADA"
	if game.player.has_flashlight:
		light_label.text = "LANTERNA / " + ("LIGADA" if game.player.flashlight.visible else "DESLIGADA")
	inventory_label.text = "SEM EQUIPAMENTO"
	if game.chapter.has_flag("badge"):
		inventory_label.text = "CRACHÁ  ·  CHAVE"
	if game.player.has_flashlight: inventory_label.text += "  ·  LANTERNA"
	if not modal and not paused and not ending:
		prompt_card.visible = not hint.text.is_empty()
		reticle.hovering = prompt_card.visible
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
	chapter_label.text = "CAPÍTULO 1  /  %02d — %s" % [mini(stage + 1, 8), preload("res://scripts/chapter_data.gd").TITLES[stage].to_upper()]
	objective_label.text = text
	for index in range(progress_segments.size()):
		progress_segments[index].color = Style.ACCENT if index <= stage else Color(0.14, 0.2, 0.18)

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

func button(text: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 36
	control.pressed.connect(callback)
	column.add_child(control)
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
	button("Encerrar capítulo" if final else "Guardar / continuar [E ou Esc]", close_modal)
	open_modal()

func show_floor_plan(texture: Texture2D) -> void:
	clear_panel()
	panel.anchor_left = 0.04
	panel.anchor_right = 0.96
	panel.anchor_top = 0.02
	panel.anchor_bottom = 0.98
	title("VESPER — Planta do térreo")
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
		if child != panel and child is CanvasItem: child.show()
	modal_shade.hide()
	game.set_player_control(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if final_document:
		final_document = false
		game.chapter.complete()

func show_breakers() -> void:
	clear_panel()
	title("Quadro elétrico — Sala técnica")
	text_body("Diagrama: A/B/C ligados. D desligado.\nO subsolo não deve ser energizado.")
	breaker_buttons.clear()
	for index in range(4):
		var control := button("", func():
			game.chapter.toggle_breaker(index)
			update_breakers())
		breaker_buttons.append(control)
	update_breakers()
	button("Confirmar circuitos", func(): game.chapter.confirm_breakers())
	button("Sair [Esc]", close_modal)
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
	button("Sair do jogo", func(): get_tree().quit())
	panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.set_player_control(false)

func show_ending() -> void:
	ending = true
	modal = false
	game.set_player_control(false)
	var fade := ColorRect.new()
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
	title("CAPÍTULO 1 CONCLUÍDO\nO Primeiro Turno")
	text_body("01:00\n\nAugusto: 'Primeira hora concluída, Daniel.\nIsso aconteceu da última vez também.'\n\nPróximo capítulo: Registros Incompletos")
	button("Jogar novamente", func(): get_tree().reload_current_scene())
	button("Sair", func(): get_tree().quit())
	panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
