extends RefCounted
const Art = preload("res://scripts/art.gd")

func run(game: Node, test: Node) -> void:
	var failures_before: int = test.failures
	var authored: Node3D = load("res://scenes/cenario_editavel.tscn").instantiate()
	game.add_child(authored)
	var by_id := {}
	for node in authored.find_children("*","Node3D",true,false):
		if node.has_meta("vesper_source_id") and not by_id.has(node.get_meta("vesper_source_id")):
			by_id[node.get_meta("vesper_source_id")] = node
	for id in ["envelope","phone","recorder","flashlight","network_log","it_terminal","fuse_slot"]:
		var live: Node3D = game.world.objects[id]
		var key: String = live.get_meta("vesper_applied_id","")
		test.check(by_id.has(key),"Interaction has an authored placement: "+id)
		if not by_id.has(key): continue
		var saved: Node3D = by_id[key]
		test.check(live.global_transform.is_equal_approx(saved.global_transform),"Runtime keeps edited interaction root: "+id)
		var expected := saved.find_children("*","CollisionShape3D",false,false)
		var actual := live.find_children("*","CollisionShape3D",false,false)
		if not expected.is_empty() and not actual.is_empty():
			test.check(actual[0].global_transform.is_equal_approx(expected[0].global_transform),"Edited interaction collision follows saved placement: "+id)
		test.check(live.action.is_valid(),"Placement edit preserves live interaction: "+id)
	authored.free()
	var benches := 0
	var book_rows := 0
	for node in game.world.find_children("*","Node3D",true,false):
		if node.get_meta("vesper_prop","") == "real_bench":
			benches += 1
			test.check(not node.find_children("*","CollisionShape3D",true,false).is_empty(),"Photographic bench owns physical collision")
		if node.has_meta("vesper_shelf_top"):
			book_rows += 1
			var bounds := Art.mesh_bounds(node,Transform3D.IDENTITY)
			test.check(absf(bounds.position.y-float(node.get_meta("vesper_shelf_top"))-0.0015)<0.004,"Books stand on actual shelf surface")
			test.check(bounds.position.x > -0.64 and bounds.end.x < 0.64,"Books fit within shelf sides")
	test.check(benches>=5 and book_rows>=12,"Detailed bench and encyclopedia replacements are instantiated")
	var cabinet: Node3D = game.world.objects.it_cabinet
	var socket := cabinet.get_node("FuseSocket") as Node3D
	test.check(game.world.objects.fuse20.global_transform.is_equal_approx(socket.global_transform),"Spare follows editable cabinet socket")
	test.check(cabinet.position.x>-2.5,"TI cabinet leaves the desk aisle clear")
	if test.failures == failures_before: print("PROP_LAYOUT_TEST_OK: saved interaction transforms, collision, realistic props, shelf support, cabinet socket")
