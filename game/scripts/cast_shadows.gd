extends Node3D

# Sombra projetada a mao. O renderizador Compatibility do Godot 4.0 nao projeta
# sombra de spot light, entao cada objeto ganha uma copia preta e translucida,
# um pouco maior que o original, sempre empurrada para o lado oposto ao da
# lanterna: lanterna -> objeto -> sombra.

const SCALE := 1.08
const OFFSET := 0.24
const MAX_DISTANCE := 9.0
const MAX_ALPHA := 0.62

var game: Node
var casters: Array = []

func _ready() -> void:
	for id in game.world.objects:
		var source = game.world.objects[id]
		if source is Node3D:
			var entry := build(source)
			if not entry.is_empty(): casters.append(entry)

func build(source: Node3D) -> Dictionary:
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.albedo_color = Color(0, 0, 0, MAX_ALPHA)
	dark.cull_mode = BaseMaterial3D.CULL_DISABLED
	var shadow := Node3D.new()
	var inverse := source.global_transform.affine_inverse()
	for mesh in source.find_children("*", "MeshInstance3D", true, false):
		var copy := MeshInstance3D.new()
		copy.mesh = mesh.mesh
		copy.transform = inverse * mesh.global_transform
		copy.material_override = dark
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shadow.add_child(copy)
	if shadow.get_child_count() == 0:
		shadow.free()
		return {}
	shadow.visible = false
	add_child(shadow)
	return {"source": source, "shadow": shadow, "material": dark}

func _process(_delta: float) -> void:
	var light: SpotLight3D = game.player.flashlight
	var lit := light != null and light.is_visible_in_tree()
	# o cone sai da propria lanterna: mudar spot_angle nao desencontra a sombra
	var edge := cos(deg_to_rad(light.spot_angle)) if lit else 1.0
	for entry in casters:
		var source: Node3D = entry.source
		var shadow: Node3D = entry.shadow
		if not lit or not source.is_visible_in_tree():
			shadow.visible = false
			continue
		var to_object: Vector3 = source.global_position - light.global_position
		var distance := to_object.length()
		var direction := to_object / maxf(distance, 0.001)
		# O mesmo cone do facho: fora dele nao ha luz, logo nao ha sombra.
		var alignment := direction.dot(-light.global_transform.basis.z)
		if distance > MAX_DISTANCE or alignment <= edge:
			shadow.visible = false
			continue
		shadow.visible = true
		shadow.global_transform = Transform3D(
			source.global_transform.basis.scaled(Vector3.ONE * SCALE),
			source.global_position + direction * OFFSET)
		# Some junto com a luz: com a distancia e com o afastamento do eixo.
		var falloff := (1.0 - distance / MAX_DISTANCE) * ((alignment - edge) / (1.0 - edge))
		entry.material.albedo_color.a = MAX_ALPHA * falloff
