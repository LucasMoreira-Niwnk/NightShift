extends Node

var game: Node
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("CHAPTER_TEST: " + message)

func dismiss() -> void:
	if game.ui.modal: game.ui.close_modal()

func reachable(id: String, position: Vector3, height: float = 0.0) -> void:
	game.player.position = position
	game.player.velocity = Vector3.ZERO
	var item: Node3D = game.world.objects[id]
	game.player.camera.look_at(item.global_position + Vector3(0, height, 0))
	await get_tree().physics_frame
	game.player.camera.look_at(item.global_position + Vector3(0, height, 0))
	game.player.ray.force_raycast_update()
	check(game.player.interaction_target() == item, "Ray can reach " + id)
	if game.player.interaction_target() != item:
		print("RAY_DEBUG ", id, " collider=", game.player.ray.get_collider(), " player=", game.player.position)

func run() -> void:
	get_tree().create_timer(40).timeout.connect(func():
		push_error("CHAPTER_TEST_TIMEOUT")
		get_tree().quit(1))
	var chapter: Node = game.chapter
	await get_tree().create_timer(0.8).timeout
	check(game.player.is_on_floor(), "Player settles on reception floor")
	for asset in ["SchoolChair_01", "metal_office_desk", "vintage_radio_transceiver", "desk_lamp_arm_01", "drawer_cabinet", "binder_notebook"]:
		check(game.world.find_child(asset + "_1kModel", true, false) != null, "External model is instantiated: " + asset)
	for id in ["envelope", "flashlight", "recorder", "logbook", "maintenance", "phone"]:
		var bounds: AABB = preload("res://scripts/art.gd").mesh_bounds(game.world.objects[id], Transform3D.IDENTITY)
		check(absf(bounds.position.y - 1.08) < 0.012, "Prop rests on desk surface: " + id)
	check(game.world.clocks.size() == 3, "Three physical wall clocks installed")
	check(game.world.floor_plans.size() == 2, "Two wall floor plans installed")
	game.world.set_time("01:00")
	for clock in game.world.clocks:
		check(clock.displayed_time == "01:00", "Clock readouts stay synchronized")
		check(is_equal_approx(clock.hour_hand.rotation.z, -TAU / 12), "Clock hour hand follows narrative time")
	game.world.set_time("23:57")
	game.player.position = Vector3(-4.8, 0.05, 6.4)
	game.player.camera.look_at(Vector3(-4.1, 1.8, 4.14))
	await capture("wall-plan-clock")
	var board: Node3D = game.world.floor_plans[0]
	game.player.camera.look_at(board.global_position)
	await get_tree().physics_frame
	game.player.ray.force_raycast_update()
	check(game.player.interaction_target() == board, "Wall map is reachable with interaction ray")
	board.interact()
	check(game.ui.modal, "Floor plan opens readable inspection panel")
	await capture("floor-plan-detail")
	dismiss()
	game.player.position = Vector3(0, 0.05, 10.5)
	game.player.camera.rotation = Vector3.ZERO
	await capture("art-reception")
	# Regression: the security room's overhang behind the terminal had no wall.
	var arrival_position: Vector3 = game.player.position
	game.player.position = Vector3(-7, 0.05, 2.8)
	game.player.rotation.y = 0
	game.player.velocity = Vector3.ZERO
	Input.action_press("move_back")
	await get_tree().create_timer(1.0).timeout
	Input.action_release("move_back")
	check(game.player.position.z < 3.65, "Rear security wall blocks walking out behind terminal")
	check(game.player.position.y > -0.1, "Player stays above floor at former rear-wall gap")
	game.player.position = arrival_position
	game.player.velocity = Vector3.ZERO
	check(not chapter.can_open("security"), "Security locked before badge")
	await reachable("envelope", Vector3(-3.2, 0.05, 9))
	chapter.interact("envelope")
	await capture("chapter1-protocol")
	dismiss()
	check(chapter.has_flag("badge"), "Envelope awards badge/key")
	# Exercise a doorway with the actual player controller and physics.
	game.player.position = Vector3(0, 0.05, 1)
	game.player.rotation.y = 0
	Input.action_press("move_left")
	await get_tree().create_timer(0.7).timeout
	Input.action_release("move_left")
	check(game.player.position.x > -1.65, "Closed security door blocks walking")
	game.player.camera.look_at(Vector3(-2, 1.3, 1))
	await capture("art-door")
	game.world.doors.security.interact()
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_left")
	await get_tree().create_timer(0.9).timeout
	Input.action_release("move_left")
	check(game.world.in_security(game.player.position), "Player walks through open security doorway")
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	check(chapter.stage == 1, "Arrival advances on entering security")
	await reachable("flashlight", Vector3(-5.8, 0.05, 1.6))
	game.player.interaction_target().interact()
	check(game.player.hand.visible and game.player.flashlight.visible, "FPV hand and flashlight equipped")
	check(game.player.hand.skeleton != null, "Imported right-hand skeleton loaded")
	check(game.player.hand.lens_point != Vector3.ZERO, "Flashlight lens anchor found")
	check(game.player.hand.light.position.distance_to(game.player.hand.lens_point) < 0.025, "Beam starts at the model lens")
	check((-game.player.flashlight.global_transform.basis.z).dot(-game.player.camera.global_transform.basis.z) > 0.99, "Flashlight beam aligns with camera aim")
	await RenderingServer.frame_post_draw
	check("LIGADA" in game.ui.light_label.text, "HUD reflects actual flashlight state")
	var flash_key := InputEventKey.new()
	flash_key.physical_keycode = KEY_F
	flash_key.pressed = true
	game.player._unhandled_input(flash_key)
	await RenderingServer.frame_post_draw
	check("DESLIGADA" in game.ui.light_label.text, "HUD updates when flashlight switches off")
	game.player._unhandled_input(flash_key)
	await reachable("recorder", Vector3(-7.25, 0.05, 1.6))
	game.player.interaction_target().interact()
	dismiss()
	game.player.position = Vector3(-6.5, 0.05, 1.8)
	game.player.camera.look_at(game.computer.global_position + Vector3(0, 0.45, 0))
	await get_tree().physics_frame
	game.player.ray.force_raycast_update()
	check(game.player.interaction_target() == game.computer, "Terminal reachable via interaction ray")
	await capture("chapter1-hand")
	game.computer.interact()
	await get_tree().process_frame
	check(game.computer.actions_row.get_global_rect().position.y > 0 and game.computer.actions_row.get_global_rect().end.y < 720, "CCTV actions fit inside viewport")
	for index in range(3):
		game.computer.select_camera(index)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var frame: Image = game.computer.feed.get_texture().get_image()
		check(not frame.is_empty(), "CCTV renders camera " + str(index))
		game.computer.inspect_button.emit_signal("pressed")
	check(chapter.stage == 2, "Three initial inspections advance patrol")
	game.computer.close()
	game.world.doors.archive.interact()
	await get_tree().create_timer(0.4).timeout
	game.player.position = Vector3(0, 0.05, -5)
	game.player.rotation.y = 0
	Input.action_press("move_right")
	await get_tree().create_timer(0.95).timeout
	Input.action_release("move_right")
	check(game.player.position.x > 2.5, "Archive doorway can be traversed")
	await reachable("emergency", Vector3(0.4, 0.05, -13.4))
	game.player.interaction_target().interact()
	await reachable("logbook", Vector3(6.4, 0.05, -6.1))
	await capture("art-logbook")
	game.player.interaction_target().interact()
	dismiss()
	game.player.position = Vector3(-6.5, 0.05, 1.8)
	game.computer.interact()
	check(chapter.stage == 3, "Patrol and return advance chair event")
	check(not chapter.report_anomaly(0, 1), "Incorrect report rejected without advancing")
	game.computer.select_camera(2)
	check(chapter.report_anomaly(2, 0), "Chair report accepted")
	check(chapter.history.size() == 1, "Occurrence history recorded")
	chapter.report_anomaly(2, 0)
	check(chapter.history.size() == 1, "Duplicate report idempotent")
	await capture("chapter1-cctv")
	game.computer.close()
	await reachable("chair", Vector3(2.5, 0.05, -5), 0.55)
	game.player.interaction_target().interact()
	await get_tree().create_timer(1.6).timeout
	check(chapter.has_flag("chair_inspected"), "Chair inspection recorded")
	game.player.position = Vector3(-6.5, 0.05, 1.8)
	game.computer.interact()
	check(chapter.stage == 4, "Technical room stage reached")
	game.computer.close()
	check(game.world.doors.technical.is_open, "Technical door opened by event")
	game.player.position = Vector3(0, 0.05, -10)
	Input.action_press("move_left")
	await get_tree().create_timer(0.95).timeout
	Input.action_release("move_left")
	check(game.player.position.x < -2.5, "Technical doorway can be traversed")
	chapter.toggle_breaker(3)
	check(not chapter.breakers[3], "Subsoil circuit resets on error")
	check(not chapter.confirm_breakers(), "Incomplete breaker solution rejected")
	await reachable("breakers", Vector3(-6.1, 0.05, -11))
	game.player.interaction_target().interact()
	await capture("chapter1-breakers")
	game.ui.breaker_buttons[1].emit_signal("pressed")
	check(chapter.confirm_breakers(), "A/B/C on and D off accepted")
	check(chapter.has_flag("power"), "Power restored")
	check(chapter.save_game(), "Checkpoint saved")
	var saved_stage: int = chapter.stage
	chapter.stage = 0
	chapter.flags = {}
	check(chapter.load_game(), "Checkpoint loaded")
	check(chapter.stage == saved_stage and chapter.has_flag("power") and game.player.has_flashlight, "Save restores flags/items/stage")
	game.player.position = Vector3(-6.5, 0.05, 1.8)
	game.computer.interact()
	check(chapter.stage == 5, "Entity stage reached")
	game.computer.select_camera(1)
	chapter.report_anomaly(1, 1)
	for index in range(3):
		game.computer.select_camera(0)
		game.computer.select_camera(1)
	await get_tree().create_timer(3.8).timeout
	check(chapter.stage == 6, "Three switches advance doppelganger")
	check(chapter.has_flag("double_seen"), "Double shown on CAM-01")
	await get_tree().create_timer(2.1).timeout
	await capture("chapter1-reflection")
	chapter.power_off_monitor()
	check(chapter.stage == 7 and not game.computer.monitor_power, "Power-off unlocks final report")
	await reachable("report", Vector3(-6.1, 0.05, 1.6))
	game.player.interaction_target().interact()
	check(game.ui.modal and chapter.has_flag("report_read"), "Report readable")
	dismiss()
	await get_tree().create_timer(1.8).timeout
	check(chapter.stage == 8 and game.ui.ending, "Chapter completable from start to finish")
	await capture("chapter1-ending")
	if failures == 0: print("CHAPTER1_TEST_OK: eight scenes, three puzzles, FPV hand, CCTV, reports, checkpoints, ending")
	get_tree().quit(0 if failures == 0 else 1)

func capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("res://../.local/" + id + ".png")
