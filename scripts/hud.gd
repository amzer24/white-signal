extends Node2D
## HUD + screen overlays — port of JS drawHUD/drawMenu/drawDraft/drawWin.
## Lives inside a CanvasLayer (layer 50); CanvasLayer can't draw, Node2D can.

var banner_t := 0.0

func _ready() -> void:
	RunState.banner.connect(_on_banner)

func _on_banner(_t: String, _s: String) -> void:
	banner_t = 2.5

func _process(_d: float) -> void:
	banner_t = maxf(0.0, banner_t - get_process_delta_time())
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var t := Time.get_ticks_msec() / 1000.0
	if RunState.state != "menu":
		_draw_hud(font)
	if banner_t > 0.0 and RunState.state != "draft" and RunState.state != "win":
		var zi: int = RunState.cur_zone
		var z: Dictionary = RunState.zones[zi]
		draw_rect(Rect2(120, 40, 240, 42), DrawUtil.BG)
		draw_rect(Rect2(120.5, 40.5, 239, 41), DrawUtil.GRAY, false, 1.0)
		draw_string(font, Vector2(121, 61), String(z.name), HORIZONTAL_ALIGNMENT_CENTER, 238, 16, DrawUtil.WHITE)
		draw_string(font, Vector2(130, 74), String(z.sub), HORIZONTAL_ALIGNMENT_CENTER, 220, 8, DrawUtil.GRAY)
	if RunState.state == "menu":
		_draw_menu(font)
	elif RunState.state == "draft":
		_draw_draft(font)
	elif RunState.state == "win":
		_draw_win(font, t)
	elif RunState.state == "pause":
		draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.66))
		draw_string(font, Vector2(190, 120), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 100, 20, DrawUtil.WHITE)
		draw_string(font, Vector2(140, 140), "P / ESC RESUME · R RESPAWN", HORIZONTAL_ALIGNMENT_CENTER, 200, 8, DrawUtil.GRAY)

func _draw_hud(font: Font) -> void:
	var W := 480.0
	var H := 270.0
	# top bar
	draw_rect(Rect2(0, 0, W, 18), DrawUtil.BG)
	draw_rect(Rect2(0, 18, W, 1), DrawUtil.DARK)
	draw_string(font, Vector2(4, 12), "o %d/%d" % [RunState.gems, LevelData.DATA.gems.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.WHITE)
	for i in 5:
		var col := DrawUtil.WHITE if i < RunState.gems % 5 else DrawUtil.DARK
		draw_rect(Rect2(62 + i * 6, 6, 4, 6), col)
	var zone_name: String = String(RunState.zones[RunState.cur_zone].name)
	var mid := zone_name + "  " + DrawUtil.fmt_time(RunState.time)
	draw_string(font, Vector2(0, 12), mid, HORIZONTAL_ALIGNMENT_CENTER, W, 8, DrawUtil.GRAY)
	draw_string(font, Vector2(W - 90, 12), "x%d %d" % [RunState.deaths, Engine.get_frames_per_second()], HORIZONTAL_ALIGNMENT_RIGHT, 86, 8, DrawUtil.WHITE)
	# bottom-left deck chips + notches
	var norm: Array = []
	var curs: Array = []
	for id in RunState.deck:
		if RunState.CARDS[id].cursed:
			curs.append(id)
		else:
			norm.append(id)
	var u := RunState.used_notches()
	var label := "NO GLYPHS" if norm.is_empty() else " ".join(norm.map(func(id): return RunState.SHORT[id]))
	var np := ""
	for i in u:
		np += "o"
	for i in maxi(0, RunState.notches_max - u):
		np += "."
	draw_string(font, Vector2(5, H - 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.BG)
	draw_string(font, Vector2(5, H - 13), np, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.BG)
	draw_string(font, Vector2(4, H - 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.GRAY)
	draw_string(font, Vector2(4, H - 14), np, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.WHITE)
	if not curs.is_empty():
		var cu := RunState.used_cursed()
		var cl := " ".join(curs.map(func(id): return RunState.SHORT[id]))
		var cp := ""
		for i in cu:
			cp += "."
		for i in maxi(0, RunState.cursed_max - cu):
			cp += "o"
		draw_string(font, Vector2(5, H - 23), cl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.BG)
		draw_string(font, Vector2(5, H - 33), cp, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.BG)
		draw_string(font, Vector2(4, H - 24), cl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.GRAY)
		draw_string(font, Vector2(4, H - 34), cp, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DrawUtil.WHITE)

func _draw_menu(font: Font) -> void:
	draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(2, 82), "WHITE SIGNAL", HORIZONTAL_ALIGNMENT_CENTER, 480, 30, DrawUtil.BG)
	draw_string(font, Vector2(0, 80), "WHITE SIGNAL", HORIZONTAL_ALIGNMENT_CENTER, 480, 30, DrawUtil.WHITE)
	draw_string(font, Vector2(0, 98), "A MONO RUNNER . CARRY THE SPARK TO THE GATE", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)
	if not RunState.best.is_empty():
		draw_string(font, Vector2(0, 110), "BEST %s . x%d" % [DrawUtil.fmt_time(float(RunState.best.t)), int(RunState.best.d)], HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)
	draw_string(font, Vector2(0, 124), "A/D MOVE . SPACE JUMP (HOLD = HIGHER)", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.WHITE)
	draw_string(font, Vector2(0, 138), "HOLD INTO WALL + JUMP = WALL KICK", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.WHITE)
	draw_string(font, Vector2(0, 152), "o x5 = SIGNAL SURGE . DRAFT A GLYPH", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.WHITE)
	draw_string(font, Vector2(0, 166), "SHIFT DASH . R RESPAWN . P PAUSE", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)
	if int(Time.get_ticks_msec() / 500.0) % 2 == 0:
		draw_string(font, Vector2(0, 196), "CLICK OR SPACE TO IGNITE", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.WHITE)

func _draw_draft(font: Font) -> void:
	draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.72))
	draw_string(font, Vector2(0, 40), "SIGNAL SURGE", HORIZONTAL_ALIGNMENT_CENTER, 480, 14, DrawUtil.WHITE)
	var u := RunState.used_notches()
	draw_string(font, Vector2(0, 54), "CHOOSE A GLYPH . 1/2/3 . S SKIP . NOTCHES %d/%d" % [u, RunState.notches_max], HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)
	for i in RunState.draft_opts.size():
		var id: String = RunState.draft_opts[i]
		var c: Dictionary = RunState.CARDS[id]
		var cx := 30.0 + i * 144.0
		var afford: bool
		if c.cursed:
			afford = RunState.used_cursed() + int(c.cost) <= RunState.cursed_max
		else:
			afford = u + int(c.cost) <= RunState.notches_max
		var col := DrawUtil.WHITE if afford else DrawUtil.GRAY
		draw_rect(Rect2(cx, 84, 132, 108), col)
		draw_rect(Rect2(cx + 2, 86, 128, 104), DrawUtil.BG)
		var inner := col
		draw_string(font, Vector2(cx + 66 - 20, 110), String(c.g), HORIZONTAL_ALIGNMENT_CENTER, 40, 16, inner)
		draw_string(font, Vector2(cx + 66 - 30, 124), String(c.n), HORIZONTAL_ALIGNMENT_CENTER, 60, 8, inner)
		var cost_str := ""
		for j in int(c.cost):
			cost_str += "o"
		draw_string(font, Vector2(cx + 66 - 20, 138), cost_str, HORIZONTAL_ALIGNMENT_CENTER, 40, 8, DrawUtil.GRAY if afford else DrawUtil.DARK)
		# description (up to 3 wrapped lines)
		var desc: String = _card_desc(id)
		var yy := 154.0
		for line in desc.split("\n"):
			draw_string(font, Vector2(cx + 4, yy), line, HORIZONTAL_ALIGNMENT_CENTER, 124, 8, inner)
			yy += 10
		var foot := "LOCKED" if not afford else ("CURSED [%d]" % (i + 1) if c.cursed else "[%d]" % (i + 1))
		draw_string(font, Vector2(cx + 66 - 30, 184), foot, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, DrawUtil.DARK)
	draw_rect(Rect2(170.5, 204.5, 139, 15), DrawUtil.GRAY, false, 1.0)
	draw_string(font, Vector2(0, 216), "SKIP [S]", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)

