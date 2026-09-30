extends SceneTree
## The Pips: freeing one from its glass, Dot keeping them in Last Relay, her
## gifts, and what stays through New Game.
##   godot --headless --path . --script res://scripts/world1/w1_pips_test.gd

const P := "res://test-user/w1-pips/progress.json"
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


func fresh(mode: String) -> void:
	if game:
		game.queue_free()
		await frames(2)
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = P
	game.start_mode = mode
	root.add_child(game)
	await frames(2)


func person(id: String) -> Dictionary:
	for n in game.here:
		if str(n.id) == id:
			return n
	return {}


func talk_to(id: String) -> Array:
	game._set_state("play")
	game._start_talk(person(id))
	var lines: Array = game.talk.lines.duplicate()
	game._set_state("play")
	return lines


## Pretends `n` Pips are home, spread over the levels in order.
func pips_home(n: int) -> void:
	game.big = {}
	for id in game._pip_levels():
		for k in int(game._level_info(id).big):
			if n <= 0:
				return
			if not game.big.has(id):
				game.big[id] = {}
			game.big[id]["%d,0" % k] = true
			n -= 1


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-pips"))
	for f in [P, P + ".tmp", P + ".bad"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	await fresh("new")
	check(game._pips_total() == 47, "47 Pips wait in the glass (%d)" % game._pips_total())
	check(not game.SHOP.any(func(i): return str(i.id) == "compass"), "Tally no longer sells the compass")

	# free the first Pip in 1-1 by touching its glass
	game.load_level("1-1", Vector2i(-1, -1), false)
	await frames(3)
	var cell: Vector2i = game.L.find("O")[0]
	game.S.x = cell.x * 16.0 + 8.0
	game.S.y = cell.y * 16.0 + 8.0
	game.S.vx = 0.0
	game.S.vy = 0.0
	await frames(2)
	check(game._pips_home() == 1, "touching the glass sets the Pip free (%d home)" % game._pips_home())
	check(game.fx.any(func(f): return f[0] == "pip_fly"), "and it flies off home")
	check(game._pip_home_at(cell.x, cell.y), "its glass stays empty from now on")
	game.load_level("1-1", Vector2i(-1, -1), false)
	await frames(3)
	game.S.x = cell.x * 16.0 + 8.0
	game.S.y = cell.y * 16.0 + 8.0
	await frames(2)
	check(game._pips_home() == 1, "an empty glass can't be counted twice")

	# Dot lives in Last Relay, beside her switchboard
	game.load_level("village", Vector2i(-1, -1), false)
	await frames(3)
	check(not person("dot").is_empty(), "Dot is in Last Relay")
	var first := talk_to("dot")
	check(str(first[0]).contains("DOT") and first.any(func(l): return str(l).contains("PIP")), "her first talk is about the Pips")
	check(str(first[first.size() - 1]).begins_with("1 OF 47"), "and ends with how many are home (%s)" % first[first.size() - 1])
	game.load_level("2-3", Vector2i(-1, -1), false)
	await frames(2)
	check(person("dot").is_empty(), "Dot is no longer out in 2-3")
	game.load_level("village-radio", Vector2i(-1, -1), false)
	await frames(2)
	check(person("dot").is_empty(), "nor in the radio shack")

	# her gifts
	game.load_level("village", Vector2i(-1, -1), false)
	await frames(2)
	pips_home(5)
	var lives: int = game.lives
	var lines := talk_to("dot")
	check(game.gifts.has("life") and game.lives == lives + 1, "5 Pips home: Dot gives an extra life")
	check(lines.any(func(l): return str(l).contains("EXTRA LIFE")), "and says so")
	talk_to("dot")
	check(game.lives == lives + 1, "a gift is only given once")
	pips_home(10)
	talk_to("dot")
	check(game.gifts.has("tuner"), "10 Pips home: the Pip tuner")
	pips_home(18)
	talk_to("dot")
	check(game.gifts.has("heart1") and game._start_lives() == 6, "18 Pips home: every game starts with 6 lives")
	pips_home(47)
	lines = talk_to("dot")
	check(game.gifts.has("heart2") and game.gifts.has("all"), "all 47 home: the last gifts")
	check(str(lines[lines.size() - 1]).begins_with("ALL 47"), "Dot thanks you for every one")

	# New Game keeps the Pips and Dot's gifts
	game._save_progress()
	await fresh("new")
	check(game._pips_home() == 47 and game.gifts.has("heart2"), "New Game keeps the Pips and the gifts")
	check(game.lives == 7, "and starts with the extra lives (%d)" % game.lives)

	# Old Mast tells you about them
	var mast: Array = []
	for e in game.story.mast.talk:
		if str(e.get("when", "")) == "!met_mast":
			mast = e.lines
	check(mast.any(func(l): return str(l).contains("PIP")), "Old Mast's first talk mentions the Pips")

	print("PIPS TEST: %d failure(s)" % fails)
	quit()
