extends SceneTree
## Screenshots of the hand-off from the intro into Last Relay.
##   godot --path . --script res://scripts/intro/handoff_capture.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(960, 540))
	var Game = load("res://scripts/world1/w1_game.gd")
	Game.progress_override = "res://test-user/intro/handoff-progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.progress_override))
	Game.start_mode = "new"
	Game.intro_handoff = true
	var game = load("res://scenes/world1_play.tscn").instantiate()
	root.add_child(game)
	for spot in [[0.5, "h1-iris"], [0.95, "h2-lying"], [2.2, "h3-mast-talks"]]:
		while game.handoff >= 0.0 and game.handoff < spot[0]:
			await process_frame
		if game.handoff < 0.0:
			await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-user/intro/%s.png" % spot[1])
		print("CAPTURE ", spot[1])
	quit()
