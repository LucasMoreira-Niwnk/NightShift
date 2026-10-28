extends RefCounted

func run(game: Node, test: Node) -> void:
	var sound: Node = game.sound
	for id in ["rain", "rain_inside", "hum", "ring", "drag", "knock", "printer", "switch", "engine", "car_door", "door_open", "door_close"]:
		var stream: AudioStreamWAV = sound.effects[id]
		test.check(stream != null and stream.data.size() > 0 and stream.get_length() > 0.03, "Recorded cue imports: " + id)
	for id in ["rain", "rain_inside", "hum"]:
		var stream: AudioStreamWAV = sound.effects[id]
		test.check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 0, "Ambience loop configured: " + id)
	var hard := Vector3(0, 0, 8)
	var wood := Vector3(-4.8, 4.2, -9)
	test.check(sound.step_surface(hard) == "hard", "Reception uses hard footfalls")
	test.check(sound.step_surface(wood) == "wood", "Administration uses wood footfalls")
	test.check(sound.step_surface(Vector3(-4.8, 4.2, 2)) == "hard", "TI keeps hard footfalls")
	test.check(sound.step_surface(Vector3(-9.7, 4.2, -9)) == "hard", "Service landing keeps concrete footfalls")
	for point in [hard, wood]:
		var previous: AudioStreamWAV = null
		for i in range(20):
			var next: AudioStreamWAV = sound.choose_step(point)
			test.check(next != previous, "Adjacent footsteps use distinct recordings")
			previous = next
	sound.update_mix(hard, 10)
	test.check(sound.indoor_rain.volume_db > sound.rain.volume_db and sound.reverb.wet > 0.1, "Interior uses muffled rain and room reflections")
	var powered: bool = game.world.interior_powered
	game.world.interior_powered = false
	sound.update_mix(hard, 10)
	test.check(sound.ambience.volume_db < -70 and sound.indoor_rain.playing, "Blackout silences electrical tone but preserves rain")
	game.world.interior_powered = powered
	sound.update_mix(hard, 10)
	test.check(sound.ambience.volume_db > -40 if powered else sound.ambience.volume_db < -70, "Electrical mix restores its previous power state")
	sound.update_mix(Vector3(0, 0, 20), 10)
	test.check(sound.rain.volume_db > sound.indoor_rain.volume_db and sound.reverb.wet < 0.02, "Exterior restores open rain and removes room reflections")
	sound.update_mix(game.player.position, 10)
	print("SOUNDSCAPE_TEST_OK: recorded cues, nonrepeating surface steps, rain transition, blackout mix")
