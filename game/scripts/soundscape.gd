extends Node

# Recorded CC0 foley, prepared offline. Only radio interference remains procedural.
const AUDIO_ROOT := "res://assets/audio/vesper/"
var effects: Dictionary = {}
var ambience: AudioStreamPlayer
var infrasound: AudioStreamPlayer
var monitor_music: AudioStreamPlayer
var stare_time := 0.0
var memesis_pad: AudioStreamPlayer3D
var lamp_hum: AudioStreamPlayer3D
var rain: AudioStreamPlayer
var indoor_rain: AudioStreamPlayer
var reverb: AudioEffectReverb
var variants: Dictionary = {}
var last_variant: Dictionary = {}
var rng := RandomNumberGenerator.new()
var game: Node
var step_distance := 0.0
var last_position := Vector3.ZERO

func _ready() -> void:
	for bus_name in ["Ambiente", "Efeitos", "Musicas"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	rng.randomize()
	for id in ["rain", "rain_inside", "hum", "ring", "drag", "knock", "printer", "switch", "engine", "car_door", "door_open", "door_close"]:
		effects[id] = load(AUDIO_ROOT + id + ".wav")
	for id in ["rain", "rain_inside", "hum"]:
		var stream: AudioStreamWAV = effects[id].duplicate()
		stream.loop_end = stream.data.size() / 2 / (2 if stream.stereo else 1)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		effects[id] = stream
	for surface in ["hard", "wood"]:
		var bank: Array = []
		for i in range(6 if surface == "hard" else 4):
			bank.append(load(AUDIO_ROOT + "step_%s_%d.wav" % [surface, i]))
		variants[surface] = bank
	effects.step = variants.hard[0]
	effects["static"] = synthesize_static()
	reverb = AudioEffectReverb.new()
	reverb.room_size = 0.55
	reverb.damping = 0.72
	reverb.predelay_msec = 35
	reverb.predelay_feedback = 0.12
	reverb.wet = 0.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Efeitos"), reverb)
	ambience = loop_player("hum", -50)
	infrasound = infrasound_player()
	monitor_music = music_player("res://assets/audio/abandoned_mine.wav", -80)
	memesis_pad = memesis_pad_player()
	lamp_hum = lamp_hum_player()
	rain = loop_player("rain", -20)
	indoor_rain = loop_player("rain_inside", -60)
	last_position = game.player.position
	play("engine", Vector3.ZERO, -14, false)
	var settings := ConfigFile.new()
	if settings.load("user://audio.cfg") == OK:
		for bus in ["Ambiente", "Efeitos", "Musicas", "Master"]:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), float(settings.get_value("volume", bus, 0)))
	await get_tree().create_timer(3.2, false).timeout
	play("car_door", Vector3.ZERO, -20, false)

# Musica de fundo do primeiro ato, em 20% do volume master.
const INFRASOUND_LEVEL := 0.20
# Segunda faixa: entra quando Daniel encara os monitores por alguns segundos.
const MONITOR_STARE_DELAY := 5.0
const MONITOR_RANGE := 4.5

func infrasound_player() -> AudioStreamPlayer:
	return music_player("res://assets/audio/weird_stuff_galore.wav", linear_to_db(INFRASOUND_LEVEL))

func music_player(path: String, volume: float) -> AudioStreamPlayer:
	var stream = load(path)
	if stream == null: return null
	seam_crossfade(stream, 2.0)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Musicas"
	player.volume_db = volume
	add_child(player)
	player.play()
	return player

# Loop sem emenda: o rabo da faixa recebe o inicio dela por cima, em fade
# cruzado, e o loop volta logo depois desse inicio. Sem isso o reinicio estala.
func seam_crossfade(stream: AudioStreamWAV, seconds: float) -> void:
	var channels := 2 if stream.stereo else 1
	var total := stream.data.size() / 2 / channels
	var fade := mini(int(seconds * stream.mix_rate), total / 3)
	if fade > 0:
		var bytes := stream.data
		for frame in range(fade):
			var weight := float(frame) / float(fade)
			for channel in range(channels):
				var head := (frame * channels + channel) * 2
				var tail := ((total - fade + frame) * channels + channel) * 2
				var mixed: int = int(bytes.decode_s16(tail) * (1.0 - weight) + bytes.decode_s16(head) * weight)
				bytes.encode_s16(tail, clampi(mixed, -32768, 32767))
		stream.data = bytes
		stream.loop_begin = fade
	stream.loop_end = total
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

