extends SceneTree
## Plays through Last Relay with real key presses: talk to Old Mast with Down,
## page through with jump, walk into Tally's, buy, come back out, take the line.
##   godot --headless --path . --script res://scripts/world1/w1_village_test.gd

var game
var fails := 0


func _initialize() -> void:
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)


func tap_down() -> void:
	key(KEY_DOWN, true)
	await frames(3)
	key(KEY_DOWN, false)
	await frames(3)


func tap_jump() -> void:
	Input.action_press("jump")
	await frames(3)
	Input.action_release("jump")
	await frames(3)


func walk_to(c: int) -> void:
	var target := c * 16.0 + 8.0
	for i in 600:
		var dx: float = target - game.S.x
		if absf(dx) < 3.0:
			break
		if dx > 0:
			Input.action_press("move_right")
			Input.action_release("move_left")
		else:
			Input.action_press("move_left")
			Input.action_release("move_right")
		await frames(1)
	Input.action_release("move_right")
	Input.action_release("move_left")
	await frames(20)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-village"))
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-village/test-progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	await frames(120)
	check(game.level_id == "village" and game.state == "play", "a new game starts in Last Relay")
	check(game.time_left > 900.0, "the village has no clock")
	await walk_to(8)
	key(KEY_DOWN, true)
	await frames(1)
	await frames(2)
	key(KEY_DOWN, false)
	await frames(3)
	check(game.state == "talk" and str(game.talk.n.get("id", "")) == "mast", "Down next to Old Mast starts a conversation")
	var lines: int = game.talk.lines.size()
	for i in lines * 2 + 2:
		if game.state != "talk":
			break
		await tap_jump()
	check(game.state == "play", "jump pages through and closes the bubble")
	check(game.flags.has("met_mast"), "meeting Mast is remembered")
	var y0: float = game.S.y
	await frames(10)
	check(absf(game.S.y - y0) < 1.0, "closing the bubble does not make the Spark jump")
	await tap_down()
	check(game.state == "talk" and game.talk.lines[0].begins_with("THE LINE STARTS"), "talking again gives his next lines")
	for i in 8:
		if game.state != "talk":
			break
		await tap_jump()
	# Tally's shop
	await walk_to(36)
	await tap_down()
	check(game.level_id == "village-shop", "Down at the shop door goes inside")
	game.shards = 50
	await walk_to(15)
	await tap_down()
	check(game.state == "talk", "Tally talks")
	for i in 10:
		if game.state != "talk":
			break
		await tap_jump()
	check(game.state == "shop", "Tally's lines end in the shop")
	await frames(12)
	await tap_jump()
	check(game.lives == 6 and game.shards == 10, "buying an extra life costs 40 shards")
	await tap_jump()
	check(game.lives == 6 and game.shards == 10, "no sale without enough shards")
	for i in game.SHOP.size():
		await tap_down()
	check(game.shop_sel == game.SHOP.size(), "Down moves to LEAVE")
	await tap_jump()
	check(game.state == "play", "LEAVE closes the shop")
	await walk_to(3)
	await tap_down()
	check(game.level_id == "village" and absf(game.S.x - (37 * 16 + 8)) < 2.0, "the shop door comes back out beside it")
	# a locked house
	await walk_to(64)
	await tap_down()
	check(game.state == "talk" and game.talk.lines[0] == "LOCKED.", "a locked house says so")
	await frames(12)
	await tap_jump()
	# the switchboard
	await walk_to(45)
	await tap_down()
	check(game.state == "pause" and game.board_open, "the switchboard opens the level list")
	key(KEY_ESCAPE, true)
	await frames(2)
	key(KEY_ESCAPE, false)
	await frames(4)
	check(game.state == "play" and not game.board_open, "Esc closes the switchboard")
	# the line
	await walk_to(87)
	await tap_down()
	check(game.level_id == "1-1", "the signpost starts the first level you haven't cleared")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.progress_path))
	check(saved.save.level == "1-1" and saved.flags.has("met_mast") and int(saved.save.lives) == 6, "flags and the purchase are saved")
	print("VILLAGE TEST: %d failure(s)" % fails)
	quit(1 if fails > 0 else 0)
