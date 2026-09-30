extends SceneTree
## Screenshots of World 4 (Dead Air): turrets, echoes, the rising static, the
## chase and the ring. Writes PNGs to test-user/w1-world4/ and uses its own progress file.
##   godot --path . --resolution 960x540 --script res://scripts/world1/w1_world4_capture.gd

var game


func _initialize() -> void:
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-user/w1-world4/%s.png" % name)
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-world4"))
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-world4/progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	game.flags.append("seen_descent")   # straight into the level, not the cutscene
	game.load_level("4-1")
	await frames(10)
	await shot("00-card")
	# [level, column, row, name, frames to wait first]
	for spot in [["4-1", 8, 13, "01-brace-first-turret", 100], ["4-1", 38, 13, "02-pit-bolts", 70],
			["4-1", 72, 9, "03-roof", 50], ["4-1", 100, 13, "04-back-to-back", 90], ["4-1", 140, 13, "05-mast", 40],
			["4-2", 12, 13, "06-first-echo", 60], ["4-2", 36, 13, "07-girder-wait", 60], ["4-2", 72, 13, "08-tunnel", 60],
			["4-2", 100, 13, "09-dark-stair", 60], ["4-3", 6, 64, "10-shaft-foot", 300], ["4-3", 22, 34, "11-shaft-midway", 60],
			["4-3", 20, 12, "12-shaft-top", 60], ["4-4", 8, 13, "13-the-howl-wakes", 330], ["4-4", 68, 10, "14-echoes", 60],
			["4-4", 100, 13, "15-crumbling-floor", 60], ["4-4", 168, 13, "16-the-ring", 60]]:
		if game.level_id != spot[0]:
			game.load_level(spot[0], Vector2i(-1, -1), false)
			await frames(4)
		stand(spot[1], spot[2])
		for k in int(spot[4]) / 10:
			await frames(10)
			stand(spot[1], spot[2])
		game.S.invuln = 0.0   # stop the hurt blink for the picture
		await shot(spot[3])
	print("WORLD 4 CAPTURE DONE")
	quit()
