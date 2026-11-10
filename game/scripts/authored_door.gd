extends "res://scripts/door.gd"
# Reuse the authored hinge hierarchy. Rebuilding/renaming it in _ready would
# invalidate Godot 4.0's PackedScene duplication paths in the scenery adapter.
func _ready() -> void:
	display_name = get_meta("door_caption","porta")
	pivot = get_child(0) as Node3D
	handle = pivot.get_child(0) as Node3D
	for child in get_children():
		if child is CollisionShape3D: collider = child
	hide_static_leaf()
	# Mesma folha, mesmo occluder: a porta autorada tambem tem de tapar a sala.
	add_leaf_occluder(Vector3(0.75, 1.25, 0), Vector3(1.5, 2.5, 0.15))

# A folha, as dobradiças e a maçaneta que abrem já ficam sob `pivot`. A migração
# das salas novas gravou também o modelo importado inteiro ao lado dele, então
# uma segunda folha fechada aparecia no vão com a porta aberta. Do modelo fixo
# só o batente (peças "Frame") deve aparecer.
func hide_static_leaf() -> void:
	for child in get_children():
		if child == pivot or not child is Node3D: continue
		for part in child.find_children("*","MeshInstance3D",true,false):
			if not part.name.begins_with("Frame"): part.hide()
