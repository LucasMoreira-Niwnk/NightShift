extends Node

# Original procedural sound design. Streams are cached; no downloads at runtime.
var effects: Dictionary = {}
var ambience: AudioStreamPlayer
var infrasound: AudioStreamPlayer
var rain: AudioStreamPlayer
var game: Node
var step_distance := 0.0
var last_position := Vector3.ZERO

func _ready() -> void:
	for bus_name in ["Ambiente", "Efeitos"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	for id in ["rain", "hum", "step", "ring", "drag", "knock", "static", "printer", "switch", "engine"]:
		effects[id] = synthesize(id)
	ambience = loop_player("hum", -30)
	infrasound = infrasound_player()
	rain = loop_player("rain", -18)
	last_position = game.player.position
	play("engine", Vector3.ZERO, -14, false)
	var settings := ConfigFile.new()
	if settings.load("user://audio.cfg") == OK:
		for bus in ["Ambiente", "Efeitos"]:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), float(settings.get_value("volume", bus, 0)))
	await get_tree().create_timer(1.5, false).timeout
	play("knock", Vector3.ZERO, -18, false)

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

func synthesize(id: String) -> AudioStreamWAV:
	var duration := 0.22
	match id:
		"rain", "hum": duration = 4.0
		"ring": duration = 1.5
		"drag", "printer": duration = 1.6
		"static": duration = 0.7
		"engine": duration = 1.8
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(int(duration * rate) * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	var filtered := 0.0
	for i in range(int(duration * rate)):
		var t := float(i) / rate
		var noise := rng.randf_range(-1, 1)
		filtered = lerpf(filtered, noise, 0.12)
		var envelope := minf(t * 50, 1.0) * minf((duration - t) * 15, 1.0)
		var sample := noise * 0.12
		match id:
			"rain": sample = noise * 0.19 + filtered * 0.4
			"hum": sample = sin(t * TAU * 60) * 0.18 + sin(t * TAU * 121) * 0.04 + filtered * 0.1
			"step": sample = (filtered * 1.5 + sin(t * TAU * 85) * 0.4) * exp(-t * 24)
			"knock": sample = (sin(t * TAU * 72) * 0.7 + noise * 0.2) * exp(-t * 20)
			"ring": sample = (sin(t * TAU * 440) + sin(t * TAU * 480)) * 0.17 * (1.0 if fmod(t, 0.42) < 0.29 else 0.0)
			"drag": sample = filtered * 1.5 * (0.5 + 0.5 * sin(t * TAU * 19))
			"printer": sample = sin(t * TAU * (180 + 35 * sin(t * 17))) * 0.16 + noise * 0.07
			"switch": sample = noise * exp(-t * 65) * 0.7
			"engine": sample = sin(t * TAU * (70 - t * 25)) * 0.3 * (1.0 - t / duration) + filtered * 0.15
		bytes.encode_s16(i * 2, int(clampf(sample * envelope, -0.95, 0.95) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	if id in ["rain", "hum"]:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(duration * rate)
	return stream

func loop_player(id: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = effects[id]
	player.bus = "Ambiente"
	player.volume_db = volume
	add_child(player)
	player.play()
	return player

func play(id: String, point: Vector3 = Vector3.ZERO, volume: float = -12, spatial: bool = true) -> void:
	if not effects.has(id): return
	if spatial:
		var player := AudioStreamPlayer3D.new()
		player.stream = effects[id]
		player.bus = "Efeitos"
		player.volume_db = volume
		player.max_distance = 24
		add_child(player)
		player.global_position = point
		player.finished.connect(player.queue_free)
		player.play()
	else:
		var player := AudioStreamPlayer.new()
		player.stream = effects[id]
		player.bus = "Efeitos"
		player.volume_db = volume
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()

func _physics_process(_delta: float) -> void:
	var point: Vector3 = game.player.position
	var distance := point.distance_to(last_position)
	last_position = point
	if game.player.controls_enabled and game.player.is_on_floor() and distance < 0.5:
		step_distance += distance
		if step_distance > 1.5:
			step_distance = 0
			play("step", point + Vector3(0, 0.1, 0), -19)
	rain.volume_db = -16 if game.world.is_outdoors(point) else -34

func set_volume(bus: String, value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(maxf(value, 0.0001)))
	var settings := ConfigFile.new()
	for bus_name in ["Ambiente", "Efeitos"]:
		settings.set_value("volume", bus_name, AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)))
	settings.save("user://audio.cfg")
