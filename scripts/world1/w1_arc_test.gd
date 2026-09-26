extends SceneTree
## The Arc, the bonus room coming back out, and the music on a death, with
## real key presses where the player would press them.
##   godot --headless --path . --script res://scripts/world1/w1_arc_test.gd

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


func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-arc"))
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-arc/progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	await frames(2)

	# 2-1 opens with a shed sealed by a cracked wall, right next to the start
	game.load_level("2-1", Vector2i(-1, -1), false)
	await frames(10)
	var wall := Vector2i(3, 30)
	check(game.L.at(wall.x, wall.y) == "%", "2-1 has a cracked wall beside the start")
	check(game.S.solid(wall.x, wall.y, game.S.t), "the cracked wall is solid before the Arc")
	game.S.face = 1
	await tap("attack")
	await frames(4)
	check(game.S.tiles.get(wall, "") == "broken", "the Arc breaks the cracked wall")
	check(not game.S.solid(wall.x, wall.y, game.S.t), "the broken wall lets the Spark through")
	var before: int = game.shards
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	await frames(4)
	check(game.shards >= before + 3, "the shards inside the shed can be taken (%d -> %d)" % [before, game.shards])

	# the Arc knocks out a spiked walker from the side, which stomps and dashes can't
	game.load_level("2-2", Vector2i(-1, -1), false)
	await frames(10)
	var spiky := -1
	for n in game.L.walkers.size():
		if str(game.L.walkers[n].kind) == "spiky":
			spiky = n
			break
	check(spiky >= 0, "2-2 has a spiked walker")
	if spiky >= 0:
		var wp: Vector2 = game.S.walker_pos(spiky)
		game.S.x = wp.x - 22.0
		game.S.y = wp.y - 7.5
		game.S.vx = 0.0
		game.S.vy = 0.0
		game.S.face = 1
		game.S.invuln = 5.0
		await tap("attack")
		check(game.S.killed.has(spiky), "the Arc knocks out the spiked walker")

	# World 1 before it is cleared: no Arc yet
	game.flags.clear()
	game.items.erase("arc")
	game.load_level("1-1", Vector2i(-1, -1), false)
	await frames(10)
	await tap("attack")
	check(game.S.arc_cd <= 0.0, "no Arc in World 1 until World 1 is cleared")

	# a bonus room: coming back out keeps the shards taken and the clock
	var taken_cell := Vector2i(-1, -1)
	for cell in game.L.find("o"):
		taken_cell = cell
		break
	game.S.taken[taken_cell] = true
	game.time_left = 222.0
	var pipe: Dictionary = game.L.pipes[0]
	game.S.x = int(pipe.c) * 16.0 + 16.0
	game._enter_pipe()
	await frames(4)
	check(game.level_id.ends_with("-bonus"), "the pipe leads to the bonus room")
	game._enter_pipe()
	await frames(4)
	check(game.level_id == "1-1", "the bonus room pipe leads back to 1-1")
	check(game.S.taken.has(taken_cell), "shards taken before the bonus room stay taken")
	check(absf(game.time_left - 222.0) < 1.0, "the clock carries on where it was (%.1f)" % game.time_left)

	# a death: the music stops for the death sound and starts again on respawn
	game.load_level("1-1", Vector2i(-1, -1), false)
	await frames(10)
	game.S.charged = false
	game.S.invuln = 0.0
	game.S.hurt("fell")
	await frames(40)
	check(not game.music.playing or game.music.volume_db < -30.0, "the music is off while the Spark dies")
	await frames(120)
	check(game.music.playing and game.music.volume_db > -20.0, "the music is back after the respawn")

	print("ARC TEST: %d failure(s)" % fails)
	quit()
