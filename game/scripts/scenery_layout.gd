extends RefCounted
# The authored scene stores scenery edits; gameplay objects keep their scripts.
const ID := "vesper_source_id"
const ATOMIC := "vesper_asset"
const REFERENCE := "vesper_gameplay_reference"
const PROPERTIES := ["transform","visible","layers","cast_shadow","material_override","mesh","shape","disabled","collision_layer","collision_mask","light_color","light_energy","light_indirect_energy","light_volumetric_fog_energy","light_size","shadow_enabled","omni_range","omni_attenuation","spot_range","spot_angle","spot_attenuation","text","font_size","pixel_size","modulate","albedo_color"]
var nodes: Dictionary = {}
var protected: Dictionary = {}
var assets: Dictionary = {}
var excluded: Array = []
var reference_nodes: Array = []
var containers: Array = []

func build_index(game: Node) -> void:
	nodes.clear()
	protected.clear()
	assets.clear()
	reference_nodes = game.world.camera_mounts.duplicate()
	reference_nodes.append_array([game.world.phone_display,game.world.upper.camera_chair,game.world.upper.warning,game.world.upper.window_shadow])
	containers = [game.world,game.world.architecture,game.world.staircases,game.world.upper]
	excluded = [game.world.figure,game.world.figure_volume,game.world.double,game.world.drifting_fog,game.world.chair_marks]
	index_node(game.world,"world",false)
	index_node(game.computer,"terminal",true)

func index_node(node: Node, key: String, reference: bool) -> void:
	if node in excluded or not node is Node3D: return
	nodes[key] = node
	var path := node.scene_file_path
	var script: Script = node.get_script()
	var script_path := script.resource_path if script != null else ""
	var is_reference := reference or node in reference_nodes or script_path in ["res://scripts/interactable.gd","res://scripts/door.gd","res://scripts/wall_clock.gd","res://scripts/floor_plan.gd"]
	if is_reference:
		protected[key] = true
		return
	if not path.is_empty():
		assets[key] = true
		return
	var counts := {}
	for child in node.get_children():
		if not child is Node3D: continue
		var child_script: Script = child.get_script()
		var token: String = child.get_class()+str(child.transform)+(child_script.resource_path if child_script != null else "")
		if child.has_meta("source_scene"): token += child.get_meta("source_scene").resource_path
		if child is MeshInstance3D and child.mesh != null: token += str(child.get_aabb())
		var digest := token.md5_text().left(16)
		var ordinal: int = counts.get(digest,0)
		counts[digest] = ordinal+1
		index_node(child,key+"/"+digest+"_"+str(ordinal),false)

func apply(game: Node, authored: Node3D) -> void:
	build_index(game)
	var present := {}
	apply_node(authored,game.world,present)
	# Only remove elements which were part of the saved baseline. New code-side
	# scenery and gameplay references are never removed by an older snapshot.
	for key in authored.get_meta("vesper_baseline",PackedStringArray()):
		if present.has(key) or protected.has(key) or not nodes.has(key): continue
		var target = nodes[key]
		if is_instance_valid(target) and not target in containers: target.free()
	# Remove deleted light references before the scripted rhythm/power updates.
	var world: Node = game.world
	for field in ["corridor_lights","interior_lights","lighting_fixtures"]:
		world.set(field,world.get(field).filter(func(value): return is_instance_valid(value)))
	world.room_lights = world.room_lights.filter(func(entry): return is_instance_valid(entry.light))
	for entry in world.room_lights: entry.energy = entry.light.light_energy
	world.lighting_fixtures = world.lighting_fixtures.filter(func(fixture): return is_instance_valid(fixture.source))
	for fixture in world.lighting_fixtures: fixture.nominal = maxf(fixture.source.light_energy,0.01)
	world.upper.lights = world.upper.lights.filter(func(value): return is_instance_valid(value))
	world.upper.emergency_lights = world.upper.emergency_lights.filter(func(value): return is_instance_valid(value))
	world.staircases.service_lights = world.staircases.service_lights.filter(func(value): return is_instance_valid(value))
	world.building_lights.clear()
	world.powered_materials.clear()
	world.capture_building_power()
	world.set_interior_power(world.interior_powered)

