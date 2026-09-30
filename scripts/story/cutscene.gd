extends Node2D
## Story cutscenes at key moments, in the intro's style: a few shots, each a
## picture with up to two lines typed in the game font, through the same tint
## pass and screen filter. Tap to finish a line or move on, hold to skip, Esc or
## Start skips the lot. Set `play` before changing to scenes/cutscene.tscn.

const Sheets := preload("res://scripts/world1/sheets.gd")
const J := preload("res://scripts/world1/juice.gd")
const ScreenFit := preload("res://scripts/screen_fit.gd")
const SFX_DIR := "res://assets/audio/sfx8/"
const SFX_TRIM := -5.0
const MUSIC_DB := -9.0
const STEP := 0.12            # one palette step when fading
const TYPE_RATE := 40.0       # letters a second, as in the intro
const DARK := Color("3a3a3a")
const GAME := "res://scripts/world1/w1_game.gd"   # loaded, not preloaded: the game preloads nothing of this

## Each cutscene is a list of shots. `paint` names the _paint_<name> function,
## `tint` the palette, `cue` the music (carried on if the next shot has the same
## one), `sounds` [[at, name, db]], `in` when the text starts, and `garble` types
## the lines as the Howl's broken voice.
const SCENES := {
	# the end of World 1: the first Gate wakes, its light leaps into the Spark as
	# the Arc, and far below, the Howl wakes up too
	"gate1": [
		{"paint": "gate", "tint": "1", "cue": "intro_line", "dur": 6.0, "in": 1.4, "fade_in": true,
			"lines": ["THE FIRST GATE WOKE UP", "AND LIGHT RAN BACK DOWN THE LINE"],
			"sounds": [[0.9, "gate_wake", 0.0]]},
		{"paint": "arc", "tint": "1", "cue": "intro_line", "dur": 7.0, "in": 2.0,
			"lines": ["SOME OF ITS LIGHT LEAPT INTO YOU", "NOW YOU CAN THROW IT . THE ARC"],
			"sounds": [[1.25, "arc_learn", 0.0]]},
		{"paint": "below", "tint": "test", "cue": "intro_noise", "dur": 6.5, "in": 2.8, "fade_in": true,
			"lines": ["BUT FAR BELOW, WHERE THE CUT WIRES END", "SOMETHING ELSE HEARD THE GATE"],
			"sounds": [[1.2, "howl_wake", 0.0]]},
		{"paint": "howl", "tint": "test", "cue": "intro_noise", "dur": 6.5, "in": 0.8, "garble": true,
			"lines": ["EVERY . VOICE . IS . MINE", "AND . I . HEAR . YOU . LITTLE . SPARK"]},
		{"paint": "watch", "tint": "1", "cue": "intro_still", "dur": 7.0, "in": 1.0, "fade_in": true, "fade_out": 6.2,
			"lines": ["THE HOWL IS AWAKE . AND LISTENING", "THE LINE RUNS ON INTO THE SWITCHYARD"]},
	],
	# the start of World 4: the line runs down into Dead Air, the Howl waits
	# there, and under it the call is close
	"descent": [
		{"paint": "shaft", "tint": "4", "cue": "intro_noise", "dur": 6.5, "in": 1.2, "fade_in": true,
			"lines": ["BELOW THE LAST STATION, THE LINE RUNS DOWN", "INTO DEAD AIR, WHERE EVERY CUT WIRE ENDS"]},
		{"paint": "deep", "tint": "test", "cue": "intro_noise", "dur": 6.5, "in": 1.0, "garble": true,
			"lines": ["YOU . CAME . ALL . THIS . WAY", "TO . BRING . ME . ONE . MORE . VOICE"],
			"sounds": [[0.4, "howl_wake", -2.0]]},
		{"paint": "call", "tint": "4", "cue": "intro_still", "dur": 7.0, "in": 1.2, "fade_in": true, "fade_out": 6.2,
			"lines": ["BUT UNDER THE HOWL, THE CALL IS CLOSE NOW", "SPARK . COME HOME . WE KEPT YOUR PLACE"],
			"sounds": [[0.8, "line_ring", -4.0], [1.6, "line_ring", -4.0], [2.4, "line_ring", -4.0]]},
	],
	# the ending: the ring closes, the Howl comes apart into every voice it
	# swallowed, and the whole line comes home
	"ending": [
		{"paint": "ring_wait", "tint": "4", "cue": "intro_still", "dur": 6.5, "in": 1.4, "fade_in": true,
			"lines": ["SEVEN SPARKS HELD THE HOWL INSIDE A RING", "AND ONE PLACE HAD BEEN KEPT, ALL THIS TIME"]},
		{"paint": "ring_close", "tint": "4", "cue": "m_ending", "dur": 6.5, "in": 2.2,
			"lines": ["THE SPARK TOOK ITS PLACE", "AND THE RING CLOSED AT LAST"],
			"sounds": [[0.5, "ring_close", 0.0]]},
		{"paint": "unravel", "tint": "4", "cue": "m_ending", "dur": 7.0, "in": 1.4,
			"lines": ["THE HOWL CAME APART INTO EVERY VOICE IT SWALLOWED", "AND THEY ALL RAN HOME ALONG THE WIRES"],
			"sounds": [[0.3, "howl_wake", -8.0], [1.2, "pip_home", -4.0], [2.0, "pip_home", -6.0]]},
		{"paint": "stations", "tint": "1", "cue": "m_ending", "dur": 7.0, "in": 1.0, "fade_in": true,
			"lines": ["ONE STATION AT A TIME", "THE WHOLE LINE CAME BACK TO LIFE"]},
		{"paint": "relay", "tint": "village", "cue": "m_ending", "dur": 8.0, "in": 1.0, "fade_in": true,
			"lines": ["AT LAST RELAY, THE DEAD LINE RANG THREE TIMES", "LAST RELAY, THIS IS THE LINE . WE'RE ALL COMING HOME"],
			"sounds": [[0.6, "line_ring", -2.0], [1.4, "line_ring", -2.0], [2.2, "line_ring", -2.0]]},
		{"paint": "switchboard", "tint": "village", "cue": "m_ending", "dur": 6.5, "in": 1.0, "if": "all_pips",
			"lines": ["EVERY PIP YOU FREED ANSWERED TOO", "AND DOT'S WHOLE SWITCHBOARD LIT UP AT ONCE"],
			"sounds": [[0.8, "pip_home", 0.0]]},
		{"paint": "switchboard", "tint": "village", "cue": "m_ending", "dur": 6.5, "in": 1.0, "if": "some_pips",
			"lines": ["{home} PIPS ANSWERED THE CALL WITH YOU", "AND THE REST ARE STILL OUT THERE, WAITING"],
			"sounds": [[0.8, "pip_home", 0.0]]},
		{"paint": "home", "tint": "village", "cue": "m_ending", "dur": 7.5, "in": 1.0,
			"lines": ["SO THAT'S WHERE HOME IS, FOR SOMETHING LIKE YOU", "IT'S EVERYWHERE THE LINE GOES"]},
		{"paint": "credits", "tint": "village", "cue": "m_ending", "dur": 10.0, "in": 99.0, "fade_in": true, "fade_out": 9.2,
			"lines": ["", ""]},
	],
}

