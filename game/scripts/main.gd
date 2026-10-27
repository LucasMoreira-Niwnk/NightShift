extends Node3D

var player: CharacterBody3D
var world: Node3D
var chapter: Node
var computer: StaticBody3D
var ui: CanvasLayer
var sound: Node
var director: Node
var shadows: Node3D

var tablet_hud: Control = null
var hud_minimal: Control = null
var crt_overlay_layer: CanvasLayer = null
var hud_demo_instance: Control = null
var hud_demo_layer: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	configure_input()
	chapter = preload("res://scripts/chapter.gd").new()
	chapter.game = self
	chapter.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(chapter)
	world = preload("res://scripts/chapter_world.gd").new()
	world.game = self
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	player = preload("res://scripts/player.gd").new()
	player.position = Vector3(0, 0.1, 14.7)
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.ray.collision_mask = 3
	ui = preload("res://scripts/chapter_ui.gd").new()
	ui.game = self
	add_child(ui)
	computer = preload("res://scripts/computer.gd").new()
	computer.player = player
	computer.chapter = chapter
	computer.game = self
	computer.position = Vector3(-6.5, 1.08, -0.18)
	add_child(computer)
	sound = preload("res://scripts/soundscape.gd").new()
	sound.game = self
	sound.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(sound)
	shadows = preload("res://scripts/cast_shadows.gd").new()
	shadows.game = self
	shadows.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(shadows)
	director = preload("res://scripts/event_director.gd").new()
	director.game = self
	director.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(director)

	# Inicializa integrações de HUD (CRT, Scanlines, Tablet móvel e Demo)
	setup_hud_integrations()

	chapter.refresh()
	ui.say("14 de novembro de 2008 — 23h57\nEdifício Vesper. Daniel Reis, seu primeiro turno começa agora.\n[Tab] Consultar Tablet  |  [F1] Alternar HUDs  |  [F2] Filtro CRT")
	if OS.get_cmdline_user_args().has("--smoke-test"):
		var tests := preload("res://scripts/chapter_tests.gd").new()
		tests.game = self
		add_child(tests)
		tests.call_deferred("run")

func setup_hud_integrations() -> void:
	# 1. Overlay visual global de Scanlines analógicas e vinheta CRT
	crt_overlay_layer = CanvasLayer.new()
	crt_overlay_layer.layer = 25
	add_child(crt_overlay_layer)

	# O CRT vem primeiro: reamostra tudo que ja foi desenhado (3D + textos dos HUDs)
	# e devolve como imagem curvada, entao as letras passam a fazer parte do tubo.
	var crt_rect := overlay_rect("res://shaders/crt.gdshader")
	# curvatura mais suave que o padrao do shader: o HUD de gameplay precisa ser legivel
	crt_rect.material.set_shader_parameter("curvature", 6.0)
	crt_rect.material.set_shader_parameter("chromatic_aberration", 0.35)
	crt_overlay_layer.add_child(crt_rect)
	crt_overlay_layer.add_child(overlay_rect("res://shaders/scanlines.gdshader"))

	# 2. HUD minimalista de exploração (relógio, prompt e bateria da lanterna)
	var minimal_scene = load("res://scenes/huds/hud_minimal.tscn")
	if minimal_scene:
		var minimal_layer := CanvasLayer.new()
		minimal_layer.layer = 15
		add_child(minimal_layer)
		hud_minimal = minimal_scene.instantiate()
		minimal_layer.add_child(hud_minimal)
		# ponytail: relogio e bateria ja vivem no card do chapter_ui; aqui so o prompt
		hud_minimal.get_node("TopLeft").visible = false
		hud_minimal.get_node("TopRight").visible = false

	# 3. Tablet de Segurança de Daniel (Planta Baixa 2D & Checklist - Tecla Tab ou M)
	var tablet_scene = load("res://scenes/huds/hud_tablet.tscn")
	if tablet_scene:
		var tablet_layer := CanvasLayer.new()
		tablet_layer.layer = 18
		add_child(tablet_layer)
		tablet_hud = tablet_scene.instantiate()
		tablet_hud.visible = false
		tablet_layer.add_child(tablet_hud)

func overlay_rect(shader_path: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = load(shader_path)
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		rect.material = mat
	return rect

func configure_input() -> void:
	var bindings := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "interact": KEY_E}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.physical_keycode = bindings[action]
			InputMap.action_add_event(action, key)

func set_player_control(enabled: bool) -> void:
	player.controls_enabled = enabled
	player.velocity = Vector3.ZERO
	player.hand.visible = enabled and player.has_flashlight

func _input(event: InputEvent) -> void:
	if ui == null or ui.ending: return
	if event.is_action_pressed("ui_cancel"):
		if hud_demo_layer != null and hud_demo_layer.visible:
			toggle_hud_demo()
		elif tablet_hud != null and tablet_hud.visible:
			toggle_tablet()
		elif ui.modal:
			ui.close_modal()
		elif computer.active:
			computer.close()
		else:
			ui.toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if ui.modal and event.physical_keycode == KEY_E:
			ui.close_modal()
			get_viewport().set_input_as_handled()
		elif not ui.paused and not ui.modal and not computer.active and (event.physical_keycode == KEY_TAB or event.physical_keycode == KEY_M):
			toggle_tablet()
			get_viewport().set_input_as_handled()
		elif not ui.paused and not ui.modal and not computer.active and event.physical_keycode == KEY_J:
			ui.show_journal()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F1:
			toggle_hud_demo()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F3:
			# Teste de arte: planta o Mêmesis na frente de quem joga, para olhar
			# o vulto de perto sem esperar a etapa 5 do capítulo.
			if world != null and world.figure != null and player != null:
				world.figure.chamar_para_frente(player.camera)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F2:
			if crt_overlay_layer:
				crt_overlay_layer.visible = !crt_overlay_layer.visible
			get_viewport().set_input_as_handled()

func toggle_tablet() -> void:
	if tablet_hud == null or ui.modal or computer.active:
		return
	var is_open = not tablet_hud.visible
	tablet_hud.visible = is_open
	set_player_control(not is_open)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED

func toggle_hud_demo() -> void:
	if hud_demo_layer == null:
		var demo_scene = load("res://scenes/huds/main_hud_demo.tscn")
		if demo_scene:
			hud_demo_layer = CanvasLayer.new()
			hud_demo_layer.layer = 30
			add_child(hud_demo_layer)
			hud_demo_instance = demo_scene.instantiate()
			hud_demo_layer.add_child(hud_demo_instance)
			set_player_control(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
	if hud_demo_layer:
		var active_demo = not hud_demo_layer.visible
		hud_demo_layer.visible = active_demo
		set_demo_sublayers(active_demo)
		set_player_control(not active_demo)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if active_demo else Input.MOUSE_MODE_CAPTURED

func set_demo_sublayers(shown: bool) -> void:
	# CanvasLayer ignora a visibilidade do pai: alterna cada sub-layer do demo
	if hud_demo_instance == null: return
	for child in hud_demo_instance.get_children():
		if child is CanvasLayer:
			child.visible = shown

func _process(_delta: float) -> void:
	if player == null or ui == null: return
	var target: Node = player.interaction_target()
	ui.hint.text = target.interaction_prompt().trim_prefix("E — ") if player.controls_enabled and target != null and target.has_method("interaction_prompt") else ""
	if hud_minimal != null:
		hud_minimal.visible = player.controls_enabled
		hud_minimal.set_prompt(ui.hint.text, not ui.hint.text.is_empty())
