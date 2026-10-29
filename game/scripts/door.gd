extends StaticBody3D

signal operated(opened)

var glazed := false
var is_open := false
var moving := false
var pivot: Node3D
var collider: CollisionShape3D
var access: Callable
var display_name := "porta"
var forced_locked := false
var handle: Node3D
var animation: Tween
var override_action: Callable
var custom_prompt := ""

func interaction_prompt() -> String:
	if not custom_prompt.is_empty(): return custom_prompt
	return "E — Fechar " + display_name if is_open else "E — Abrir " + display_name

func _ready() -> void:
	name = "InteractiveDoor"
	pivot = Node3D.new()
	pivot.position.x = -0.75
	add_child(pivot)
	handle = Node3D.new()
	handle.position = Vector3(1.3, 1.16, 0)
	pivot.add_child(handle)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 2.5, 0.15)
	mesh.mesh = box
	mesh.position = Vector3(0.75, 1.25, 0)
	pivot.add_child(mesh)
	mesh.material_override = preload("res://scripts/materials.gd").fitting(Color(0.24,0.28,0.22))
	if glazed:
		mesh.material_override = preload("res://scripts/materials.gd").fitting(Color(0.3,0.32,0.28),true)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for x in [0.04, 1.46]: aged_box(pivot, Vector3(x, 1.25, 0), Vector3(0.08, 2.5, 0.17), Color(0.12, 0.17, 0.15))
		for y in [0.06, 1.0, 2.45]: aged_box(pivot, Vector3(0.75, y, 0), Vector3(1.5, 0.09, 0.17), Color(0.12, 0.17, 0.15))
	# The visual frame sits outside the existing clear opening.
	for x in [-0.8, 0.8]:
		aged_box(self, Vector3(x, 1.25, 0), Vector3(0.1, 2.6, 0.24), Color(0.09, 0.13, 0.12))
	aged_box(self, Vector3(0, 2.55, 0), Vector3(1.7, 0.1, 0.24), Color(0.09, 0.13, 0.12))
	for side in [-1.0, 1.0]:
		for y in ([] if glazed else [0.65, 1.6]):
			aged_box(pivot, Vector3(0.75, y, side * 0.08), Vector3(1.15, 0.65, 0.025), Color(0.14, 0.19, 0.16))
		aged_box(pivot, Vector3(1.3, 1.15, side * 0.1), Vector3(0.1, 0.24, 0.025), Color(0.38, 0.4, 0.34))
		aged_box(handle, Vector3(-0.09, 0, side * 0.15), Vector3(0.24, 0.045, 0.06), Color(0.54, 0.54, 0.45))
		aged_box(pivot, Vector3(0.75, 2.15, side * 0.09), Vector3(0.95, 0.22, 0.025), Color(0.045, 0.07, 0.06))
		var label := Label3D.new()
		label.shaded = true
		label.text = display_name.to_upper()
		label.position = Vector3(0.75, 2.15, side * 0.11)
		label.rotation.y = PI if side < 0 else 0.0
		label.font_size = 32
		label.pixel_size = 0.0011
		label.outline_size = 0
		pivot.add_child(label)
	for y in [0.35, 1.25, 2.2]:
		aged_box(pivot, Vector3(0.03, y, 0), Vector3(0.08, 0.16, 0.21), Color(0.3, 0.33, 0.29))
	collider = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collider.shape = shape
	collider.position.y = 1.25
	add_child(collider)

func interact() -> void:
	if override_action.is_valid() and override_action.call(): return
	if moving:
		return
	if forced_locked and not Engine.get_main_loop().has_meta("debug_free_roam"):
		return
	if access.is_valid() and not access.call():
		return
	set_open(not is_open)

func restore_open(value: bool) -> void:
	if animation != null and animation.is_valid(): animation.kill()
	moving = false
	handle.rotation.z = 0
	is_open = value
	set_collision_layer_value(1, not is_open)
	set_collision_layer_value(2, true)
	pivot.rotation.y = -PI / 2.0 if is_open else 0.0

func set_open(value: bool) -> void:
	if moving or value == is_open:
		return
	moving = true
	is_open = value
	if value: operated.emit(true)
	# The closed doorway is the interaction target even while the door is open.
	# Disable physical obstruction, retaining ray detection on collision layer 2.
	set_collision_layer_value(1, not is_open)
	set_collision_layer_value(2, true)
	animation = create_tween()
	animation.tween_property(pivot, "rotation:y", -PI / 2.0 if is_open else 0.0, 0.35)
	await animation.finished
	if not value: operated.emit(false)
	moving = false

func aged_box(parent: Node3D, point: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := preload("res://scripts/art.gd").box(parent,point,size,color)
	mesh.material_override = preload("res://scripts/materials.gd").fitting(color)
	return mesh
