extends Node3D

var player: CharacterBody3D
var world: Node3D
var chapter: Node
var computer: StaticBody3D
var ui: CanvasLayer
var sound: Node
var director: Node

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
	director = preload("res://scripts/event_director.gd").new()
	director.game = self
	director.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(director)
	chapter.refresh()
	ui.say("14 de novembro de 2008 — 23h57\nEdifício Vesper. Daniel Reis, seu primeiro turno começa agora.")
	if OS.get_cmdline_user_args().has("--smoke-test"):
		var tests := preload("res://scripts/chapter_tests.gd").new()
		tests.game = self
		add_child(tests)
		tests.call_deferred("run")

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
		if ui.modal:
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
		elif not ui.paused and not ui.modal and not computer.active and event.physical_keycode == KEY_J:
			ui.show_journal()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if player == null or ui == null: return
	var target: Node = player.interaction_target()
	ui.hint.text = target.interaction_prompt().trim_prefix("E — ") if player.controls_enabled and target != null and target.has_method("interaction_prompt") else ""
