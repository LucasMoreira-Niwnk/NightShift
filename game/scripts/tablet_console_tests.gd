extends RefCounted

func run(game: Node, test: Node) -> void:
	var point: Vector3 = game.player.position
	var stage: int = game.chapter.stage
	var initial_flags: Dictionary = game.chapter.flags.duplicate(true)
	var initial_transcript: Array = game.chapter.transcript.duplicate()
	game.toggle_tablet()
	await game.get_tree().process_frame
	test.check(game.tablet_hud.visible and not game.player.controls_enabled,"Tablet owns input and blocks movement")
	test.check(game.tablet_hud.hint_label.text == game.chapter.objective(),"Objectives live in tablet hints")
	test.check(not game.ui.get_child(0).get_node("MissionData").visible,"Exploration mission card remains hidden")
	await test.capture("tablet-live-ground")
	var old_projection: Vector2 = game.tablet_hud.map.project(point)
	game.player.position = point + Vector3(2,0,0)
	await test.capture("tablet-live-position")
	test.check(game.tablet_hud.map.project(game.player.position).distance_to(old_projection)>1,"Map projects actual player movement")
	game.player.position = Vector3(0,4.25,-12)
	await test.capture("tablet-live-upper")
	test.check(game.tablet_hud.map.upper,"Tablet follows upper floor without opening a different modal")
	game.player.position = point
	game.toggle_tablet()
	test.check(game.player.controls_enabled and not game.tablet_hud.visible,"Closing tablet restores movement")
	game.chapter.collect_document("tablet_test_note","Nota de teste","Conteúdo exato de uma nota já lida.")
	game.ui.close_modal()
	game.toggle_tablet()
	game.tablet_hud.refresh_notes()
	game.tablet_hud.read_entry("tablet_test_note")
	test.check(game.tablet_hud.note_body.text == "Conteúdo exato de uma nota já lida.","Tablet rereads actual collected note content")
	var tabs: TabContainer = game.tablet_hud.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await test.capture("tablet-note-history")
	tabs.current_tab = 0
	game.toggle_tablet()
	game.chapter.documents.erase("tablet_test_note")
	game.chapter.flags.document_records.erase("tablet_test_note")
	game.computer.interact()
	game.computer.select_camera(2)
	game.computer.console.open_report()
	test.check(game.computer.console.report_dialog.visible and game.computer.console.report_camera == 2,"Single report button opens types for selected camera")
	await test.capture("cctv-report-selector")
	test.check(game.computer.console.cancel_report() and game.computer.active,"Cancelling report preserves CCTV session")
	game.computer.console.submit_report(2)
	test.check(game.chapter.stage == stage and game.chapter.history.is_empty(),"Unconfirmed incident does not fabricate history")
	game.computer.console.feedback = ""
	game.computer.console.set_contaminated(true,"DANIEL. A TRANSMISSÃO NÃO É SUA.")
	await test.capture("cctv-memesis-ready")
	test.check(game.computer.console.contaminated,"Narrative hook activates contaminated console")
	game.computer.console.set_contaminated(false)
	game.computer.close()
	game.chapter.flags = initial_flags
	game.chapter.transcript = initial_transcript
	game.computer.set_monitor_power(false)
	test.check(game.chapter.stage == stage,"HUD checks preserve chapter progression")
	print("TABLET_CONSOLE_TEST_OK: live position, both floors, real notes, report selector, contamination hook, input ownership")
