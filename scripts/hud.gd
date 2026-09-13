extends Node2D
## HUD + screen overlays — port of JS drawHUD/drawMenu/drawDraft/drawWin,
## drawn with the 3x5 pixel font. Lives inside a CanvasLayer (layer 50).

const W := 480.0
const H := 270.0
const BANNER_T := 2.5

var can_resume := false
var banner_t := 0.0
var _last_gems := 0
var _gem_pop := 0.0     # shard counter bump
var _surge_flash := 0.0 # white flash on surge open
var _menu_t := 0.0
var menu_ui: Node2D

func _ready() -> void:
	GameInput.controller_lost.connect(_controller_lost)
	can_resume = not RunState.load_boundary().is_empty()
	RunState.banner.connect(_on_banner)
	RunState.state_changed.connect(_on_state)
	menu_ui = Node2D.new()
	menu_ui.name = "Menu"
	menu_ui.set_script(load("res://scripts/menu_ui.gd"))
	add_child(menu_ui)

func _on_banner(_t: String, _s: String) -> void:
	banner_t = BANNER_T

func _controller_lost() -> void:
	if RunState.state == "play": RunState.toggle_pause()

func _on_state(s: String) -> void:
	if s == "menu": can_resume = not RunState.load_boundary().is_empty()
	if s == "draft":
		_surge_flash = 0.0 if AppSettings.reduced_flashes else 0.25

func _process(d: float) -> void:
	banner_t = maxf(0.0, banner_t - d)
	_gem_pop = maxf(0.0, _gem_pop - d * 6.0)
	_surge_flash = maxf(0.0, _surge_flash - d)
	_menu_t += d
	if RunState.gems != _last_gems:
		_last_gems = RunState.gems
		_gem_pop = 1.0
	queue_redraw()

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	_draw_scan_vignette()
	if RunState.state != "menu":
		_draw_hud(t)
	if banner_t > 0.0 and RunState.state in ["play", "pause"]:
		_draw_banner()
	match RunState.state:
		"draft": _draw_draft(t)
		"win": _draw_win(t)
		"relay_clear", "build_complete": _draw_relay_clear()
		"pause": _draw_pause()
		"lab_complete": _draw_lab_complete()
	if _surge_flash > 0.0 and not AppSettings.reduced_flashes:
		draw_rect(Rect2(0, 0, W, H), Color(DrawUtil.WHITE, _surge_flash * 0.6))

# ------------------------------------------------------------- diegetic CRT
func _draw_scan_vignette() -> void:
	# scanlines: every 3rd row, 20% black (JS drawScanVignette)
	var y := 0
	while y < int(H):
		draw_rect(Rect2(0, y, W, 1), Color(0, 0, 0, 0.2))
		y += 3
	# vignette: four edge gradients (per-vertex alpha) approximate the radial
	var edge := Color(0, 0, 0, 0.45)
	var clear := Color(0, 0, 0, 0.0)
	var d := 70.0
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, d), Vector2(0, d)]),
		PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, H - d), Vector2(W, H - d), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([clear, clear, edge, edge]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(d, 0), Vector2(d, H), Vector2(0, H)]),
		PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2(W - d, 0), Vector2(W, 0), Vector2(W, H), Vector2(W - d, H)]),
		PackedColorArray([clear, edge, edge, clear]))

