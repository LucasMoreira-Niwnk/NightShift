extends RefCounted

func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()

func run(game: Node, test: Node) -> void:
	var failures_before: int = test.failures
	var chapter: Node = game.chapter
	var original: Dictionary = chapter.serialize_state()
	var original_path: String = chapter.save_path
	var chapter_processing: bool = chapter.is_processing()
	var director_processing: bool = game.director.is_processing()
	chapter.set_process(false)
	game.director.set_process(false)
	# Isolated files: never corrupt the player's checkpoint or its backup.
	chapter.save_path = "user://collaboration-regression.json"
	chapter.flags.collaboration_marker = "first"
	chapter.flags.power_sequence = [2,0]
	chapter.flags.patch_port = 7
	chapter.verified = [0,2]
	test.check(chapter.save_game(),"Atomic checkpoint writes initial generation")
	chapter.flags.collaboration_marker = "second"
	test.check(chapter.save_game(),"Atomic checkpoint writes next generation")
	var backup = chapter.read_checkpoint(chapter.backup_path())
	test.check(backup is Dictionary and backup.flags.get("collaboration_marker","")=="first","Checkpoint backup retains previous valid generation")
	write_text(chapter.save_path,"{truncated")
	test.check(chapter.load_game(),"Truncated primary checkpoint recovers from backup")
	test.check(chapter.flags.get("collaboration_marker","")=="first","Recovery loads backup contents")
	test.check(chapter.verified.has(0) and typeof(chapter.verified[0])==TYPE_INT,"Verified camera indices restore as integers")
	test.check(chapter.flags.power_sequence==[2,0] and typeof(chapter.flags.power_sequence[0])==TYPE_INT,"Breaker startup sequence restores integer identity")
	test.check(chapter.flags.patch_port==7 and typeof(chapter.flags.patch_port)==TYPE_INT,"Network port restores as integer")
	test.check(not FileAccess.file_exists(chapter.save_path+".tmp"),"Successful save leaves no pending temporary checkpoint")
	# Player-operated closing must not re-enable a door collider around the player.
	var door: Node3D = game.world.doors.archive
	door.restore_open(true)
	game.player.global_position = door.to_global(Vector3.ZERO)
	game.player.velocity = Vector3.ZERO
	door.interact()
	test.check(door.is_open and not door.moving and not door.get_collision_layer_value(1),"Door remains open while player stands in doorway")
	game.player.global_position = door.to_global(Vector3(0,0,1.2))
	door.interact()
	await game.get_tree().create_timer(0.45).timeout
	test.check(not door.is_open and not door.moving and door.get_collision_layer_value(1),"Player can close door after leaving doorway")
	# Restore state through the real loader, then return to the smoke-test path.
	write_text(chapter.save_path,JSON.stringify(original))
	test.check(chapter.load_game(),"Collaboration cases restore original world state")
	chapter.save_path = original_path
	chapter.set_process(chapter_processing)
	game.director.set_process(director_processing)
	if test.failures==failures_before: print("COLLABORATION_TEST_OK: atomic checkpoint, backup recovery, integer restoration, doorway protection")