# O pad do Mêmesis sai do proprio vulto: 3D, e com o corte de agudos caindo
# quando ha parede no caminho. Parede nao silencia, abafa.
const MEMESIS_PAD_LEVEL := -14.0
const MEMESIS_PAD_OPEN_HZ := 6500.0
const MEMESIS_PAD_MUFFLED_HZ := 700.0

func memesis_pad_player() -> AudioStreamPlayer3D:
	var stream = load("res://assets/audio/memesis_pad.wav")
	if stream == null: return null
	seam_crossfade(stream, 2.0)
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = "Ambiente"
	player.volume_db = -80
	player.unit_size = 4.0
	player.max_distance = 26
	player.attenuation_filter_cutoff_hz = MEMESIS_PAD_OPEN_HZ
	add_child(player)
	player.play()
	return player

func update_memesis_pad(blend: float) -> void:
	if memesis_pad == null or game.world.figure == null: return
	memesis_pad.global_position = game.world.figure.global_position + Vector3(0, 1.2, 0)
	var audible: bool = game.world.figure.visible
	memesis_pad.volume_db = crossfade_db(memesis_pad.volume_db, MEMESIS_PAD_LEVEL if audible else -80.0, blend)
	if not audible: return
	var blocked: bool = occluded(memesis_pad.global_position)
	memesis_pad.attenuation_filter_cutoff_hz = lerpf(memesis_pad.attenuation_filter_cutoff_hz, MEMESIS_PAD_MUFFLED_HZ if blocked else MEMESIS_PAD_OPEN_HZ, blend)

# Zumbido de reator: um player 3D que segue a luminaria mais proxima, em vez de
# um por lampada. Cai com a distancia pelo proprio AudioStreamPlayer3D e abafa
# atras de parede, igual ao pad. ponytail: so a mais proxima soa; se duas
# luminarias precisarem zumbir juntas, vire isso numa lista de players.
const LAMP_HUM_LEVEL := -22.0
const LAMP_HUM_OPEN_HZ := 7000.0
const LAMP_HUM_MUFFLED_HZ := 900.0

func lamp_hum_player() -> AudioStreamPlayer3D:
	var stream = load("res://assets/audio/fluorescent_hum.wav")
	if stream == null: return null
	seam_crossfade(stream, 1.5)
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = "Ambiente"
	player.volume_db = -80
	player.unit_size = 1.6
	player.max_distance = 9
	player.attenuation_filter_cutoff_hz = LAMP_HUM_OPEN_HZ
	add_child(player)
	player.play()
	return player

func update_lamp_hum(blend: float) -> void:
	if lamp_hum == null: return
	var eye: Vector3 = game.player.camera.global_position
	var nearest: Light3D = null
	var best := INF
	for entry in game.world.interior_lights:
		var lamp: Light3D = entry
		if not lamp.visible: continue
		var span: float = lamp.global_position.distance_to(eye)
		if span < best:
			best = span
			nearest = lamp
	var audible: bool = nearest != null and game.world.interior_powered
	lamp_hum.volume_db = crossfade_db(lamp_hum.volume_db, LAMP_HUM_LEVEL if audible else -80.0, blend)
	if not audible: return
	lamp_hum.global_position = nearest.global_position
	lamp_hum.attenuation_filter_cutoff_hz = lerpf(lamp_hum.attenuation_filter_cutoff_hz, LAMP_HUM_MUFFLED_HZ if occluded(lamp_hum.global_position) else LAMP_HUM_OPEN_HZ, blend)