static var play := "gate1"     # which cutscene the scene shows
static var replay := false     # watched from EXTRAS: back to the title at the end
static var pips := [0, 0]      # Pips home and in all, for the ending (set by the game)

var sh: Sheets
var shots: Array = []
var shot := 0
var ct := 0.0                  # time in the current shot
var clock := 0.0
var typed_full := false        # a tap finished the shot's text early
var vw := 480.0
var hx := 0.0
var fxmat: ShaderMaterial
var fx_rect: ColorRect
var post: ColorRect
var sfx := {}
var players: Array = []
var music: AudioStreamPlayer
var voice: AudioStreamPlayer
var cue := ""
var fired := {}                # sounds already played this shot
var voiced := 0                # letters of the Howl's speech already voiced
var shake_t := 0.0
var settle := 0.5              # ignore input at first; the jump that cleared the level may still be held
var released := false
var hold_t := 0.0
var hold_tick := 0
var ending := -1.0             # seconds since the fade out began


func _ready() -> void:
	sh = Sheets.new()
	shots = []
	var all_home: bool = int(pips[1]) > 0 and int(pips[0]) >= int(pips[1])
	for s in SCENES.get(play, SCENES["gate1"]):
		var want := str(s.get("if", ""))
		if want in ["all_pips", "some_pips"] and (int(pips[0]) == 0 or (want == "all_pips") != all_home):
			continue   # (a replay from the title doesn't know the Pips, so it leaves both out)
		var shot_copy: Dictionary = s.duplicate(true)
		for i in 2:
			var line := str(shot_copy.lines[i]).replace("{home}", str(pips[0])).replace("{total}", str(pips[1]))
			shot_copy.lines[i] = line.replace("1 PIPS ANSWERED", "ONE PIP ANSWERED") if int(pips[0]) == 1 else line
		shots.append(shot_copy)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	RenderingServer.set_default_clear_color(DrawUtil.BG)
	var man = JSON.parse_string(FileAccess.get_file_as_string(SFX_DIR + "manifest.json"))
	for s in (man.get("sounds", []) if man is Dictionary else []):
		if s is Dictionary and ResourceLoader.exists(SFX_DIR + str(s.get("file", ""))):
			sfx[str(s.name)] = load(SFX_DIR + str(s.file))
	for n in 4:
		players.append(_player("SFX"))
	voice = _player("SFX")
	music = _player("Music")
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 9
	add_child(fx_layer)
	fx_rect = ColorRect.new()
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxmat = ShaderMaterial.new()
	fxmat.shader = load("res://shaders/world1/world_fx.gdshader")
	fxmat.set_shader_parameter("hud_rows", 0.0)
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
	layer.add_child(post)
	get_tree().root.size_changed.connect(_fit_screen)
	_fit_screen()
	_enter(0)


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


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


func _has(name: String) -> bool:
	return sh.tex.has(name)


# ================================================================ sound

func _play(name: String, db := 0.0, pitch := 1.0) -> void:
	if not sfx.has(name):
		return
	var p: AudioStreamPlayer = players[0]
	for q in players:
		if not q.playing:
			p = q
			break
	p.stream = sfx[name]
	p.volume_db = db + SFX_TRIM
	p.pitch_scale = pitch
	p.play()


func _looped(name: String) -> AudioStream:
	var st: AudioStream = sfx.get(name)
	if st is AudioStreamWAV and st.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = int(st.get_length() * st.mix_rate)
	return st


## A new music cue fades in on its own player while the old one fades out.
func _cue(name: String) -> void:
	if name == cue:
		return
	cue = name
	var old := music
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, 1.5)
		tw.tween_callback(old.queue_free)
	else:
		old.queue_free()
	music = _player("Music")
	var st: AudioStream = _looped(name) if name != "" else null
	if st == null:
		return
	music.stream = st
	music.volume_db = -40.0
	music.play()
	create_tween().tween_property(music, "volume_db", MUSIC_DB, 1.5)


