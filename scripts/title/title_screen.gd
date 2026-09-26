extends Node2D
## The title screen: a live night scene over the flats, the Spark resting on the
## signal wire, the logo lighting up letter by letter, and a short menu.
## Spec: docs/research/title-screen-2026-09-26.md ("Recommended for WHITE SIGNAL").

const Sheets := preload("res://scripts/world1/sheets.gd")
const J := preload("res://scripts/world1/juice.gd")
const Game := preload("res://scripts/world1/w1_game.gd")
const ScreenFit := preload("res://scripts/screen_fit.gd")
const Level := preload("res://scripts/world1/w1_level.gd")
const Intro := preload("res://scripts/intro/intro_scene.gd")
const SFX_DIR := "res://assets/audio/sfx8/"
const SFX_TRIM := -5.0          # same trim as the game's effects
const REVEAL_TIME := 1.2        # logo lights up over this long
const WIRE_Y := 190.0           # the wire's height at the poles (title_pole sheet notes)
const POLE_GAP := 160.0
const ROW_Y := 100.0            # first menu row
const ROW_STEP := 18.0
const MENU_X := 56.0
const CLIFF := Vector2(320, 142)    # title_cliff top-left in the 480 column
const HERO_FEET := Vector2(347, 171) # where the Spark stands on the cliff tip
const LOOK_EVERY := 7.68            # eight passes of the 0.96 s idle loop

var progress_path := "user://w1_progress.json"
var sh: Sheets
var clock := 0.0
var reveal := 0.0
var page := "home"              # home, new_confirm, extras, controls, credits, settings
var sel := 0
var home_sel := 0
var cursor_y := ROW_Y
var leaving := -1.0             # seconds since the game was started, or -1
var leave_mode := ""
var hold_dir := 0
var hold_t := 0.0
var vw := 480.0
var hx := 0.0
var progress := {}
var music: AudioStreamPlayer
var players: Array = []
var sfx := {}
var settings: Node2D
var fxmat: ShaderMaterial
var fx_rect: ColorRect
var post: ColorRect
var world := "1"
var last_sound := ""


func _ready() -> void:
	sh = Sheets.new()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	RenderingServer.set_default_clear_color(DrawUtil.BG)
	_load_progress()
	world = _furthest_world()
	# sounds
	var man = JSON.parse_string(FileAccess.get_file_as_string(SFX_DIR + "manifest.json"))
	var list: Array = man.get("sounds", []) if man is Dictionary else (man if man is Array else [])
	for s in list:
		if s is Dictionary and s.has("name") and s.has("file") and ResourceLoader.exists(SFX_DIR + str(s.file)):
			sfx[str(s.name)] = load(SFX_DIR + str(s.file))
	for n in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = -9.0
	add_child(music)
	_start_music()
	# the same tint and screen filter as the levels
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 9
	add_child(fx_layer)
	fx_rect = ColorRect.new()
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxmat = ShaderMaterial.new()
	fxmat.shader = load("res://shaders/world1/world_fx.gdshader")
	fxmat.set_shader_parameter("hud_rows", 0.0)
	var tint: Array = Game.TINTS.get(world, Game.TINTS["1"])
	for k in 4:
		fxmat.set_shader_parameter("ramp%d" % k, tint[k])
	fx_rect.material = fxmat
	fx_layer.add_child(fx_rect)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	layer.add_child(copy)
	post = ColorRect.new()
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/world1/signal_crt.gdshader")
	post.material = mat
	post.visible = bool(progress.get("filter", true))
	layer.add_child(post)
	# settings reuse the shared settings pages
	settings = preload("res://scripts/menu_ui.gd").new()
	settings.settings_only = true
	settings.z_index = 100
	add_child(settings)
	get_tree().root.size_changed.connect(_fit_screen)
	_fit_screen()
	sel = 0
	cursor_y = _row_y(0)


func _exit_tree() -> void:
	ScreenFit.reset(get_tree().root)


func _fit_screen() -> void:
	var win := get_tree().root
	ScreenFit.fit(win)
	vw = float(win.content_scale_size.x)
	hx = floorf((vw - 480.0) / 2.0)
	fx_rect.size = Vector2(vw, 270)
	post.size = Vector2(vw, 270)
	fxmat.set_shader_parameter("view", Vector2(vw, 270))
	(post.material as ShaderMaterial).set_shader_parameter("logical", Vector2(vw, 270))
	settings.position = Vector2(hx, 0)


