@tool
extends Node3D
# Objeto de ambientação editável no Godot (cenas/ambientacao.tscn).
# O nó marca a base do objeto: o modelo de `asset` é instanciado como filho,
# centralizado em X/Z, apoiado em Y = 0 e ajustado a `dimensions` (metros, antes
# da rotação do nó). Mova/gire o nó no editor; ajuste o tamanho em `dimensions`.
# O modelo e a colisão são recriados ao abrir a cena e não são salvos nela.

const MODEL_NAME := "PropModel"
const BODY_NAME := "PropCollision"

@export_file("*.gltf", "*.glb") var asset := "":
	set(value):
		asset = value
		rebuild()
@export var dimensions := Vector3.ONE:
	set(value):
		dimensions = value
		rebuild()
# Colisão em caixa do tamanho de `dimensions`. Desligue para papéis/objetos
# pequenos sobre mesas, que não devem travar o jogador nem o raio de interação.
@export var solid := true:
	set(value):
		solid = value
		rebuild()
# Para modelos com variantes (ex.: binder_notebook), lista das malhas visíveis.
@export var visible_parts := PackedStringArray():
	set(value):
		visible_parts = value
		rebuild()

func _ready() -> void:
	rebuild()

func rebuild() -> void:
	if not is_inside_tree(): return
	# Cópias feitas pelo adaptador do cenário trazem o modelo da original.
	for child in get_children():
		if child.name == MODEL_NAME or child.name == BODY_NAME: child.free()
	if asset.is_empty() or not ResourceLoader.exists(asset): return
	var packed := load(asset) as PackedScene
	if packed == null: return
	var model := packed.instantiate() as Node3D
	if model == null: return
	model.name = MODEL_NAME
	add_child(model)
	if not visible_parts.is_empty():
		for part in model.find_children("*", "MeshInstance3D", true, false):
			part.visible = visible_parts.has(String(part.name))
	var bounds := mesh_bounds(model, Transform3D.IDENTITY)
	if bounds.size.x <= 0.0001 or bounds.size.y <= 0.0001 or bounds.size.z <= 0.0001: return
	var factor := dimensions / bounds.size
	model.scale = factor
	model.position = -(bounds.position + Vector3(bounds.size.x * 0.5, 0, bounds.size.z * 0.5)) * factor
	if solid:
		var body := StaticBody3D.new()
		body.name = BODY_NAME
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = dimensions
		shape.shape = box
		shape.position.y = dimensions.y * 0.5
		body.add_child(shape)
		add_child(body)

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
