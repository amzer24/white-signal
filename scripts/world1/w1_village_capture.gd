extends SceneTree
## Screenshots of Last Relay, the village: people, speech bubbles, the shop,
## house interiors, the switchboard, and story people out in the levels.
## Writes PNGs to test-user/w1-village/ and uses its own progress file.
##   godot --path . --resolution 960x540 --script res://scripts/world1/w1_village_capture.gd

var game


func _initialize() -> void:
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func shot(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-user/w1-village/%s.png" % name)
	print("CAPTURE ", name)


func stand(c: int, r: int) -> void:
	var S = game.S
	S.x = c * 16.0 + 8.0
	S.y = (r + 1) * 16.0 - 7.5
	S.vx = 0.0
	S.vy = 0.0
	S.on_floor = true
	game.cam_x = game._cam_target(true)
	game.cam_y = game._cam_y_target(true)


func npc(id: String) -> Dictionary:
	for n in game.here:
		if n.id == id:
			return n
	return {}


func talk_to(id: String, line: int, typed: float) -> void:
	game._start_talk(npc(id))
	game.talk.i = mini(line, game.talk.lines.size() - 1)
	game.talk.shown = typed * str(game.talk.lines[game.talk.i]).length()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-village"))
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-village/progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	await frames(10)
	assert(game.level_id == "village", "a new game should start in the village")
	await shot("00-card")
	await frames(100)
	await shot("01-start")
	# Old Mast, first meeting: the prompt, then a line half typed and fully typed
	stand(6, 13)
	await frames(6)
	await shot("02-prompt")
	talk_to("mast", 1, 0.5)
	await frames(1)
	await shot("03-talk-typing")
	game.talk.shown = 999.0
	game.talk.shown = str(game.talk.lines[game.talk.i]).length()
	await shot("04-talk-full")
	game._set_state("play")
	# the square and the way out
	stand(45, 13)
	await frames(6)
	await shot("05-square")
	game._use({"kind": "board"})
	await frames(4)
	await shot("06-switchboard")
	game.board_open = false
	game._set_state("play")
	stand(80, 13)
	await frames(6)
	await shot("07-line-starts")
	stand(13, 13)
	game._use(game._usable())
	await frames(2)
	game.talk.shown = 999.0
	await shot("08-mast-house")
	game._set_state("play")
	# Tally's shop: walk in through the door, talk, buy
	stand(36, 13)
	game._use(game._usable())
	await frames(4)
	assert(game.level_id == "village-shop", "the shop door should lead inside")
	await shot("09-shop-inside")
	game.shards = 90
	talk_to("tally", 0, 1.0)
	await frames(2)
	await shot("10-tally")
	game._set_state("shop")
	game.shop_sel = 2
	await frames(4)
	await shot("11-shop")
	game.items["compass"] = true
	game.shards = 10
	game.shop_sel = 3
	await frames(4)
	await shot("12-shop-owned")
	game._set_state("play")
	# the radio shack once everyone has come home
	game.flags = ["met_mast", "met_tally", "met_wren", "met_brace", "met_dot", "met_hum", "w1_clear"]
	game.load_level("village-radio", Vector2i(-1, -1), false)
	await frames(4)
	assert(game.here.size() == 4, "all four listeners should be in the radio shack")
	await shot("13-radio")
	talk_to("wren", 1, 1.0)
	await frames(2)
	await shot("14-wren-home")
	game._set_state("play")
	# out in the levels: Wren in 1-2, Brace in 1-4, Dot in 2-3, Hum in 2-4
	game.flags = []
	for pair in [["1-2", "wren"], ["1-4", "brace"], ["2-3", "dot"], ["2-4", "hum"]]:
		game.load_level(pair[0], Vector2i(-1, -1), false)
		var n := npc(pair[1])
		assert(not n.is_empty(), "%s should stand in %s" % [pair[1], pair[0]])
		stand(int(n.c) - 2, int(n.r))
		talk_to(pair[1], 1, 1.0)
		await frames(2)
		await shot("15-" + pair[0] + "-" + pair[1])
		game._set_state("play")
	# the shard compass pointing off screen in 1-1
	game.items["compass"] = true
	game.load_level("1-1", Vector2i(-1, -1), false)
	await frames(30)
	await shot("16-compass")
	print("VILLAGE CAPTURE DONE")
	quit()