# ------------------------------------------------------------- in-run HUD
func _draw_hud(t: float) -> void:
	# top plate
	draw_rect(Rect2(0, 0, W, 18), DrawUtil.BG)
	draw_rect(Rect2(0, 18, W, 1), DrawUtil.DARK)
	var x := 0
	while x < int(W):  # dotted underline so the plate reads as a panel, not a bar
		draw_rect(Rect2(x, 19, 1, 1), Color("1a1a1a"))
		x += 3

	# shards: ◆ N/TOTAL with a pop on pickup
	var pop := int(roundf(_gem_pop * 2.0))
	DrawUtil.diamond(self, Vector2(4, 6 - pop), DrawUtil.WHITE)
	DrawUtil.text(self, Vector2(12, 6), "%d/%d" % [RunState.collected_this_relay, RunState.level.gems.size() + RunState.level.get("fixtures", []).filter(func(f): return f.kind == "memory").size()], DrawUtil.WHITE)
	# surge pips: fill toward the next SURGE; the 5th slot pulses when 4/5
	var filled := RunState.gems % 5
	for i in 5:
		var px := 46 + i * 7
		var lit := i < filled
		var col := DrawUtil.WHITE if lit else DrawUtil.DARK
		if not lit and filled == 4 and int(t * 4.0) % 2 == 0:
			col = DrawUtil.GRAY
		draw_rect(Rect2(px, 6, 5, 6), col)
		if lit:
			draw_rect(Rect2(px + 1, 7, 3, 4), DrawUtil.BG)
			draw_rect(Rect2(px + 2, 8, 1, 2), DrawUtil.WHITE)
	if filled == 4:
		DrawUtil.text(self, Vector2(84, 6), "SURGE", DrawUtil.GRAY if int(t * 4.0) % 2 == 0 else DrawUtil.DARK)

	# centre: zone + time
	var zone_name: String = "AFTERLIGHT" if RunState.lab_active else "R%d . %s" % [RunState.relay_index, ["FLATS", "LISTEN", "STAND"][RunState.relay_index]]
	DrawUtil.text(self, Vector2(W / 2.0 - 2, 6), zone_name, DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_rect(Rect2(W / 2.0 + 1, 5, 1, 7), DrawUtil.DARK)
	DrawUtil.text(self, Vector2(W / 2.0 + 5, 6), DrawUtil.fmt_time(RunState.time), DrawUtil.WHITE)

	# right: deaths (✕N) + fps
	var fps := "%d" % Engine.get_frames_per_second()
	DrawUtil.text(self, Vector2(W - 4, 6), fps, DrawUtil.DARK, 1, HORIZONTAL_ALIGNMENT_RIGHT)
	var dx := W - 4 - DrawUtil.text_width(fps) - 6
	DrawUtil.text(self, Vector2(dx, 6), "%d" % RunState.deaths, DrawUtil.WHITE, 1, HORIZONTAL_ALIGNMENT_RIGHT)
	var xx := dx - DrawUtil.text_width("%d" % RunState.deaths) - 7
	draw_rect(Rect2(xx, 6, 1, 1), DrawUtil.WHITE); draw_rect(Rect2(xx + 4, 6, 1, 1), DrawUtil.WHITE)
	draw_rect(Rect2(xx + 1, 7, 1, 1), DrawUtil.WHITE); draw_rect(Rect2(xx + 3, 7, 1, 1), DrawUtil.WHITE)
	draw_rect(Rect2(xx + 2, 8, 1, 1), DrawUtil.WHITE)
	draw_rect(Rect2(xx + 1, 9, 1, 1), DrawUtil.WHITE); draw_rect(Rect2(xx + 3, 9, 1, 1), DrawUtil.WHITE)
	draw_rect(Rect2(xx, 10, 1, 1), DrawUtil.WHITE); draw_rect(Rect2(xx + 4, 10, 1, 1), DrawUtil.WHITE)

	DrawUtil.text_shadow(self, Vector2(W - 6, 28), RunState.objective_text(), DrawUtil.WHITE, 1, HORIZONTAL_ALIGNMENT_RIGHT)
	if RunState.level.get("rain_pressure", false):
		DrawUtil.text_shadow(self, Vector2(W - 6, 39), "RAIN %d/3" % mini(3, 1 + int(RunState.relay_time / 40.0)), DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_RIGHT)

	if RunState.lab_active:
		DrawUtil.text_shadow(self,Vector2(6,28),["1 ORDINARY","2 AFTERLIGHT","3 READABILITY"][RunState.lab_mode],DrawUtil.GRAY)
		DrawUtil.text_shadow(self,Vector2(474,248),"1/2/3 LIGHT . G ART . H GENTLE . Q EXIT",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_RIGHT)
		DrawUtil.text_shadow(self,Vector2(474,258),("GENERATED" if RunState.lab_generated else "PROCEDURAL") + (" . GENTLE ON" if RunState.lab_gentle else " . GENTLE OFF"),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_RIGHT)

	# bottom-left: glyph chips + notch diamonds (+ cursed row)
	var player := get_tree().get_first_node_in_group("player")
	var norm: Array = []
	var curs: Array = []
	for id in RunState.deck:
		if RunState.CARDS[id].cursed:
			curs.append(id)
		else:
			norm.append(id)
	var u := RunState.used_notches()
	var y0 := H - 9.0
	# notches
	for i in RunState.notches_max:
		DrawUtil.diamond(self, Vector2(4 + i * 7, y0 - 8), DrawUtil.WHITE, i >= u)
	# chips
	var cx := 4.0
	if norm.is_empty():
		DrawUtil.text_shadow(self, Vector2(cx, y0), "NO GLYPHS", DrawUtil.GRAY)
	else:
		for id in norm:
			var label: String = RunState.SHORT[id]
			var w := DrawUtil.text_width(label) + 4
			var col := DrawUtil.GRAY
			# DASH chip lights when the dash is ready — a live resource, not a label
			if id == "dash" and player:
				col = DrawUtil.WHITE if player.dash_ready else DrawUtil.DARK
			elif id == "jump2" and player:
				col = DrawUtil.WHITE if player.air_jumps > 0 else DrawUtil.DARK
			elif id == "aegis" and player:
				col = DrawUtil.WHITE if player.shield > 0 else DrawUtil.DARK
			draw_rect(Rect2(cx - 1, y0 - 2, w + 1, 9), DrawUtil.BG)
			draw_rect(Rect2(cx - 1, y0 - 2, w + 1, 1), col)
			DrawUtil.text(self, Vector2(cx + 1, y0), label, col)
			cx += w + 3
	if not curs.is_empty():
		var cu := RunState.used_cursed()
		var yc := y0 - 20.0
		for i in RunState.cursed_max:
			DrawUtil.diamond(self, Vector2(4 + i * 7, yc - 8), DrawUtil.GRAY, i >= cu)
		cx = 4.0
		for id in curs:
			var label: String = RunState.SHORT[id]
			var w := DrawUtil.text_width(label) + 4
			draw_rect(Rect2(cx - 1, yc - 2, w + 1, 9), DrawUtil.BG)
			draw_rect(Rect2(cx - 1, yc - 2, w + 1, 1), DrawUtil.GRAY)
			DrawUtil.text(self, Vector2(cx + 1, yc), label, DrawUtil.GRAY)
			cx += w + 3
		DrawUtil.text(self, Vector2(cx + 2, yc), "CURSED", DrawUtil.DARK)

# ------------------------------------------------------------- zone banner
func _draw_banner() -> void:
	var z: Dictionary = {"name": RunState.level.name if RunState.lab_active else "R%d . %s" % [RunState.relay_index, RunState.level.name], "sub": RunState.objective_text()}
	# slide in from above over 0.25s, hold, fade out over the last 0.4s
	var age := BANNER_T - banner_t
	var slide := 1.0 - minf(1.0, age / 0.25)
	slide = slide * slide
	var alpha := minf(1.0, banner_t / 0.4)
	var y := 40.0 - slide * 60.0
	var plate := Color(DrawUtil.BG, alpha)
	draw_rect(Rect2(120, y, 240, 42), plate)
	draw_rect(Rect2(120, y, 240, 1), Color(DrawUtil.GRAY, alpha))
	draw_rect(Rect2(120, y + 41, 240, 1), Color(DrawUtil.GRAY, alpha))
	draw_rect(Rect2(120, y, 1, 42), Color(DrawUtil.GRAY, alpha))
	draw_rect(Rect2(359, y, 1, 42), Color(DrawUtil.GRAY, alpha))
	# corner ticks
	for c in [Vector2(120, y), Vector2(357, y), Vector2(120, y + 39), Vector2(357, y + 39)]:
		draw_rect(Rect2(c.x, c.y, 3, 3), Color(DrawUtil.WHITE, alpha))
	DrawUtil.text_shadow(self, Vector2(W / 2.0, y + 9), String(z.name), Color(DrawUtil.WHITE, alpha), 2, HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self, Vector2(W / 2.0, y + 29), String(z.sub), Color(DrawUtil.GRAY, alpha), 1, HORIZONTAL_ALIGNMENT_CENTER)

# ------------------------------------------------------------- screens
func _dim(a: float) -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, a))