# ================================================================ time and input

func _enter(i: int) -> void:
	shot = i
	ct = 0.0
	typed_full = false
	fired.clear()
	voiced = 0
	_cue(str(shots[i].get("cue", "")))


func _input_down() -> bool:
	return Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept") \
		or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) \
		or Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)


func _unhandled_input(event: InputEvent) -> void:
	if ending >= 0.0 or settle > 0.0:
		return
	var skip: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) \
		or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if skip:
		_end()


func _process(delta: float) -> void:
	clock += delta
	if ScreenFit.stale(get_tree().root):
		_fit_screen()
	shake_t = maxf(0.0, shake_t - delta)
	if ending >= 0.0:
		ending += delta
		_update_shader()
		if ending >= 0.5:
			ending = -9.0
			_hand_off()
		queue_redraw()
		return
	settle = maxf(0.0, settle - delta)
	var down := _input_down()
	if settle <= 0.0:
		if not down:
			released = true
			if hold_t > 0.0 and hold_t < 0.15:
				_tap()
			hold_t = maxf(0.0, hold_t - delta * 3.0) if hold_t >= 0.15 else 0.0
		elif released:
			hold_t += delta
			var q := int(hold_t / 0.15)
			if q > hold_tick and hold_t > 0.15:
				_play("menu_tick")
			hold_tick = q
			if hold_t >= 0.6:
				_play("menu_confirm")
				_end()
				return
	ct += delta
	for s in shots[shot].get("sounds", []):
		var key := str(s[1]) + str(s[0])
		if ct >= float(s[0]) and not fired.has(key):
			fired[key] = true
			_play(str(s[1]), float(s[2]))
			if str(s[1]) == "howl_wake":
				shake_t = 0.5
	if shots[shot].get("garble", false):
		_voice_howl()
	if ct >= float(shots[shot].dur):
		if shot + 1 < shots.size():
			_enter(shot + 1)
		else:
			_end()
	_update_shader()
	queue_redraw()


## One rough blip every two letters of the Howl's speech, each a little different.
func _voice_howl() -> void:
	var n := _shown(0).length() + _shown(1).length()
	while voiced + 2 <= n:
		voiced += 2
		if sfx.has("voice_howl"):
			voice.stream = sfx["voice_howl"]
			voice.volume_db = SFX_TRIM
			voice.pitch_scale = 0.82 + float(DrawUtil.hash2(voiced, 7) % 17) / 100.0
			voice.play()


func _tap() -> void:
	## Finish the shot's text if it is still typing, else go to the next shot.
	if not typed_full and ct < _text_done_at():
		typed_full = true
		return
	if shot + 1 < shots.size():
		_enter(shot + 1)
	else:
		_end()


func _end() -> void:
	if ending >= 0.0:
		return
	ending = 0.0
	var tw := create_tween()
	tw.tween_property(music, "volume_db", -40.0, 0.36)


func _hand_off() -> void:
	if replay:
		replay = false
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
	# the game saved in Last Relay before the cutscene began, so it carries on there
	load(GAME).start_mode = "continue"
	get_tree().change_scene_to_file("res://scenes/world1_play.tscn")


# ================================================================ tint and fades

func _update_shader() -> void:
	var s: Dictionary = shots[shot]
	var tints: Dictionary = load(GAME).TINTS   # each world's four colours, as in the game
	var tint: Array = tints.get(str(s.get("tint", "1")), tints["1"])
	var level := 0
	if s.get("fade_in", false):
		level = maxi(level, 3 - int(ct / STEP))
	if s.has("fade_out") and ct >= float(s.fade_out):
		level = maxi(level, 1 + int((ct - float(s.fade_out)) / STEP))
	if ending >= 0.0:
		level = maxi(level, 1 + int(ending / STEP))
	level = clampi(level, 0, 3)
	for k in 4:
		fxmat.set_shader_parameter("ramp%d" % k, tint[maxi(0, k - level)] if level < 3 or k == 0 else tint[0])
	fxmat.set_shader_parameter("dark_count", 0)
	fxmat.set_shader_parameter("flash", 0.0)


# ================================================================ text

func _text_done_at() -> float:
	var s: Dictionary = shots[shot]
	return float(s.in) + float(str(s.lines[0]).length() + str(s.lines[1]).length()) / TYPE_RATE + 0.25


func _line_start(line: int) -> float:
	var s: Dictionary = shots[shot]
	return float(s.in) + (float(str(s.lines[0]).length()) / TYPE_RATE + 0.25 if line == 1 else 0.0)


func _shown(line: int) -> String:
	var s := str(shots[shot].lines[line])
	if typed_full:
		return s
	return s.substr(0, clampi(int((ct - _line_start(line)) * TYPE_RATE), 0, s.length()))


func _draw_text() -> void:
	var s: Dictionary = shots[shot]
	if ct < float(s.in) and not typed_full:
		return
	var garble: bool = s.get("garble", false)
	var glyphs := "#%&*+=?!/"
	for i in 2:
		var shown := _shown(i)
		if shown == "":
			continue
		var full := str(s.lines[i])
		var x := floorf(vw / 2.0 - DrawUtil.text_width(full, 2) / 2.0)   # lines grow from a fixed left edge
		if not garble:
			DrawUtil.text_shadow(self, Vector2(x, 28.0 + 16.0 * i), shown, DrawUtil.GRAY, 2)
			continue
		# the Howl's voice: each letter arrives as noise, and the words never sit still
		var typed := int((ct - _line_start(i)) * TYPE_RATE) if not typed_full else full.length() + 9
		for k in shown.length():
			var ch := shown[k]
			if ch == " ":
				continue
			var h := DrawUtil.hash2(k + i * 40, int(clock * 14.0))
			if typed - k < 4 or h % 23 == 0:
				ch = glyphs[h % glyphs.length()]
			var jit := Vector2(float(h % 3) - 1.0, float((h >> 3) % 3) - 1.0) if h % 5 == 0 else Vector2.ZERO
			DrawUtil.text_shadow(self, Vector2(x + k * 8.0, 28.0 + 16.0 * i) + jit, ch,
				DrawUtil.WHITE if h % 7 == 0 else DrawUtil.GRAY, 2)


