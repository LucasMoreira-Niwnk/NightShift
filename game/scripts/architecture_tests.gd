extends RefCounted

const Layout = preload("res://scripts/building_layout.gd")

func run(game: Node, test: Node) -> void:
	var original: Dictionary = game.chapter.serialize_state()
	test.check(game.world.architecture.window_count >= 20, "Facades and stairwells contain real window openings")
	test.check(is_equal_approx(game.world.upper.position.y, 4.2), "Upper storey sits directly above ground floor")
	for id in ["repair_note", "network_patch", "meeting_minutes", "cam04", "cam05"]:
		var point: Vector3 = game.world.objects[id].global_position
		test.check(absf(point.x) < 8 and point.z > -14 and point.z < 10 and point.y > 4.2, "Upper evidence lies within stacked footprint: " + id)
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(4, 6, -5), Vector3(4, 3.9, -5)))
	test.check(not floor_hit.is_empty() and absf(floor_hit.position.y - 4.2) < 0.02, "Upper floor has physical support above archive")
	var pane_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(7, 1.7, 6.2), Vector3(9, 1.7, 6.2)))
	test.check(not pane_hit.is_empty() and absf(pane_hit.position.x - 8) < 0.03, "Window panes physically close the facade apertures")
	var exterior_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 1.7, 17), Vector3(0, 1.7, 23)))
	test.check(exterior_hit.is_empty(), "Former porch end wall no longer blocks exterior exploration")
	game.player.position = Vector3(7, 0.05, 6.2)
	game.player.rotation.y = 0
	game.player.velocity = Vector3.ZERO
	Input.action_press("move_right")
	for tick in range(42): await game.get_tree().physics_frame
	Input.action_release("move_right")
	test.check(game.player.position.x < 7.75 and game.player.position.y > -0.1, "Player cannot walk through facade glass")
	var legacy: Dictionary = original.duplicate(true)
	legacy.erase("map_revision")
	legacy.position = [-6.6, 4.25, -31.5]
	var file := FileAccess.open(game.chapter.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	test.check(game.chapter.load_game(), "Old map checkpoint can be loaded")
	test.check(game.player.position.distance_to(Layout.upper_point(Vector3(-6.6, 4.25, -31.5))) < 0.01, "Legacy checkpoint is relocated to its corresponding upstairs room")
	file = FileAccess.open(game.chapter.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(original))
	file.close()
	test.check(game.chapter.load_game(), "Current architecture checkpoint restores unchanged")
	test.check(game.player.position.distance_to(Vector3(original.position[0], original.position[1], original.position[2])) < 0.01, "Current checkpoint is not transformed a second time")
	if test.failures == 0: print("ARCHITECTURE_TEST_OK: stacked floors, facade glass, exterior access, checkpoint migration")
