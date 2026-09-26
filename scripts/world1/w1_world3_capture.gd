extends SceneTree
## Screenshots of World 3 (The Aerials): flyers, wind and sweep arms.
## Writes PNGs to test-user/w1-world3/ and uses its own progress file.
##   godot --path . --resolution 960x540 --script res://scripts/world1/w1_world3_capture.gd

var game


func _initialize() -> void:
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-user/w1-world3/%s.png" % name)
	print("CAPTURE ", name)


func stand(c: int, r: int) -> void:
	var S = game.S
	S.x = c * 16.0 + 8.0
	S.y = (r + 1) * 16.0 - 7.5
	S.vx = 0.0
	S.vy = 0.0
	S.invuln = 99.0   # a tour, not a test: nothing can hurt the Spark while we look
	game.cam_x = game._cam_target(true)
	game.cam_y = game._cam_y_target(true)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-world3"))
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-world3/progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	game.load_level("3-1")
	await frames(10)
	await shot("00-card")
	for spot in [["3-1", 12, 30, "01-first-flyer"], ["3-1", 36, 30, "02-flyer-bridge"], ["3-1", 96, 21, "03-midway-gap"],
			["3-2", 14, 30, "04-tailwind"], ["3-2", 44, 32, "05-updraft"], ["3-2", 72, 21, "06-headwind"],
			["3-2", 97, 21, "07-tailwind-leap"], ["3-3", 10, 30, "08-first-arms"], ["3-3", 38, 30, "09-arm-over-pit"],
			["3-3", 100, 21, "10-twin-arms"], ["3-4", 6, 47, "11-spire-foot"], ["3-4", 33, 21, "12-spire-rings"],
			["3-4", 62, 10, "13-spire-top"]]:
		if game.level_id != spot[0]:
			game.load_level(spot[0], Vector2i(-1, -1), false)
			await frames(4)
		stand(spot[1], spot[2])
		await frames(40)
		stand(spot[1], spot[2])
		game.S.invuln = 0.0   # stop the hurt blink for the picture
		await shot(spot[3])
	# the gust tell in 3-2: half a second before the wind comes back
	game.load_level("3-2", Vector2i(-1, -1), false)
	stand(72, 21)
	while not game._gust_tell():
		await frames(1)
	await frames(10)
	await shot("14-gust-tell")
	print("WORLD 3 CAPTURE DONE")
	quit()
