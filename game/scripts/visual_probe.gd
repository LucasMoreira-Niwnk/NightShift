extends Node
## Sonda visual temporaria: teleporta o jogador para pontos-chave, grava PNG e
## imprime o cull_mask resultante. Usada so para inspecionar o culling por andar.
var game: Node

const POINTS := [
	{"id": "01-recepcao", "at": Vector3(1.5, 0.1, 5.0), "look": Vector3(0, 1.6, -12)},
	{"id": "02-rua-fachada", "at": Vector3(1.5, 0.1, 23.0), "look": Vector3(0, 5.0, 4)},
	{"id": "03-corredor-porta-escada", "at": Vector3(0.0, 0.1, -14.0), "look": Vector3(0, 2.5, -20)},
	{"id": "04-vao-escada", "at": Vector3(0.0, 0.1, -18.0), "look": Vector3(0, 5.5, -22)},
	{"id": "05-patamar", "at": Vector3(0.0, 2.2, -23.0), "look": Vector3(0, 5.0, -18)},
	{"id": "06-segundo-andar", "at": Vector3(0.0, 4.3, -12.0), "look": Vector3(0, 4.8, 0)},
	{"id": "07-segundo-andar-janela", "at": Vector3(5.0, 4.3, -5.0), "look": Vector3(8, 5.2, -5)},
]

func run() -> void:
	var player: Node3D = game.player
	player.controls_enabled = false
	for entry in POINTS:
		player.global_position = entry["at"]
		player.velocity = Vector3.ZERO
		await get_tree().process_frame
		game.world.update_floor_culling()
		player.camera.look_at(entry["look"], Vector3.UP)
		await get_tree().process_frame
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		var mask: int = player.camera.cull_mask
		print("PROBE %s cull_mask=%d upper=%s" % [entry["id"], mask, "ON" if (mask & game.world.UPPER_LAYER) != 0 else "OFF"])
		game.get_viewport().get_texture().get_image().save_png("res://../.local/probe-" + entry["id"] + ".png")
	# Feed do CCTV na CAM-04 (2o andar) com o jogador no terreo.
	player.global_position = Vector3(-6.0, 0.1, 1.0)
	await get_tree().process_frame
	game.world.update_floor_culling()
	game.computer.select_camera(3)
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	print("PROBE cctv cam04 player_mask=%d" % player.camera.cull_mask)
	game.computer.feed.get_texture().get_image().save_png("res://../.local/probe-08-cctv-cam04.png")
	print("PROBE_DONE")
	get_tree().quit(0)
