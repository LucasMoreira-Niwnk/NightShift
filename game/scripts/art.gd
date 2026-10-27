extends RefCounted

const Materials = preload("res://scripts/materials.gd")

static func model(parent: Node3D, asset: String, position: Vector3, dimensions: Vector3, angle: float = 0) -> Node3D:
	return load_fitted(parent, "res://assets/models/kenney/" + asset + ".glb", position, dimensions, angle, true)

static func external(parent: Node3D, asset: String, position: Vector3, dimensions: Vector3, angle: float = 0) -> Node3D:
	return load_fitted(parent, "res://assets/models/polyhaven/%s/%s_1k.gltf" % [asset, asset], position, dimensions, angle, false)

static func flashlight(parent: Node3D, position: Vector3, length: float = 0.24) -> Node3D:
	return load_fitted(parent, "res://assets/models/flashlight/led_flashlight.glb", position, Vector3(length, length * 0.246, length * 0.241), PI / 2, false)

static func load_fitted(parent: Node3D, path: String, position: Vector3, dimensions: Vector3, angle: float, stylized: bool) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Missing art asset: " + path)
		return null
	var holder := Node3D.new()
	holder.name = path.get_file().get_basename() + "Model"
	# Keep the imported source resources alive for Godot 4.0's GLES renderer.
	holder.set_meta("source_scene", packed)
	parent.add_child(holder)
	holder.position = position
	holder.rotation.y = angle
	var instance := packed.instantiate() as Node3D
	holder.add_child(instance)
	if "binder_notebook" in path:
		select_closed_notebook(instance)
	if "vintage_radio_transceiver" in path:
		select_radio_body(instance)
	var bounds := mesh_bounds(instance, Transform3D.IDENTITY)
	var factor := dimensions / bounds.size
	if path.ends_with("books.glb"):
		factor = Vector3.ONE * minf(factor.x, minf(factor.y, factor.z))
	instance.scale = factor
	instance.position = -(bounds.position + Vector3(bounds.size.x * 0.5, 0, bounds.size.z * 0.5)) * factor
	if stylized:
		restyle(instance)
	else:
		preserve_pbr(instance)
	return holder

static func wall_diagram(parent: Node3D, size: Vector3) -> void:
	box(parent, Vector3.ZERO, Vector3(0.012, size.y, size.z), Color(0.7, 0.7, 0.58))
	for index in range(4):
		var y := 0.18 - index * 0.12
		box(parent, Vector3(0.008, y, 0), Vector3(0.002, 0.006, 0.22), Color(0.13, 0.2, 0.16))
		var label := Label3D.new()
		label.text = ["ORDEM", "ARQUIVADA", "ADMIN", "2º ANDAR"][index]
		label.position = Vector3(0.012, y + 0.025, 0)
		label.rotation.y = PI / 2
		label.font_size = 32
		label.pixel_size = 0.0008
		label.outline_size = 0
		label.modulate = Color(0.12, 0.17, 0.12)
		parent.add_child(label)

static func select_closed_notebook(node: Node) -> void:
	if node is MeshInstance3D: node.visible = "closed" in node.name.to_lower()
	for child in node.get_children(): select_closed_notebook(child)

static func select_radio_body(node: Node) -> void:
	if node is MeshInstance3D:
		node.visible = node.name == "vintage_radio_transceiver" or node.name == "vintage_radio_transceiver_dial"
	for child in node.get_children(): select_radio_body(child)

static func preserve_pbr(node: Node) -> void:
	if node is MeshInstance3D:
		node.mesh = node.mesh.duplicate()
		for index in range(node.mesh.get_surface_count()):
			var original := node.get_active_material(index) as StandardMaterial3D
			if original == null: continue
			var material := StandardMaterial3D.new()
			for property in ["albedo_color", "albedo_texture", "metallic", "metallic_texture", "metallic_texture_channel", "roughness", "roughness_texture", "roughness_texture_channel", "normal_enabled", "normal_texture", "normal_scale", "ao_enabled", "ao_texture", "ao_texture_channel", "transparency", "cull_mode"]:
				material.set(property, original.get(property))
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			node.mesh.surface_set_material(index, material)
	for child in node.get_children(): preserve_pbr(child)