# ================================================================ save and progress

func _load_progress() -> void:
	progress = {}
	if FileAccess.file_exists(progress_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(progress_path))
		if data is Dictionary:
			progress = data


func _save() -> Dictionary:
	var s = progress.get("save", {})
	if s is Dictionary and not s.is_empty() and FileAccess.file_exists(Level.path_for(str(s.get("level", "")))):
		return s
	return {}


## The title's colours follow how far you have got: the flats, the relay
## towers, then the aerials at dawn.
func _furthest_world() -> String:
	var reached: Array = progress.get("unlocked", [])
	var w := "1"
	for id in reached:
		var s := str(id)
		if s.begins_with("3-"):
			return "3"
		if s.begins_with("2-"):
			w = "2"
	return w


func _place(level: String) -> String:
	if level == "village":
		return "LAST RELAY"
	if level == "test-room":
		return "THE TRAINING YARD"
	if level.ends_with("-bonus"):
		return "WORLD %s BONUS" % level.trim_suffix("-bonus")
	return "WORLD " + level


func _big_count() -> int:
	var n := 0
	var big = progress.get("big", {})
	if big is Dictionary:
		for k in big:
			if big[k] is Array or big[k] is Dictionary:
				n += big[k].size()
	return n


# ================================================================ menu rows

func _home_rows() -> Array:
	var rows: Array = []
	var s := _save()
	if s.is_empty():
		rows.append(["START", "FIND WHO IS CALLING . BEGIN IN LAST RELAY, THE LAST STATION THAT STILL HUMS", "start"])
	else:
		var detail := "%s . %d LIVES . %d SHARDS" % [_place(str(s.level)), int(s.get("lives", 5)), int(s.get("shards", 0))]
		var bigs := _big_count()
		if bigs > 0:
			detail += " . %d BIG" % bigs
		rows.append(["CONTINUE", detail, "continue"])
		rows.append(["NEW GAME", "START THE STORY AGAIN . YOU KEEP YOUR BIG SHARDS AND BEST TIMES", "new"])
	rows.append(["SETTINGS", "MUSIC . EFFECTS . DISPLAY . KEYS", "settings"])
	rows.append(["EXTRAS", "THE INTRO . HOW TO PLAY . CREDITS . CLASSIC ARCADE", "extras"])
	rows.append(["QUIT", "BACK TO THE DESKTOP", "quit"])
	return rows


func _rows() -> Array:
	match page:
		"home":
			return _home_rows()
		"new_confirm":
			return [["BACK", "KEEP YOUR SAVE", "back"], ["START OVER", "YOU LOSE YOUR PLACE, LIVES AND SHARDS . YOU KEEP BIG SHARDS AND BEST TIMES", "new_go"]]
		"extras":
			return [["WATCH THE INTRO", "HOW THE STORY BEGINS . ABOUT A MINUTE", "intro"], ["HOW TO PLAY", "THE CONTROLS", "controls"], ["CREDITS", "WHO MADE WHAT", "credits"],
				["CLASSIC ARCADE", "THE EARLIER ARCADE RUN AND THE AFTERLIGHT STUDY", "arcade"], ["BACK", "", "back"]]
		"controls", "credits":
			return [["BACK", "", "back"]]
	return []


func _row_y(i: int) -> float:
	match page:
		"home", "extras":
			return ROW_Y + i * ROW_STEP
		"new_confirm":
			return 150.0 + i * ROW_STEP
	return 226.0


# ================================================================ sound

func _play(name: String, pitch := 1.0, db := 0.0) -> void:
	if not sfx.has(name):
		return
	last_sound = name
	var p: AudioStreamPlayer = players[0]
	for q in players:
		if not q.playing:
			p = q
			break
	p.stream = sfx[name]
	p.pitch_scale = pitch
	p.volume_db = db + SFX_TRIM
	p.play()


