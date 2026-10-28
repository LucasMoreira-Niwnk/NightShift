extends Node

# Recorded CC0 foley, prepared offline. Only radio interference remains procedural.
const AUDIO_ROOT := "res://assets/audio/vesper/"
var effects: Dictionary = {}
var ambience: AudioStreamPlayer
var infrasound: AudioStreamPlayer
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
	for bus_name in ["Ambiente", "Efeitos"]:
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
	rain = loop_player("rain", -20)
	indoor_rain = loop_player("rain_inside", -60)
	last_position = game.player.position
	play("engine", Vector3.ZERO, -14, false)
	var settings := ConfigFile.new()
	if settings.load("user://audio.cfg") == OK:
		for bus in ["Ambiente", "Efeitos"]:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), float(settings.get_value("volume", bus, 0)))
	await get_tree().create_timer(3.2, false).timeout
	play("car_door", Vector3.ZERO, -20, false)

# Leito de infrassom do primeiro ato, em 15% do volume master.
const INFRASOUND_LEVEL := 0.15

func infrasound_player() -> AudioStreamPlayer:
	var stream = load("res://assets/audio/infrasound.wav")
	if stream == null: return null
	# loop_end precisa vir antes de loop_mode: com loop_end zerado o playback
	# para no primeiro frame. O fim real sai do tamanho dos dados (16 bits).
	if stream.loop_end <= 0:
		stream.loop_end = stream.data.size() / 2 / (2 if stream.stereo else 1)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Ambiente"
	player.volume_db = linear_to_db(INFRASOUND_LEVEL)
	add_child(player)
	player.play()
	return player

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
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(maxf(value, 0.0001)))
	var settings := ConfigFile.new()
	for bus_name in ["Ambiente", "Efeitos"]:
		settings.set_value("volume", bus_name, AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)))
	settings.save("user://audio.cfg")
