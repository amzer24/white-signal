extends SceneTree
## The story intro: music starts, a tap finishes the text then moves on a card,
## holding skips it, and the game wakes the Spark by Old Mast, who talks first.
##   godot --headless --path . --script res://scripts/intro/intro_test.gd

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func wait(secs: float) -> void:
	await create_timer(secs).timeout


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	load("res://scripts/world1/w1_game.gd").progress_override = "res://test-user/scene-change-progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://test-user/scene-change-progress.json"))
	var intro = load("res://scenes/intro.tscn").instantiate()
	root.add_child(intro)
	await wait(0.2)
	check(intro.card == 0, "the intro opens on card 1")
	check(intro.music.playing or intro.cue == "intro_line", "card 1 has its music")
	await wait(0.5)
	# a tap while the text types finishes it, the next tap moves on a card
	intro.ct = 1.0
	Input.action_press("jump")
	await wait(0.06)
	Input.action_release("jump")
	await wait(0.1)
	check(intro.typed_full, "a tap finishes the card's text")
	Input.action_press("jump")
	await wait(0.06)
	Input.action_release("jump")
	await wait(0.1)
	check(intro.card == 1, "the next tap goes to card 2")
	# holding skips the rest
	Input.action_press("jump")
	await wait(0.8)
	Input.action_release("jump")
	await wait(1.0)
	var game = null
	for n in root.get_children():
		if str(n.scene_file_path).ends_with("world1_play.tscn"):
			game = n
	check(game != null, "holding skips to the game")
	if game:
		game.progress_path = "res://test-user/intro-progress.json"
		check(game.level_id == "village", "the game starts in Last Relay")
		check(game.handoff >= 0.0 or game.state == "talk", "the Spark wakes by Old Mast")
		await wait(1.8)
		check(game.state == "talk" and str(game.talk.n.id) == "mast", "Old Mast's first talk opens by itself")
		check(str(game.talk.lines[0]).contains("ALONG THE WIRE"), "his first line follows on from the intro")
	print("INTRO TEST: %d failure(s)" % fails)
	quit()
