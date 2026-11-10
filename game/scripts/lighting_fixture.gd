extends Node3D
const Art = preload("res://scripts/art.gd")
var source: Light3D
var wall_mount := false
var model_asset := ""
var model_dimensions := Vector3.ZERO
var world: Node
var glow: Array = []
var nominal := 1.0

func _ready() -> void:
	nominal = maxf(source.light_energy,0.01)
	var model: Node3D
	if not model_asset.is_empty():
		model = Art.external(self,model_asset,Vector3.ZERO,model_dimensions)
	elif wall_mount:
		model = Art.external(self,"industrial_wall_lamp",Vector3(0,-0.24,0),Vector3(0.32,0.48,0.2))
	else:
		model = Art.external(self,"mounted_fluorescent_lights",Vector3.ZERO,Vector3(1.12,0.14,0.32))
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for index in range(mesh.mesh.get_surface_count()):
			var material: Material = mesh.get_active_material(index)
			if material is StandardMaterial3D and ("glass" in material.resource_name.to_lower() or "bulb" in material.resource_name.to_lower() or material.emission_enabled):
				material = material.duplicate()
				material.emission = source.light_color
				material.emission_enabled = true
				mesh.set_surface_override_material(index,material)
				glow.append({"material":material,"albedo":material.albedo_color})
	update_state()

func update_state() -> void:
	var strength := clampf(source.light_energy/nominal,0,1) if is_instance_valid(source) and source.visible and world.interior_powered else 0.0
	for entry in glow:
		if is_instance_valid(source): entry.material.emission = source.light_color
		entry.material.emission_enabled = strength > 0.001
		entry.material.emission_energy_multiplier = strength*0.75
		entry.material.albedo_color = entry.albedo * Color(lerpf(0.12,1.0,strength),lerpf(0.12,1.0,strength),lerpf(0.12,1.0,strength),1)

func _process(_delta: float) -> void:
	update_state()