func _draw_skip() -> void:
	if ending >= 0.0:
		return
	if hold_t < 0.15:
		if clock > 0.6 and clock < 5.0:   # say once, quietly, that it can be skipped
			var hint := "HOLD %s TO SKIP" % ("A" if GameInput.controller_active else GameInput.keyboard.key_label("jump").split("/")[0])
			var hw := DrawUtil.text_width(hint)
			draw_rect(Rect2(hx + 464.0 - hw, 253.0, hw + 12.0, 11.0), Color(DrawUtil.BG, 0.8))
			DrawUtil.text(self, Vector2(hx + 470.0 - hw, 256.0), hint, DrawUtil.GRAY)
		return
	var x := hx + 430.0
	var u := clampf((hold_t - 0.15) / 0.45, 0.0, 1.0)
	DrawUtil.text(self, Vector2(x - 4.0 - DrawUtil.text_width("HOLD TO SKIP"), 256.0), "HOLD TO SKIP", DrawUtil.GRAY)
	draw_rect(Rect2(x, 258.0, 40.0, 3.0), DARK)
	draw_rect(Rect2(x, 258.0, floorf(40.0 * u), 3.0), DrawUtil.GRAY)


# ================================================================ drawing

func _draw() -> void:
	draw_rect(Rect2(0, 0, vw, 270), DrawUtil.BG)
	var off := Vector2.ZERO
	if shake_t > 0.0 and AppSettings.camera_shake:
		off = Vector2(float(int(clock * 60.0) % 3) - 1.0, float(int(clock * 47.0) % 3) - 1.0) * 2.0
	draw_set_transform(off)
	call("_paint_" + str(shots[shot].paint))
	draw_set_transform(Vector2.ZERO)
	_draw_text()
	_draw_skip()
	if ending >= 0.0 and ending > 0.36:
		draw_rect(Rect2(0, 0, vw, 270), DrawUtil.BG)


func _stars(n: int, seed: int) -> void:
	for i in int(n * vw / 480.0):
		var h := DrawUtil.hash2(i, seed)
		var x := float(h % int(vw))
		var y := float((h >> 8) % 150) + 6.0
		if x > hx + 60.0 and x < hx + 420.0 and y > 20.0 and y < 64.0:
			continue   # keep the text band clear
		draw_rect(Rect2(x, y, 1, 1), DrawUtil.GRAY if h % 9 == 0 else DARK)


func _strip(anim: String, y: float, origin: float) -> void:
	if not _has("title_scene"):
		return
	var w: float = sh.size("title_scene").x
	var x := fposmod(origin, w) - w
	while x < vw:
		sh.draw_frame(self, "title_scene", anim, 0, Vector2(floorf(x), y))
		x += w


## A jagged bolt of light between two points, redrawn every few frames.
func _bolt(a: Vector2, b: Vector2, seed: int) -> void:
	var last := a
	for k in range(1, 9):
		var u := k / 8.0
		var h := DrawUtil.hash2(k + seed * 13, int(clock * 20.0))
		var p := a.lerp(b, u) + (Vector2(float(h % 11) - 5.0, float((h >> 4) % 11) - 5.0) if k < 8 else Vector2.ZERO)
		draw_line(last.floor(), p.floor(), DrawUtil.WHITE, 1.0)
		last = p


# ---------------------------------------------------------------- gate1, shot 1: the Gate wakes

func _paint_gate() -> void:
	_stars(70, 13)
	_strip("far", 160.0, hx)
	var awake := ct >= 1.0
	var gx := hx + 330.0
	if _has("gate_transmitter"):
		sh.draw_anim(self, "gate_transmitter", "awake" if awake else "dormant", clock, Vector2(gx, 70.0))
	# the wire from the Gate's foot out across the land
	var foot := Vector2(gx + 40.0, 196.0)
	var left := Vector2(-4.0, 204.0)
	draw_line(foot, left, DrawUtil.GRAY, 1.0)
	# light runs back down the line, and every station lamp it passes comes on
	var run := clampf((ct - 1.2) / 1.8, 0.0, 1.0)
	var px := lerpf(foot.x, left.x, run)
	for i in 18:
		var lx := hx - 40.0 + i * 24.0
		if lx < foot.x - 8.0 and lx > -4.0:
			var lit := ct >= 1.2 and lx >= px
			draw_rect(Rect2(floorf(lx), 214, 1, 1), DrawUtil.WHITE if lit else DARK)
	if ct >= 1.2 and run < 1.0:
		var p := foot.lerp(left, run)
		draw_line((p + Vector2(18, -0.3)).floor(), p.floor(), DrawUtil.WHITE, 1.0)
		if _has("fx_light"):
			sh.draw_anim(self, "fx_light", "ring", fposmod(ct, 0.5), (p - Vector2(24, 24)).floor())
	# the Pips ride the line again behind the light
	if _has("pip") and ct >= 1.6:
		for k in 3:
			var u := clampf((ct - 1.6 - k * 0.45) / 2.4, 0.0, 1.0)
			if u > 0.0 and u < 1.0:
				var pp := foot.lerp(left, u)
				sh.draw_anim(self, "pip", "free", clock + k * 0.2, (pp - Vector2(8, 17)).floor())
	draw_rect(Rect2(0, 232, vw, 38), DARK)
	_strip("mid", 196.0, hx - 60.0)
	if awake and ct < 1.6 and _has("fx_light"):
		sh.draw_anim(self, "fx_light", "ring", ct - 1.0, Vector2(gx + 64.0 - 24.0, 70.0))


