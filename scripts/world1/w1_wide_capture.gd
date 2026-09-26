extends SceneTree
## Screenshots at 16:9, 21:9 and 32:9 to check wide screens fill properly.
## Writes PNGs to test-user/w1-wide/ and uses its own progress file.
##   godot --path . --script res://scripts/world1/w1_wide_capture.gd

var game


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-wide"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-wide/progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	for spot in [["3-2", Vector2i(960, 540), "16x9"], ["3-2", Vector2i(1260, 540), "21x9"], ["2-2", Vector2i(1500, 585), "wide-window"],
			["village", Vector2i(1260, 540), "village-21x9"], ["village-shop", Vector2i(1260, 540), "shop-21x9"], ["3-2", Vector2i(1920, 540), "32x9"]]:
		root.size = spot[1]
		DisplayServer.window_set_size(spot[1])
		await frames(4)
		game.load_level(spot[0], Vector2i(-1, -1), false)
		await frames(90)
		game.S.invuln = 0.0
		await frames(2)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-user/w1-wide/%s.png" % spot[2])
		print("CAPTURE ", spot[2], " view ", root.content_scale_size)
	print("WIDE CAPTURE DONE")
	quit()
