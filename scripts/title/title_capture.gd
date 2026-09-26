extends SceneTree
## Screenshots of the title screen: the logo lighting up, each page, the start
## transition, and a wide screen. Writes PNGs to test-user/title/.
##   godot --path . --script res://scripts/title/title_capture.gd

var title


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-user/title/%s.png" % name)
	print("CAPTURE ", name)


func key(code: int) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = down
		Input.parse_input_event(e)
		await frames(2)


func open(progress: Dictionary, size: Vector2i) -> void:
	if title:
		title.queue_free()
		await frames(2)
	DisplayServer.window_set_size(size)
	root.size = size
	var path := "res://test-user/title/progress.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(progress))
	f.close()
	title = load("res://scenes/title.tscn").instantiate()
	title.progress_path = path
	root.add_child(title)
	await frames(4)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# the last shot starts the game: keep it off the player's real save
	load("res://scripts/world1/w1_game.gd").progress_override = "res://test-user/title/game-progress.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/title"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# a first launch: no save
	await open({}, Vector2i(960, 540))
	await frames(30)
	await shot("00-logo-lighting")
	await key(KEY_SPACE)   # any key skips the logo
	await frames(10)
	await shot("01-first-launch")
	# a returning player in World 2
	await open({"save": {"level": "2-3", "lives": 4, "shards": 57}, "unlocked": ["test-room", "1-1", "2-1", "2-3"],
		"big": {"1-1": ["1,1", "2,2"], "2-1": ["3,3"]}}, Vector2i(960, 540))
	await key(KEY_SPACE)
	await frames(10)
	await shot("02-continue-world2")
	await key(KEY_DOWN)
	await shot("03-new-game-row")
	await key(KEY_ENTER)
	await shot("04-new-game-confirm")
	await key(KEY_ESCAPE)
	await key(KEY_DOWN)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await shot("05-extras")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await shot("06-how-to-play")
	await key(KEY_ESCAPE)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await shot("07-credits")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	await key(KEY_UP)
	await key(KEY_ENTER)
	await shot("08-settings")
	await key(KEY_ESCAPE)
	await frames(4)
	await shot("09-back-home")
	# World 3 reached, on a wide screen
	await open({"save": {"level": "village", "lives": 5, "shards": 120}, "unlocked": ["1-1", "2-1", "3-1"]}, Vector2i(1260, 540))
	await key(KEY_SPACE)
	await frames(10)
	await shot("10-world3-wide")
	# the start transition
	await key(KEY_ENTER)
	await frames(18)
	await shot("11-leaving")
	await frames(14)
	await shot("12-iris")
	print("TITLE CAPTURE DONE")
	quit()
