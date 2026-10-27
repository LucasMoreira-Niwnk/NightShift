extends RefCounted

func click(game: Node, button: Button) -> void:
	await game.get_tree().process_frame
	button.pressed.emit()
	await game.get_tree().process_frame

func key(game: Node, code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		game.get_viewport().push_input(event, true)
		await game.get_tree().process_frame

func run(game: Node, test: Node) -> void:
	test.check(game.world.camera_mounts.size() == 5, "All five CCTV lenses have physical mounts")
	for index in range(5):
		game.computer.select_camera(index)
		var lens: Marker3D = game.world.camera_mounts[index].get_node("Lens")
		test.check(lens.global_position.distance_to(game.computer.security_camera.global_position) < 0.0001, "Physical lens matches live viewpoint: " + str(index + 1))
		test.check(lens.global_transform.basis.z.dot(game.computer.security_camera.global_transform.basis.z) > 0.9999, "Physical lens matches filming direction: " + str(index + 1))
	game.computer.select_camera(4)
	await click(game, game.computer.participants_button)
	test.check(game.ui.modal and game.ui.panel.is_visible_in_tree(), "Participant dialog is immediately visible over CCTV")
	test.check(not game.player.controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Participant dialog owns visible mouse and blocks FPS")
	var angle: Vector3 = game.player.camera.rotation
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(80, 20)
	game.player._unhandled_input(motion)
	test.check(game.player.camera.rotation.is_equal_approx(angle), "Moving modal cursor cannot rotate player camera")
	await key(game, KEY_1)
	test.check(game.computer.selected == 4, "CCTV shortcuts do not leak through participant dialog")
	await test.capture("cctv-participants-visible")
	await key(game, KEY_ESCAPE)
	test.check(not game.ui.modal and game.computer.active, "Escape returns from investigation to CCTV without closing both")
	test.check(not game.player.controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "CCTV retains mouse after closing modal")
	await click(game, game.computer.participants_button)
	game.computer.close()
	test.check(game.ui.modal and game.ui.panel.is_visible_in_tree() and not game.player.controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Closing underlying CCTV cannot capture mouse from an open dialog")
	var back: Button = game.ui.column.get_child(game.ui.column.get_child_count() - 1)
	await click(game, back)
	test.check(not game.ui.modal and game.player.controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Leaving final dialog restores FPS only when no menu owns input")
	game.computer.interact()
	game.computer.select_camera(4)
	print("CCTV_UI_TEST_OK")
