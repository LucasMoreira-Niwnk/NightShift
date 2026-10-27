extends Node

# Reconstructed recordings have their own World3D. Scrubbing cannot move a
# gameplay door, actor, or collider, nor change the player's narrative state.
var game: Node
var viewport: SubViewport
var camera: Camera3D
var scene: Node3D
var actors: Array = []
var door_pivot: Node3D
var active := false
var paused := false
var kind := ""
var elapsed := 0.0
var duration := 8.0
var delivered := false

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)

func play(clip: String) -> void:
	stop()
	kind = clip
	elapsed = 0
	delivered = false
	paused = false
	scene = game.world.duplicate(0) as Node3D
	remove_logic(scene)
	viewport.add_child(scene)
	for environment in scene.find_children("*", "WorldEnvironment", true, false):
		environment.environment = environment.environment.duplicate()
		environment.environment.ambient_light_energy = 0.6
		environment.environment.ambient_light_color = Color(0.6, 0.8, 0.75)
	camera = Camera3D.new()
	camera.cull_mask = 5
	camera.fov = 60
	viewport.add_child(camera)
	camera.current = true
	if kind == "tomorrow":
		camera.position = Vector3(5.5, 2.7, 11.4)
		camera.look_at(Vector3(-2, 1.1, 7.5))
		actors.append(game.world.humanoid(Color(0.45, 0.6, 0.52), scene))
	elif kind == "meeting":
		camera.position = Vector3(9.3, 6.9, -44)
		camera.look_at(Vector3(4.5, 5.1, -38))
		for index in range(5): actors.append(game.world.humanoid(Color(0.4, 0.53, 0.46), scene))
	else:
		camera.position = Vector3(1.5, 6.8, -28)
		camera.look_at(Vector3(-1, 5.1, -42))
		actors.append(game.world.humanoid(Color(0.45, 0.6, 0.52), scene))
		var relative: NodePath = game.world.get_path_to(game.world.doors.it)
		var recorded_door := scene.get_node(relative)
		door_pivot = recorded_door.get_child(0)
	active = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	pose()

func remove_logic(node: Node) -> void:
	# Do this before entering the tree: no _ready/event callbacks are executed.
	for child in node.get_children(): remove_logic(child)
	if node.get_script() != null: node.set_script(null)
	node.process_mode = Node.PROCESS_MODE_DISABLED

func stop() -> void:
	active = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	actors.clear()
	door_pivot = null
	if is_instance_valid(camera):
		viewport.remove_child(camera)
		camera.queue_free()
	if is_instance_valid(scene):
		viewport.remove_child(scene)
		scene.queue_free()
	camera = null
	scene = null

func seek(value: float) -> void:
	if not active: return
	elapsed = clampf(value, 0, duration)
	pose()

func pose() -> void:
	if kind == "future":
		actors[0].position = Vector3(lerpf(-4, 0.8, clampf(elapsed / 4, 0, 1)), 4.2, -42)
		door_pivot.rotation.y = lerpf(-PI / 2, 0, clampf((elapsed - 4) / 0.65, 0, 1))
	elif kind == "meeting":
		for index in range(5):
			var progress := clampf((elapsed - index * 0.8) / 3, 0, 1)
			actors[index].visible = elapsed >= index * 0.8
			actors[index].position = Vector3(lerpf(2.2, 4.6 + (index % 3) * 1.2, progress), 4.2, lerpf(-38, -37 if index < 3 else -40, progress))
	else:
		actors[0].position = Vector3(lerpf(0, -2.7, clampf((elapsed - 1) / 4, 0, 1)), 0, lerpf(11, 8.2, clampf((elapsed - 1) / 4, 0, 1)))

func label() -> String:
	match kind:
		"future": return "ARQUIVO CAM-04 / 14/11/2008 / 01:03:%02d" % (17 + int(elapsed))
		"meeting": return "ARQUIVO CAM-05 / 14/11/2008 / ACESSOS 23h35–23h39"
	return "ARQUIVO CAM-01 / 15/11/2008 / 00:00:%02d" % int(elapsed)

func _process(delta: float) -> void:
	if not active or paused: return
	elapsed = minf(duration, elapsed + delta)
	pose()
	if elapsed >= duration and not delivered:
		delivered = true
		game.chapter.act_two.recording_finished(kind)
