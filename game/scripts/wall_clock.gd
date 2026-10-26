extends Node3D

var hour_hand: Node3D
var minute_hand: Node3D
var readout: Label3D
var displayed_time := "23:57"
const Art = preload("res://scripts/art.gd")

func _ready() -> void:
	disc(0.3, 0.065, 0, Color(0.08, 0.12, 0.11))
	disc(0.267, 0.015, 0.04, Color(0.72, 0.72, 0.61))
	for index in range(60):
		var angle := index * TAU / 60.0
		var tick := Art.box(self, Vector3(sin(angle) * 0.245, cos(angle) * 0.245, 0.055), Vector3(0.008, 0.025 if index % 5 == 0 else 0.01, 0.004), Color(0.08, 0.12, 0.1))
		tick.rotation.z = -angle
	for number in [3, 6, 9, 12]:
		var angle: float = number * TAU / 12.0
		var label := Label3D.new()
		label.text = str(number)
		label.position = Vector3(sin(angle) * 0.205, cos(angle) * 0.205, 0.061)
		label.font_size = 40
		label.pixel_size = 0.001
		label.outline_size = 0
		label.modulate = Color(0.07, 0.11, 0.09)
		add_child(label)
	hour_hand = hand(0.13, 0.017, 0.07)
	minute_hand = hand(0.19, 0.01, 0.078)
	disc(0.018, 0.008, 0.087, Color(0.21, 0.12, 0.06))
	Art.box(self, Vector3(0, -0.4, 0), Vector3(0.57, 0.13, 0.045), Color(0.07, 0.11, 0.1))
	readout = Label3D.new()
	readout.position = Vector3(0, -0.4, 0.028)
	readout.font_size = 48
	readout.pixel_size = 0.0014
	readout.outline_size = 0
	readout.modulate = Color(0.64, 0.79, 0.64)
	add_child(readout)
	set_time(displayed_time)

func disc(radius: float, depth: float, z: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = depth
	cylinder.radial_segments = 64
	mesh.mesh = cylinder
	mesh.rotation.x = PI / 2
	mesh.position.z = z
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	mesh.material_override = material
	add_child(mesh)

func hand(length: float, width: float, z: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position.z = z
	add_child(pivot)
	Art.box(pivot, Vector3(0, length * 0.5, 0), Vector3(width, length, 0.006), Color(0.035, 0.055, 0.04))
	return pivot

func set_time(value: String) -> void:
	displayed_time = value
	if readout == null: return
	readout.text = value
	var parts := value.split(":")
	var hour := int(parts[0]) % 12
	var minute := int(parts[1])
	hour_hand.rotation.z = -(hour + minute / 60.0) * TAU / 12.0
	minute_hand.rotation.z = -minute * TAU / 60.0