## Each row has its own note, higher rows higher, if the pitched set is there.
func _move_sound() -> void:
	var name := "menu_move_%d" % clampi(5 - sel, 1, 5)
	if sfx.has(name):
		_play(name)
	else:
		_play("menu_move", 1.0, -3.0)


## The intro plays once, then the theme loops. They are joined into one sound
## that loops back to where the theme starts, so there is no gap at the join.
func _start_music() -> void:
	if not sfx.has("title_theme"):
		return
	var theme: AudioStream = sfx["title_theme"]
	var intro: AudioStream = sfx.get("title_intro")
	if theme is AudioStreamWAV and intro is AudioStreamWAV and intro.format == theme.format 			and intro.mix_rate == theme.mix_rate and intro.stereo == theme.stereo:
		var joined := AudioStreamWAV.new()
		joined.format = theme.format
		joined.mix_rate = theme.mix_rate
		joined.stereo = theme.stereo
		var head: PackedByteArray = intro.data
		joined.data = head + theme.data
		var frame_bytes := (2 if theme.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if theme.stereo else 1)
		joined.loop_mode = AudioStreamWAV.LOOP_FORWARD
		joined.loop_begin = head.size() / frame_bytes
		joined.loop_end = joined.data.size() / frame_bytes
		music.stream = joined
	else:
		music.stream = _looped("title_theme")
	music.play()


func _looped(name: String) -> AudioStream:
	var st: AudioStream = sfx[name]
	if st is AudioStreamWAV and st.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = int(st.get_length() * st.mix_rate)
	return st


# ================================================================ input

