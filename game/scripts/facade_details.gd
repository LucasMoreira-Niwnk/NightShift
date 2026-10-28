extends Node3D
# Exterior envelope only: additional mass and a restrained material hierarchy.
const Materials = preload("res://scripts/materials.gd")
const Art = preload("res://scripts/art.gd")
var world: Node3D
var finishes: Dictionary = {}

func _ready() -> void:
	name = "FacadeStructure"
	var concrete := Materials.photographic("concrete_floor_worn_001",1.7)
	concrete.albedo_color = Color(0.69,0.71,0.66)
	concrete.normal_scale = 0.4
	concrete.metallic_specular = 0.12
	finishes.concrete = concrete
	var plinth := concrete.duplicate()
	plinth.albedo_color = Color(0.43,0.47,0.43)
	finishes.plinth = plinth
	finishes.metal = Materials.fitting(Color(0.13,0.18,0.16))
	finishes.stone = Materials.photographic("damaged_plaster",1.4)
	finishes.stone.albedo_color = Color(0.67,0.64,0.55)
	build()

func block(point: Vector3, size: Vector3, finish: String = "concrete", solid: bool = false) -> MeshInstance3D:
	var mesh: MeshInstance3D = world.box(self,point,size,"facade_detail",solid)
	mesh.material_override = finishes[finish]
	return mesh

func build() -> void:
	# Full-height piers define the portico; the entrance stays 2.4 m clear.
	for x in [-7.8,-1.45,1.45,7.8]:
		block(Vector3(x,3.67,12.25),Vector3(0.46,7.34,0.52),"concrete",true)
		block(Vector3(x,0.37,12.27),Vector3(0.62,0.74,0.62),"plinth")
		block(Vector3(x,7.28,12.25),Vector3(0.65,0.24,0.7))
	# Deep string courses, caps and a metal drip edge read at street distance.
	for y in [3.57,7.42]:
		block(Vector3(0,y,12.32),Vector3(16.95,0.34,0.58))
		block(Vector3(0,y+0.19,12.38),Vector3(17.0,0.045,0.67),"metal")
	for side in [-1.0,1.0]:
		var x: float = side*8.25
		for z in ([4.0,11.75] if side<0 else [-13.5,-9.7,-2.2,3.8,11.75]):
			block(Vector3(x,3.65,z),Vector3(0.48,7.3,0.42),"concrete",true)
			block(Vector3(x,0.3,z),Vector3(0.57,0.6,0.58),"plinth")
		for y in [3.57,7.42]:
			block(Vector3(x,y,-2),Vector3(0.45,0.28,28.7))
			block(Vector3(x,y+0.16,-2),Vector3(0.51,0.035,28.75),"metal")
	# A masonry skirt terminates the render above splash water and debris.
	for x in [-4.55,4.55]: block(Vector3(x,0.31,12.16),Vector3(6.8,0.62,0.16),"plinth")
	block(Vector3(8.16,0.31,-2),Vector3(0.16,0.62,28),"plinth")
	block(Vector3(-8.16,0.31,7.6),Vector3(0.16,0.62,8.8),"plinth")
	block(Vector3(-8.16,0.31,-13.6),Vector3(0.16,0.62,4.8),"plinth")
	# The service tower gets its own weathered masonry base and coping.
	block(Vector3(-14.48,0.38,-3.75),Vector3(0.15,0.76,13.7),"stone")
	block(Vector3(-14.48,7.42,-3.75),Vector3(0.45,0.3,14.0))
	for z in [-10.4,3.0]: block(Vector3(-14.48,3.65,z),Vector3(0.4,7.3,0.42),"concrete",true)
	# Reinforced canopy: a thick edge, substantial posts and restrained ribs.
	block(Vector3(0,3.2,14),Vector3(6.9,0.34,4.8))
	block(Vector3(0,3.4,14),Vector3(7.0,0.06,4.9),"metal")
	block(Vector3(0,3.02,16.35),Vector3(6.9,0.36,0.28),"plinth")
	for x in [-2.9,2.9]:
		block(Vector3(x,1.46,15.5),Vector3(0.34,2.92,0.34),"concrete",true)
		block(Vector3(x,0.22,15.5),Vector3(0.5,0.44,0.5),"plinth")
	for x in [-2.2,0.0,2.2]: block(Vector3(x,2.97,14.3),Vector3(0.09,0.11,3.6),"metal")
	# Recessed entrance and a central sign panel between the structural piers.
	for x in [-1.05,1.05]: block(Vector3(x,1.35,12.22),Vector3(0.21,2.7,0.35))
	block(Vector3(0,2.73,12.22),Vector3(2.31,0.18,0.35))
	block(Vector3(0,6.15,12.38),Vector3(2.2,2.2,0.18),"metal")
	for x in [-0.97,0.97]:
		for y in [5.2,7.08]:
			var bolt := Art.rounded_box(self,Vector3(x,y,12.49),Vector3(0.035,0.035,0.018),Color(0.25,0.24,0.18),0.008)
			bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var date: Label3D = world.add_sign("VSP / 1978",Vector3(0,5.35,12.5))
	date.pixel_size = 0.0012
	# Small expansion joints and ventilation grilles break up broad blind walls.
	for z in [-12.0,-8.0,-4.0,0.0,4.0,8.0]:
		block(Vector3(8.3,3.55,z),Vector3(0.014,0.33,0.025),"metal")
	for y in [1.2,5.4]:
		block(Vector3(8.13,y,3),Vector3(0.13,0.65,1.0),"metal")
		for i in range(7): block(Vector3(8.21,y-0.23+i*0.075,3),Vector3(0.05,0.025,0.85),"plinth")