static func mesh_bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	if not node.visible: return AABB()
	var transform := parent_transform * node.transform
	var result := AABB()
	var found := false
	if node is MeshInstance3D and node.mesh != null:
		result = transform * node.get_aabb()
		found = true
	for child in node.get_children():
		if child is Node3D:
			var bounds := mesh_bounds(child, transform)
			if bounds.size.length_squared() > 0:
				result = result.merge(bounds) if found else bounds
				found = true
	return result

static func restyle(node: Node) -> void:
	if node is MeshInstance3D:
		# Bake per-instance materials into a mesh copy instead of GLES overrides.
		node.mesh = node.mesh.duplicate()
		for index in range(node.mesh.get_surface_count()):
			var original := node.get_active_material(index) as StandardMaterial3D
			if original == null: continue
			var material := StandardMaterial3D.new()
			material.albedo_color = original.albedo_color
			material.roughness = 0.9
			var name := original.resource_name.to_lower()
			if "wood" in name:
				material = Materials.surface("wood")
			elif "metal" in name:
				material.albedo_color = material.albedo_color.darkened(0.45)
				material.metallic = 0.25
				material.roughness = 0.6
			elif "lamp" in name:
				material.emission_enabled = true
				material.emission = Color(0.65, 0.75, 0.58)
			else:
				material.albedo_color = material.albedo_color.darkened(0.28)
			node.mesh.surface_set_material(index, material)
	for child in node.get_children(): restyle(child)

static func box(parent: Node3D, position: Vector3, dimensions: Vector3, color: Color, material: Material = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = dimensions
	mesh.mesh = geometry
	mesh.position = position
	if material == null:
		var surface := StandardMaterial3D.new()
		surface.albedo_color = color
		surface.roughness = 0.8
		material = surface
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

static func rounded_box(parent: Node3D, position: Vector3, dimensions: Vector3, color: Color, radius: float = 0.025) -> MeshInstance3D:
	var mesh := box(parent, position, dimensions, color)
	mesh.mesh = preload("res://scripts/rounded_mesh.gd").box(dimensions, radius)
	return mesh

static func book(parent: Node3D, size: Vector3, title: String, color: Color) -> void:
	box(parent, Vector3.ZERO, size * Vector3(0.94, 0.75, 0.94), Color(0.63, 0.59, 0.45))
	for y in [-size.y * 0.45, size.y * 0.45]:
		box(parent, Vector3(0, y, 0), Vector3(size.x, size.y * 0.1, size.z), color)
	box(parent, Vector3(-size.x * 0.48, 0, 0), Vector3(size.x * 0.06, size.y, size.z), color)
	for y in [-0.02, 0.0, 0.02]:
		box(parent, Vector3(0.01, y, size.z * 0.473), Vector3(size.x * 0.87, 0.002, 0.002), Color(0.27, 0.25, 0.19))
	var label := Label3D.new()
	label.text = title
	label.font_size = 32
	label.pixel_size = 0.0007
	label.outline_size = 0
	label.rotation.x = -PI / 2
	label.position = Vector3(0, size.y * 0.51, 0)
	label.modulate = Color(0.74, 0.67, 0.42)
	parent.add_child(label)

static func paper(parent: Node3D, size: Vector3, envelope: bool) -> void:
	box(parent, Vector3.ZERO, Vector3(size.x, 0.012, size.z), Color(0.63, 0.58, 0.42))
	for index in range(5):
		box(parent, Vector3(0, 0.007, -size.z * 0.3 + index * size.z * 0.12), Vector3(size.x * 0.65, 0.001, 0.003), Color(0.19, 0.2, 0.17))
	if envelope:
		var fold := box(parent, Vector3(0, 0.012, -0.03), Vector3(size.x * 0.75, 0.005, size.z * 0.5), Color(0.47, 0.41, 0.27))
		fold.rotation.y = 0.1
