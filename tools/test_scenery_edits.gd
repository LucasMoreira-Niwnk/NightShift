extends SceneTree
const Layout = preload("res://scripts/scenery_layout.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, text: String) -> void:
	if not value:
		failures += 1
		push_error("SCENERY_EDIT_FAILED: "+text)
func find_id(root_node: Node, id: String) -> Node:
	for node in root_node.find_children("*","Node3D",true,false):
		if node.get_meta("vesper_applied_id","") == id: return node
	return null
func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	var authored: Node3D = game.get_node("CenarioEditavel")
	var wall: MeshInstance3D
	var body: StaticBody3D
	var removed_id := ""
	var shelf := authored.find_child("AgedArchiveShelf_*",true,false)
	check(shelf != null and not shelf.find_children("*","StaticBody3D",true,false).is_empty(),"Archive shelf collision belongs to its editable furniture group")
	for node in authored.find_children("*","MeshInstance3D",true,false):
		if not node.has_meta(Layout.ID): continue
		if node.mesh is BoxMesh and wall == null:
			for child in node.get_children():
				if child is StaticBody3D and child.has_meta(Layout.ID):
					wall = node
					body = child
		elif node.mesh is CylinderMesh and removed_id.is_empty():
			removed_id = node.get_meta(Layout.ID)
			node.free()
	check(wall != null and body != null,"Editable geometry includes grouped collision")
	if wall == null or body == null:
		quit(1)
		return
	var wall_id: String = wall.get_meta(Layout.ID)
	var body_id: String = body.get_meta(Layout.ID)
	wall.position += Vector3(0,0.25,0)
	var expected_wall: Transform3D
	var expected_body: Transform3D
	var added := MeshInstance3D.new()
	added.name = "ManualAssetRegression"
	added.mesh = BoxMesh.new()
	added.position = Vector3(100,0,100)
	authored.add_child(added)
	added.owner = authored
	var added_body := StaticBody3D.new()
	added.add_child(added_body)
	added_body.owner = authored
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	added_body.add_child(shape)
	shape.owner = authored
	# Save/reload the edited map just as the editor does, without changing the
	# project's actual scenery file or the player's save.
	var duplicated: Node3D = wall.duplicate(15)
	wall.get_parent().add_child(duplicated)
	duplicated.name = "DuplicatedSceneryRegression"
	duplicated.position += Vector3(0,5,0)
	duplicated.owner = authored
	for child in duplicated.find_children("*","Node3D",true,false): child.owner = authored
	var asset_id := ""
	var material_path := NodePath()
	for node in authored.find_children("*","Node3D",true,false):
		if not node.get_meta(Layout.ATOMIC,false) or not node.has_meta(Layout.ID): continue
		var meshes := node.find_children("*","MeshInstance3D",true,false)
		if meshes.is_empty(): continue
		asset_id = node.get_meta(Layout.ID)
		var mesh: MeshInstance3D = meshes[0]
		material_path = node.get_path_to(mesh)
		var custom := StandardMaterial3D.new()
		custom.albedo_color = Color(0.42,0.24,0.11)
		mesh.material_override = custom
		mesh.owner = authored
		break
	var removed_asset := ""
	var removed_fixture := ""
	for node in authored.find_children("*","Node3D",true,false):
		if removed_fixture.is_empty() and node.name.begins_with("Luminaria_") and node.has_meta(Layout.ID):
			removed_fixture = node.get_meta(Layout.ID)
			node.free()
			break
	for node in authored.find_children("*","Node3D",true,false):
		if not node.get_meta(Layout.ATOMIC,false) or node.get_meta(Layout.ID,"") == asset_id: continue
		var holder := node.get_parent()
		if holder.has_meta(Layout.ID):
			removed_asset = holder.get_meta(Layout.ID)
			holder.free()
			break
	var wall_path := authored.get_path_to(wall)
	var body_path := authored.get_path_to(body)
	var edited := PackedScene.new()
	check(edited.pack(authored) == OK,"Edited scenery packs")
	check(ResourceSaver.save(edited,"user://scenery-edited-test.tscn") == OK,"Edited scenery saves")
	authored.free()
	authored = load("user://scenery-edited-test.tscn").instantiate()
	game.add_child(authored)
	wall = authored.get_node(wall_path)
	body = authored.get_node(body_path)
	root.add_child(game)
	game.chapter.save_path = "user://scenery-edit-regression.json"
	expected_wall = wall.global_transform
	expected_body = body.global_transform
	await process_frame
	await process_frame
	check(game.scenery_applied,"Game consumed the editable scene")
	var live_wall := find_id(game.world,wall_id) as Node3D
	var live_body := find_id(game.world,body_id) as Node3D
	check(live_wall != null and live_wall.global_transform.is_equal_approx(expected_wall),"Moved scenery appears in gameplay")
	check(live_body != null and live_body.global_transform.is_equal_approx(expected_body),"Collision follows the moved scenery")
	var updated := Layout.new()
	updated.build_index(game)
	check(removed_id != "" and not updated.nodes.has(removed_id),"Deleted scenery is absent in gameplay")
	check(not updated.nodes.has(removed_asset),"Deleting an imported asset removes its full subtree")
	check(not updated.nodes.has(removed_fixture),"Deleted fixture is removed without stale light links")
	game.world.set_interior_power(false)
	game.world.set_interior_power(true)
	check(game.world.find_child("ManualAssetRegression",true,false) != null,"Manually added asset appears in gameplay")
	check(game.world.find_child("DuplicatedSceneryRegression",true,false) != null,"Ctrl+D scenery duplication creates an independent instance")
	var live_asset := find_id(game.world,asset_id)
	check(live_asset != null,"Imported asset remains bound to gameplay")
	if live_asset != null:
		var edited_mesh: MeshInstance3D = live_asset.get_node(material_path)
		check(edited_mesh.material_override is StandardMaterial3D and edited_mesh.material_override.albedo_color.is_equal_approx(Color(0.42,0.24,0.11)),"Saved imported material override reaches gameplay")
	check(game.world.doors.security.has_method("interact") and game.computer.has_method("select_camera"),"Gameplay references retain their scripts")
	await physics_frame
	var hit: Dictionary = game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(100,2,100),Vector3(100,-1,100)))
	check(not hit.is_empty(),"Manually added collision is active")
	if failures == 0: print("SCENERY_EDIT_TEST_OK: move, grouped collision, add, delete, preserved gameplay")
	quit(0 if failures == 0 else 1)
