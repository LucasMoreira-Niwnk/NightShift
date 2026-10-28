extends Control

var computer: Node
var game: Node
var panels: Array = []
var images: Array = []
var titles: Array = []
var statuses: Array = []
var previews: Array = []
var lenses: Array = []
var reflections: Array = []
var interference_masks: Array = []
var contaminated_labels: Array = []
var channel_ids := [0,1,2]
var report_dialog: PanelContainer
var report_camera := 0
var header: Label
var clock: Label
var incident: Label
var patrol: Label
var message: Label
var inspection: HBoxContainer
var observations: OptionButton
var chapter_row: HBoxContainer
var seek: HSlider
var playback: Button
var alert_button: Button
var participants: Button
var delete_button: Button
var pause_button: Button
var contamination_override := false
var contamination_text := ""
var contaminated := false
var accent := Color("00d97d")
var feedback := ""
var feedback_age := 0.0

func text(parent: Node, value: String, font_size: int = 15) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size",font_size)
	parent.add_child(item)
	return item

func button(parent: Node, value: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = value
	item.add_theme_font_size_override("font_size",14)
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = preload("res://scripts/ui_style.gd").theme()
	var background := ColorRect.new()
	background.color = Color("050a08")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,18)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	margin.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	header = text(top,"VESPER SECURITY NETWORK",21)
	header.size_flags_horizontal = SIZE_EXPAND_FILL
	clock = text(top,"OPERADOR: REIS, D.",14)
	var grid := HBoxContainer.new()
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation",12)
	column.add_child(grid)
	for index in range(3):
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		panel.size_flags_stretch_ratio = 1.0
		grid.add_child(panel)
		panels.append(panel)
		var contents := VBoxContainer.new()
		panel.add_child(contents)
		titles.append(text(contents,"CAM-%02d" % (index+1),16))
		var image := TextureRect.new()
		image.size_flags_vertical = SIZE_EXPAND_FILL
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(image)
		images.append(image)
		var mirror := ColorRect.new()
		mirror.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mirror.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mirror.material = computer.reflection.material
		image.add_child(mirror)
		reflections.append(mirror)
		var noise := ColorRect.new()
		noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
		noise.material = computer.interference.material
		image.add_child(noise)
		interference_masks.append(noise)
		var ghost := Label.new()
		ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ghost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.add_theme_color_override("font_color",Color("d35550"))
		image.add_child(ghost)
		contaminated_labels.append(ghost)
		statuses.append(text(contents,"AO VIVO",12))
		panel.gui_input.connect(feed_input.bind(index))
		var viewport := SubViewport.new()
		viewport.size = Vector2i(384,216)
		viewport.world_3d = game.get_viewport().world_3d
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		computer.add_child(viewport)
		var lens := Camera3D.new()
		lens.cull_mask = 5
		lens.fov = 75
		viewport.add_child(lens)
		lens.current = true
		previews.append(viewport)
		lenses.append(lens)
	var status_row := HBoxContainer.new()
	column.add_child(status_row)
	incident = text(status_row,"ÚLTIMO INCIDENTE\nNenhuma ocorrência registrada",14)
	incident.size_flags_horizontal = SIZE_EXPAND_FILL
	patrol = text(status_row,"STATUS DA RONDA",14)
	patrol.size_flags_horizontal = SIZE_EXPAND_FILL
	message = text(column,"",15)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var actions := HFlowContainer.new()
	column.add_child(actions)
	button(actions,"▶ REPORTAR INCIDENTE",open_report)
	button(actions,"◀ CÂMERA",func(): computer.select_camera(computer.selected-1))
	button(actions,"CÂMERA ▶",func(): computer.select_camera(computer.selected+1))
	button(actions,"RELATÓRIO DO TURNO",func(): game.ui.document("Ocorrências do turno","\n".join(game.chapter.history) if not game.chapter.history.is_empty() else "Nenhuma ocorrência registrada."))
	button(actions,"RAMAL 000",func(): game.chapter.interact("phone"))
	button(actions,"Zoom [Z]",computer.toggle_zoom)
	button(actions,"Desligar monitor",func(): game.chapter.power_off_monitor())
	button(actions,"Sair [E / Esc]",computer.close)
	inspection = HBoxContainer.new()
	column.add_child(inspection)
	observations = OptionButton.new()
	for value in ["Relógio visível","Porta técnica fechada","Cadeira diante da mesa"]: observations.add_item(value)
	inspection.add_child(observations)
	button(inspection,"Confirmar inspeção",func(): game.chapter.verify_camera(computer.selected,observations.selected))
	chapter_row = HBoxContainer.new()
	column.add_child(chapter_row)
	alert_button = button(chapter_row,"Confirmar alerta CAM-04",func(): game.chapter.act_two.acknowledge_alert())
	playback = button(chapter_row,"Reproduzir arquivo",func(): game.chapter.act_two.watch_recording(game.chapter.act_two.available_recording()))
	participants = button(chapter_row,"Investigar participantes",func(): game.ui.show_participants())
	delete_button = button(chapter_row,"Apagar arquivo",func(): game.chapter.act_two.delete_tomorrow())
	pause_button = button(chapter_row,"Pausar / continuar",func(): computer.recording.paused = not computer.recording.paused)
	seek = HSlider.new()
	seek.custom_minimum_size = Vector2(150,30)
	seek.max_value = 8
	seek.step = 0.05
	seek.value_changed.connect(func(value: float): computer.recording.seek(value))
	chapter_row.add_child(seek)
	var scan := ColorRect.new()
	scan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/scanlines.gdshader")
	scan.material = material
	add_child(scan)
	report_dialog = PanelContainer.new()
	add_child(report_dialog)
	report_dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	report_dialog.offset_left = -250
	report_dialog.offset_right = 250
	report_dialog.offset_top = -160
	report_dialog.offset_bottom = 160
	var choices := VBoxContainer.new()
	report_dialog.add_child(choices)
	text(choices,"REGISTRAR OCORRÊNCIA / CÂMERA ATUAL",19)
	for index in range(3):
		button(choices,["Objeto deslocado","Presença não autorizada","Falha elétrica"][index],submit_report.bind(index))
	button(choices,"Cancelar / Esc",func(): report_dialog.hide())
	report_dialog.hide()

