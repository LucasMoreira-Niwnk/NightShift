extends RefCounted

var game: Node
var test: Node

func walk(action: String, seconds: float) -> void:
	game.player.rotation.y = 0
	game.player.velocity = Vector3.ZERO
	Input.action_press(action)
	await game.get_tree().create_timer(seconds).timeout
	Input.action_release(action)

func stairs_up() -> void:
	game.player.position = Vector3(0, 0.05, -14.2)
	game.player.camera.rotation = Vector3.ZERO
	if not game.world.doors.stairs.is_open: game.world.doors.stairs.interact()
	if not game.world.doors.upper_gate.is_open: game.world.doors.upper_gate.interact()
	await game.get_tree().create_timer(0.4).timeout
	await walk("move_forward", 4.4)
	test.check(game.player.position.y > 4.0 and game.player.position.z < -27, "Controller climbs main stairs without teleport or jump")

func restore(snapshot: Dictionary) -> void:
	var file := FileAccess.open(game.chapter.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot))
	file.close()
	test.check(game.chapter.load_game(), "Expanded checkpoint restores")

func repair_power() -> void:
	var chapter: Node = game.chapter
	test.check(not chapter.can_open("stairs"), "Upper access locked until technical fault inspected")
	await test.reachable("breakers", Vector3(-6.1, 0.05, -11))
	game.player.interaction_target().interact()
	test.dismiss()
	test.check(chapter.has_flag("fault_inspected"), "Fault inspection authorizes maintenance access")
	chapter.interact("diagram")
	test.check(not chapter.has_flag("repair_note_read"), "Panel notice does not give the repair procedure")
	test.dismiss()
	chapter.interact("fuse_slot")
	test.check(chapter.has_flag("burnt_fuse_removed"), "Burned fuse physically removed with isolated circuits")
	test.check(not chapter.confirm_breakers(), "Power cannot be restored without a replacement fuse and remote note")
	await stairs_up()
	game.world.doors.administration.restore_open(true)
	game.world.doors.it.restore_open(true)
	await test.reachable("repair_note", Vector3(-6.6, 4.25, -31.5))
	game.player.interaction_target().interact()
	test.dismiss()
	await test.reachable("fuse10", Vector3(-5.1, 4.25, -42.9))
	game.player.interaction_target().interact()
	chapter.interact("fuse_slot")
	test.check(not chapter.has_flag("fuse_replaced"), "Wrong fuse rating rejected without consuming a correct spare")
	await test.reachable("fuse20", Vector3(-5.8, 4.25, -42.9))
	game.player.interaction_target().interact()
	test.check(chapter.has_flag("fuse20_owned") and not game.world.objects.fuse20.visible, "Correct spare collected and removed from world")
	test.check(chapter.save_game() and chapter.load_game(), "Checkpoint preserves note and fuse inventory")
	test.check(chapter.has_flag("fuse20_owned") and chapter.documents.has("repair_note"), "Repair evidence persists across load")
	game.player.position = Vector3(0, 4.25, -29.5)
	game.player.camera.rotation = Vector3.ZERO
	await walk("move_back", 4.4)
	test.check(game.player.position.y < 0.2 and game.player.position.y > -0.1 and game.player.position.z > -16, "Controller descends main stairs safely")
	await test.reachable("fuse_slot", Vector3(-6.1, 0.05, -10.65))
	game.player.interaction_target().interact()
	test.check(chapter.has_flag("fuse_replaced") and not chapter.has_flag("fuse20_owned"), "Spare installed in physical fuse holder")
	chapter.toggle_breaker(3)
	test.check(not chapter.breakers[3], "Forbidden basement circuit trips safely")
	for index in [0, 1, 2]: chapter.toggle_breaker(index)
	test.check(not chapter.confirm_breakers(), "Correct final switches in wrong startup order rejected")
	for index in [2, 1, 0]: chapter.toggle_breaker(index)
	chapter.interact("breakers")
	for index in [2, 0, 1]: game.ui.breaker_buttons[index].emit_signal("pressed")
	await test.capture("chapter1-new-breakers")
	test.check(chapter.confirm_breakers(), "Remote note, rated spare and correct startup sequence restore power")