func occluded(point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(game.player.camera.global_position, point)
	query.exclude = [game.player.get_rid()]
	return not game.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func synthesize_static() -> AudioStreamWAV:
	# Deliberately electronic: a short, band-limited radio dropout, no loud sting.
	var bytes := PackedByteArray()
	bytes.resize(15435 * 2)
	var noise_rng := RandomNumberGenerator.new()
	noise_rng.seed = 90210
	var filtered := 0.0
	for i in range(15435):
		filtered = lerpf(filtered, noise_rng.randf_range(-1, 1), 0.35)
		var envelope := minf(float(i) / 400, 1.0) * minf(float(15435 - i) / 1300, 1.0)
		bytes.encode_s16(i * 2, int(filtered * envelope * 12000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream

func step_surface(point: Vector3) -> String:
	if game.world.is_outdoors(point): return "hard"
	if game.world.staircases.is_main(point) or game.world.staircases.is_service(point): return "hard"
	# Administration and meeting room have wood; TI and corridors do not.
	if point.y > 3.8 and (point.x > 1.6 or (point.x < -1.6 and point.z < -5)):
		return "wood"
	return "hard"

func choose_step(point: Vector3) -> AudioStreamWAV:
	var surface := step_surface(point)
	var bank: Array = variants[surface]
	var previous: int = last_variant.get(surface, -1)
	var index := rng.randi_range(0, bank.size() - 1)
	if index == previous: index = (index + 1) % bank.size()
	last_variant[surface] = index
	return bank[index]

func loop_player(id: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = effects[id]
	player.bus = "Ambiente"
	player.volume_db = volume
	add_child(player)
	player.play()
	return player

func play(id: String, point: Vector3 = Vector3.ZERO, volume: float = -12, spatial: bool = true) -> Node:
	if not effects.has(id): return null
	# Bound bursts of overlapping events without cutting ambience loops.
	if get_child_count() >= 28: return null
	var stream: AudioStream = choose_step(point) if id == "step" else effects[id]
	var pitch := rng.randf_range(0.97, 1.03) if id in ["step", "door_open", "door_close", "knock"] else 1.0
	if spatial:
		var player := AudioStreamPlayer3D.new()
		player.stream = stream
		player.pitch_scale = pitch
		player.bus = "Efeitos"
		player.volume_db = volume
		player.unit_size = 3.5
		player.max_distance = 22
		player.attenuation_filter_cutoff_hz = 4500
		add_child(player)
		player.global_position = point
		player.finished.connect(player.queue_free)
		player.play()
		return player
	else:
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.pitch_scale = pitch
		player.bus = "Efeitos"
		player.volume_db = volume
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
		return player

func _physics_process(delta: float) -> void:
	var point: Vector3 = game.player.position
	var distance := point.distance_to(last_position)
	last_position = point
	if game.player.controls_enabled and game.player.is_on_floor() and distance < 0.5:
		step_distance += distance
		if step_distance > 1.65:
			step_distance = 0
			play("step", point + Vector3(0, 0.1, 0), -19)
	update_mix(point, delta)

func update_mix(point: Vector3, delta: float) -> void:
	var outdoors: bool = game.world.is_outdoors(point)
	var blend := 1.0 - exp(-delta * 3.0)
	rain.volume_db = crossfade_db(rain.volume_db, -20.0 if outdoors else -60.0, blend)
	indoor_rain.volume_db = crossfade_db(indoor_rain.volume_db, -60.0 if outdoors else -29.0, blend)
	# A quiet room tone, stronger near technical spaces; the blackout removes it.
	var hum_level := -34.0
	if point.x < -2 and point.z < -6: hum_level = -28.0
	if outdoors or not game.world.interior_powered: hum_level = -80.0
	ambience.volume_db = lerpf(ambience.volume_db, hum_level, blend)
	reverb.wet = lerpf(reverb.wet, 0.015 if outdoors else 0.13, blend)
	update_monitor_music(delta, blend)
	update_memesis_pad(blend)
	update_lamp_hum(blend)

# Encarar os monitores acumula tempo; virar o rosto devolve o dobro mais rapido.
func update_monitor_music(delta: float, blend: float) -> void:
	if monitor_music == null or game.computer == null: return
	var eye: Vector3 = game.player.camera.global_position
	var to_screens: Vector3 = game.computer.global_position + Vector3(0, 0.9, 0) - eye
	# Na overlay das cameras Daniel esta olhando a tela de perto: conta igual.
	var staring: bool = game.computer.active or (to_screens.length() < MONITOR_RANGE and (-game.player.camera.global_transform.basis.z).dot(to_screens.normalized()) > 0.9)
	stare_time = clampf(stare_time + (delta if staring else -delta * 2.0), 0.0, MONITOR_STARE_DELAY)
	var target := linear_to_db(INFRASOUND_LEVEL) if stare_time >= MONITOR_STARE_DELAY else -80.0
	monitor_music.volume_db = crossfade_db(monitor_music.volume_db, target, blend)

func crossfade_db(current: float, target: float, blend: float) -> float:
	return linear_to_db(lerpf(db_to_linear(current), db_to_linear(target), blend))

func _exit_tree() -> void:
	# AudioServer outlives a scene reload; never stack reverbs on New Game.
	var bus := AudioServer.get_bus_index("Efeitos")
	if bus < 0: return
	for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
		if AudioServer.get_bus_effect(bus, i) == reverb:
			AudioServer.remove_bus_effect(bus, i)

func set_volume(bus: String, value: float) -> void:
	for name in bus.split(","):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(name), linear_to_db(maxf(value, 0.0001)))
	var settings := ConfigFile.new()
	for bus_name in ["Ambiente", "Efeitos", "Musicas", "Master"]:
		settings.set_value("volume", bus_name, AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)))
	settings.save("user://audio.cfg")