func apply_node(authored: Node, parent: Node3D, present: Dictionary) -> void:
	if authored.get_meta("vesper_editor_only",false): return
	if authored.has_meta(ID):
		var key: String = authored.get_meta(ID)
		if protected.has(key):
			# Keep the live script/state, but honor the editor's placement of the
			# complete interaction body (visuals and ray/physics collision together).
			if nodes.has(key) and is_instance_valid(nodes[key]):
				nodes[key].global_transform = authored.global_transform
				nodes[key].set_meta("vesper_applied_id",key)
				var script: Script = nodes[key].get_script()
				if script != null and script.resource_path == "res://scripts/interactable.gd":
					apply_reference_children(authored,nodes[key])
			return
		if present.has(key):
			add_manual_branch(authored,parent)
			return
		present[key] = true
		if not nodes.has(key): return
		var target: Node3D = nodes[key]
		if not is_instance_valid(target): return
		target.set_meta("vesper_applied_id",key)
		target.global_transform = authored.global_transform
		# Imported instances retain runtime material adaptations and power links.
		if not assets.has(key):
			for property in PROPERTIES:
				if property == "transform" or not property_exists(authored,property) or not property_exists(target,property): continue
				# Fixture materials are owned by their existing power controller.
				if property == "material_override" and in_fixture(target): continue
				target.set(property,authored.get(property))
		parent = target
		if assets.has(key):
			target.visible = authored.visible
			apply_asset_overrides(authored,target)
			return
	elif authored.name != "CenarioEditavel" and not contains_source(authored):
		add_manual_branch(authored,parent)
		return
	for child in authored.get_children():
		if child is Node3D: apply_node(child,parent,present)

func apply_reference_children(authored: Node3D, target: Node3D) -> void:
	# The authoring snapshot keeps the order of the generated Node3D children.
	# This also preserves edits made inside an interaction's mesh/model rather
	# than only at its root, without replacing its action or scripted visibility.
	var saved := authored.get_children().filter(func(node): return node is Node3D)
	var live := target.get_children().filter(func(node): return node is Node3D)
	for index in range(mini(saved.size(),live.size())):
		var source: Node3D = saved[index]
		var destination: Node3D = live[index]
		if source.get_class() != destination.get_class(): continue
		destination.transform = source.transform
		if not source.scene_file_path.is_empty(): apply_asset_overrides(source,destination)
		else: apply_reference_children(source,destination)

func in_fixture(node: Node) -> bool:
	var cursor := node
	while cursor != null:
		var script: Script = cursor.get_script()
		if script != null and script.resource_path == "res://scripts/lighting_fixture.gd": return true
		cursor = cursor.get_parent()
	return false

static func property_exists(node: Object, property: String) -> bool:
	for entry in node.get_property_list():
		if entry.name == property: return true
	return false

static func contains_source(node: Node) -> bool:
	for child in node.get_children():
		if child.has_meta(ID) or contains_source(child): return true
	return false

func apply_asset_overrides(authored: Node3D, target: Node3D) -> void:
	# Compare with the imported source, so untouched assets keep the runtime
	# aging/power materials while manual editor overrides are respected.
	var original: Node3D = load(authored.scene_file_path).instantiate()
	for child in authored.find_children("*","Node3D",true,false):
		var path := authored.get_path_to(child)
		var base := original.get_node_or_null(path)
		var live := target.get_node_or_null(path)
		if base == null:
			if live == null:
				var parent_path := str(path).get_base_dir()
				var destination: Node = target if parent_path.is_empty() else target.get_node_or_null(NodePath(parent_path))
				if destination != null: destination.add_child(child.duplicate(15))
			continue
		if live == null: continue
		for property in ["transform","visible","layers","cast_shadow","material_override","mesh"]:
			if not property_exists(child,property) or not property_exists(base,property): continue
			if child.get(property) != base.get(property): live.set(property,child.get(property))
		if child is MeshInstance3D and base is MeshInstance3D and child.mesh != null and base.mesh != null:
			for index in range(mini(child.mesh.get_surface_count(),base.mesh.get_surface_count())):
				var material: Material = child.get_surface_override_material(index)
				if material != base.get_surface_override_material(index): live.set_surface_override_material(index,material)
	original.free()

func add_manual_branch(authored: Node, parent: Node3D) -> void:
	var added := authored.duplicate(15)
	strip_preview_references(added)
	parent.add_child(added)
	if added is Node3D: added.global_transform = authored.global_transform

func strip_preview_references(node: Node) -> void:
	for child in node.get_children():
		if child.get_meta(REFERENCE,false) or child.get_meta("vesper_editor_only",false): child.free()
		else: strip_preview_references(child)
