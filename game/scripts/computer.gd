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
var camera_names := ["01 / RECEPÇÃO", "02 / CORREDOR PRINCIPAL", "03 / ARQUIVO"]
var camera_positions := [Vector3(5.5, 2.7, 11.4), Vector3(1.7, 2.7, 3.4), Vector3(7.6, 2.7, -9.5)]
var camera_targets := [Vector3(-2, 1.1, 7.5), Vector3(0, 1.1, -11), Vector3(4, 0.8, -5.5)]

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
	glow.position = Vector3(0, 0.5, 0.4)
	glow.light_color = Color(0.3, 0.85, 0.7)
	glow.light_energy = 0.45
	glow.omni_range = 2
	add_child(glow)

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
	for index in range(3):
		var button := Button.new()
		button.text = "CAM %02d [%d]" % [index + 1, index + 1]
		button.custom_minimum_size = Vector2(160, 42)
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
	inspect.pressed.connect(func(): chapter.verify_camera(selected))
	actions.add_child(inspect)
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
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reflection = ColorRect.new()
	reflection.color = Color(0.005, 0.01, 0.012)
	overlay.add_child(reflection)
	reflection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reflection.offset_top = 78
	reflection.offset_bottom = -250
	var silhouette := Polygon2D.new()
	silhouette.polygon = PackedVector2Array([Vector2(515, 365), Vector2(535, 210), Vector2(575, 175), Vector2(570, 125), Vector2(590, 105), Vector2(620, 105), Vector2(640, 125), Vector2(635, 175), Vector2(675, 210), Vector2(700, 365)])
	silhouette.color = Color(0.12, 0.19, 0.17)
	reflection.add_child(silhouette)
	reflection.hide()
	var help := Label.new()
	help.text = "NIGHTSHIFT SECURITY  •  AO VIVO  |  ← → alternar câmeras"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(30, -28)
	overlay.add_child(help)
	overlay.hide()

func interaction_prompt() -> String:
	return "E — Usar computador / câmeras"

func interact() -> void:
	if active:
		return
	active = true
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
	active = false
	overlay.hide()
	reflection.hide()
	game.set_player_control(true)
	game.ui.get_child(0).show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func select_camera(index: int) -> void:
	var previous := selected
	selected = posmod(index, camera_names.size())
	security_camera.position = camera_positions[selected]
	security_camera.look_at(camera_targets[selected], Vector3.UP)
	if channel_label != null:
		channel_label.text = "● AO VIVO   /   CAM " + camera_names[selected]
	if active and chapter != null:
		chapter.camera_changed(selected, previous)
	update_status()

func update_status() -> void:
	if status_label == null or chapter == null: return
	status_label.text = chapter.objective() + "\n" + game.ui.subtitle.text
	if not chapter.history.is_empty():
		status_label.text += "\nHistórico: " + " | ".join(chapter.history)

func toggle_zoom() -> void:
	security_camera.fov = 42 if security_camera.fov > 50 else 75

func set_monitor_power(powered: bool) -> void:
	monitor_power = powered
	if screen_material != null:
		screen_material.albedo_texture = feed.get_texture() if powered else null
		screen_material.albedo_color = Color.WHITE if powered else Color(0.015, 0.02, 0.02)

func show_reflection() -> void:
	if reflecting: return
	reflecting = true
	await get_tree().create_timer(2.0, false).timeout
	if not active:
		reflecting = false
		return
	reflection.show()
	await get_tree().create_timer(1.3, false).timeout
	reflection.hide()
	security_camera.position = Vector3(-7.5, 2.7, 3.5)
	security_camera.look_at(Vector3(-5, 1, 0))
	reflecting = false

func _process(delta: float) -> void:
	elapsed += delta
	if active:
		channel_label.text = "● AO VIVO   /   CAM " + camera_names[selected]
		clock_label.text = "TURNO 01   |   00:%02d:%02d   |   SINAL OK" % [int(elapsed) / 60 % 60, int(elapsed) % 60]
		picture.modulate = Color.BLACK if signal_lost and selected == 1 else Color.WHITE
		if signal_lost and selected == 1: clock_label.text = "SEM SINAL — MOVIMENTO DETECTADO NA SEGURANÇA"
		update_status()

func _input(event: InputEvent) -> void:
	if not active or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3:
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
