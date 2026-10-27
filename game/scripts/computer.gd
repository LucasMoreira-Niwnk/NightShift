extends StaticBody3D

var player: CharacterBody3D
var chapter: Node
var game: Node
var signal_lost := false
var monitor_power := true
var screen_material: StandardMaterial3D
var picture: TextureRect
var status_label: Label
var report_category: OptionButton
var reflection: ColorRect
var reflecting := false
var actions_row: HBoxContainer
var inspect_button: Button
var report_button: Button
var active := false
var selected := 0
var feed: SubViewport
var security_camera: Camera3D
var overlay: Control
var channel_label: Label
var clock_label: Label
var elapsed := 0.0
var camera_names := ["01 / RECEPÇÃO", "02 / CORREDOR PRINCIPAL", "03 / ARQUIVO", "04 / 2º ANDAR", "05 / REUNIÕES"]
var camera_positions: Array = preload("res://scripts/security_camera_layout.gd").POSITIONS
var camera_targets: Array = preload("res://scripts/security_camera_layout.gd").TARGETS
var observation: OptionButton
var interference: ColorRect
var channel_screens: Array = []
var stage_six_time := 0.0
var monitor_glow: OmniLight3D
var recording: Node
var chapter_actions: HBoxContainer
var clip_button: Button
var alert_button: Button
var participants_button: Button
var delete_button: Button
var pause_clip: Button
var clip_seek: HSlider

func _ready() -> void:
	name = "SecurityComputer"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	feed = SubViewport.new()
	feed.size = Vector2i(640, 360)
	feed.world_3d = get_viewport().world_3d
	feed.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(feed)
	security_camera = Camera3D.new()
	security_camera.cull_mask = 5
	security_camera.fov = 75
	feed.add_child(security_camera)
	security_camera.current = true
	select_camera(0)
	build_monitor()
	build_overlay()
	recording = preload("res://scripts/recording_player.gd").new()
	recording.game = game
	add_child(recording)
	set_monitor_power(false)

func build_monitor() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.05, 0.8, 0.4)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = 0.4
	add_child(collider)
	part(Vector3(0, 0.45, 0), Vector3(1.05, 0.68, 0.18), Color(0.045, 0.055, 0.055))
	part(Vector3(0, 0.1, 0), Vector3(0.12, 0.2, 0.12), Color(0.07, 0.08, 0.08))
	part(Vector3(0, 0.02, 0.08), Vector3(0.5, 0.04, 0.3), Color(0.06, 0.07, 0.07))
	var art = preload("res://scripts/art.gd")
	art.model(self, "computerKeyboard", Vector3(0, 0.02, 0.42), Vector3(0.85, 0.06, 0.27))
	art.model(self, "computerMouse", Vector3(0.57, 0.02, 0.28), Vector3(0.13, 0.06, 0.22))
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.91, 0.52)
	screen.mesh = quad
	screen.position = Vector3(0, 0.45, 0.096)
	# CCTV excludes layer 2 to avoid a recursive image of its own monitor.
	screen.layers = 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = feed.get_texture()
	screen_material = material
	screen.material_override = material
	add_child(screen)
	var glow := OmniLight3D.new()
	monitor_glow = glow
	glow.position = Vector3(0, 0.5, 0.4)
	glow.light_color = Color(0.3, 0.85, 0.7)
	glow.light_energy = 0.45
	glow.omni_range = 2
	add_child(glow)
	# Three physical surveillance displays share the selected viewport. Other
	# channels retain their last inspected frame rather than rendering 3 worlds.
	for index in range(3):
		var image := MeshInstance3D.new()
		var quad_screen := QuadMesh.new()
		quad_screen.size = Vector2(0.61, 0.35)
		image.mesh = quad_screen
		image.position = Vector3(-0.65 + index * 0.65, 1.18, -0.05)
		image.layers = 2
		var bezel = preload("res://scripts/art.gd")
		bezel.rounded_box(self, image.position - Vector3(0, 0, 0.04), Vector3(0.65, 0.4, 0.07), Color(0.035, 0.045, 0.04))
		var surface := StandardMaterial3D.new()
		surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		surface.albedo_color = Color(0.04, 0.06, 0.05)
		image.material_override = surface
		add_child(image)
		channel_screens.append(surface)

func part(location: Vector3, size: Vector3, color: Color) -> void:
	preload("res://scripts/art.gd").rounded_box(self, location, size, color)

