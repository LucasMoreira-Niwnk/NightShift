extends Node3D
var source: Light3D
var world: Node
var nominal := 1.0
var glow: Array = []

func bind(lamp: Light3D, building: Node) -> void:
	source = lamp
	world = building
	nominal = maxf(source.light_energy,0.01)
	for mesh in find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for index in range(mesh.mesh.get_surface_count()):
			var material: Material = mesh.get_active_material(index)
			if material is StandardMaterial3D and (material.emission_enabled or "glass" in material.resource_name.to_lower()):
				material = material.duplicate()
				mesh.set_surface_override_material(index,material)
				glow.append({"material":material,"albedo":material.albedo_color})
	update_state()

func update_state() -> void:
	if not is_instance_valid(source) or world == null: return
	var powered: bool = world.interior_powered and source.visible and source.light_energy>0.001
	var strength := clampf(source.light_energy/nominal,0,1) if powered else 0.0
	for entry in glow:
		var material: StandardMaterial3D = entry.material
		material.emission_enabled = powered
		material.emission = source.light_color
		material.emission_energy_multiplier = strength*0.7
		var shade := lerpf(0.12,1.0,strength)
		material.albedo_color = entry.albedo*Color(shade,shade,shade,1)

func _process(_delta: float) -> void: update_state()
