extends RefCounted

# One reference for the physical lenses, live feeds and recorded viewpoints.
const POSITIONS := [Vector3(5.5, 2.7, 11.4), Vector3(1.7, 2.7, 3.4), Vector3(7.6, 2.7, -9.5), Vector3(1.2, 6.8, -12), Vector3(7.44, 6.9, 4)]
const TARGETS := [Vector3(-2, 1.1, 7.5), Vector3(0, 1.1, -11), Vector3(4, 0.8, -5.5), Vector3(0, 5.3, 3), Vector3(4.4, 5.1, -2)]
const Art = preload("res://scripts/art.gd")

static func install(world: Node3D) -> void:
	for index in range(POSITIONS.size()):
		var mount: Node3D
		if index >= 3:
			mount = world.item("cam%02d" % (index + 1), "Inspecionar CAM-%02d%s" % [index + 1, " e cabeamento" if index == 3 else " / arquivo da reunião"], POSITIONS[index], Vector3(0.36, 0.4, 0.6), Color.WHITE, false)
		else:
			mount = Node3D.new()
			world.add_child(mount)
			mount.position = POSITIONS[index]
		mount.name = "CAM_%02d_Mount" % (index + 1)
		mount.look_at(TARGETS[index], Vector3.UP)
		var lens := Marker3D.new()
		lens.name = "Lens"
		mount.add_child(lens)
		# Housing stays behind the optical origin; -Z is the filming direction.
		Art.rounded_box(mount, Vector3(0, 0, 0.2), Vector3(0.25, 0.18, 0.4), Color(0.35, 0.37, 0.32))
		var aperture := MeshInstance3D.new()
		var glass := CylinderMesh.new()
		glass.top_radius = 0.065
		glass.bottom_radius = 0.065
		glass.height = 0.025
		glass.radial_segments = 32
		aperture.mesh = glass
		aperture.rotation.x = PI / 2
		aperture.position.z = 0.005
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.008, 0.025, 0.03)
		material.metallic = 0.5
		aperture.material_override = material
		mount.add_child(aperture)
		Art.box(mount, Vector3(-0.1, 0.05, 0.02), Vector3(0.02, 0.02, 0.02), Color(0.2, 0.8, 0.35))
		var ceiling := 3.0 if index < 3 else 7.2
		var height: float = ceiling - POSITIONS[index].y
		var support := Node3D.new()
		mount.add_child(support)
		support.global_transform = Transform3D(Basis.IDENTITY, POSITIONS[index])
		Art.box(support, Vector3(0, height / 2, 0.15), Vector3(0.065, height, 0.065), Color(0.17, 0.2, 0.18))
		Art.box(support, Vector3(0, height, 0.15), Vector3(0.23, 0.035, 0.23), Color(0.17, 0.2, 0.18))
		# Main camera sees layer 2. CCTV excludes it, so a lens cannot film itself.
		world.upper.mesh_layers(mount, 2)
		world.camera_mounts.append(mount)
	world.upper.add_label("CAM-04\nRACK 2B — PORTA 07", Vector3(1.82, 1.58, -28), -PI / 2, 0.0009)