# ---------------------------------------------------------------- shot 2: the Arc leaps into the Spark

func _paint_arc() -> void:
	_stars(40, 7)
	var gate := Vector2(hx + 395.0, 112.0)   # the top of the far Gate
	if _has("intro_far"):
		sh.draw_frame(self, "intro_far", "gate_far", 0, Vector2(hx + 378.0, 104.0))
	if _has("fx_light"):
		sh.draw_anim(self, "fx_light", "ring", fposmod(clock, 0.5), gate - Vector2(24, 24))
	draw_rect(Rect2(0, 232, vw, 38), DARK)
	var spark := Vector2(hx + 150.0, 168.0)
	var mid := spark + Vector2(32, 30)
	var anim := "look" if ct < 1.25 else "answer"
	if _has("title_hero"):
		sh.draw_anim(self, "title_hero", anim, ct, spark)
	else:
		J.spark(self, spark + Vector2(32, 64), 1)
	if ct >= 1.25 and ct < 1.6:
		_bolt(gate, mid, 1)
		_bolt(gate + Vector2(0, 4), mid + Vector2(2, 2), 2)
	if ct >= 1.25 and ct < 1.75 and _has("fx_light"):
		sh.draw_anim(self, "fx_light", "ring", ct - 1.25, mid - Vector2(24, 24))
	# the Arc crackles around the Spark from now on, then it throws one
	if ct >= 1.6:
		for k in 3:
			var h := DrawUtil.hash2(k, int(clock * 12.0))
			if h % 3 == 0:
				draw_rect(Rect2(mid.x - 26.0 + float(h % 52), mid.y - 28.0 + float((h >> 5) % 50), 1, 1), DrawUtil.WHITE)
	if ct >= 2.6 and _has("arc"):
		var a := fposmod(ct - 2.6, 1.4)
		if a < 0.4:
			sh.draw_anim(self, "arc", "swing", a, Vector2(spark.x + 60.0 + a * 60.0, mid.y - 8.0))
	if ct >= 3.4:
		var hint := "PRESS %s TO THROW IT . IT KNOCKS OUT ANY ENEMY AND BREAKS CRACKED WALLS" % GameInput.action_label("attack")
		var hw := DrawUtil.text_width(hint)
		draw_rect(Rect2(hx + 240.0 - hw / 2.0 - 6.0, 240.0, hw + 12.0, 12.0), Color(DrawUtil.BG, 0.85))
		DrawUtil.text(self, Vector2(hx + 240.0 - hw / 2.0, 243.0), hint, DrawUtil.GRAY)


# ---------------------------------------------------------------- shot 3: far below, the Howl wakes

func _paint_below() -> void:
	# the ceiling of the deep, with cut wires hanging down into the dark
	for i in int(vw / 8.0) + 1:
		var h := DrawUtil.hash2(i, 31)
		draw_rect(Rect2(i * 8.0, 0.0, 8.0, 10.0 + float(h % 12)), DARK)
	for k in 7:
		var h2 := DrawUtil.hash2(k, 57)
		var x := hx + 40.0 + k * 64.0 + float(h2 % 20)
		var y1 := 70.0 + float((h2 >> 5) % 60)
		draw_line(Vector2(x, 10.0), Vector2(x + float(h2 % 7) - 3.0, y1), DARK, 1.0)
		if int(clock * 3.0 + k) % 5 == 0:
			draw_rect(Rect2(x, y1 + 1.0, 1, 1), DrawUtil.GRAY)   # a spark dripping off the frayed end
	var at := Vector2(hx + 192.0, 182.0)
	var woke := ct - 1.2
	if _has("howl"):
		if woke < 0.0:
			sh.draw_anim(self, "howl", "sleep", clock, at)
		elif woke < 0.6:
			sh.draw_anim(self, "howl", "wake", woke, at)
		else:
			sh.draw_anim(self, "howl", "idle", clock, at)
	else:
		_static_blob(at + Vector2(48, 40), 44.0, woke >= 0.0)
	# small scraps of static skitter round it
	if _has("intro_static"):
		for k in 3:
			var sx: float = hx + [70.0, 330.0, 400.0][k] + sin(clock * 1.3 + k) * 14.0
			sh.draw_anim(self, "intro_static", "crawl", clock + k * 0.3, Vector2(floorf(sx), 250.0 - k * 4.0))


# ---------------------------------------------------------------- shot 4: the Howl speaks