func feed_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		computer.select_camera(channel_ids[index])

func open_report() -> void:
	report_camera = computer.selected
	var heading: Label = report_dialog.get_child(0).get_child(0)
	heading.text = "OCORRÊNCIA / CAM-%02d\nSelecione o tipo observado" % (report_camera+1)
	report_dialog.show()

func submit_report(category: int) -> void:
	var accepted: bool = game.chapter.report_anomaly(report_camera,category)
	feedback = "Ocorrência registrada." if accepted else "Não confirmada. Confira a câmera e o tipo de incidente."
	feedback_age = 4.0
	report_dialog.hide()

func cancel_report() -> bool:
	if report_dialog.visible:
		report_dialog.hide()
		return true
	return false

# Hook for narrative events; no demo timers or random spoiler messages.
func set_contaminated(active: bool, line: String = "") -> void:
	contamination_override = active
	contamination_text = line

func _process(delta: float) -> void:
	var running: bool = computer.active and not game.ui.modal
	for viewport in previews:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if running else SubViewport.UPDATE_DISABLED
	if not running: return
	feedback_age = maxf(0.0,feedback_age-delta)
	if feedback_age == 0.0: feedback = ""
	var chapter: Node = game.chapter
	contaminated = contamination_override or chapter.stage == 6
	accent = Color("d35550") if contaminated else Color("00d97d")
	header.modulate = accent
	clock.modulate = accent
	clock.text = "OPERADOR: REIS, D.  |  " + game.world.clocks[0].displayed_time
	channel_ids = [0,1,2] if computer.selected < 3 else [3,4,0]
	for i in range(3):
		var id: int = channel_ids[i]
		previews[i].render_target_update_mode = SubViewport.UPDATE_DISABLED if id == computer.selected else SubViewport.UPDATE_ALWAYS
		lenses[i].position = computer.camera_positions[id]
		lenses[i].look_at(computer.camera_targets[id],Vector3.UP)
		titles[i].text = "● CAM-" + computer.camera_names[id]
		titles[i].modulate = accent
		images[i].texture = computer.picture.texture if id == computer.selected else previews[i].get_texture()
		var offline: bool = (computer.signal_lost and id == 1) or (id >= 3 and not chapter.has_flag("cam04_restored"))
		images[i].modulate = Color.BLACK if offline else Color.WHITE
		reflections[i].visible = computer.reflection.visible and id == computer.selected
		interference_masks[i].visible = id == computer.selected
		contaminated_labels[i].visible = contaminated
		contaminated_labels[i].text = ["DANIEL ESTÁ AQUI\n[ORIGEM NÃO VERIFICADA]","PROXIMIDADE DETECTADA","ELE ESTÁ\nAPRENDENDO\nA SER VOCÊ"][i]
		statuses[i].text = ("SEM SINAL" if offline else "AO VIVO") + (" / SELECIONADA" if id == computer.selected else " / CLIQUE PARA INSPECIONAR")
		if id == computer.selected and computer.recording.active: statuses[i].text = computer.recording.label()
		var style := preload("res://scripts/ui_style.gd").card(Color("080e0c"),2)
		style.border_color = accent if id == computer.selected else Color("1b382b")
		panels[i].add_theme_stylebox_override("panel",style)
	incident.text = "ÚLTIMO INCIDENTE\n" + (str(chapter.history.back()) if not chapter.history.is_empty() else "Nenhuma ocorrência registrada.")
	patrol.text = "STATUS DA RONDA\n"
	for i in range(3): patrol.text += "%s %s  " % [["Recepção","Corredor","Arquivo"][i],"✓" if chapter.verified.has(i) else "○"]
	message.text = feedback if not feedback.is_empty() else game.ui.subtitle.text
	message.modulate = accent if contaminated else Color("b7c9bc")
	if contaminated:
		message.text = "MÊMESIS / TRANSMISSÃO INTERCEPTADA\n" + (contamination_text if not contamination_text.is_empty() else "OPERADOR: DANIEL REIS\nLOCALIZAÇÃO DUPLICADA — RECEPÇÃO / SEGURANÇA")
	inspection.visible = chapter.stage == 1
	chapter_row.visible = chapter.stage >= 9
	alert_button.visible = chapter.stage == 9
	playback.visible = not chapter.act_two.available_recording().is_empty()
	participants.visible = chapter.stage == 14
	delete_button.visible = chapter.stage == 16 and chapter.has_flag("tomorrow_recording_watched")
	pause_button.visible = computer.recording.active
	seek.visible = computer.recording.active
	if computer.recording.active: seek.set_value_no_signal(computer.recording.elapsed)
	# Reflection and interference use the existing event materials, not demo effects.