func _rule(y: float, w := 200.0) -> void:
	var x := W / 2.0 - w / 2.0
	while x < W / 2.0 + w / 2.0:
		draw_rect(Rect2(x, y, 2, 1), DrawUtil.DARK)
		x += 4

func _draw_pause() -> void:
	_dim(0.66)
	DrawUtil.text_shadow(self, Vector2(W / 2.0, 92), "PAUSED", DrawUtil.WHITE, 4, HORIZONTAL_ALIGNMENT_CENTER)
	_rule(118)
	var deck_str := "NONE" if RunState.deck.is_empty() else " ".join(RunState.deck.map(func(id): return RunState.CARDS[id].n))
	DrawUtil.text(self, Vector2(W / 2.0, 126), "GLYPHS: " + deck_str, DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self, Vector2(W / 2.0, 138), "SHARDS %d/%d . %s . X%d" % [RunState.gems, RunState.level.gems.size(), DrawUtil.fmt_time(RunState.time), RunState.deaths], DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self, Vector2(W / 2.0, 160), ("START / B RESUME" if GameInput.controller_active else "P / ESC RESUME . R RESPAWN"), DrawUtil.WHITE, 1, HORIZONTAL_ALIGNMENT_CENTER)
	draw_rect(Rect2(170,182,140,22),DrawUtil.DARK)
	DrawUtil.text(self,Vector2(240,190),("X . SETTINGS" if GameInput.controller_active else "O . SETTINGS"),DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_draft(t: float) -> void:
	_dim(0.72)
	DrawUtil.text_shadow(self, Vector2(W / 2.0, 30), "SIGNAL SURGE", DrawUtil.WHITE, 3, HORIZONTAL_ALIGNMENT_CENTER)
	var u := RunState.used_notches()
	DrawUtil.text(self, Vector2(W / 2.0, 52), ("CHOOSE A GLYPH . A/X/Y . B SKIP" if GameInput.controller_active else "CHOOSE A GLYPH . 1/2/3 . S SKIP"), DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	# notch budget as diamonds
	var nx := W / 2.0 - (RunState.notches_max * 7) / 2.0
	for i in RunState.notches_max:
		DrawUtil.diamond(self, Vector2(nx + i * 7, 62), DrawUtil.WHITE, i >= u)
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
		var mid := cx + 66.0
		# card frame (cursed: dashed border)
		draw_rect(Rect2(cx, 84, 132, 108), col if not c.cursed else DrawUtil.DARK)
		draw_rect(Rect2(cx + 2, 86, 128, 104), DrawUtil.BG)
		if c.cursed:
			var dx := cx
			while dx < cx + 132:
				draw_rect(Rect2(dx, 84, 4, 2), col)
				draw_rect(Rect2(dx, 190, 4, 2), col)
				dx += 8
			var dy := 84.0
			while dy < 192:
				draw_rect(Rect2(cx, dy, 2, 4), col)
				draw_rect(Rect2(cx + 130, dy, 2, 4), col)
				dy += 8
		# key hint tab
		draw_rect(Rect2(cx + 4, 80, 13, 9), col)
		DrawUtil.text(self, Vector2(cx + 10, 82), "%d" % (i + 1), DrawUtil.BG, 1, HORIZONTAL_ALIGNMENT_CENTER)
		# big glyph, name, cost diamonds
		DrawUtil.text(self, Vector2(mid, 98), String(c.g), col, 4, HORIZONTAL_ALIGNMENT_CENTER)
		DrawUtil.text(self, Vector2(mid, 126), String(c.n), col, 2, HORIZONTAL_ALIGNMENT_CENTER)
		var cost := int(c.cost)
		var cxx := mid - (cost * 7) / 2.0
		for j in cost:
			DrawUtil.diamond(self, Vector2(cxx + j * 7, 140), DrawUtil.GRAY if afford else DrawUtil.DARK, c.cursed)
		var yy := 152.0
		for line in _card_desc(id).split("\n"):
			DrawUtil.text(self, Vector2(mid, yy), line, col if afford else DrawUtil.DARK, 1, HORIZONTAL_ALIGNMENT_CENTER)
			yy += 8
		var foot := "LOCKED" if not afford else ("CURSED" if c.cursed else "PICK [%d]" % (i + 1))
		if afford and int(t * 3.0) % 2 == 0 and not c.cursed:
			foot = "PICK [%d]" % (i + 1)
		DrawUtil.text(self, Vector2(mid, 180), foot, DrawUtil.DARK if not afford else (DrawUtil.GRAY if c.cursed else DrawUtil.DARK), 1, HORIZONTAL_ALIGNMENT_CENTER)
	draw_rect(Rect2(170, 204, 140, 16), DrawUtil.BG)
	draw_rect(Rect2(170, 204, 140, 1), DrawUtil.GRAY); draw_rect(Rect2(170, 219, 140, 1), DrawUtil.GRAY)
	draw_rect(Rect2(170, 204, 1, 16), DrawUtil.GRAY); draw_rect(Rect2(309, 204, 1, 16), DrawUtil.GRAY)
	DrawUtil.text(self, Vector2(W / 2.0, 210), ("SKIP [B] . FREE" if GameInput.controller_active else "SKIP [S] . FREE"), DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _card_desc(id: String) -> String:
	match id:
		"dash": return "AIR DASH . " + GameInput.action_label("dash") + "\nKILLS NOISE\nREFILLS ON GROUND"
		"jump2": return "+1 AIR JUMP\nREFILLS ON GROUND"
		"feather": return "-30% FALL SPEED\nFLOATY ARCS"
		"swift": return "+25% RUN SPEED\nFASTER ACCEL"
		"spring": return "+20% JUMP HEIGHT"
		"magnet": return "SHARDS FLY TO YOU"
		"aegis": return "SURVIVE 1 HIT\nPER LIFE\nBEACONS MEND IT"
		"stomp": return "SHOCKWAVE STOMPS\nBIGGER BOUNCE"
		"heavy": return "+25% JUMP\n35% HEAVIER FALL\nHARD LANDINGS"
		"glass": return "+50% RUN . +1 JUMP\nANY HIT KILLS\nAEGIS VOID"
	return ""

func _draw_win(t: float) -> void:
	_dim(0.66)
	DrawUtil.text_shadow(self, Vector2(W / 2.0, 78), "SIGNAL RESTORED", DrawUtil.WHITE, 4, HORIZONTAL_ALIGNMENT_CENTER)
	_rule(104)
	DrawUtil.text(self, Vector2(W / 2.0, 114), "SHARDS %d/%d . %s . X%d DEATHS" % [RunState.gems, RunState.level.gems.size(), DrawUtil.fmt_time(RunState.time), RunState.deaths], DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	var deck_str := "NONE" if RunState.deck.is_empty() else " ".join(RunState.deck.map(func(id): return RunState.CARDS[id].n))
	DrawUtil.text(self, Vector2(W / 2.0, 126), "GLYPHS: " + deck_str, DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	if RunState.new_best:
		var flash := DrawUtil.WHITE if AppSettings.reduced_flashes or int(t * 4.0) % 2 == 0 else DrawUtil.GRAY
		DrawUtil.text(self, Vector2(W / 2.0, 144), "* NEW BEST %s *" % DrawUtil.fmt_time(float(RunState.best.get("t", 0.0))), flash, 2, HORIZONTAL_ALIGNMENT_CENTER)
	elif not RunState.best.is_empty():
		DrawUtil.text(self, Vector2(W / 2.0, 144), "BEST %s" % DrawUtil.fmt_time(float(RunState.best.t)), DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	if int(t * 2.0) % 2 == 0:
		DrawUtil.text(self, Vector2(W / 2.0, 170), "> CLICK OR SPACE - NEW RUN <", DrawUtil.WHITE, 1, HORIZONTAL_ALIGNMENT_CENTER)

# ------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	# Menu actions may detach the HUD during a scene change.
	var input_viewport := get_viewport()
	if menu_ui.handle_input(event):
		input_viewport.set_input_as_handled()
		return
	event = GameInput.classic_event(event,RunState.state)
	if RunState.state == "pause":
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_O:
			menu_ui.open_settings()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Rect2(170,182,140,22).has_point(get_viewport().get_mouse_position()):
			menu_ui.open_settings()
			get_viewport().set_input_as_handled()
			return
	# mouse: menu/win → start, pause → resume, draft → card / skip hit-test (JS canvas click)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mp: Vector2 = get_viewport().get_mouse_position()
		if RunState.state == "relay_clear":
			RunState.advance_relay()
		elif RunState.state == "build_complete":
			RunState.start_run()
		elif RunState.state == "menu" or RunState.state == "win":
			RunState.start_run()
		elif RunState.state == "pause":
			RunState.toggle_pause()
		elif RunState.state == "draft":
			for i in RunState.draft_opts.size():
				if Rect2(30.0 + i * 144.0, 80, 132, 112).has_point(mp):
					RunState.pick_card(i)
					return
			if Rect2(170, 204, 140, 16).has_point(mp):
				RunState.skip_draft()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: InputEventKey = event
		if RunState.state == "menu" and k.keycode == KEY_L:
			RunState.start_lab()
			return
		if RunState.lab_active:
			if k.keycode == KEY_Q:
				RunState.leave_lab()
				return
			if RunState.state == "lab_complete" and k.keycode in [KEY_SPACE,KEY_ENTER]:
				RunState.start_lab()
				return
			if RunState.state in ["play","pause"]:
				if k.keycode in [KEY_1,KEY_2,KEY_3]:
					RunState.lab_mode = int(k.keycode - KEY_1)
					return
				if k.keycode == KEY_G:
					RunState.lab_generated = not RunState.lab_generated
					return
				if k.keycode == KEY_H:
					RunState.lab_gentle = not RunState.lab_gentle
					return
		if k.keycode == KEY_F11:
			AppSettings.toggle_fullscreen()
			return
		if RunState.state == "menu" and k.keycode == KEY_C:
			RunState.resume_run()
		elif RunState.state == "relay_clear":
			if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER: RunState.advance_relay()
		elif RunState.state == "build_complete":
			if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER: RunState.start_run()
		elif RunState.state == "menu" or RunState.state == "win":
			if k.keycode == KEY_SPACE or k.keycode == KEY_ENTER:
				RunState.start_run()
		elif RunState.state == "draft":
			if k.keycode == KEY_1: RunState.pick_card(0)
			elif k.keycode == KEY_2: RunState.pick_card(1)
			elif k.keycode == KEY_3: RunState.pick_card(2)
			elif k.keycode == KEY_S or k.keycode == KEY_ESCAPE: RunState.skip_draft()
		elif k.keycode == KEY_P or k.keycode == KEY_ESCAPE:
			RunState.toggle_pause()
		elif k.keycode == KEY_R:
			RunState.manual_respawn()

func _draw_relay_clear() -> void:
	_dim(0.86)
	var has_next := RunState.state == "relay_clear"
	DrawUtil.text_shadow(self, Vector2(240, 60), "RELAY RESTORED", DrawUtil.WHITE, 3, HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self, Vector2(240, 88), "R%d . %s" % [RunState.relay_index, RunState.level.name], DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	for i in 8:
		var x := 138 + i * 28
		DrawUtil.diamond(self, Vector2(x, 115), DrawUtil.WHITE if i <= RunState.relay_index else DrawUtil.GRAY, i > RunState.relay_index)
		if i < 7: draw_line(Vector2(x + 7, 117), Vector2(x + 23, 117), DrawUtil.DARK)
	if has_next:
		var next: Dictionary = LevelData.get_level(RunState.relay_index + 1)
		DrawUtil.text(self, Vector2(240, 145), "NEXT . " + String(next.name), DrawUtil.WHITE, 2, HORIZONTAL_ALIGNMENT_CENTER)
		DrawUtil.text(self, Vector2(240, 167), next.objective, DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
		DrawUtil.text(self, Vector2(240, 192), "ENTER / SPACE / CLICK TO CONTINUE", DrawUtil.WHITE, 1, HORIZONTAL_ALIGNMENT_CENTER)
		DrawUtil.text(self, Vector2(240, 214), "YOUR GLYPHS TRAVEL WITH YOU", DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		DrawUtil.text(self, Vector2(240, 145), "THE CHAIN CONTINUES", DrawUtil.WHITE, 2, HORIZONTAL_ALIGNMENT_CENTER)
		DrawUtil.text(self, Vector2(240, 167), "3 OF 8 RELAYS PLAYABLE IN THIS BUILD", DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
		DrawUtil.text(self, Vector2(240, 192), "NEXT . THE DROWNED ARRAY", DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
		DrawUtil.text(self, Vector2(240, 214), "SPACE / ENTER / CLICK . NEW RUN", DrawUtil.WHITE, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_lab_complete() -> void:
	_dim(0.84)
	DrawUtil.text_shadow(self,Vector2(240,76),"THEY WERE HERE",DrawUtil.WHITE,3,HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self,Vector2(240,116),"THREE MEMORIES . ONE SIGNAL",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self,Vector2(240,143),"TRY ANOTHER LIGHTING MODE",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self,Vector2(240,174),"ENTER / SPACE REPLAY . Q TITLE",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self,Vector2(240,202),"CAMPAIGN SAVE KEPT",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