func _unhandled_input(event: InputEvent) -> void:
	if leaving >= 0.0:
		return
	if page == "settings":
		settings.handle_input(event)
		get_viewport().set_input_as_handled()
		if settings.page == "home":
			page = "home"
			sel = home_sel
			_play("menu_back")
		return
	var pressed := (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo()
	if reveal < 1.0 and (pressed or (event is InputEventMouseButton and event.pressed)):
		reveal = 1.0   # any input skips the logo
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var i := _row_at(get_global_mouse_position())
		if i >= 0 and i != sel:
			sel = i
			_move_sound()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _row_at(get_global_mouse_position())
		if i >= 0:
			sel = i
			_confirm()
		return
	if not pressed:
		return
	var key: int = event.physical_keycode if event is InputEventKey else 0
	if event.is_action("ui_up") or key == KEY_W:
		_step(-1)
		hold_dir = -1
		hold_t = 0.0
	elif event.is_action("ui_down") or key == KEY_S:
		_step(1)
		hold_dir = 1
		hold_t = 0.0
	elif event.is_action("ui_accept") or event.is_action("jump") or key == KEY_Z:
		_confirm()
	elif event.is_action("ui_cancel") or key in [KEY_ESCAPE, KEY_BACKSPACE, KEY_X]:
		_back()
	get_viewport().set_input_as_handled()


func _row_at(p: Vector2) -> int:
	var rows := _rows()
	for i in rows.size():
		var y := _row_y(i)
		var x := _row_x()
		if p.x >= x - 4.0 and p.x < x + _bar_w() and p.y >= y - 4.0 and p.y < y + ROW_STEP - 4.0:
			return i
	return -1


func _row_x() -> float:
	return hx + (MENU_X if page in ["home", "extras"] else 160.0)


func _bar_w() -> float:
	return 160.0


func _step(d: int) -> void:
	var n := _rows().size()
	if n <= 1:
		return
	sel = posmod(sel + d, n)   # linear menus wrap
	_move_sound()


func _back() -> void:
	match page:
		"new_confirm", "extras":
			page = "home"
			sel = home_sel
			_play("menu_back")
		"controls", "credits":
			sel = 1 if page == "controls" else 2
			page = "extras"
			_play("menu_back")


func _confirm() -> void:
	var rows := _rows()
	if sel < 0 or sel >= rows.size():
		return
	var id := str(rows[sel][2])
	match id:
		"start", "continue":
			_leave("new" if id == "start" else "continue")
		"new":
			home_sel = sel
			page = "new_confirm"
			sel = 0   # BACK first, so a double press can't wipe a save
			_play("menu_confirm")
		"new_go":
			_leave("new")
		"settings":
			home_sel = sel
			page = "settings"
			settings.open_settings()
			_play("menu_confirm")
		"extras":
			home_sel = sel
			page = "extras"
			sel = 0
			_play("menu_confirm")
		"controls", "credits":
			page = id
			sel = 0
			_play("menu_confirm")
		"intro":
			_play("menu_confirm")
			Intro.replay = true
			get_tree().change_scene_to_file("res://scenes/intro.tscn")
		"arcade":
			_play("menu_confirm")
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"quit":
			_play("menu_back")
			get_tree().quit()
		"back":
			_back()


## Start the game: a rising sting, the music fades, the Spark zips off along
## the wire and a circle closes on it.
func _leave(mode: String) -> void:
	leaving = 0.0
	leave_mode = mode
	_play("title_start", 1.0, 2.0)
	var tw := create_tween()
	tw.tween_property(music, "volume_db", -40.0, 0.4)
	tw.tween_callback(music.stop)


# ================================================================ frame

func _process(delta: float) -> void:
	clock += delta
	if ScreenFit.stale(get_tree().root):
		_fit_screen()
	if reveal < 1.0:
		reveal = minf(1.0, reveal + delta / REVEAL_TIME)
	# held up or down repeats after 400 ms, then every 110 ms
	if hold_dir != 0 and leaving < 0.0 and page != "settings":
		var still := Input.is_action_pressed("ui_up") if hold_dir < 0 else Input.is_action_pressed("ui_down")
		if not still:
			hold_dir = 0
		else:
			hold_t += delta
			if hold_t >= 0.4:
				hold_t -= 0.11
				_step(hold_dir)
	# the Spark cursor slides to the row over about 80 ms
	cursor_y = lerpf(cursor_y, _row_y(sel), minf(1.0, delta * 30.0))
	if leaving >= 0.0:
		leaving += delta
		if leaving >= 0.85:
			leaving = -2.0
			if leave_mode == "new":
				Intro.replay = false
				get_tree().change_scene_to_file("res://scenes/intro.tscn")   # a new game starts with the story
			else:
				Game.start_mode = leave_mode
				get_tree().change_scene_to_file("res://scenes/world1_play.tscn")
	queue_redraw()


# ================================================================ drawing

func _has(name: String) -> bool:
	return sh.tex.has(name)


func _draw() -> void:
	draw_rect(Rect2(0, 0, vw, 270), DrawUtil.BG)
	_draw_scene()
	var menu_a := 1.0
	if leaving >= 0.0:
		menu_a = clampf(1.0 - leaving / 0.15, 0.0, 1.0)
	_draw_logo()
	if menu_a > 0.0 and reveal >= 1.0:
		_draw_page(menu_a)
	if page == "settings":
		draw_rect(Rect2(0, 0, vw, 270), Color(DrawUtil.BG, 0.9))
	if leaving >= 0.0:
		_draw_leave()


## The Spark's feet: on the cliff tip, or leaping off it toward the land.
func _hero_feet() -> Vector2:
	var p := Vector2(hx + HERO_FEET.x, HERO_FEET.y)
	if leaving >= 0.16:
		var u := (leaving - 0.16) / 0.55
		p += Vector2(-96.0 * u, -56.0 * u + 140.0 * u * u)
	return p


func _pole_off() -> float:
	return 0.0   # the poles stand still, so the cliff in front never seems to slide


func _wire_y(x: float) -> float:
	## Straight across each pole between its insulators (frame x 3 to 20), then
	## a 6 px sag to the next pole.
	var rel := fposmod(x + _pole_off(), POLE_GAP)
	if rel >= 3.0 and rel <= 20.0:
		return WIRE_Y
	var u := clampf(fposmod(rel - 20.0, POLE_GAP) / (POLE_GAP - 17.0), 0.0, 1.0)
	return WIRE_Y + 24.0 * u * (1.0 - u)


func _draw_scene() -> void:
	# a few stars, never over the logo
	for i in int(60.0 * vw / 480.0):
		var h := DrawUtil.hash2(i, 91)
		var x := float(h % int(vw))
		var y := float((h >> 8) % 140) + 8.0
		if y < 76.0 and absf(x - vw / 2.0) < 130.0:
			continue
		var tw := (h + int(clock * 2.0)) % 23 == 0
		draw_rect(Rect2(x, y, 1, 1), DrawUtil.GRAY if h % 7 == 0 and not tw else DrawUtil.DARK)
	var still := reduced_motion()
	if _has("title_scene"):
		var fs: Vector2 = sh.size("title_scene")
		# far strip, with the caller's light blinking on its mast tip. The land
		# holds still: the wind, the scarf and the lights carry the motion.
		var off := 0.0
		var x := -off
		while x < vw:
			sh.draw_frame(self, "title_scene", "far", 0, Vector2(floorf(x), 160.0))
			if _has("title_caller"):
				var f := sh.frame_at("title_caller", "blink", clock, true)
				sh.draw_frame(self, "title_caller", "blink", f, Vector2(floorf(x) + 203.0, 163.0))
			x += fs.x
		draw_rect(Rect2(0, 224, vw, 46), DrawUtil.DARK)
		# mid strip
		off = 0.0
		x = -off
		while x < vw:
			sh.draw_frame(self, "title_scene", "mid", 0, Vector2(floorf(x), 188.0))
			x += fs.x
		draw_rect(Rect2(0, 252, vw, 18), DrawUtil.BG)
	# poles and the wire
	var po := _pole_off()
	var px := -po
	var k := int(floor(po / POLE_GAP))
	while px < vw + POLE_GAP:
		if _has("title_pole"):
			var n := k
			sh.draw_frame(self, "title_pole", "pole", 1 if posmod(n, 4) == 2 else 0, Vector2(floorf(px), WIRE_Y - 4.0))
		else:
			draw_rect(Rect2(px + 11.0, WIRE_Y - 4.0, 2.0, 64.0), DrawUtil.DARK)
			draw_rect(Rect2(px + 2.0, WIRE_Y - 1.0, 20.0, 2.0), DrawUtil.DARK)
		px += POLE_GAP
		k += 1
	var last := Vector2(0.0, _wire_y(0.0))
	for sx in range(1, int(vw) + 2):
		var p := Vector2(float(sx), _wire_y(float(sx)))
		draw_line(last, p, DrawUtil.GRAY, 1.0)
		last = p
	# wind streaks blowing right, clear of the menu
	if not still:
		for i in 6:
			var h := DrawUtil.hash2(i, 419)
			var speed := 100.0 + float(h % 41)
			var span := vw - (hx + 220.0) + 40.0
			var x := hx + 220.0 + fposmod(clock * speed + float(h % 997), span) - 20.0
			var y := 96.0 + float((h >> 6) % 75)
			var ln := 10.0 + float((h >> 3) % 11)
			draw_rect(Rect2(floorf(x - ln), y, ln, 1.0), DrawUtil.DARK)
			draw_rect(Rect2(floorf(x), y, 3.0, 1.0), DrawUtil.GRAY)
	# the cliff, filled on to the right edge on wide screens
	var cp := Vector2(hx + CLIFF.x, CLIFF.y)
	if _has("title_cliff"):
		sh.draw_frame(self, "title_cliff", "edge", 0, cp)
		var fx := cp.x + 160.0
		while fx < vw:
			sh.draw_part(self, "title_cliff", "fill", 0, Vector2(fx, cp.y), Rect2(0, 0, 32, 128))
			fx += 32.0
		sh.draw_anim(self, "title_cliff", "grass", 0.0 if still else clock, cp)
	# the Spark on the tip, scarf in the wind, now and then looking out at you
	var feet := _hero_feet()
	if _has("title_hero"):
		var anim := "idle"
		var at := 0.0 if still else clock
		if leaving >= 0.0:
			anim = "leap"
			at = leaving
		elif not still and clock > 4.0 and fposmod(clock, LOOK_EVERY) < 0.96:
			anim = "look"
			at = fposmod(clock, LOOK_EVERY)
		elif _answering() and sh.frames("title_hero", "answer") > 0:
			# her antenna answers the far light, flickering (steady with reduced flashes)
			if still or int(clock / 0.07) % 2 == 0:
				anim = "answer"
		elif _blinking():
			anim = "blink"
		sh.draw_anim(self, "title_hero", anim, at, (feet - Vector2(24.0, 59.0)).floor())
	else:
		J.spark(self, feet.floor(), -1, 2.0, 2.0, "stand", clock, 1)


## A blink lasting about 0.12 s, every 3 to 5 seconds.
func _blinking() -> bool:
	var n := int(clock / 4.0)
	var at := 4.0 * n + 1.0 + float(DrawUtil.hash2(n, 61) % 20) / 10.0
	return clock >= at and clock < at + 0.12 and sh.tex.has("title_hero") 		and preload("res://scripts/world1/sheet_data.gd").SHEETS["title_hero"].anims.has("blink")


## Just after the far caller's light blinks (its loop is 3.0 s dark, then
## 0.34 s lit), her antenna answers for a moment.
func _answering() -> bool:
	var ph := fposmod(clock, 3.34)
	return ph < 0.42 and clock > 3.0


func reduced_motion() -> bool:
	return AppSettings.reduced_flashes


func _draw_logo() -> void:
	var at := Vector2(floorf(vw / 2.0 - 120.0), 26.0)
	if not _has("title_logo"):
		var col := DrawUtil.WHITE if reveal >= 1.0 else DrawUtil.GRAY
		DrawUtil.text_shadow(self, Vector2(vw / 2.0 - DrawUtil.text_width("WHITE SIGNAL", 5) / 2.0, 38), "WHITE SIGNAL", col, 5)
		return
	sh.draw_frame(self, "title_logo", "unlit", 0, at)
	var w := floorf(240.0 * reveal)
	if w > 0.0:
		sh.draw_part(self, "title_logo", "lit", 0, at, Rect2(0, 0, w, 44))
	if reveal < 1.0:
		# the Spark runs along under the logo, lighting each letter
		J.spark(self, Vector2(at.x + w, 78.0), 1, 1.0, 1.0, "run", clock * 2.0, 1)
	elif sh.tex.has("title_logo"):
		var a := 0.25 + 0.2 * sin(clock * 1.6)
		sh.draw_frame(self, "title_logo", "glow", 0, at, false, Color(1, 1, 1, a))
		if _has("title_logo_antenna"):
			# the antenna transmits twice per caller loop, every other flare on the
			# far light's blink. It pulses under once a second, far below the three
			# a second that counts as flashing, so it plays with reduced flashes too
			var f := sh.frame_at("title_logo_antenna", "pulse", clock - 3.0, true)
			sh.draw_frame(self, "title_logo_antenna", "pulse", f, at + Vector2(132.0, 0.0))
	DrawUtil.text(self, Vector2(vw / 2.0, 76.0), "SOMEONE IS STILL CALLING", DrawUtil.GRAY if reveal >= 1.0 else DrawUtil.BG, 1, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_page(a: float) -> void:
	var rows := _rows()
	var white := Color(DrawUtil.WHITE, a)
	var gray := Color(DrawUtil.GRAY, a)
	match page:
		"new_confirm":
			_panel()
			_ctext("START OVER?", 104, white, 2)
			_ctext("YOU WILL LOSE YOUR PLACE, YOUR LIVES AND YOUR SHARDS", 126, gray)
			_ctext("YOU KEEP YOUR BIG SHARDS AND BEST TIMES", 136, gray)
		"controls":
			_panel()
			_ctext("HOW TO PLAY", 92, white, 2)
			var lines := _control_lines()
			for i in lines.size():
				DrawUtil.text(self, Vector2(hx + 110.0, 116.0 + i * 12.0), lines[i][0], gray)
				DrawUtil.text(self, Vector2(hx + 196.0, 116.0 + i * 12.0), lines[i][1], white)
		"credits":
			_panel()
			_ctext("CREDITS", 92, white, 2)
			var credits := [["ENGINE", "GODOT"], ["PIXEL ART", "MADE IN CODE . PIXELLAB . IMAGEGEN"],
				["8-BIT MUSIC AND EFFECTS", "WRITTEN AS CODE FOR THE NES SOUND CHIP"], ["EARLIER MUSIC", "DEAD CARRIER . SUNO"],
				["TUTORIAL AUDIO", "PROVIDED BY THE CREATOR"]]
			for i in credits.size():
				DrawUtil.text(self, Vector2(hx + 110.0, 114.0 + i * 20.0), credits[i][0], gray)
				DrawUtil.text(self, Vector2(hx + 110.0, 123.0 + i * 20.0), credits[i][1], white)
	if page in ["home", "extras"]:
		# a darker patch of sky behind the menu keeps the text readable
		draw_rect(Rect2(hx + MENU_X - 20.0, ROW_Y - 8.0, _bar_w() + 32.0, rows.size() * ROW_STEP + 12.0), Color(DrawUtil.BG, 0.55 * a))
	for i in rows.size():
		var y := _row_y(i)
		var x := _row_x()
		var on := i == sel
		if on:
			draw_rect(Rect2(x - 4.0, y - 4.0, _bar_w(), ROW_STEP - 2.0), white)
		var label := str(rows[i][0])
		if page in ["home", "extras"]:
			DrawUtil.text(self, Vector2(x + 4.0, y - 1.0), label, Color(DrawUtil.BG, a) if on else white, 2)
		else:
			DrawUtil.text(self, Vector2(x + _bar_w() / 2.0 - 4.0, y + 1.0), label, Color(DrawUtil.BG, a) if on else white, 1, HORIZONTAL_ALIGNMENT_CENTER)
	var detail := str(rows[sel][1]) if sel < rows.size() else ""
	if page in ["home", "extras", "new_confirm"] and detail != "":
		var dw := DrawUtil.text_width(detail) + 12.0
		draw_rect(Rect2(vw / 2.0 - dw / 2.0, 229.0, dw, 12.0), Color(DrawUtil.BG, 0.8 * a))
		_ctext(detail, 232, gray)
	var hint := "D-PAD CHOOSE . A CONFIRM . B BACK" if GameInput.controller_active else "ARROWS CHOOSE . ENTER CONFIRM . ESC BACK"
	_ctext(hint, 252, gray)


func _panel() -> void:
	draw_rect(Rect2(hx + 90.0, 84.0, 300.0, 160.0), Color(DrawUtil.BG, 0.92))
	draw_rect(Rect2(hx + 90.0, 84.0, 300.0, 1.0), DrawUtil.DARK)
	draw_rect(Rect2(hx + 90.0, 243.0, 300.0, 1.0), DrawUtil.DARK)


func _ctext(s: String, y: float, col: Color, scale := 1) -> void:
	DrawUtil.text(self, Vector2(vw / 2.0, y), s, col, scale, HORIZONTAL_ALIGNMENT_CENTER)


func _control_lines() -> Array:
	var pad := GameInput.controller_active
	var k = GameInput.keyboard
	return [
		["MOVE", "D-PAD / STICK" if pad else "%s . %s" % [k.key_label("move_left"), k.key_label("move_right")]],
		["JUMP", ("A" if pad else k.key_label("jump")) + " . HOLD IT TO JUMP HIGHER"],
		["DASH", ("RB" if pad else k.key_label("dash")) + " . ONCE PER JUMP"],
		["ARC", ("X" if pad else k.key_label("attack")) + " . YOURS AFTER WORLD 1"],
		["STOMP", "LAND ON AN ENEMY . JUMP AS YOU LAND FOR HEIGHT"],
		["SHARDS", "SPEND THEM AT TALLY'S . EVERY 100 GIVES A LIFE"],
		["DROP", "PRESS DOWN AND JUMP ON A GIRDER"],
		["TALK . DOORS", "PRESS DOWN NEXT TO SOMEONE OR A DOOR"],
		["PAUSE", "START" if pad else "ESC"],
	]


func _draw_leave() -> void:
	## A circle closes on the Spark as it leaves, then black. With reduced flash
	## on it is a plain fade.
	var u := clampf((leaving - 0.3) / 0.45, 0.0, 1.0)
	if reduced_motion():
		draw_rect(Rect2(0, 0, vw, 270), Color(DrawUtil.BG, u))
		return
	var c := _hero_feet() + Vector2(0.0, -18.0)
	var r := lerpf(vw, 0.0, u * u)
	if u >= 1.0:
		draw_rect(Rect2(0, 0, vw, 270), DrawUtil.BG)
		return
	draw_arc(c, r + 500.0, 0.0, TAU, 96, DrawUtil.BG, 1000.0)