func watch(kind: String) -> void:
	test.check(game.chapter.act_two.watch_recording(kind), "Archive can open: " + kind)
	var index := 0 if kind == "tomorrow" else (4 if kind == "meeting" else 3)
	var lens: Marker3D = game.world.camera_mounts[index].get_node("Lens")
	test.check(lens.global_position.distance_to(game.computer.recording.camera.position) < 0.0001 and lens.global_transform.basis.z.dot(game.computer.recording.camera.transform.basis.z) > 0.9999, "Recorded viewpoint matches physical camera: " + kind)
	var original: Transform3D = game.world.doors.it.pivot.transform
	var point: Vector3 = game.player.position
	game.computer.recording.seek(5)
	await game.get_tree().process_frame
	await test.capture("chapter2-archive-" + kind)
	test.check(game.world.doors.it.pivot.transform == original and game.player.position.distance_to(point) < 0.08, "Scrubbing reconstructed recording leaves gameplay world unchanged")
	game.computer.recording.seek(7.95)
	await game.get_tree().create_timer(0.2).timeout

func run() -> void:
	var chapter: Node = game.chapter
	var act: RefCounted = chapter.act_two
	act.begin()
	test.check(chapter.stage == 9 and not game.ui.ending, "Chapter one transitions into chapter two in the same world")
	chapter.interact("report")
	test.dismiss()
	await test.reachable("phone", Vector3(-2.4, 0.05, 8.8))
	game.player.interaction_target().interact()
	test.dismiss()
	game.player.position = Vector3(-6.5, 0.05, 1.8)
	game.computer.interact()
	game.computer.alert_button.emit_signal("pressed")
	test.check(chapter.stage == 10, "Failed call and acknowledged future-dated alert authorize inspection")
	game.computer.close()
	await stairs_up()
	test.check(chapter.stage == 11, "Entering upper corridor advances chapter two")
	await test.capture("chapter2-corridor")
	await test.reachable("cam04", Vector3(0.2, 4.25, -29))
	game.player.interaction_target().interact()
	test.dismiss()
	test.check(chapter.stage == 12 and chapter.has_flag("cam04_inspected"), "Camera LED, label and cable inspected")
	chapter.interact("knock_door")
	chapter.interact("knock_door")
	await game.get_tree().create_timer(1.8).timeout
	test.check(game.world.doors.meeting.is_open, "Second knock response opens door behind operator")
	game.player.position = Vector3(0, 4.25, -42)
	if not game.world.doors.it.is_open: game.world.doors.it.interact()
	await game.get_tree().create_timer(0.4).timeout
	await walk("move_left", 1.0)
	test.check(game.player.position.x < -2.5, "Upper IT doorway can be traversed")
	await test.reachable("network_patch", Vector3(-8.2, 4.25, -42))
	game.player.interaction_target().interact()
	test.check(not act.restore_network(2) and chapter.stage == 12, "Wrong network port can be retried")
	for child in game.ui.column.get_children():
		if child is GridContainer: child.get_child(6).emit_signal("pressed")
	test.check(chapter.stage == 13 and chapter.has_flag("cam04_restored"), "Port 07 restores CAM-04 and unlocks buffer")
	game.player.position = Vector3(-7.2, 4.25, -43.1)
	chapter.interact("it_terminal")
	await watch("future")
	test.check(chapter.has_flag("future_recording_watched"), "Future recording evidence stored")
	game.computer.close()
	var before_future: Dictionary = chapter.serialize_state()
	game.player.position = Vector3(-0.8, 4.25, -42)
	await game.get_tree().create_timer(0.2).timeout
	test.check(chapter.has_flag("future_door_pending"), "Leaving IT arms predicted door event")
	game.world.doors.it.interact()
	test.check(chapter.stage == 14 and chapter.has_flag("future_event_resisted"), "Holding the moving door changes predicted event")
	test.check(chapter.save_game() and chapter.load_game() and chapter.has_flag("future_event_resisted"), "Door resistance decision persists")
	restore(before_future)
	game.player.position = Vector3(-0.8, 4.25, -42)
	await game.get_tree().create_timer(3.9).timeout
	test.check(chapter.stage == 14 and not chapter.has_flag("future_event_resisted"), "Allowing door closure records alternate decision")
	await test.reachable("meeting_minutes", Vector3(5.3, 4.25, -36.9))
	game.player.interaction_target().interact()
	test.dismiss()
	await test.reachable("access_log", Vector3(6.5, 4.25, -36.9))
	game.player.interaction_target().interact()
	test.dismiss()
	test.check(not act.identify_participant(5), "Meeting investigation requires video as well as documents")
	game.player.position = Vector3(8.7, 4.25, -36.5)
	chapter.interact("meeting_terminal")
	await watch("meeting")
	var cctv_cases = preload("res://scripts/cctv_tests.gd").new()
	await cctv_cases.run(game, test)
	test.check(not act.identify_participant(0), "Registered attendee cannot be marked absent")
	test.check(act.identify_participant(5), "Henrique identified from six names and five entries")
	test.dismiss()
	game.computer.close()
	test.check(chapter.stage == 15 and chapter.documents.has("henrique_photo"), "Henrique evidence starts alternate-route blackout")
	game.player.position = Vector3(0, 4.25, -27.7)
	await walk("move_back", 0.7)
	test.check(game.player.position.z < -26.65 and not chapter.can_open("upper_gate"), "Blackout gate physically blocks main stairs")
	chapter.interact("emergency_map")
	test.dismiss()
	game.player.position = Vector3(-6, 4.25, -33)
	await game.get_tree().create_timer(0.7).timeout
	test.check(chapter.has_flag("voice_shadow_seen"), "Alternate route triggers voice and window shadow once")
	game.world.doors.service_upper.interact()
	await game.get_tree().create_timer(0.4).timeout
	game.player.position = Vector3(-8.5, 4.25, -31)
	await walk("move_left", 1.0)
	test.check(chapter.has_flag("service_crossed"), "Service doorway reached by walking from administration")
	game.player.position = Vector3(-12, 4.25, -31)
	game.player.camera.look_at(game.world.upper.warning.global_position)
	await game.get_tree().create_timer(0.1).timeout
	game.player.camera.rotation.y += PI
	await game.get_tree().create_timer(0.1).timeout
	game.player.camera.look_at(game.world.upper.warning.global_position)
	await game.get_tree().create_timer(0.1).timeout
	test.check(chapter.has_flag("service_message_gone"), "Service warning disappears after looking away and back")
	game.player.camera.rotation = Vector3.ZERO
	await walk("move_back", 4.4)
	test.check(chapter.stage == 16 and game.player.position.y < 0.2, "Service stair leads continuously to ground floor")
	await walk("move_back", 3.6)
	game.player.position = Vector3(-9.5, 0.05, 1)
	game.world.doors.service_exit.interact()
	await game.get_tree().create_timer(0.4).timeout
	await walk("move_right", 0.8)
	test.check(game.world.in_security(game.player.position), "Service passage reconnects to security through real doorway")
	game.computer.interact()
	test.check(not act.delete_tomorrow(), "Tomorrow recording must be examined before deletion attempt")
	await watch("tomorrow")
	game.computer.delete_button.emit_signal("pressed")
	test.check(chapter.stage == 17 and chapter.has_flag("mimesis_discovered"), "Protected archive reveals MIMESIS and prints second report")
	await test.reachable("report", Vector3(-4.4, 0.05, 1.6))
	game.player.interaction_target().interact()
	test.check("REPRODUZIU" in preload("res://scripts/chapter_two_data.gd").report(false) and "ALTEROU" in preload("res://scripts/chapter_two_data.gd").report(true), "Final report distinguishes both behavioral choices")
	test.dismiss()
	test.check(chapter.save_game() and chapter.load_game(), "Final chapter-two dialogue resumes after checkpoint load")
	await game.get_tree().create_timer(15.2).timeout
	test.check(chapter.stage == 18 and game.ui.ending and game.world.clocks[0].displayed_time == "02:00", "Nine chapter-two scenes conclude at 02:00")
	await test.capture("chapter2-ending")
