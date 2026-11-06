extends Node
## Bench temporario de FPS. Mede frametime real (vsync off) em pontos fixos,
## ligando e desligando um efeito de cada vez. Nao faz parte do jogo.
var game: Node

const WARMUP := 20
const SAMPLES := 90

# Ponto de vista usado para medir: corredor do terreo olhando o fundo.
const SPOTS := [
	{"id": "corredor", "at": Vector3(0.0, 0.1, -6.0), "look": Vector3(0, 1.5, -15)},
	{"id": "recepcao", "at": Vector3(1.5, 0.1, 5.0), "look": Vector3(-3, 1.5, -2)},
	{"id": "rua", "at": Vector3(1.5, 0.1, 23.0), "look": Vector3(0, 4.0, 4)},
]

var lights_cache: Array = []

func env() -> Environment:
	for child in game.world.get_children():
		if child is WorldEnvironment: return child.environment
	return null

func set_shadows(on: bool) -> void:
	if lights_cache.is_empty():
		for lamp in game.world.find_children("*", "Light3D", true, false):
			if lamp.shadow_enabled: lights_cache.append(lamp)
	for lamp in lights_cache: lamp.shadow_enabled = on

func toggles() -> Array:
	return [
		{"id": "baseline (tudo ligado)", "off": func(): pass, "on": func(): pass},
		{"id": "sem desconforto", "off": func(): game.discomfort.enabled = false, "on": func(): game.discomfort.enabled = true},
		{"id": "sem nevoa volumetrica", "off": func(): env().volumetric_fog_enabled = false, "on": func(): env().volumetric_fog_enabled = true},
		{"id": "sem bolhas de nevoa", "off": func(): game.world.drifting_fog.visible = false, "on": func(): game.world.drifting_fog.visible = true},
		{"id": "sem feed do CCTV", "off": func(): game.computer.feed.render_target_update_mode = SubViewport.UPDATE_DISABLED, "on": func(): game.computer.feed.render_target_update_mode = SubViewport.UPDATE_ALWAYS},
		{"id": "sem sombras", "off": func(): set_shadows(false), "on": func(): set_shadows(true)},
		{"id": "sem glow", "off": func(): env().glow_enabled = false, "on": func(): env().glow_enabled = true},
		{"id": "sem grao de filme", "off": func(): game.crt_overlay_layer.visible = false, "on": func(): game.crt_overlay_layer.visible = true},
	]

func measure() -> float:
	for index in range(WARMUP): await get_tree().process_frame
	var total := 0.0
	for index in range(SAMPLES):
		await get_tree().process_frame
		total += get_process_delta_time()
	return total / SAMPLES

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for child in game.ui.get_children():
		if child is ColorRect or child is Label: child.queue_free()
	game.player.controls_enabled = false
	await get_tree().process_frame
	print("BENCH res=%s" % str(get_viewport().get_visible_rect().size))
	for spot in SPOTS:
		game.player.global_position = spot["at"]
		game.player.velocity = Vector3.ZERO
		await get_tree().process_frame
		game.world.update_floor_culling()
		game.player.camera.look_at(spot["look"], Vector3.UP)
		for entry in toggles():
			entry["off"].call()
			var ms := await measure()
			entry["on"].call()
			print("BENCH %s | %-26s | %6.2f ms | %6.1f fps" % [spot["id"], entry["id"], ms * 1000.0, 1.0 / maxf(ms, 0.0001)])
	# Combinacao: tudo o que nao e cenario desligado de uma vez.
	for spot in SPOTS:
		game.player.global_position = spot["at"]
		await get_tree().process_frame
		game.world.update_floor_culling()
		game.player.camera.look_at(spot["look"], Vector3.UP)
		game.discomfort.enabled = false
		env().volumetric_fog_enabled = false
		game.world.drifting_fog.visible = false
		game.computer.feed.render_target_update_mode = SubViewport.UPDATE_DISABLED
		game.crt_overlay_layer.visible = false
		env().glow_enabled = false
		var ms := await measure()
		print("BENCH %s | %-26s | %6.2f ms | %6.1f fps" % [spot["id"], "TODOS OS EFEITOS OFF", ms * 1000.0, 1.0 / maxf(ms, 0.0001)])
		set_shadows(false)
		var ms2 := await measure()
		print("BENCH %s | %-26s | %6.2f ms | %6.1f fps" % [spot["id"], "EFEITOS+SOMBRAS OFF", ms2 * 1000.0, 1.0 / maxf(ms2, 0.0001)])
		set_shadows(true)
		game.discomfort.enabled = true
		env().volumetric_fog_enabled = true
		game.world.drifting_fog.visible = true
		game.computer.feed.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		game.crt_overlay_layer.visible = true
		env().glow_enabled = true
	print("BENCH_DONE")
	get_tree().quit(0)
