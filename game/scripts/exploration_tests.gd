extends RefCounted

func cross_door(game: Node, test: Node, id: String, start: Vector3, action: String) -> void:
	game.player.position = start
	game.player.velocity = Vector3.ZERO
	game.player.rotation = Vector3.ZERO
	game.world.doors[id].restore_open(true)
	await game.get_tree().physics_frame
	Input.action_press(action)
	await game.get_tree().create_timer(0.7).timeout
	Input.action_release(action)
	await game.get_tree().create_timer(0.15).timeout
	var point: Vector3 = game.player.position
	test.check(absf(point.y-start.y)<0.15,"New room floor supports player: "+id)
	test.check(point.x < -2.4 if id == "stores" else point.x > 2.3,"Authored doorway is traversable: "+id)

func run(game: Node, test: Node) -> void:
	var initial_failures: int = test.failures
	var chapter: Node = game.chapter
	chapter.interact("fuse20")
	test.check(not chapter.has_flag("fuse20_taken"),"Locked cabinet prevents picking spare through closed door")
	chapter.interact("it_cabinet")
	test.check(chapter.documents.has("it_cabinet_note") and game.ui.modal,"Cabinet gives actionable clue")
	test.dismiss()
	test.check(not game.exploration.allow_door("personnel"),"Personnel door initially requires its own key")
	await cross_door(game,test,"break_room",Vector3(0.6,0.05,1),"move_right")
	await test.reachable("handover",Vector3(6.1,0.05,1.5))
	game.player.interaction_target().interact()
	test.check(chapter.documents.has("handover"),"Copa handover document stored for later reference")
	test.dismiss()
	await cross_door(game,test,"stores",Vector3(-0.6,0.05,-4),"move_left")
	await test.reachable("personnel_key",Vector3(-5.8,0.05,-4.1))
	game.player.interaction_target().interact()
	test.check(chapter.has_flag("personnel_key") and not game.world.objects.personnel_key.visible,"Unique key collected into inventory")
	chapter.save_game()
	chapter.flags.personnel_key = false
	chapter.load_game()
	test.check(chapter.has_flag("personnel_key"),"Inventory key survives checkpoint reload")
	test.check(game.exploration.allow_door("personnel") and not chapter.has_flag("personnel_key"),"Key automatically used in matching lock")
	await cross_door(game,test,"personnel",Vector3(0.3,4.25,7.5),"move_right")
	await test.reachable("it_key",Vector3(5.9,4.25,7.6))
	game.player.interaction_target().interact()
	chapter.interact("it_cabinet")
	test.check(chapter.has_flag("it_cabinet_open") and not chapter.has_flag("it_key"),"TI key opens cabinet and is consumed once")
	test.check(game.world.objects.fuse20.visible and game.world.objects.fuse20.collision_layer == 1,"Open cabinet exposes actual spare")
	game.ui.show_inventory()
	test.check(game.ui.modal and not game.player.controls_enabled and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Inventory owns mouse and blocks player movement")
	game.ui.close_modal()
	test.check(game.player.controls_enabled and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Closing inventory returns player control")
	chapter.save_game()
	chapter.flags.it_cabinet_open = false
	chapter.load_game()
	test.check(chapter.has_flag("it_cabinet_open") and chapter.has_flag("personnel_unlocked"),"Unlocked states survive reload")
	game.world.set_interior_power(false)
	for fixture in game.world.lighting_fixtures:
		if fixture.get_script().resource_path != "res://scripts/authored_fixture.gd": continue
		fixture.update_state()
		for entry in fixture.glow: test.check(not entry.material.emission_enabled,"New fixture stops emitting during blackout")
	if test.failures == initial_failures: print("EXPLORATION_TEST_OK: rooms, collisions, clues, locked cabinet, inventory and checkpoint")
