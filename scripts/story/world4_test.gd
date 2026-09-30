extends SceneTree
## World 4 and the ending: the way down plays once before 4-1, Brace waits in
## 4-1, the ring closes at the end of 4-4, the ending plays, and the game
## carries on in Last Relay with everyone home.
##   godot --headless --path . --script res://scripts/story/world4_test.gd

const P := "res://test-user/world4/progress.json"
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


func wait_scene(path: String, n: int) -> bool:
	for i in n:
		await physics_frame
		if current_scene != null and current_scene.scene_file_path == path:
			return true
	return false


func tap_through(cut) -> int:
	var seen := {}
	for i in 60:
		seen[cut.shot] = true
		cut._tap()
		await frames(4)
		if cut.ending >= 0.0:
			break
	return seen.size()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/world4"))
	for f in [P, P + ".tmp", P + ".bad"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var Game = load("res://scripts/world1/w1_game.gd")
	Game.progress_override = P
	Game.start_mode = "new"
	var game = load("res://scenes/world1_play.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	for id in ["1-1", "1-2", "1-3", "1-4", "2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "3-3", "3-4"]:
		game.flags.append("clear_" + id)
	game.flags.append_array(["w1_clear", "w2_clear", "w3_clear", "seen_gate1", "met_brace"])
	game.big = {"1-1": {"1,1": true, "2,2": true, "3,3": true}}   # three Pips home

	# the way down plays the first time the line leads into 4-1
	check(game._next_level() == "4-1", "after World 3 the line leads to 4-1")
	game.load_level("4-1")
	var ok: bool = await wait_scene("res://scenes/cutscene.tscn", 30)
	check(ok, "going into 4-1 the first time plays the way down")
	game.queue_free()
	var saved = JSON.parse_string(FileAccess.get_file_as_string(P))
	check(saved is Dictionary and saved.save.level == "4-1" and (saved.flags as Array).has("seen_descent"),
		"the game saved at 4-1 first")
	var cut = current_scene
	await frames(40)
	check(cut.shots.size() == 3, "it has three shots (%d)" % cut.shots.size())
	check(await tap_through(cut) == 3, "tapping goes through every shot")
	ok = await wait_scene("res://scenes/world1_play.tscn", 90)
	await frames(10)
	game = current_scene
	check(ok and game.level_id == "4-1", "afterwards the game carries on in 4-1")

	# Brace waits at the top of Dead Air
	var brace := {}
	for n in game.here:
		if str(n.id) == "brace":
			brace = n
	check(not brace.is_empty(), "Brace waits in 4-1")
	if not brace.is_empty():
		game._start_talk(brace)
		check(str(game.talk.lines[1]).contains("CUT THE WIRE YOU WERE LYING ON"), "with the line about the cut wire")
		game._set_state("play")

	# the ring closes at the end of 4-4 and the ending plays
	for id in ["4-1", "4-2", "4-3"]:
		game.flags.append("clear_" + id)
	game.load_level("4-4", Vector2i(-1, -1), false)
	await frames(3)
	check(game._ring_goal(), "4-4 ends at the ring, not a mast")
	game.S.won = true
	ok = await wait_scene("res://scenes/cutscene.tscn", 400)
	check(ok, "reaching the ring plays the ending")
	saved = JSON.parse_string(FileAccess.get_file_as_string(P))
	check(saved is Dictionary and (saved.flags as Array).has("w4_clear") and saved.save.level == "village",
		"World 4 is cleared and the game saved in Last Relay")
	cut = current_scene
	await frames(40)
	check(cut.play == "ending", "it is the ending")
	var n_shots: int = cut.shots.size()
	check(n_shots == 8, "eight shots, with one about the Pips (%d)" % n_shots)
	check(cut.shots.any(func(s): return str(s.lines[0]).contains("PIPS ANSWERED")), "and it counts the Pips that answered")
	check(await tap_through(cut) == n_shots, "tapping goes through every shot")
	ok = await wait_scene("res://scenes/world1_play.tscn", 120)
	await frames(10)
	game = current_scene
	check(ok and game.level_id == "village", "afterwards the game carries on in Last Relay")
	var mast := {}
	for n in game.here:
		if str(n.id) == "mast":
			mast = n
	if not mast.is_empty():
		game._start_talk(mast)
		check(str(game.talk.lines[0]).contains("EVERY STATION WAS CALLING"), "and Old Mast has heard the whole line calling")
	Game.progress_override = ""
	print("WORLD 4 TEST: %d failure(s)" % fails)
	quit()