func build_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	overlay = Control.new()
	overlay.theme = preload("res://scripts/ui_style.gd").theme()
	canvas.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.01, 0.025, 0.02)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	picture = TextureRect.new()
	picture.texture = feed.get_texture()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.offset_top = 78
	picture.offset_bottom = -250
	overlay.add_child(picture)
	var monitor_scan := ColorRect.new()
	monitor_scan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	monitor_scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scan_sh = load("res://shaders/scanlines.gdshader")
	if scan_sh:
		var scan_mat := ShaderMaterial.new()
		scan_mat.shader = scan_sh
		monitor_scan.material = scan_mat
	picture.add_child(monitor_scan)
	channel_label = Label.new()
	channel_label.position = Vector2(30, 22)
	channel_label.add_theme_font_size_override("font_size", 25)
	channel_label.modulate = Color(0.5, 1, 0.75)
	overlay.add_child(channel_label)
	clock_label = Label.new()
	clock_label.position = Vector2(30, 54)
	overlay.add_child(clock_label)
	var buttons := HBoxContainer.new()
	buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	buttons.position = Vector2(30, -230)
	buttons.add_theme_constant_override("separation", 16)
	overlay.add_child(buttons)
	for index in range(5):
		var button := Button.new()
		button.text = "CAM %02d [%d]" % [index + 1, index + 1]
		button.custom_minimum_size = Vector2(140, 42)
		button.pressed.connect(select_camera.bind(index))
		buttons.add_child(button)
	var leave := Button.new()
	leave.text = "Sair [E / Esc]"
	leave.custom_minimum_size = Vector2(180, 42)
	leave.pressed.connect(close)
	buttons.add_child(leave)
	var actions := HBoxContainer.new()
	actions_row = actions
	overlay.add_child(actions)
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	actions.offset_left = 30
	actions.offset_top = -176
	actions.offset_bottom = -136
	actions.add_theme_constant_override("separation", 10)
	var inspect := Button.new()
	inspect_button = inspect
	inspect.text = "Confirmar inspeção"
	inspect.custom_minimum_size = Vector2(180, 40)
	inspect.pressed.connect(func(): chapter.verify_camera(selected, observation.selected))
	actions.add_child(inspect)
	observation = OptionButton.new()
	for text in ["Relógio visível", "Porta técnica fechada", "Cadeira diante da mesa"]:
		observation.add_item(text)
	observation.custom_minimum_size = Vector2(210, 40)
	actions.add_child(observation)
	report_category = OptionButton.new()
	report_category.add_item("Objeto deslocado")
	report_category.add_item("Presença não autorizada")
	report_category.add_item("Falha elétrica")
	report_category.custom_minimum_size = Vector2(230, 40)
	actions.add_child(report_category)
	var report := Button.new()
	report_button = report
	report.text = "Reportar"
	report.pressed.connect(func(): chapter.report_anomaly(selected, report_category.selected))
	actions.add_child(report)
	var zoom := Button.new()
	zoom.text = "Zoom [Z]"
	zoom.pressed.connect(toggle_zoom)
	actions.add_child(zoom)
	var power := Button.new()
	power.text = "Desligar monitor"
	power.pressed.connect(func(): chapter.power_off_monitor())
	actions.add_child(power)
	status_label = Label.new()
	overlay.add_child(status_label)
	status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status_label.offset_left = 30
	status_label.offset_right = -30
	status_label.offset_top = -124
	status_label.offset_bottom = -32
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reflection = ColorRect.new()
	reflection.color = Color(0.005, 0.01, 0.012)
	overlay.add_child(reflection)
	reflection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reflection.offset_top = 78
	reflection.offset_bottom = -250
	var reflection_shader := Shader.new()
	reflection_shader.code = """shader_type canvas_item;
float person(vec2 p, vec2 center, float scale){
 vec2 q=(p-center)/scale;
 float head=1.0-smoothstep(0.94,1.1,length((q-vec2(0.0,-0.2))/vec2(0.045,0.092)));
 float torso=1.0-smoothstep(0.9,1.08,length((q-vec2(0.0,0.12))/vec2(0.12,0.28)));
 return max(head,torso);
}
void fragment(){
 vec2 p=UV; p.x=(p.x-0.5)*1.77+0.5;
 float operator=person(p,vec2(0.48,0.76),1.3);
 float stranger=person(p,vec2(0.59,0.47),1.13);
 float grain=fract(sin(dot(UV+TIME*0.01,vec2(12.98,78.23)))*43758.54);
 vec3 glass=vec3(0.008,0.014,0.016)+grain*0.006;
 glass+=stranger*vec3(0.035,0.05,0.044);
 glass=mix(glass,vec3(0.016,0.028,0.026),operator*0.96);
 float sheen=pow(max(0.0,1.0-length(UV-vec2(0.15,0.1))),6.0);
 COLOR=vec4(glass+sheen*0.035,1.0);
}"""
	var reflection_material := ShaderMaterial.new()
	reflection_material.shader = reflection_shader
	reflection.material = reflection_material
	reflection.hide()
	var help := Label.new()
	help.text = "NIGHTSHIFT SECURITY  •  AO VIVO  |  ← → alternar câmeras"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(30, -28)
	overlay.add_child(help)
	interference = ColorRect.new()
	interference.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interference.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interference.offset_top = 78
	interference.offset_bottom = -250
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float strength = 0.0; void fragment(){ float line = step(0.88, fract(UV.y * 180.0 + TIME * 4.0)); float grain = fract(sin(dot(UV + TIME, vec2(12.9898,78.233))) * 43758.5453); COLOR = vec4(vec3(0.45 + grain * 0.3), strength * (line * 0.3 + grain * 0.5)); }"
	var effect := ShaderMaterial.new()
	effect.shader = shader
	interference.material = effect
	overlay.add_child(interference)
	chapter_actions = HBoxContainer.new()
	chapter_actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	chapter_actions.position = Vector2(30, -176)
	chapter_actions.add_theme_constant_override("separation", 8)
	overlay.add_child(chapter_actions)
	alert_button = chapter_button("Confirmar alerta CAM-04", func(): chapter.act_two.acknowledge_alert())
	clip_button = chapter_button("Reproduzir arquivo", func(): chapter.act_two.watch_recording(chapter.act_two.available_recording()))
	participants_button = chapter_button("Investigar participantes", func(): game.ui.show_participants())
	delete_button = chapter_button("Apagar arquivo", func(): chapter.act_two.delete_tomorrow())
	chapter_button("Zoom [Z]", toggle_zoom)
	pause_clip = chapter_button("Pausar / continuar", func(): recording.paused = not recording.paused)
	clip_seek = HSlider.new()
	clip_seek.custom_minimum_size = Vector2(160, 36)
	clip_seek.max_value = 8
	clip_seek.step = 0.05
	clip_seek.value_changed.connect(func(value: float): recording.seek(value))
	chapter_actions.add_child(clip_seek)
	overlay.hide()

