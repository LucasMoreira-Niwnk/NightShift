extends RefCounted

func run(game: Node, test: Node) -> void:
	var failures_before: int = test.failures
	var finish: Node3D = game.world.staircases.get_node_or_null("AcabamentoEscadariaPrincipal")
	test.check(finish != null,"Authored main stair finish is applied")
	if finish == null: return
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	for point in [Vector3(0,0,-23.7),Vector3(1.6,0,-21),Vector3(2.5,0,-19.5)]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.25,point-Vector3.UP*0.3))
		test.check(not hit.is_empty() and absf(hit.position.y)<0.015,"Ground floor closes the former terrain gap: "+str(point))
	var ground := finish.get_node("PisoTerreoContinuo") as MeshInstance3D
	var floor_material := ground.material_override as StandardMaterial3D
	test.check(floor_material != null and floor_material.albedo_texture != null and floor_material.normal_texture != null,"Main stair ground uses photographic concrete")
	for point in [Vector3(0,0,-17),Vector3(0,2.1,-23.35),Vector3(0,4.2,-16)]:
		var textured := false
		for mesh in game.world.staircases.get_children():
			if not mesh is MeshInstance3D or not mesh.mesh is BoxMesh: continue
			var bounds: AABB = mesh.global_transform*mesh.get_aabb()
			if absf(bounds.end.y-point.y)>0.002 or bounds.size.x<5.5: continue
			if point.z<bounds.position.z or point.z>bounds.end.z: continue
			var material := mesh.material_override as StandardMaterial3D
			textured = material != null and material.albedo_texture != null
		test.check(textured,"Main landing has a textured finish at height "+str(point.y))
	for x in [-1.4,2.7]:
		var guard := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,4.75,-16.6),Vector3(x,4.75,-18.6)))
		test.check(not guard.is_empty() and guard.collider.get_meta("main_stair_guard",false),"Upper parapet physically covers open edge: "+str(x))
	var entrance := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(1.4,4.75,-17),Vector3(1.4,4.75,-18.5)))
	test.check(entrance.is_empty(),"Upper flight remains open between the parapets")
	var original_position: Vector3 = game.player.position
	var original_rotation: Vector3 = game.player.rotation
	var original_camera: Transform3D = game.player.camera.transform
	var chapter_processing: bool = game.chapter.is_processing()
	var director_processing: bool = game.director.is_processing()
	game.chapter.set_process(false)
	game.director.set_process(false)
	game.player.position = Vector3(-1.4,4.25,-16.8)
	game.player.rotation = Vector3.ZERO
	game.player.velocity = Vector3.ZERO
	for tick in range(45):
		Input.action_press("move_forward")
		await game.get_tree().physics_frame
	Input.action_release("move_forward")
	test.check(game.player.position.y>4.1 and game.player.position.z>-17.8,"Controller cannot walk off the upper landing through the parapet")
	game.player.position = original_position
	game.player.rotation = original_rotation
	game.player.camera.transform = original_camera
	game.player.velocity = Vector3.ZERO
	game.chapter.set_process(chapter_processing)
	game.director.set_process(director_processing)
	await game.get_tree().physics_frame
	if test.failures == failures_before: print("STAIR_FINISH_TEST_OK: continuous textured ground, three landings, upper parapets, clear stair route")
