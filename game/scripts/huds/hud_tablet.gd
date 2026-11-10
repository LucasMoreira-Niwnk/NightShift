class_name HUDTablet
extends Control

signal task_toggled(task_name: String, completed: bool)
var game: Node
var map: Control
var hint_label: Label
var state_label: Label
var note_list: VBoxContainer
var note_title: Label
var note_body: RichTextLabel
var alert_label: Label
var signature := ""
var live_preview: TextureRect
var preview_status: Label
var entries: Dictionary = {}

func label(parent: Node, text: String, font_size: int = 16) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size",font_size)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(item)
	return item

func action(parent: Node, text: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

func _ready() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://scripts/ui_style.gd").theme()
	var background := ColorRect.new()
	background.color = Color(0.015,0.025,0.03,0.98)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,22)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := label(header,"VESPER / TABLET DE RONDA",21)
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	action(header,"Guardar [Tab / Esc]",func():
		if game != null: game.toggle_tablet())
	state_label = label(column,"SEM CONEXÃO COM O TURNO",13)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(tabs)
	var map_page := HBoxContainer.new()
	map_page.name = "Mapa e dicas"
	tabs.add_child(map_page)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.2
	map_page.add_child(left)
	var tools := HBoxContainer.new()
	left.add_child(tools)
	var floors := OptionButton.new()
	for text in ["Piso atual • automático","Térreo / exterior","2º andar"]: floors.add_item(text)
	floors.item_selected.connect(func(index: int): map.floor_mode = index-1)
	tools.add_child(floors)
	action(tools,"−",func(): map.zoom = maxf(1.0,map.zoom-0.5))
	action(tools,"+",func(): map.zoom = minf(3.0,map.zoom+0.5))
	action(tools,"Centralizar",func(): map.zoom = 1.0; map.floor_mode = -1; floors.select(0))
	map = preload("res://scripts/huds/live_floor_map.gd").new()
	map.game = game
	map.clip_contents = true
	left.add_child(map)
	label(left,"▲ Daniel / direção   ■ Câmera   ● Porta: verde aberta · âmbar fechada",12)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 310
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	map_page.add_child(right)
	label(right,"PRÓXIMA AÇÃO / DICA DO TURNO",16)
	hint_label = label(right,"Abra uma partida para acompanhar a ronda.",18)
	preview_status = label(right,"CÂMERA SELECIONADA NO TERMINAL",12)
	live_preview = TextureRect.new()
	live_preview.custom_minimum_size = Vector2(280,155)
	live_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	live_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(live_preview)
	alert_label = label(right,"Nenhuma ocorrência registrada.",14)
	var notes := HBoxContainer.new()
	notes.name = "Notas lidas"
	tabs.add_child(notes)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 300
	notes.add_child(scroll)
	note_list = VBoxContainer.new()
	note_list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(note_list)
	var reading := VBoxContainer.new()
	reading.size_flags_horizontal = SIZE_EXPAND_FILL
	notes.add_child(reading)
	note_title = label(reading,"Arquivo pessoal de Daniel",21)
	note_body = RichTextLabel.new()
	note_body.size_flags_vertical = SIZE_EXPAND_FILL
	note_body.selection_enabled = true
	reading.add_child(note_body)
	note_body.text = "Somente documentos já lidos aparecem aqui. As notas acompanham o checkpoint."
	refresh_notes()

func refresh_notes() -> void:
	if game == null: return
	entries = game.ui.document_entries()
	for child in note_list.get_children():
		note_list.remove_child(child)
		child.queue_free()
	label(note_list,"LIDOS / %02d" % game.chapter.documents.size(),13)
	for id in game.chapter.documents:
		if entries.has(id): action(note_list,entries[id][0],read_entry.bind(id))
	action(note_list,"Mensagens e diálogos",func():
		note_title.text = "Registro do turno"
		note_body.text = "\n\n".join(game.chapter.transcript))
	action(note_list,"Histórico de ocorrências",func():
		note_title.text = "Ocorrências registradas"
		note_body.text = "\n".join(game.chapter.history) if not game.chapter.history.is_empty() else "Nenhuma ocorrência registrada.")

func read_entry(id: String) -> void:
	if not entries.has(id) or not game.chapter.documents.has(id): return
	note_title.text = entries[id][0]
	note_body.text = entries[id][1]

func _process(_delta: float) -> void:
	if not is_visible_in_tree() or game == null: return
	hint_label.text = game.chapter.objective()
	state_label.text = "%s  /  %s  /  CAPÍTULO %d  /  LOCALIZAÇÃO ATUALIZADA" % [game.world.clocks[0].displayed_time,game.ui.zone_label.text,2 if game.chapter.stage >= 9 else 1]
	var selected: int = game.computer.selected
	var signal_ok: bool = game.computer.monitor_power and not (game.computer.signal_lost and selected == 1) and (selected < 3 or game.chapter.has_flag("cam04_restored"))
	preview_status.text = "CAM-%02d / " % (selected+1) + ("AO VIVO" if signal_ok else "SEM SINAL / TERMINAL DESLIGADO" if not game.computer.monitor_power else "SEM SINAL")
	live_preview.texture = game.computer.feed.get_texture() if signal_ok else null
	alert_label.text = game.chapter.history.back() if not game.chapter.history.is_empty() else "Nenhuma ocorrência registrada."
	var current := str(game.chapter.documents) + str(game.chapter.stage) + str(game.chapter.history.size())
	if current != signature:
		signature = current
		refresh_notes()

func set_alert(active: bool, text: String = "") -> void:
	if alert_label != null: alert_label.text = text if active else "Nenhum alerta."