func _paint_howl() -> void:
	for i in 60:
		var h := DrawUtil.hash2(i, int(clock * 10.0))
		draw_rect(Rect2(float(h % int(vw)), 70.0 + float((h >> 8) % 200), 1, 1), DrawUtil.GRAY if h % 4 == 0 else DARK)
	var speaking := ct >= 0.8 and ct < _text_done_at()
	if _has("howl"):
		draw_set_transform(Vector2(hx + 144.0, 142.0), 0.0, Vector2(2, 2))
		sh.draw_anim(self, "howl", "speak" if speaking else "idle", clock, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
	else:
		_static_blob(Vector2(hx + 240.0, 230.0), 90.0, true)


# ---------------------------------------------------------------- shot 5: the Spark looks out; something looks back

func _paint_watch() -> void:
	_stars(60, 21)
	_strip("far", 160.0, hx - 30.0)
	if _has("howl_far"):
		sh.draw_anim(self, "howl_far", "watch", clock, Vector2(hx + 372.0, 186.0))
	draw_rect(Rect2(0, 224, vw, 46), DARK)
	_strip("mid", 188.0, hx - 90.0)
	draw_line(Vector2(0, 204), Vector2(vw, 198), DARK, 1.0)
	J.spark(self, Vector2(hx + 132.0, 224.0), 1)


# ---------------------------------------------------------------- descent, shot 1: the line runs down

func _paint_shaft() -> void:
	# the camera sinks down a shaft of cut cables; the Spark stands at the lip
	var sink := minf(ct * 14.0, 70.0)
	for k in 14:
		var by := fposmod(k * 40.0 - clock * 30.0, 560.0) - 20.0
		draw_rect(Rect2(hx + 62.0, by, 8.0, 2.0), DrawUtil.GRAY)       # cable brackets on the walls
		draw_rect(Rect2(hx + 410.0, by + 20.0, 8.0, 2.0), DrawUtil.GRAY)
	for side in [-1, 1]:
		for k in 12:
			var h := DrawUtil.hash2(k, 41 + side)
			var x: float = hx + 240.0 + side * (120.0 + float(h % 40))
			draw_line(Vector2(x, -10.0), Vector2(x + float(h % 5) - 2.0, 280.0), DARK, 1.0)
		draw_rect(Rect2(hx + 240.0 + side * 170.0 - (40.0 if side < 0 else 0.0), 0, 40.0, 270.0), DARK)
	# the line itself, running down the middle into the dark
	draw_line(Vector2(hx + 240.0, 180.0 - sink), Vector2(hx + 240.0, 280.0), DrawUtil.GRAY, 1.0)
	for k in 6:
		var y := fposmod(clock * 40.0 + k * 45.0, 200.0) + 180.0 - sink
		draw_rect(Rect2(hx + 239.0, floorf(y), 3, 2), DrawUtil.WHITE if k % 2 == 0 else DrawUtil.GRAY)
	draw_rect(Rect2(hx + 150.0, 180.0 - sink, 90.0, 6.0), DrawUtil.GRAY)   # the ledge where the line goes over
	J.spark(self, Vector2(hx + 206.0, 180.0 - sink), 1)
	for i in 30:
		var h2 := DrawUtil.hash2(i, int(clock * 8.0))
		draw_rect(Rect2(hx + 130.0 + float(h2 % 220), 150.0 + float((h2 >> 8) % 120), 1, 1), DARK)


# ---------------------------------------------------------------- descent, shot 2: the Howl waits below

func _paint_deep() -> void:
	for i in 80:
		var h := DrawUtil.hash2(i, int(clock * 10.0))
		draw_rect(Rect2(float(h % int(vw)), float((h >> 8) % 270), 1, 1), DrawUtil.GRAY if h % 5 == 0 else DARK)
	var a := clampf(ct / 1.5, 0.0, 1.0)
	if _has("howl"):
		draw_set_transform(Vector2(hx + 144.0, 120.0), 0.0, Vector2(2, 2))
		sh.draw_anim(self, "howl", "speak" if ct >= 1.0 and ct < _text_done_at() else "idle", clock, Vector2.ZERO,
			false, Color(1, 1, 1, a))
		draw_set_transform(Vector2.ZERO)
	else:
		_static_blob(Vector2(hx + 240.0, 200.0), 90.0, true)


# ---------------------------------------------------------------- descent, shot 3: the call is close

func _paint_call() -> void:
	_stars(20, 51)
	# far below, a faint ring of lights with one place dark, and the line running to it
	var ring := Vector2(hx + 330.0, 196.0)
	draw_line(Vector2(hx + 150.0, 168.0), ring, DARK, 1.0)
	for k in 8:
		var ang := TAU * k / 8.0 + PI
		var p := ring + Vector2(cos(ang) * 18.0, sin(ang) * 8.0)
		if k == 0:
			draw_rect(Rect2(p.floor(), Vector2(2, 2)), DARK)
		elif (int(clock * 3.0) + k) % 4 != 0:
			draw_rect(Rect2(p.floor(), Vector2(2, 2)), DrawUtil.WHITE if k % 2 == 0 else DrawUtil.GRAY)
	# a pulse of the call running up the line to the Spark on each ring
	for r in [0.8, 1.6, 2.4]:
		var u: float = (ct - r) / 0.6
		if u > 0.0 and u < 1.0:
			var p2 := ring.lerp(Vector2(hx + 150.0, 168.0), u)
			draw_rect(Rect2(p2.floor() - Vector2(1, 1), Vector2(3, 3)), DrawUtil.WHITE)
	draw_rect(Rect2(hx + 100.0, 168.0, 70.0, 6.0), DrawUtil.GRAY)
	J.spark(self, Vector2(hx + 140.0, 168.0), 1)


# ---------------------------------------------------------------- the ending

## The ring of Sparks, drawn twice size around `c` (its middle).
func _ring(anim: String, t: float, c: Vector2) -> void:
	if _has("ring"):
		draw_set_transform(c - Vector2(96, 64), 0.0, Vector2(2, 2))
		sh.draw_anim(self, "ring", anim, t, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
		return
	for k in 8:
		var ang := TAU * k / 8.0 + PI
		if k > 0 or anim != "wait":
			J.spark(self, c + Vector2(cos(ang) * 36.0, sin(ang) * 36.0 + 6.0), 1, 0.6, 0.6)


func _paint_ring_wait() -> void:
	for i in 40:
		var h := DrawUtil.hash2(i, int(clock * 6.0))
		draw_rect(Rect2(float(h % int(vw)), 150.0 + float((h >> 8) % 120), 1, 1), DARK)
	_ring("wait", clock, Vector2(hx + 290.0, 150.0))
	# the Spark comes in from the left and stops beside the empty place
	var x := lerpf(hx + 40.0, hx + 186.0, clampf(ct / 3.0, 0.0, 1.0))
	J.spark(self, Vector2(floorf(x), 214.0), 1, 1.0, 1.0, "run" if ct < 3.0 else "stand", clock * 3.0)
	draw_rect(Rect2(0, 214, vw, 56), DARK)


func _paint_ring_close() -> void:
	_ring("close" if ct < 1.6 else "lit", ct if ct < 1.6 else clock, Vector2(hx + 290.0, 150.0))
	if ct < 0.5:
		var p := Vector2(hx + 186.0, 214.0).lerp(Vector2(hx + 238.0, 158.0), ct / 0.5)
		J.spark(self, p.floor(), 1, 0.8, 0.8)
	if ct >= 0.5 and ct < 1.1 and _has("fx_light"):
		sh.draw_anim(self, "fx_light", "ring", ct - 0.5, Vector2(hx + 290.0 - 24.0, 150.0 - 24.0))
	draw_rect(Rect2(0, 214, vw, 56), DARK)


func _paint_unravel() -> void:
	# the Howl fades, and the voices it swallowed stream out along the wires
	var fade := clampf(1.0 - ct / 3.0, 0.0, 1.0)
	if _has("howl") and fade > 0.0:
		draw_set_transform(Vector2(hx + 144.0, 110.0), 0.0, Vector2(2, 2))
		sh.draw_anim(self, "howl", "idle", clock, Vector2.ZERO, false, Color(1, 1, 1, fade))
		draw_set_transform(Vector2.ZERO)
	var c := Vector2(hx + 240.0, 170.0)
	var ends := [Vector2(-20.0, 90.0), Vector2(-20.0, 190.0), Vector2(hx + 60.0, 290.0),
		Vector2(hx + 420.0, 290.0), Vector2(vw + 20.0, 190.0), Vector2(vw + 20.0, 90.0)]
	for w in 6:
		var end: Vector2 = ends[w]
		draw_line(c, end, DARK, 1.0)
		for k in 5:
			var u := fposmod(ct * 0.35 + k * 0.2 + w * 0.07, 1.0)
			if ct > 0.6 + k * 0.3 and _has("pip"):
				var p := c.lerp(end, u)
				sh.draw_anim(self, "pip", "free", clock + k * 0.1, (p - Vector2(8, 8)).floor())


func _paint_stations() -> void:
	_stars(50, 71)
	_strip("far", 160.0, hx)
	draw_rect(Rect2(0, 224, vw, 46), DARK)
	_strip("mid", 188.0, hx - 40.0)
	# poles along the line, and each station lamp comes on in turn, left to right
	var n := int(vw / 80.0) + 2
	for k in n:
		var px := hx - 60.0 + k * 80.0
		if px < -40.0 or px > vw + 20.0:
			continue
		if _has("title_pole"):
			sh.draw_frame(self, "title_pole", "pole", 1 if k % 4 == 2 else 0, Vector2(floorf(px), 186.0))
		else:
			draw_rect(Rect2(px + 11.0, 186.0, 2.0, 64.0), DARK)
		var on := ct >= 0.8 + (px + 60.0) / vw * 3.2
		if _has("lamp"):
			sh.draw_anim(self, "lamp", "on" if on else "off", clock, Vector2(floorf(px + 26.0), 217.0))
		if on and ct < 0.8 + (px + 60.0) / vw * 3.2 + 0.4 and _has("fx_light"):
			sh.draw_anim(self, "fx_light", "ring", ct - 0.8 - (px + 60.0) / vw * 3.2, Vector2(px + 30.0 - 24.0, 212.0 - 24.0))
	# the wire lights up behind the lamps
	var lit_to := (ct - 0.8) / 3.2 * vw - 60.0
	draw_line(Vector2(0, 194), Vector2(vw, 194), DARK, 1.0)
	if lit_to > 0.0:
		draw_line(Vector2(0, 194), Vector2(minf(vw, lit_to), 194), DrawUtil.GRAY, 1.0)
	if _has("pip") and ct > 2.0:
		for k in 5:
			var x := fposmod(clock * 60.0 + k * 97.0, vw + 40.0) - 20.0
			if x < lit_to:
				sh.draw_anim(self, "pip", "free", clock + k * 0.2, Vector2(floorf(x) - 8.0, 177.0))


func _paint_relay() -> void:
	_stars(40, 17)
	if _has("backdrop_village"):
		var vs: Vector2 = sh.size("backdrop_village")
		for slot in int(vw / vs.x) + 2:
			sh.draw_frame(self, "backdrop_village", "pieces", DrawUtil.hash2(slot, 523) % 4,
				Vector2(slot * vs.x - 20.0, 232.0 - vs.y), false, Color(1, 1, 1, 0.7))
	draw_rect(Rect2(0, 232, vw, 38), DARK)
	# Brace pulls the handle back the other way, and the line is joined again
	var pole := Vector2(hx + 150.0, 168.0)
	if _has("intro_poles"):
		var n: int = sh.frames("intro_poles", "switch_pull")
		var f := n - 1 - clampi(int((ct - 0.2) / 0.12), 0, n - 1)
		sh.draw_frame(self, "intro_poles", "switch_pull", f, pole)
	if _has("npc"):
		sh.draw_anim(self, "npc", "brace_idle", clock, pole + Vector2(-14, 40))
		sh.draw_anim(self, "npc", "mast_talk" if ct > 2.6 else "mast_idle", clock, Vector2(hx + 300.0, 208.0), true)
		sh.draw_anim(self, "npc", "wren_idle", clock, Vector2(hx + 330.0, 208.0), true)
	# the three rings arrive down the wire
	draw_line(Vector2(0, 176), pole + Vector2(24, 8), DrawUtil.GRAY, 1.0)
	for r in [0.6, 1.4, 2.2]:
		var u: float = (ct - r) / 0.5
		if u > 0.0 and u < 1.0:
			var p := Vector2(0, 176).lerp(pole + Vector2(24, 8), u)
			draw_rect(Rect2(p.floor() - Vector2(1, 1), Vector2(3, 3)), DrawUtil.WHITE)


func _paint_switchboard() -> void:
	draw_rect(Rect2(0, 222, vw, 48), DARK)
	var at := Vector2(hx + 150.0, 190.0)
	if _has("switchboard"):
		draw_set_transform(at, 0.0, Vector2(2, 2))
		sh.draw_anim(self, "switchboard", "idle", clock, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
	if _has("npc"):
		draw_set_transform(at + Vector2(-40, -16), 0.0, Vector2(2, 2))
		sh.draw_anim(self, "npc", "dot_talk" if ct < 3.0 else "dot_idle", clock, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
	var n := mini(int(pips[0]), 40)
	for i in n:
		var x := at.x + 80.0 + float(i % 14) * 14.0
		var y := at.y + 18.0 - float(i / 14) * 14.0 + (3.0 if i % 3 == 1 else 0.0)
		if _has("pip") and ct > 0.4 + i * 0.03:
			sh.draw_anim(self, "pip", "hop", clock + i * 0.17, Vector2(floorf(x), floorf(y)), i % 2 == 1)
	if ct > 0.8 and int(pips[0]) >= int(pips[1]) and int(clock * 6.0) % 2 == 0:
		draw_rect(Rect2(at + Vector2(4, 4), Vector2(56, 20)), Color(DrawUtil.WHITE, 0.25))


func _paint_home() -> void:
	_stars(40, 23)
	if _has("backdrop_village"):
		var vs: Vector2 = sh.size("backdrop_village")
		for slot in int(vw / vs.x) + 2:
			sh.draw_frame(self, "backdrop_village", "pieces", DrawUtil.hash2(slot, 97) % 4,
				Vector2(slot * vs.x - 40.0, 232.0 - vs.y), false, Color(1, 1, 1, 0.7))
	draw_rect(Rect2(0, 224, vw, 46), DARK)
	# the Spark at home, with Sparks visiting from every station down the line
	J.spark(self, Vector2(hx + 200.0, 224.0), 1)
	for k in 5:
		var x := hx + 250.0 + k * 26.0 + sin(clock * 2.0 + k) * 6.0
		var hop := absf(sin(clock * 4.0 + k * 1.3)) * 6.0
		J.spark(self, Vector2(floorf(x), floorf(224.0 - hop)), -1, 0.7, 0.7)
	if _has("npc"):
		sh.draw_anim(self, "npc", "wren_talk" if ct > 1.0 and ct < _text_done_at() else "wren_idle", clock,
			Vector2(hx + 150.0, 200.0))


func _paint_credits() -> void:
	_stars(60, 5)
	var c := hx + 240.0
	DrawUtil.text_shadow(self, Vector2(c - DrawUtil.text_width("THE END", 3) / 2.0, 44.0), "THE END", DrawUtil.WHITE, 3)
	var rows := [["ENGINE", "GODOT"], ["PIXEL ART", "MADE IN CODE . PIXELLAB . IMAGEGEN"],
		["8-BIT MUSIC AND EFFECTS", "WRITTEN AS CODE FOR THE NES SOUND CHIP"]]
	for i in rows.size():
		var y := 100.0 + i * 24.0
		DrawUtil.text(self, Vector2(c - DrawUtil.text_width(rows[i][0]) / 2.0, y), rows[i][0], DrawUtil.GRAY)
		DrawUtil.text(self, Vector2(c - DrawUtil.text_width(rows[i][1]) / 2.0, y + 10.0), rows[i][1], DrawUtil.WHITE)
	if ct > 2.0:
		var thanks := "THANK YOU FOR PLAYING"
		DrawUtil.text_shadow(self, Vector2(c - DrawUtil.text_width(thanks, 2) / 2.0, 214.0), thanks, DrawUtil.WHITE, 2)
	J.spark(self, Vector2(c, 250.0), 1)


## Stand-in for the Howl if its sheet is missing: a heap of static with two eyes.
func _static_blob(c: Vector2, r: float, eyes: bool) -> void:
	for i in 220:
		var h := DrawUtil.hash2(i, int(clock * 12.0))
		var a := float(h % 628) / 100.0
		var d := r * sqrt(float((h >> 9) % 1000) / 1000.0)
		draw_rect(Rect2(c.x + cos(a) * d, c.y + sin(a) * d * 0.6, 1, 1), DrawUtil.GRAY if h % 3 == 0 else DARK)
	if eyes:
		draw_rect(Rect2(c.x - r * 0.35, c.y - r * 0.2, 3, 2), DrawUtil.WHITE)
		draw_rect(Rect2(c.x + r * 0.35 - 3.0, c.y - r * 0.2, 3, 2), DrawUtil.WHITE)