func chapter_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.pressed.connect(action)
	chapter_actions.add_child(button)
	return button

func interaction_prompt() -> String:
	return "E — Usar computador / câmeras"

func interact() -> void:
	if active:
		return
	active = true
	if not chapter.has_flag("terminal_booted"):
		chapter.flags.terminal_booted = true
		game.sound.play("switch", global_position)
	game.set_player_control(false)
	game.ui.get_child(0).hide()
	set_monitor_power(true)
	overlay.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	chapter.use_terminal()
	if chapter.stage == 6:
		chapter.camera_changed(selected, selected)
	update_status()

func close() -> void:
	if recording != null and recording.active: stop_recording()
	active = false
	overlay.hide()
	reflection.hide()
	game.set_player_control(not game.ui.modal and not game.ui.paused and not game.ui.ending)
	game.ui.get_child(0).show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if game.ui.modal or game.ui.paused or game.ui.ending else Input.MOUSE_MODE_CAPTURED

func select_camera(index: int) -> void:
	if recording != null and recording.active: stop_recording()
	var previous := selected
	if is_instance_valid(feed) and channel_screens.size() == 3 and monitor_power:
		var frame := feed.get_texture().get_image()
		if frame != null and not frame.is_empty():
			channel_screens[previous % 3].albedo_texture = ImageTexture.create_from_image(frame)
	selected = posmod(index, camera_names.size())
	if channel_screens.size() == 3 and monitor_power:
		channel_screens[selected % 3].albedo_texture = feed.get_texture()
		channel_screens[selected % 3].albedo_color = Color.WHITE
	security_camera.position = camera_positions[selected]
	security_camera.look_at(camera_targets[selected], Vector3.UP)
	if chapter != null and chapter.stage == 6 and selected == 0 and chapter.has_flag("reflection_seen"):
		show_empty_security()
	if channel_label != null:
		channel_label.text = "● AO VIVO   /   CAM " + camera_names[selected]
	if active and chapter != null:
		chapter.camera_changed(selected, previous)
	update_status()

