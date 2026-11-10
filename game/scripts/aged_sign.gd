extends Label3D

func _ready() -> void:
	if text == "SEM LINHA": return
	call_deferred("build_plate")

func build_plate() -> void:
	var face := SystemFont.new()
	face.font_names = PackedStringArray(["Georgia","Times New Roman"])
	font = face
	modulate = Color(0.22,0.19,0.13)
	var measured := face.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,-1,font_size)
	var dimensions := measured * pixel_size + Vector2(0.18,0.13)
	var plate := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = dimensions
	plate.mesh = quad
	plate.position.z = -0.012
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://shaders/aged_enamel.gdshader")
	plate.material_override = surface
	add_child(plate)
	# Four oxidised screw heads sit on the same plate, behind the lettering.
	for x in [-1.0,1.0]:
		for y in [-1.0,1.0]:
			var screw := MeshInstance3D.new()
			var head := SphereMesh.new()
			head.radius = 0.013
			head.height = 0.026
			screw.mesh = head
			screw.position = Vector3(x*(dimensions.x/2-0.04),y*(dimensions.y/2-0.035),-0.003)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.25,0.15,0.075)
			material.roughness = 0.9
			screw.material_override = material
			add_child(screw)
