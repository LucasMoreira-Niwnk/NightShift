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
	# Regressions for the visible slots around the staircase doorway and slabs.
	for x in [-2.6, -1.0, 1.0, 2.6]:
		for y in [0.5, 1.7, 3.1, 3.8]:
			var jamb := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, y, -16.5), Vector3(x, y, -15.2)))
			test.check(not jamb.is_empty(), "Stair doorway jamb closes former slot: " + str(Vector2(x, y)))
	for y in [2.8, 3.55, 3.95]:
		var lintel := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, y, -16.5), Vector3(0, y, -15.2)))
		test.check(not lintel.is_empty(), "Ground doorway lintel seals ceiling plenum: " + str(y))
	var upper_lintel := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 7, -14.7), Vector3(0, 7, -13.3)))
	test.check(not upper_lintel.is_empty(), "Upper doorway has a solid lintel")
	for z in [-14.05, -13.95, -12.0]:
		test.check(top_surfaces(game.world, Vector3(0, 4.2, z)) == 1, "Landing and upstairs floor meet without coplanar tile overlays: " + str(z))
	var soffit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 3.8, -16.7), Vector3(0, 4.3, -16.7)))
	test.check(not soffit.is_empty() and absf(soffit.position.y - 4.04) < 0.01, "Upper landing has a continuous structural soffit")
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

func top_surfaces(world: Node3D, point: Vector3) -> int:
	var count := 0
	for mesh in world.find_children("*", "MeshInstance3D", true, false):
		if not mesh.mesh is BoxMesh or not mesh.visible: continue
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		if absf(bounds.end.y - point.y) < 0.002 and point.x > bounds.position.x and point.x < bounds.end.x and point.z > bounds.position.z and point.z < bounds.end.z:
			count += 1
	return count
