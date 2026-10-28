extends Node

var game: Node
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("CHAPTER_TEST_FAILED: " + message)
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
	get_tree().create_timer(360).timeout.connect(func():
		push_error("CHAPTER_TEST_TIMEOUT")
		get_tree().quit(1))
	var chapter: Node = game.chapter
	var expansion = preload("res://scripts/chapter_two_tests.gd").new()
	expansion.game = game
	expansion.test = self
	await get_tree().create_timer(0.8).timeout
	check(game.player.is_on_floor(), "Player settles on entrance floor")
	check(game.player.position.z > 12, "Arrival begins outside reception")
	var architecture_cases = preload("res://scripts/architecture_tests.gd").new()
	await architecture_cases.run(game, self)
	check(not game.computer.monitor_power, "Terminal starts switched off")
	check(game.sound.effects.ring.data.size() > 0 and game.sound.effects.rain.loop_end > 0, "Soundscape has playable PCM and looping ambience")
	game.player.position = Vector3(0, 0.05, 14)
	game.player.rotation.y = 0
	Input.action_press("move_forward")
	await get_tree().create_timer(0.6).timeout
	Input.action_release("move_forward")
	check(game.player.position.z > 12.35, "Closed entrance blocks walking")
	game.world.doors.entrance.interact()
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_forward")
	await get_tree().create_timer(0.8).timeout
	Input.action_release("move_forward")
	check(chapter.has_flag("C1_S1_ENTER"), "Entering building triggers arrival")
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
	check(chapter.documents.has("protocol"), "Protocol retained in journal")
	check(chapter.has_flag("C1_S1_CLOCK"), "Clock and phone event is claimed once")
	check(not game.director.claim("C1_S1_CLOCK"), "Unique event cannot replay")
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
	var right_skeleton: Skeleton3D = game.player.hand.skeleton
	var right_only := true
	for bone in range(right_skeleton.get_bone_count()):
		if right_skeleton.get_bone_name(bone).ends_with(".l"): right_only = false
	check(right_only and right_skeleton.find_bone("wrist.r") >= 0, "Hand scene contains only the right-arm skeleton")
	var right_mesh: MeshInstance3D = right_skeleton.get_node("arms_mesh")
	check(right_mesh.transform.is_equal_approx(Transform3D.IDENTITY) and right_skeleton.global_transform.basis.determinant() > 0, "Right hand is neither mirrored nor displaced from its skin")
	var wrist_world := right_skeleton.global_transform * right_skeleton.get_bone_global_pose(right_skeleton.find_bone("wrist.r")).origin
	var shaft_center: Vector3 = game.player.hand.torch.to_global(Vector3(0, 0.027, 0))
	check(game.player.camera.unproject_position(wrist_world).x > game.player.camera.unproject_position(shaft_center).x, "Forearm rises to the right of the flashlight shaft on screen")
	var pose_animation: Animation = game.player.hand.get_node("PoseAnimation").get_animation("Pegada")
	var valid_rotations := true
	for track in range(pose_animation.get_track_count()):
		if pose_animation.track_get_type(track) != Animation.TYPE_ROTATION_3D: continue
		for key in range(pose_animation.track_get_key_count(track)):
			var rotation: Quaternion = pose_animation.track_get_key_value(track, key)
			if not rotation.is_normalized(): valid_rotations = false
	check(valid_rotations, "Authored finger rotations are normalized")
	check(game.player.hand.scene_file_path == "res://scenes/mao_lanterna.tscn", "Player equips the authored hand scene")
	check(not game.player.hand.has_node("Preview"), "Hand preview environment is removed from gameplay")
	var edited_hand = load("res://scenes/mao_lanterna.tscn").instantiate()
	var edited_position: Vector3 = edited_hand.get_node("Lanterna").position + Vector3(0.01, 0, 0)
	edited_hand.get_node("Lanterna").position = edited_position
	var edited_pose: AnimationPlayer = edited_hand.get_node("PoseAnimation")
	var edited_library = edited_pose.get_animation_library("").duplicate(true)
	edited_pose.remove_animation_library("")
	edited_pose.add_animation_library("", edited_library)
	var grip_animation: Animation = edited_pose.get_animation("Pegada")
	var thumb_path := NodePath("ArmRig/arms/Skeleton3D:finger_thumb2.r")
	var thumb_track := grip_animation.find_track(thumb_path, Animation.TYPE_ROTATION_3D)
	var authored_thumb := Quaternion(Vector3.BACK, 0.42)
	grip_animation.rotation_track_insert_key(thumb_track, 0, authored_thumb)
	game.player.camera.add_child(edited_hand)
	check(edited_hand.torch.position.is_equal_approx(edited_position), "Scene flashlight placement survives initialization")
	var loaded_thumb: Quaternion = edited_hand.skeleton.get_bone_pose_rotation(edited_hand.skeleton.find_bone("finger_thumb2.r"))
	check(absf(loaded_thumb.dot(authored_thumb)) > 0.9999, "Authored thumb animation survives initialization")
	edited_hand.free()
	var grip_skeleton: Skeleton3D = game.player.hand.skeleton
	var index_knuckle := grip_skeleton.get_bone_global_pose(grip_skeleton.find_bone("finger_index1.r")).origin
	var index_middle := grip_skeleton.get_bone_global_pose(grip_skeleton.find_bone("finger_index2.r")).origin
	var index_distal := grip_skeleton.get_bone_global_pose(grip_skeleton.find_bone("finger_index3.r")).origin
	# A curled finger defines the cross-section of the grip. The knuckle row
	# alone is sloped because the four fingers have different lengths.
	var curl_normal := (index_middle - index_knuckle).cross(index_distal - index_middle)
	var grip_axis := (grip_skeleton.global_transform.basis * curl_normal).normalized()
	var barrel_axis: Vector3 = game.player.hand.torch.global_transform.basis.x.normalized()
	check(absf(grip_axis.dot(barrel_axis)) > 0.99, "Flashlight axis passes through the finger curl opening, rather than across the palm")
	check(game.player.hand.lens_point != Vector3.ZERO, "Flashlight lens anchor found")
	check(game.player.hand.light.position.distance_to(game.player.hand.lens_point) < 0.025, "Beam starts at the model lens")
	check((-game.player.flashlight.global_transform.basis.z).dot(-game.player.camera.global_transform.basis.z) > 0.99, "Flashlight beam aligns with camera aim")
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	check("LIGADA" in game.ui.light_label.text, "HUD reflects actual flashlight state")
	var flash_key := InputEventKey.new()
	flash_key.physical_keycode = KEY_F
	flash_key.pressed = true
	game.player._unhandled_input(flash_key)
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
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
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		var frame: Image = game.computer.feed.get_texture().get_image()
		check(not frame.is_empty(), "CCTV renders camera " + str(index))
		if index == 0:
			chapter.verify_camera(0, 2)
			check(chapter.verified.is_empty(), "Wrong visual identification rejected without penalty")
		game.computer.observation.select(index)
		game.computer.inspect_button.emit_signal("pressed")
	check(chapter.stage == 2, "Three initial inspections advance patrol")
	game.computer.close()
	await capture("chapter1-console")
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
	await get_tree().create_timer(1.0).timeout
	check(chapter.has_flag("chair_inspected"), "Chair inspection recorded")
	check(not chapter.has_flag("chair_moved"), "Chair waits while directly observed")
	check(chapter.save_game() and chapter.load_game(), "Checkpoint restores pending chair event")
	game.player.camera.rotation.y += PI
	await get_tree().create_timer(2.0).timeout
	check(chapter.has_flag("chair_moved"), "Chair moves after player looks away")
	game.player.position = Vector3(-6.5, 0.05, 1.8)
	game.computer.interact()
	check(chapter.stage == 4, "Technical room stage reached")
	game.computer.close()
	await check_blackout("chapter one breaker failure")
	check(chapter.save_game() and chapter.load_game(), "Blackout checkpoint restores")
	await check_blackout("loaded breaker failure")
	check(game.world.doors.technical.is_open, "Technical door opened by event")
	game.player.position = Vector3(0, 0.05, -10)
	Input.action_press("move_left")
	await get_tree().create_timer(0.95).timeout
	Input.action_release("move_left")
	check(game.player.position.x < -2.5, "Technical doorway can be traversed: " + str(game.player.position))
	await expansion.repair_power()
	check(chapter.has_flag("power"), "Power restored")
	check(game.world.interior_powered and game.world.staircases.get_child_count() > 0, "Fuse repair restores the building mains")
	check(game.world.building_lights.any(func(entry): return entry.light.visible), "Fixtures return after successful repair")
	check(chapter.save_game(), "Checkpoint saved")
	var saved_stage: int = chapter.stage
	game.player.flashlight.visible = false
	chapter.save_game()
	chapter.stage = 0
	chapter.flags = {}
	check(chapter.load_game(), "Checkpoint loaded")
	check(chapter.stage == saved_stage and chapter.has_flag("power") and game.player.has_flashlight, "Save restores flags/items/stage")
	check(not game.player.flashlight.visible and chapter.documents.has("diagram"), "Save preserves torch switch and collected documents")
	game.player.flashlight.visible = true
	game.player.position = Vector3(-6.5, 0.05, 1.8)
	game.computer.interact()
	check(chapter.stage == 5, "Entity stage reached")
	game.computer.select_camera(1)
	chapter.report_anomaly(1, 1)
	for index in range(3):
		game.computer.select_camera(0)
		game.computer.select_camera(1)
	await get_tree().create_timer(5.0).timeout
	check(chapter.stage == 6, "Three switches advance doppelganger")
	check(chapter.has_flag("double_seen"), "Double shown on CAM-01")
	game.computer.select_camera(2)
	await get_tree().create_timer(5.1).timeout
	check(not game.computer.reflecting and not chapter.has_flag("double_seen"), "Reflection waits for operator to return to CAM-01")
	game.computer.select_camera(0)
	await get_tree().create_timer(5.1).timeout
	await capture("chapter1-reflection")
	await get_tree().create_timer(1.4).timeout
	check(chapter.has_flag("reflection_seen"), "Reflection completes before empty-security transmission")
	game.computer.select_camera(2)
	game.computer.select_camera(0)
	check(game.computer.security_camera.position.is_equal_approx(Vector3(-7.5, 2.7, 3.5)), "CAM-01 retains impossible empty-security view after channel switch")
	chapter.power_off_monitor()
	check(chapter.stage == 7 and not game.computer.monitor_power, "Power-off unlocks final report")
	await reachable("report", Vector3(-4.4, 0.05, 1.6))
	game.player.interaction_target().interact()
	check(game.ui.modal and chapter.has_flag("report_read"), "Report readable")
	dismiss()
	check(chapter.stage == 7 and not game.ui.ending, "Reading report leaves time to investigate phone")
	check(chapter.save_game() and chapter.load_game(), "Final phone sequence survives checkpoint load")
	game.player.position = Vector3(-2.4, 0.05, 8.8)
	await get_tree().create_timer(0.2).timeout
	check(game.director.final_started and chapter.has_flag("phone_stopped"), "Ramal 000 stops on approach without answering")
	check(chapter.load_game(), "Loading cancels an in-flight final dialogue")
	chapter.flags.phone_ignored = true
	await get_tree().create_timer(0.2).timeout
	check(game.director.final_started, "Ignoring the call also advances the ending")
	await get_tree().create_timer(13.5).timeout
	check(chapter.stage == 8 and game.ui.ending, "Chapter completable from start to finish")
	await capture("chapter1-ending")
	if failures == 0: print("CHAPTER1_TEST_OK: eight scenes, three puzzles, FPV hand, CCTV, reports, checkpoints, ending")
	await expansion.run()
	if failures == 0: print("CHAPTER2_TEST_OK: nine scenes, connected stairs, fuse quest, isolated recordings, both door choices, alternate route, checkpoints, ending")
	get_tree().quit(0 if failures == 0 else 1)

func capture(id: String) -> void:
	# Keep visual assertions deterministic even if the test window is minimized.
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	game.get_viewport().get_texture().get_image().save_png("res://../.local/" + id + ".png")

func check_blackout(context: String) -> void:
	await get_tree().process_frame
	check(not game.world.interior_powered, "Building mains off: " + context)
	check(game.world.building_lights.size() >= 24, "Registry covers rooms, upper storey, stairwells and property lights")
	for entry in game.world.building_lights:
		check(not entry.light.visible, "Fixture stays off during " + context + ": " + str(entry.light.get_path()))
	for entry in game.world.powered_materials:
		check(not entry.material.emission_enabled, "Luminaire emission stays off: " + context)
	check(not game.computer.monitor_glow.visible, "Terminal UPS does not relight room during blackout")
	check(game.player.has_flashlight and game.player.flashlight.visible, "Player retains battery flashlight during blackout")
