extends SceneTree
## The title screen: music starts straight away and loops past the intro, menu
## keys move and make a sound, NEW GAME asks first, and CONTINUE starts the game.
##   godot --headless --path . --script res://scripts/title/title_test.gd

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await process_frame


func key(code: int) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = down
		Input.parse_input_event(e)
		await frames(2)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	load("res://scripts/world1/w1_game.gd").progress_override = "res://test-user/scene-change-progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://test-user/scene-change-progress.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/title"))
	var path := "res://test-user/title/test-progress.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"save": {"level": "1-2", "lives": 3, "shards": 9}, "unlocked": ["1-1", "1-2"]}))
	f.close()
	var title = load("res://scenes/title.tscn").instantiate()
	title.progress_path = path
	root.add_child(title)
	await frames(3)
	check(title.music.playing, "title music plays as soon as the title opens")
	var st: AudioStream = title.music.stream
	check(st is AudioStreamWAV and st.loop_mode == AudioStreamWAV.LOOP_FORWARD and st.loop_begin > 0,
		"the music loops back past the intro, not to the start")
	await key(KEY_SPACE)
	check(title.reveal >= 1.0, "any key skips the logo")
	var rows: Array = title._rows()
	check(str(rows[0][0]) == "CONTINUE" and str(rows[1][0]) == "NEW GAME", "with a save: CONTINUE first, then NEW GAME")
	check(title.sel == 0, "focus starts on CONTINUE")
	await key(KEY_DOWN)
	check(title.sel == 1, "down moves to NEW GAME")
	check(str(title.last_sound).begins_with("menu_move"), "moving makes a sound (%s)" % title.last_sound)
	await key(KEY_UP)
	await key(KEY_UP)
	check(title.sel == rows.size() - 1, "up from the top wraps to QUIT")
	await key(KEY_DOWN)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(title.page == "new_confirm" and title.sel == 0, "NEW GAME asks first, with BACK selected")
	await key(KEY_ENTER)
	check(title.page == "home" and title.sel == 1, "BACK returns to NEW GAME")
	await key(KEY_UP)
	await key(KEY_ENTER)
	check(title.leaving >= 0.0, "CONTINUE starts the game")
	await create_timer(1.5).timeout
	var opened := false
	for n in root.get_children():
		opened = opened or str(n.scene_file_path).ends_with("world1_play.tscn")
	check(opened, "the game opens after the transition")
	print("TITLE TEST: %d failure(s)" % fails)
	quit()
