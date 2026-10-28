extends CharacterBody3D

const SPEED := 4.0
const SENSITIVITY := 0.0025
var camera: Camera3D
var ray: RayCast3D
var controls_enabled := true
var flashlight: SpotLight3D
var hand: Node3D
var has_flashlight := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	name = "Player"
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.current = true
	camera.cull_mask = 3 | preload("res://scripts/hand.gd").FPV_LAYER
	camera.near = 0.03
	# ponytail: predio fechado, o mais longe que se ve e a fachada do outro lado
	# do estacionamento. 4000 (padrao) so paga culling a mais. Knob de calibragem.
	camera.far = 70.0
	add_child(camera)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.5)
	camera.add_child(ray)
	hand = preload("res://scenes/mao_lanterna.tscn").instantiate()
	camera.add_child(hand)
	flashlight = hand.light
	hand.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if has_flashlight and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		flashlight.visible = not flashlight.visible
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if OS.get_cmdline_user_args().has("--smoke-test"): return
		rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * SENSITIVITY, -1.4, 1.4)
	if event.is_action_pressed("interact"):
		var target := interaction_target()
		if target != null:
			target.interact()

func equip_flashlight(owned: bool) -> void:
	if has_flashlight == owned: return
	has_flashlight = owned
	hand.visible = owned
	flashlight.visible = owned

func interaction_target() -> Node:
	if ray.is_colliding():
		var target := ray.get_collider() as Node
		if target != null and target.has_method("interact"):
			return target
	return null

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		hand.walking = false
		return
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var motion := transform.basis * Vector3(direction.x, 0, direction.y)
	velocity.x = motion.x * SPEED
	velocity.z = motion.z * SPEED
	hand.walking = direction.length() > 0.1
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
