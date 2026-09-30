extends SceneTree
## The first cutscene: clearing 1-4 plays it once, it can be tapped through or
## skipped, and the game carries on in Last Relay with the Arc.
##   godot --headless --path . --script res://scripts/story/cutscene_test.gd

const P := "res://test-user/cutscene/progress.json"
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


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/cutscene"))
	for f in [P, P + ".tmp", P + ".bad"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var Game = load("res://scripts/world1/w1_game.gd")
	Game.progress_override = P   # the game this test reaches through scene changes uses its own save
	Game.start_mode = "new"
	var game = load("res://scenes/world1_play.tscn").instantiate()
	root.add_child(game)
	await frames(3)

	# clear 1-4: the world clear card, then the cutscene
	game.load_level("1-4", Vector2i(-1, -1), false)
	await frames(3)
	game.S.won = true
	game.S.won_height = 0.3
	for i in 600:
		await physics_frame
		if current_scene != null and current_scene.scene_file_path == "res://scenes/cutscene.tscn":
			break
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/cutscene.tscn", "clearing World 1 plays the first cutscene")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(P))
	check(saved is Dictionary and saved.save.level == "village", "the game saved in Last Relay first")
	check(saved is Dictionary and (saved.flags as Array).has("seen_gate1") and saved.items.get("arc", false), "the Arc and the cutscene are remembered")
	game.queue_free()

	var cut = current_scene
	await frames(40)   # past the moment input is ignored
	check(cut.shots.size() == 5, "it has five shots")
	check(cut.shots.any(func(s): return s.get("garble", false)), "the Howl speaks in one of them")
	var seen := {}
	for i in 30:
		seen[cut.shot] = true
		cut._tap()
		await frames(4)
		if cut.ending >= 0.0:
			break
	check(seen.size() == 5, "tapping goes through every shot (%d)" % seen.size())
	for i in 90:
		await physics_frame
		if current_scene != null and current_scene.scene_file_path == "res://scenes/world1_play.tscn":
			break
	await frames(10)
	var back = current_scene
	check(back != null and back.scene_file_path == "res://scenes/world1_play.tscn" and back.level_id == "village",
		"afterwards the game carries on in Last Relay")
	check(back != null and back._has_arc(), "with the Arc")

	# a second clear of 1-4 in the same game doesn't play it again
	back.load_level("1-4", Vector2i(-1, -1), false)
	await frames(3)
	back.S.won = true
	back.S.won_height = 0.3
	for i in 420:
		await physics_frame
	check(current_scene == back, "it plays once per game")
	Game.progress_override = ""
	print("CUTSCENE TEST: %d failure(s)" % fails)
	quit()