func _card_desc(id: String) -> String:
	match id:
		"dash": return "Air dash\nSHIFT . kills foes"
		"jump2": return "+1 air jump"
		"feather": return "-30% fall\nfloaty"
		"swift": return "+25% run speed"
		"spring": return "+20% jump height"
		"magnet": return "Gems fly to you"
		"aegis": return "Survive 1 hit\nper life"
		"stomp": return "Shockwave\nstomps . +bounce"
		"heavy": return "+25% jump\n35% heavier"
		"glass": return "+50% run . +1 jump\nany hit kills"
	return ""

func _draw_win(font: Font, _t: float) -> void:
	draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.66))
	draw_string(font, Vector2(0, 100), "SIGNAL RESTORED", HORIZONTAL_ALIGNMENT_CENTER, 480, 20, DrawUtil.WHITE)
	draw_string(font, Vector2(0, 122), "o %d/%d . %s . x%d" % [RunState.gems, LevelData.DATA.gems.size(), DrawUtil.fmt_time(RunState.time), RunState.deaths], HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)
	var deck_str := "NONE" if RunState.deck.is_empty() else " ".join(RunState.deck.map(func(id): return RunState.SHORT[id]))
	draw_string(font, Vector2(0, 136), "GLYPHS: " + deck_str, HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)
	if RunState.new_best:
		draw_string(font, Vector2(0, 152), "NEW BEST . %s" % DrawUtil.fmt_time(float(RunState.best.get("t", 0.0))), HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.WHITE)
	elif not RunState.best.is_empty():
		draw_string(font, Vector2(0, 152), "BEST %s" % DrawUtil.fmt_time(float(RunState.best.t)), HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.GRAY)
	if int(Time.get_ticks_msec() / 500.0) % 2 == 0:
		draw_string(font, Vector2(0, 164), "CLICK OR SPACE — NEW RUN", HORIZONTAL_ALIGNMENT_CENTER, 480, 8, DrawUtil.WHITE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: InputEventKey = event
		if k.keycode == KEY_F11:
			var mode := DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			return
		if RunState.state == "menu" or RunState.state == "win":
			if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER:
				RunState.start_run()
		elif RunState.state == "draft":
			if k.keycode == KEY_1: RunState.pick_card(0)
			elif k.keycode == KEY_2: RunState.pick_card(1)
			elif k.keycode == KEY_3: RunState.pick_card(2)
			elif k.keycode == KEY_S or k.keycode == KEY_ESCAPE: RunState.skip_draft()
		elif k.keycode == KEY_P or k.keycode == KEY_ESCAPE:
			RunState.toggle_pause()