func update_status() -> void:
	if status_label == null or chapter == null: return
	var second: bool = chapter.stage >= 9
	chapter_actions.visible = second
	actions_row.visible = not second
	alert_button.visible = chapter.stage == 9
	clip_button.visible = not chapter.act_two.available_recording().is_empty()
	clip_button.text = {"future": "Buffer CAM-04 / 01:03", "meeting": "Arquivo CAM-05 / acessos", "tomorrow": "Arquivo 15/11 / 00:00"}.get(chapter.act_two.available_recording(), "Reproduzir arquivo")
	participants_button.visible = chapter.stage == 14
	delete_button.visible = chapter.stage == 16 and chapter.has_flag("tomorrow_recording_watched")
	pause_clip.visible = recording != null and recording.active
	clip_seek.visible = pause_clip.visible
	inspect_button.visible = chapter.stage == 1
	observation.visible = chapter.stage == 1
	report_category.visible = chapter.stage != 1
	report_button.visible = chapter.stage != 1
	status_label.text = chapter.objective() + "\n" + game.ui.subtitle.text
	if not chapter.history.is_empty():
		status_label.text += "\nHistórico: " + " | ".join(chapter.history)

func toggle_zoom() -> void:
	var target: Camera3D = recording.camera if recording != null and recording.active else security_camera
	target.fov = 42 if target.fov > 50 else 75

func set_monitor_power(powered: bool) -> void:
	monitor_power = powered
	if monitor_glow != null: monitor_glow.visible = powered
	if screen_material != null:
		screen_material.albedo_texture = feed.get_texture() if powered else null
		screen_material.albedo_color = Color.WHITE if powered else Color(0.015, 0.02, 0.02)
	for surface in channel_screens:
		surface.albedo_color = Color.WHITE if powered else Color(0.015, 0.02, 0.02)
		surface.albedo_texture = null
	if powered and channel_screens.size() == 3: channel_screens[selected % 3].albedo_texture = feed.get_texture()

func play_recording(kind: String) -> void:
	recording.play(kind)
	feed.render_target_update_mode = SubViewport.UPDATE_DISABLED
	picture.texture = recording.viewport.get_texture()
	screen_material.albedo_texture = picture.texture
	update_status()

func stop_recording() -> void:
	recording.stop()
	feed.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	picture.texture = feed.get_texture()
	screen_material.albedo_texture = feed.get_texture()

func show_reflection() -> void:
	if reflecting: return
	reflecting = true
	var generation: int = chapter.event_generation
	await get_tree().create_timer(5.0, false).timeout
	if generation != chapter.event_generation:
		reflecting = false
		return
	if not active or selected != 0 or chapter.stage != 6:
		reflecting = false
		if chapter.stage == 6: chapter.flags.double_seen = false
		return
	reflection.show()
	await get_tree().create_timer(1.3, false).timeout
	if generation != chapter.event_generation: return
	reflection.hide()
	if active and selected == 0 and chapter.stage == 6:
		chapter.flags.reflection_seen = true
		show_empty_security()
		chapter.save_game()
	reflecting = false

func show_empty_security() -> void:
	security_camera.position = Vector3(-7.5, 2.7, 3.5)
	security_camera.look_at(Vector3(-5, 1, 0))

func _process(delta: float) -> void:
	elapsed += delta
	if chapter.stage == 6: stage_six_time += delta
	else: stage_six_time = 0
	if interference != null:
		var strength := 0.0
		if chapter.stage >= 5 and selected == 1: strength = 0.45 if fmod(elapsed, 9) < 0.45 else 0.04
		if chapter.stage == 6: strength = minf(0.6, stage_six_time / 65)
		if signal_lost and selected == 1: strength = 0.75
		interference.material.set_shader_parameter("strength", strength)
	if active:
		channel_label.text = "● AO VIVO   /   CAM " + camera_names[selected]
		clock_label.text = "14/11/2008   |   " + game.world.clocks[0].displayed_time + "   |   SINAL OK"
		picture.modulate = Color.BLACK if signal_lost and selected == 1 else Color.WHITE
		if signal_lost and selected == 1: clock_label.text = "SEM SINAL — MOVIMENTO DETECTADO NA SEGURANÇA"
		if selected >= 3 and not chapter.has_flag("cam04_restored"):
			picture.modulate = Color.BLACK
			clock_label.text = "OFFLINE — ÚLTIMA TRANSMISSÃO CAM-04: 01:03:17" if chapter.stage >= 9 else "SEM SINAL — SETOR ADMINISTRATIVO"
		if recording != null and recording.active:
			channel_label.text = "▶ ARQUIVO / RECONSTRUÇÃO DO BUFFER"
			clock_label.text = recording.label()
			picture.modulate = Color.WHITE
			clip_seek.set_value_no_signal(recording.elapsed)
		update_status()

func _input(event: InputEvent) -> void:
	if not active or game.ui.modal or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			select_camera(event.physical_keycode - KEY_1)
		KEY_LEFT:
			select_camera(selected - 1)
		KEY_RIGHT:
			select_camera(selected + 1)
		KEY_E:
			close()
		KEY_Z:
			toggle_zoom()
		_:
			return
	get_viewport().set_input_as_handled()
