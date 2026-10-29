extends Node3D

# Sombra projetada a mao. O renderizador Compatibility do Godot 4.0 nao projeta
# sombra de spot light, entao cada objeto ganha uma copia preta do seu proprio
# formato, lancada para o lado oposto ao da lanterna.
#
# A copia nao pode ficar logo atras do objeto: quem olha esta junto da lanterna,
# e dali a sombra cai exatamente na silhueta de quem a projeta, escondida. Entao
# ela e deitada no chao sob o objeto e esticada para longe da luz, que e como a
# sombra aparece de verdade para quem segura a lanterna.

const DROP := 4.0
const LEAN := 1.5
const STRETCH := 2.6
const THICKNESS := 0.03
const LIFT := 0.012
const MAX_DISTANCE := 9.0
const MAX_ALPHA := 0.7

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
	var exclude: Array[RID] = []
	if source is CollisionObject3D: exclude.append(source.get_rid())
	return {"source": source, "shadow": shadow, "material": dark, "exclude": exclude}

func _process(_delta: float) -> void:
	var light: SpotLight3D = game.player.flashlight
	var lit := light != null and light.is_visible_in_tree()
	# o cone sai da propria lanterna: mudar spot_angle nao desencontra a sombra
	var edge := cos(deg_to_rad(light.spot_angle)) if lit else 1.0
	var space := get_world_3d().direct_space_state
	for entry in casters:
		var source: Node3D = entry.source
		var shadow: Node3D = entry.shadow
		if not lit or not source.is_visible_in_tree():
			shadow.visible = false
			continue
		var origin: Vector3 = source.global_position
		var lamp: Vector3 = light.global_position
		var to_object: Vector3 = origin - lamp
		var distance := to_object.length()
		var direction := to_object / maxf(distance, 0.001)
		# O mesmo cone do facho: fora dele nao ha luz, logo nao ha sombra.
		var alignment := direction.dot(-light.global_transform.basis.z)
		if distance > MAX_DISTANCE or alignment <= edge:
			shadow.visible = false
			continue

		# Chao sob o objeto: e ali que a sombra se deita.
		var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * DROP)
		query.exclude = entry.exclude
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			shadow.visible = false
			continue
		var ground: Vector3 = hit.position
		var normal: Vector3 = hit.normal

		# Quanto mais rasante a luz, mais longe e mais comprida a sombra cai.
		var away := Vector3(to_object.x, 0, to_object.z)
		if away.length_squared() < 0.0001:
			shadow.visible = false
			continue
		away = away.normalized()
		var height := origin.y - ground.y
		var lean := clampf(height * LEAN / maxf(lamp.y - origin.y, 0.35), 0.0, 3.6)

		shadow.visible = true
		var basis := source.global_transform.basis
		# Estica ao longo da direcao que foge da luz, achata contra o chao.
		basis = Basis(away, Vector3.UP, away.cross(Vector3.UP)) \
			.scaled(Vector3(STRETCH + lean, 1.0, 1.0)) \
			* Basis(away, Vector3.UP, away.cross(Vector3.UP)).inverse() * basis
		shadow.global_transform = Transform3D(
			flatten(basis, normal), ground + away * lean + normal * LIFT)
		# Some junto com a luz: com a distancia e com o afastamento do eixo.
		var falloff := (1.0 - distance / MAX_DISTANCE) * ((alignment - edge) / (1.0 - edge))
		entry.material.albedo_color.a = MAX_ALPHA * clampf(falloff, 0.0, 1.0)

# Esmaga a base contra o plano do chao, mantendo a silhueta: cada eixo perde
# quase toda a sua componente ao longo da normal.
func flatten(basis: Basis, normal: Vector3, thin: float = THICKNESS) -> Basis:
	var result := basis
	for i in 3:
		var axis: Vector3 = basis[i]
		result[i] = axis - normal * axis.dot(normal) * (1.0 - thin)
	return result
