extends SceneTree
## Screenshots of the playable World 1 mode, one per test-room station, plus
## the first screens of 1-1 to 1-4. Writes PNGs to test-user/w1-play/.
##   godot --path . --resolution 960x540 --script res://scripts/world1/w1_play_capture.gd

var game


func _initialize() -> void:
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-user/w1-play/%s.png" % name)
	print("CAPTURE ", name)


func place(col: int) -> void:
	var S = game.S
	var r := 13
	while r > 1 and game.L.at(col, r) != "." and game.L.at(col, r) != "P":
		r -= 1
	S.x = col * 16.0 + 8.0
	S.y = (r + 1) * 16.0 - 7.5
	S.vx = 0.0
	S.vy = 0.0
	game.cam_x = game._cam_target(true)
	game.cam_y = game._cam_y_target(true)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-play"))
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-play/progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	game.load_level("test-room")  # a new game starts in the village; this tour is the training yard
	await frames(10)
	await shot("00-card")
	await frames(100)
	# walk and jump for a while with real input
	Input.action_press("move_right")
	for i in 8:
		Input.action_press("jump")
		await frames(14)
		Input.action_release("jump")
		await frames(10)
	Input.action_release("move_right")
	await shot("01-play")
	for station in [[34, "02-blocks"], [66, "03-enemies"], [93, "04-loose"], [122, "05-plates"],
			[152, "06-machines"], [182, "07-ride"], [212, "08-air"], [242, "09-dropper"],
			[272, "10-warden"], [302, "11-mast"]]:
		place(station[0])
		await frames(40)
		await shot(station[1])
	# halfway down a pipe: the Spark should be hidden by the pipe, not in front
	var pipe: Dictionary = game.L.pipes[0]
	place(int(pipe.c))
	game.S.y = int(pipe.r) * 16.0 - 7.0
	game.S.x = int(pipe.c) * 16.0 + 16.0
	game._set_state("pipe")
	await frames(20)
	await shot("12-pipe")
	# the pause menu: main page, settings, level select
	game.pause_from = "play"
	game._set_state("pause")
	for pg in ["main", "settings", "levels"]:
		game.pause_page = pg
		game.pause_sel = 1
		await frames(4)
		await shot("13-pause-" + pg)
	game._set_state("play")
	game.load_level("1-1-bonus")
	await frames(110)
	await shot("level-1-1-bonus")
	for id in ["1-1", "1-2", "1-3", "1-4", "2-1", "2-2", "2-3", "2-4"]:
		game.load_level(id)
		await frames(110)
		await shot("level-" + id)
	# dark stretches, with lamps lit as the Spark passes
	for shot_at in [["2-2", 64, 20], ["1-4", 156, 22], ["2-4", 128, 18]]:
		game.load_level(shot_at[0], Vector2i(-1, -1), false)
		game.S.x = int(shot_at[1]) * 16.0 + 8.0
		game.S.y = (int(shot_at[2]) + 1) * 16.0 - 7.5
		game.cam_x = game._cam_target(true)
		game.cam_y = game._cam_y_target(true)
		await frames(50)
		await shot("dark-" + str(shot_at[0]))
	quit()
