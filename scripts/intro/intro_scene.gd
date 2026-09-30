extends Node2D
## The story intro: ten cards, about a minute, from the living line to Last
## Relay. Shot list: docs/story/intro-shots.md. Script: docs/story/intro-script.md.
## Tap jump or Down to finish a card's text or go to the next card, hold for
## 0.6 s to skip, Esc skips it all. It ends by handing over to the village as a
## new game (or back to the title when watched from EXTRAS).

const Sheets := preload("res://scripts/world1/sheets.gd")
const J := preload("res://scripts/world1/juice.gd")
const Game := preload("res://scripts/world1/w1_game.gd")
const ScreenFit := preload("res://scripts/screen_fit.gd")
const SFX_DIR := "res://assets/audio/sfx8/"
const SFX_TRIM := -5.0
const MUSIC_DB := -9.0
const STEP := 0.12            # one palette step when fading
const WIRE_Y := 190.0
const POLE_GAP := 160.0
const GAP := Vector2(203, 220)   # where the crew cut the line (card 4)

## Each card: text, length, when the text comes and goes, and its act (tint).
const CARDS := [
	{"lines": ["ONE LINE RAN ACROSS THE WHOLE LAND", "JOINING EVERY RELAY AND EVERY GATE"], "dur": 6.0, "in": 0.8, "out": 5.6, "act": "amber"},
	{"lines": ["PIPS OF SIGNAL CARRIED EVERY VOICE", "SO NO ONE WAS EVER TOO FAR AWAY"], "dur": 6.0, "in": 0.8, "out": 5.6, "act": "amber"},
	{"lines": ["THEN A HOWLING NOISE FILLED THE LINE", "AND SPREAD FROM STATION TO STATION"], "dur": 6.0, "in": 0.8, "out": 5.6, "act": "grey"},
	{"lines": ["SO THE CREWS CUT THE LINE APART", "ONE STATION AFTER ANOTHER"], "dur": 6.0, "in": 0.8, "out": 5.6, "act": "grey"},
	{"lines": ["THE NOISE STOPPED . SO DID THE VOICES", "AND THE PIPS WERE CAUGHT IN THE GLASS"], "dur": 7.0, "in": 2.0, "out": 6.4, "act": "grey"},
	{"lines": ["AT THE END OF ONE CUT WIRE", "A TINY SPARK OF SIGNAL LAY SLEEPING"], "dur": 6.0, "in": 0.8, "out": 5.6, "act": "blue"},
	{"lines": ["UNTIL ONE NIGHT THE DEAD LINE RANG", "ONCE . TWICE . THREE TIMES"], "dur": 7.0, "in": 0.6, "out": 6.6, "act": "blue"},
	{"lines": ["NOTHING SHOULD RING ON A DEAD LINE", "BUT SOMEONE IS STILL CALLING"], "dur": 6.0, "in": 0.8, "out": 5.6, "act": "blue"},
	{"lines": ["IT FOLLOWED THE WIRE TO THE LAST LIGHT", "A HILLTOP STATION CALLED LAST RELAY"], "dur": 6.0, "in": 0.8, "out": 5.6, "act": "warm"},
	{"lines": ["FREE THE PIPS AND LIGHT THE GATES", "TO FIND WHO IS ON THE OTHER END"], "dur": 7.0, "in": 1.0, "out": 6.6, "act": "warm"},
]
const TINT_OF := {"amber": "2", "grey": "test", "blue": "1", "warm": "village"}
const FADE_IN := [0, 4, 5, 8, 9]            # cards (0-based) that fade up from black
const FADE_OUT := {3: 5.64, 4: 6.64, 7: 5.64, 8: 5.64, 9: 6.64}   # card: when the fade to black starts
const NIGHT := Color(0.57, 0.57, 0.57)   # reused art with white edges, kept below white after card 5
const RINGS := [[1.40, 2.65], [2.60, 3.85], [3.80, 5.05]]           # card 7: leave, arrive at the tip

static var replay := false    # watched from EXTRAS: go back to the title at the end

var sh: Sheets
var card := 0
var ct := 0.0                 # time in the current card
var clock := 0.0
var typed_full := false       # a tap finished the card's text early
var vw := 480.0
var hx := 0.0
var fxmat: ShaderMaterial
var fx_rect: ColorRect
var post: ColorRect
var sfx := {}
var players: Array = []
var music: AudioStreamPlayer
var amb: AudioStreamPlayer
var loop_a: AudioStreamPlayer   # relay hum, static crawl
var cue := ""
var fired := {}               # events already played this card
var shake_t := 0.0
var shake_amp := 0.0
var settle := 0.5             # ignore input at first; the title's confirm may still be held
var released := false
var hold_t := 0.0
var hold_tick := 0
var ending := -1.0            # seconds since the fade out of the whole intro began


func _ready() -> void:
	sh = Sheets.new()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	RenderingServer.set_default_clear_color(DrawUtil.BG)
	var man = JSON.parse_string(FileAccess.get_file_as_string(SFX_DIR + "manifest.json"))
	for s in (man.get("sounds", []) if man is Dictionary else []):
		if s is Dictionary and ResourceLoader.exists(SFX_DIR + str(s.get("file", ""))):
			sfx[str(s.name)] = load(SFX_DIR + str(s.file))
	for n in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	music = _player("Music")
	amb = _player("SFX")
	loop_a = _player("SFX")
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
	_enter_card(0)


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


## A cue that plays once then loops another, joined with no gap (like the title).
func _joined(head_name: String, loop_name: String) -> AudioStream:
	var head: AudioStream = sfx.get(head_name)
	var body: AudioStream = sfx.get(loop_name)
	if not (head is AudioStreamWAV and body is AudioStreamWAV) or head.format != body.format or head.mix_rate != body.mix_rate:
		return _looped(loop_name) if body != null else null
	var j := AudioStreamWAV.new()
	j.format = body.format
	j.mix_rate = body.mix_rate
	j.stereo = body.stereo
	var a: PackedByteArray = head.data
	j.data = a + body.data
	var fb := (2 if body.format == AudioStreamWAV.FORMAT_16_BITS else 1) * (2 if body.stereo else 1)
	j.loop_mode = AudioStreamWAV.LOOP_FORWARD
	j.loop_begin = a.size() / fb
	j.loop_end = j.data.size() / fb
	return j


## Start a music cue. The old cue fades out while the new one fades in on its
## own player, so the music changes smoothly. A `fade_in` of 0 starts the new cue
## at full level, for a cue that begins on a hit.
func _cue(name: String, fade_in := 1.5) -> void:
	if name == cue:
		return
	cue = name
	var st: AudioStream = null
	if name == "wake_home":
		st = _joined("intro_wake", "intro_home")
	elif name != "" and sfx.has(name):
		st = _looped(name)
	var old := music
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, 0.3 if fade_in <= 0.0 else maxf(fade_in, 1.0))
		tw.tween_callback(old.queue_free)
	else:
		old.queue_free()
	music = _player("Music")
	if st == null:
		return
	music.stream = st
	music.volume_db = MUSIC_DB if fade_in <= 0.0 else -40.0
	music.play()
	if fade_in > 0.0:
		_fade(music, MUSIC_DB, fade_in)


func _fade(p: AudioStreamPlayer, to_db: float, secs: float, stop_after := false) -> void:
	var tw := create_tween()
	tw.tween_property(p, "volume_db", to_db, secs)
	if stop_after:
		tw.tween_callback(p.stop)


func _amb(name: String, from_db: float, to_db: float, secs: float) -> void:
	if not sfx.has(name):
		return
	if amb.stream != sfx[name] or not amb.playing:
		amb.stream = _looped(name)
		amb.volume_db = from_db
		amb.play()
	_fade(amb, to_db, secs)


## Music and sound that belong to a card as a whole, set when it starts (so a
## skip lands with the right sound).
func _enter_card(i: int) -> void:
	card = i
	ct = 0.0
	typed_full = false
	fired.clear()
	loop_a.stop()
	match i:
		# The music follows the story's acts: the warm line, the noise (cut dead when
		# the line is cut), the quiet, the sleeping Spark under the rings, then home.
		0, 1:
			_cue("intro_line", 0.8)
			_amb("amb_w1", -40.0, -12.0, 1.0)
			if i == 1 and sfx.has("relay_hum"):
				loop_a.stream = _looped("relay_hum")
				loop_a.volume_db = -12.0 + SFX_TRIM
				loop_a.play()
		2, 3:
			_cue("intro_noise", 1.5)
			_amb("amb_w1", -12.0, -12.0, 0.1)
		4:
			_cue("")
			_fade(amb, -60.0, 0.2, true)
		5:
			_cue("intro_still", 2.0)
			_fade(amb, -60.0, 0.2, true)
		6:
			if cue == "intro_still":
				_fade(music, -20.0, 1.0)   # it plays on, quieter, under the three rings
			else:
				_cue("")
		7:
			_cue("wake_home", 0.0)   # the Spark flares awake on the downbeat
		8, 9:
			if cue != "wake_home":
				_cue("intro_home")
			_amb("amb_village", -30.0, -12.0, 6.0 if i == 8 else 0.5)


func _event(key: String, at: float) -> bool:
	## True once, the first frame the card's clock passes `at`.
	if ct >= at and not fired.has(key):
		fired[key] = true
		return true
	return false


func _card_sounds() -> void:
	match card:
		1:
			if _event("pulse1", 1.5):
				_play("line_pulse")
			if _event("pulse2", 3.3):
				_play("line_pulse", 0.0, 1.12)
		2:
			if _event("crawl", 0.5) and sfx.has("static_crawl"):
				loop_a.stream = _looped("static_crawl")
				loop_a.volume_db = -6.0 + SFX_TRIM
				loop_a.play()
			if loop_a.playing:
				loop_a.volume_db = lerpf(-6.0, 0.0, clampf(ct / 6.0, 0.0, 1.0)) + SFX_TRIM
			if _event("lamp", 3.44):
				_play("lamp_off")
		3:
			if not loop_a.playing and ct < 3.2 and sfx.has("static_crawl"):
				loop_a.stream = _looped("static_crawl")
				loop_a.volume_db = SFX_TRIM
				loop_a.play()
			if _event("lever", 0.9):
				_play("lever_pull")
			if _event("snap", 1.25):
				_play("wire_snap")
				_fade(music, -60.0, 0.02, true)   # cutting the line cuts the music
				cue = "cut"
				_fade(amb, -60.0, 0.3, true)
				_shake(2.0, 0.25)
			if _event("lamp234", 1.89):
				_play("lamp_off")
			if _event("die", 3.2):
				loop_a.stop()
				_play("static_die")
			for k in _lights_left().size():
				if k % 2 == 0 and _event("out%d" % k, 3.6 + k * 0.3):
					_play("lamp_off", -10.0, 0.8)
		6:
			for k in 3:
				if _event("ring%d" % k, RINGS[k][1]):
					_play("line_ring")
		7:
			if _event("flare", 0.2):
				_play("spark_flare")
				_shake(1.0, 0.2)
			if _event("blip", 3.0):
				_play("caller_blip", -8.0)
		8:
			if _event("door", 0.6):
				_play("door_open", -10.0)
		9:
			if _event("blip1", 2.5):
				_play("caller_blip", -10.0)
			if _event("blip2", 4.7):   # lands on the music's answer
				_play("caller_blip", -10.0)
			if _event("musicout", 5.4):
				_fade(music, -40.0, 1.2, true)
			if _event("ambout", 6.2):
				_fade(amb, -60.0, 0.8, true)


func _shake(amp: float, secs: float) -> void:
	if AppSettings.camera_shake and not AppSettings.reduced_flashes:
		shake_amp = amp
		shake_t = secs


# ================================================================ input and time

func _input_down() -> bool:
	return Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept") \
		or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) \
		or Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)


func _unhandled_input(event: InputEvent) -> void:
	if ending >= 0.0 or settle > 0.0:
		return
	var pause: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) \
		or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if pause:
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
	_card_sounds()
	if ct >= float(CARDS[card].dur):
		if card + 1 < CARDS.size():
			_enter_card(card + 1)
		else:
			_end()
	_update_shader()
	queue_redraw()


func _tap() -> void:
	## Finish the card's text if it is still typing, else go to the next card.
	if not typed_full and ct < _text_done_at():
		typed_full = true
		return
	if card + 1 < CARDS.size():
		_enter_card(card + 1)
	else:
		_end()


func _end() -> void:
	if ending >= 0.0:
		return
	ending = 0.0
	_fade(music, -40.0, 0.36, true)
	_fade(amb, -60.0, 0.36, true)
	loop_a.stop()


func _hand_off() -> void:
	if replay:
		replay = false
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
	Game.start_mode = "new"
	Game.intro_handoff = true
	get_tree().change_scene_to_file("res://scenes/world1_play.tscn")


# ================================================================ tint, fades and light

func _update_shader() -> void:
	var tint: Array = Game.TINTS.get(TINT_OF[CARDS[card].act], Game.TINTS["1"])
	var level := 0
	if card in FADE_IN:
		level = maxi(level, 3 - int(ct / STEP))
	if FADE_OUT.has(card) and ct >= float(FADE_OUT[card]):
		level = maxi(level, 1 + int((ct - float(FADE_OUT[card])) / STEP))
	if ending >= 0.0:
		level = maxi(level, 1 + int(ending / STEP))
	level = clampi(level, 0, 3)
	for k in 4:
		fxmat.set_shader_parameter("ramp%d" % k, tint[maxi(0, k - level)] if level < 3 or k == 0 else tint[0])
	# the darkness pass: close-ups and night shots are lit only near a few lights
	var dark := 0.0
	var lights: Array = []
	match card:
		5, 6:
			dark = 0.6
			var r := 24.0
			if card == 6:
				for k in 3:
					if ct >= RINGS[k][1]:
						r = 32.0 + 8.0 * k
					elif ct >= RINGS[k][0]:
						# each ring carries its own small light along the wire
						lights.append(Vector3(hx + 180.0 + 256.0 * (RINGS[k][1] - ct), 216.0, 20.0))
			lights.append(Vector3(hx + 160.0 - _close_cam(), 212.0, r))
		7:
			if ct < 2.5:
				dark = 0.6
				var r2 := 48.0 + 40.0 * clampf((ct - 0.2) / 0.3, 0.0, 1.0)
				lights.append(Vector3(hx + 160.0, 212.0, r2))
			else:
				dark = 0.55
				lights.append(Vector3(hx + 204.0, 226.0, 56.0))
				lights.append(Vector3(hx + 392.0, 166.0, 14.0))   # the far light answering
		8:
			dark = 0.85
			lights.append(Vector3(hx + _spark9().x, _spark9().y - 6.0, 40.0))
			var m := _mast9()
			lights.append(Vector3(hx + m.x - 7.0, m.y - 8.0, 56.0))   # the lantern
			lights.append(Vector3(hx + 380.0, 104.0, 24.0))          # the keeper's window
	var ranges := PackedVector4Array()
	if dark > 0.0:
		ranges.append(Vector4(-10000.0, 10000.0, 1.0, dark))
	fxmat.set_shader_parameter("hud_rows", 64.0)   # the text band at the top is never darkened
	fxmat.set_shader_parameter("dark_ranges", ranges)
	fxmat.set_shader_parameter("dark_count", ranges.size())
	var lv := PackedVector3Array()
	for l in lights:
		lv.append(l)
	fxmat.set_shader_parameter("lights", lv)
	fxmat.set_shader_parameter("light_count", lv.size())
	fxmat.set_shader_parameter("cam", Vector2.ZERO)


# ================================================================ drawing

func _draw() -> void:
	draw_rect(Rect2(0, 0, vw, 270), DrawUtil.BG)
	var off := Vector2.ZERO
	if shake_t > 0.0:
		off = Vector2(float(int(clock * 60.0) % 3) - 1.0, float(int(clock * 47.0) % 3) - 1.0) * shake_amp
	draw_set_transform(off)
	match card:
		0:
			_land(floorf(60.0 * ct / 6.0), "alive")
		1:
			_relay_station()
		2, 3:
			_land(0.0, "noise")
		4:
			_land(0.0, "dead")
		5, 6:
			_close_up()
		7:
			if ct < 2.5:
				_close_up()
			else:
				_awake()
		8:
			_hill()
		9:
			_window()
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
		if x > hx + 80.0 and x < hx + 400.0 and y > 20.0 and y < 64.0:
			continue   # keep the text band clear
		draw_rect(Rect2(x, y, 1, 1), DrawUtil.GRAY if h % 9 == 0 else DARK)


const DARK := Color("3a3a3a")


func _strip(anim: String, y: float, origin: float) -> void:
	if not _has("title_scene"):
		return
	var w: float = sh.size("title_scene").x
	var x := fposmod(origin, w) - w
	while x < vw:
		sh.draw_frame(self, "title_scene", anim, 0, Vector2(floorf(x), y))
		x += w


# ---------------------------------------------------------------- the land (cards 1, 3, 4, 5)

func _noise_x() -> float:
	## Where the noise is on the wire (column coordinates), or 9999 before it comes.
	if card == 2:
		return 9999.0 if ct < 0.5 else 500.0 - 36.0 * (ct - 0.5)
	if card == 3:
		return maxf(222.0, 302.0 - 36.0 * ct)
	return -9999.0


func _lights_left() -> Array:
	## Lights left of the cut, right to left: they go out one by one in card 4.
	var xs: Array = []
	for i in range(8, -1, -1):
		xs.append(12.0 + 24.0 * i)
	xs.append(74.0)
	xs.sort()
	xs.reverse()
	var out: Array = []
	for x in xs:
		if x < GAP.x:
			out.append(x)
	return out


func _light_on(x: float, state: String) -> bool:
	## Is the station light or horizon light at column x still lit?
	if state == "dead":
		return false
	if state == "alive":
		return true
	var nx := _noise_x()
	if x > 480.0 and card >= 2:
		return false   # the noise came from further east
	if x >= nx:
		return false
	if card == 3 and x < GAP.x:
		var order := _lights_left()
		var k := order.find(x)
		if k >= 0 and ct >= 3.6 + k * 0.3:
			return false
	return true


func _land(cam: float, state: String) -> void:
	_stars(60, 91)
	_strip("far", 160.0, hx - cam * 0.2)
	# horizon lights
	if state != "dead":
		var x := 12.0 - ceilf((hx + 12.0) / 24.0) * 24.0
		while x < vw - hx:
			var sx := hx + x - cam * 0.2
			if _light_on(x, state) and sx >= 0.0 and sx < vw:
				draw_rect(Rect2(floorf(sx), 209, 1, 1), DrawUtil.WHITE)
			x += 24.0
	draw_rect(Rect2(0, 224, vw, 28), DARK)
	_strip("mid", 188.0, hx - cam * 0.5)
	draw_rect(Rect2(0, 252, vw, 18), DrawUtil.BG)
	# poles and station lamps
	var first := -ceilf((hx + 40.0) / POLE_GAP)
	for k in range(int(first), int(first) + int(vw / POLE_GAP) + 3):
		var px := 40.0 + POLE_GAP * k
		var sx := hx + px - cam
		if sx < -60.0 or sx > vw + 20.0:
			continue
		if state == "dead":
			_dead_pole(px, sx)
		elif px == 200.0 and card in [2, 3] and _has("intro_poles"):
			_switch_pole(sx - 12.0)
		elif _has("title_pole"):
			sh.draw_frame(self, "title_pole", "pole", 1 if posmod(k, 4) == 2 else 0, Vector2(floorf(sx), 186.0))
		else:
			draw_rect(Rect2(sx + 11.0, 186.0, 2.0, 64.0), DARK)
		# the station lamp beside the pole
		var bulb := px + 34.0
		if _has("lamp"):
			var lit := _light_on(bulb, state)
			sh.draw_anim(self, "lamp", "on" if lit else "off", clock, Vector2(floorf(sx + 26.0), 217.0))
	# the wire
	if state == "dead":
		_dead_wire(cam)
		_trapped_pips(cam)
	else:
		if state == "alive":
			_wire_pips(cam)
		var nx := _noise_x()
		var last := Vector2(-1.0, _sag(-1.0 + cam - hx))
		for sxi in range(0, int(vw) + 1):
			var sx := float(sxi)
			var colx := sx - hx + cam
			var p := Vector2(sx, _sag(colx))
			var cut := card == 3 and ct >= 1.25 and colx > GAP.x and colx < GAP.y
			if not cut:
				draw_line(last, p, DARK if colx >= nx else DrawUtil.GRAY, 1.0)
			last = p
		# the noise itself, riding the wire
		if card in [2, 3] and nx < 900.0 and not (card == 3 and ct >= 3.6):
			var sx2 := hx + nx - cam
			var anim := "crawl"
			var at := ct
			if card == 3 and ct >= 3.2:
				anim = "die"
				at = ct - 3.2
			elif card == 3 and ct >= 2.22:
				anim = "stall"
			if _has("intro_static"):
				sh.draw_anim(self, "intro_static", anim, at, Vector2(floorf(sx2 - 16.0), floorf(_sag(nx) - 8.0)))
			else:
				for j in 6:
					var h := DrawUtil.hash2(j, int(clock * 20.0))
					draw_rect(Rect2(sx2 - 8.0 + float(h % 16), _sag(nx) - 4.0 + float((h >> 4) % 8), 2, 1), DrawUtil.WHITE)
		if card == 3 and ct >= 1.25 and ct < 1.4 and _has("arc_hit"):
			sh.draw_anim(self, "arc_hit", "hit", ct - 1.25, Vector2(hx + 212.0 - 8.0, 182.0))


## Card 1: Pips running along the living wire, each carrying a voice.
func _wire_pips(cam: float) -> void:
	if not _has("pip"):
		return
	for k in 5:
		var colx := fposmod(clock * 70.0 + k * 131.0, vw + 80.0) - 40.0 - hx + cam
		var sx := hx + colx - cam
		sh.draw_anim(self, "pip", "free", clock + k * 0.3, Vector2(floorf(sx - 8.0), floorf(_sag(colx)) - 9.0))


## Card 5: after the cut, the Pips are caught in the glass of the dead poles,
## glowing faintly and flickering.
func _trapped_pips(cam: float) -> void:
	if not _has("pip"):
		return
	var first := -ceilf((hx + 40.0) / POLE_GAP)
	for k in range(int(first), int(first) + int(vw / POLE_GAP) + 3):
		var sx := hx + 40.0 + POLE_GAP * k - cam
		if posmod(k, 2) == 0 and ct > 3.0:   # as the second line types
			var dim := Color(1, 1, 1, clampf((ct - 3.0) / 0.8, 0.0, 1.0))
			sh.draw_anim(self, "pip", "trapped", ct + k * 0.4, Vector2(floorf(sx + 20.0 - 8.0), WIRE_Y - 15.0), false, dim)


func _sag(colx: float) -> float:
	## The title's wire: straight across each pole, a 6 px sag between poles.
	var rel := fposmod(colx - 40.0, POLE_GAP)
	if rel >= 3.0 and rel <= 20.0:
		return WIRE_Y
	var u := clampf(fposmod(rel - 20.0, POLE_GAP) / (POLE_GAP - 17.0), 0.0, 1.0)
	return WIRE_Y + 24.0 * u * (1.0 - u)


func _switch_pole(x: float) -> void:
	var anim := "switch_ready"
	var at := clock
	if card == 3 and ct >= 1.6:
		anim = "switch_after"
	elif card == 3 and ct >= 0.9:
		anim = "switch_pull"
		at = ct - 0.9
	sh.draw_anim(self, "intro_poles", anim, at, Vector2(floorf(x), 186.0))


func _dead_pole(px: float, sx: float) -> void:
	if px == 200.0 and _has("title_pole"):
		sh.draw_frame(self, "title_pole", "pole", 1, Vector2(floorf(sx), 186.0), false, NIGHT)
		return
	if not _has("intro_poles"):
		draw_rect(Rect2(sx + 11.0, 196.0, 2.0, 54.0), DARK)
		return
	var f := 0 if px < 200.0 else (1 if px < 480.0 else 2)
	sh.draw_frame(self, "intro_poles", "dead", f, Vector2(floorf(sx - 12.0), 186.0))


func _dead_wire(cam: float) -> void:
	## The wire in pieces: from each insulator a length hangs down to the ground.
	var first := -ceilf((hx + 40.0) / POLE_GAP)
	for k in range(int(first), int(first) + int(vw / POLE_GAP) + 3):
		var sx := hx + 40.0 + POLE_GAP * k - cam
		draw_line(Vector2(sx + 20.0, WIRE_Y), Vector2(sx + 62.0, 246.0), DARK, 1.0)
		draw_line(Vector2(sx + 3.0, WIRE_Y), Vector2(sx - 36.0, 246.0), DARK, 1.0)


# ---------------------------------------------------------------- card 2: a relay station

func _relay_station() -> void:
	_stars(60, 91)
	_strip("far", 160.0, hx - clock * 2.0)
	draw_rect(Rect2(0, 224, vw, 46), DARK)
	if _has("ground"):
		var x := -fposmod(-hx, 16.0) - 16.0
		while x < vw:
			sh.draw_frame(self, "ground", "top", DrawUtil.hash2(int(x), 3) % 4, Vector2(x, 232))
			sh.draw_frame(self, "ground", "mid", DrawUtil.hash2(int(x), 5) % 4, Vector2(x, 248))
			sh.draw_frame(self, "ground", "deep", DrawUtil.hash2(int(x), 7) % 4, Vector2(x, 264))
			x += 16.0
	# the cables run on past the tower to both edges
	for cy in [120.0, 142.0, 162.0]:
		draw_line(Vector2(0, cy), Vector2(hx + 192.0, cy), DrawUtil.GRAY, 1.0)
		draw_line(Vector2(hx + 287.0, cy), Vector2(vw, cy), DrawUtil.GRAY, 1.0)
	if _has("backdrop_w2"):
		sh.draw_frame(self, "backdrop_w2", "pieces", 0, Vector2(hx + 192.0, 104.0))
	var big := ct >= 3.0 and ct < 3.2
	draw_rect(Rect2(hx + 252.0, 220.0, 7.0 if big else 5.0, 6.0 if big else 4.0), DrawUtil.WHITE)
	if ct >= 3.0 and ct < 3.5 and _has("fx_light"):
		sh.draw_anim(self, "fx_light", "ring", ct - 3.0, Vector2(hx + 240.0 - 24.0, 112.0 - 24.0))
	if _has("intro_npc"):
		sh.draw_frame(self, "intro_npc", "listener_sit", 1 if ct >= 2.9 and ct < 3.5 else 0, Vector2(hx + 176.0, 208.0), true)
	# the pulse: a bead with a tail running along the middle cable
	var bx := -1.0
	if ct >= 1.5 and ct < 3.0:
		bx = lerpf(-10.0 - hx, 240.0, (ct - 1.5) / 1.5)
	elif ct >= 3.3 and ct < 4.9:
		bx = lerpf(240.0, 500.0 + hx, (ct - 3.3) / 1.6)
	if bx > -9000.0 and ct >= 1.5 and ct < 4.9 and not (ct >= 3.0 and ct < 3.3):
		# a Pip carrying the voice along the cable, a short trail behind it
		draw_rect(Rect2(floorf(hx + bx - 12.0), 142.0, 6.0, 1.0), DrawUtil.GRAY)
		if _has("pip"):
			sh.draw_anim(self, "pip", "free", ct, Vector2(floorf(hx + bx - 8.0), 142.0 - 9.0))
		else:
			draw_rect(Rect2(floorf(hx + bx - 2.0), 142.0, 3.0, 1.0), DrawUtil.WHITE)


# ---------------------------------------------------------------- cards 6 to 8: the close-up

func _close_cam() -> float:
	if card == 5:
		var u := clampf(ct / 6.0, 0.0, 1.0)
		return floorf(-12.0 * (1.0 - u) * (1.0 - u))   # eases out to 0
	return 0.0


func _close_up() -> void:
	var cam := _close_cam()
	_stars(30, 57)
	_strip("far", 118.0, hx)
	draw_rect(Rect2(0, 182, vw, 88), DARK)
	var ox := hx - cam
	# back grass
	if _has("intro_wire_close"):
		var gx := -fposmod(-ox, 32.0) - 32.0
		while gx < vw:
			sh.draw_frame(self, "intro_wire_close", "grass", DrawUtil.hash2(int(gx - ox), 11) % 4, Vector2(floorf(gx), 190.0))
			gx += 32.0
	# the wire, lit from the tip outward once the Spark flares
	var lit_tiles := 0
	if card == 7:
		for k in 3:
			if ct >= 0.35 + 0.1 * k:
				lit_tiles = k + 1
	if _has("intro_wire_close"):
		var wx := 208.0
		var n := 0
		while ox + wx < vw:
			var lit := n < lit_tiles
			sh.draw_frame(self, "intro_wire_close", "wire_lit" if lit else "wire", 0 if lit else n % 2, Vector2(floorf(ox + wx), 200.0))
			wx += 32.0
			n += 1
		var end_lit := card == 7 and ct >= 0.3
		sh.draw_frame(self, "intro_wire_close", "wire_lit" if end_lit else "wire_end", 1 if end_lit else 0, Vector2(floorf(ox + 176.0), 200.0))
	else:
		draw_rect(Rect2(ox + 180.0, 215.0, vw, 3.0), DARK)
	# the rings (card 7)
	if card == 6:
		for k in 3:
			var leave: float = RINGS[k][0]
			var arrive: float = RINGS[k][1]
			if ct >= leave and ct < arrive:
				var x := 180.0 + 256.0 * (arrive - ct)
				if _has("intro_wire_close"):
					sh.draw_anim(self, "intro_wire_close", "ring", ct, Vector2(floorf(ox + x - 16.0), 200.0))
				else:
					draw_rect(Rect2(floorf(ox + x - 2.0), 214.0, 4.0, 4.0), DrawUtil.GRAY)
			elif ct >= arrive and ct < arrive + 0.15 and _has("intro_wire_close"):
				sh.draw_anim(self, "intro_wire_close", "ring_pop", ct - arrive, Vector2(floorf(ox + 180.0 - 16.0), 200.0))
	# the Spark, close up
	var anim := "curled"
	var frame := -1
	var at := clock
	if card == 6:
		for k in 3:
			if ct >= RINGS[k][1]:
				anim = "stir"
				frame = k
	elif card == 7:
		if ct >= 0.2:
			anim = "flare"
			at = ct - 0.2
			if at >= 0.34:
				anim = "sit"
				at = ct
			elif AppSettings.reduced_flashes:
				frame = 0 if at < 0.17 else 3
		else:
			anim = "stir"
			frame = 2
	var feet := Vector2(ox + 160.0, 226.0)
	if _has("spark_close"):
		var top := feet - Vector2(24.0, 47.0)
		if frame >= 0:
			sh.draw_frame(self, "spark_close", anim, frame, top.floor(), true)
		else:
			sh.draw_anim(self, "spark_close", anim, at, top.floor(), true)
	else:
		J.spark(self, feet, 1, 2.0, 1.0 if anim == "curled" else 2.0, "stand", clock, -1)
	# front grass, leaving the Spark clear
	if _has("intro_wire_close"):
		var gx2 := -fposmod(-ox, 32.0) - 32.0
		while gx2 < vw:
			if gx2 + 32.0 <= ox + 136.0 or gx2 >= ox + 184.0:
				sh.draw_frame(self, "intro_wire_close", "grass", DrawUtil.hash2(int(gx2 - ox), 29) % 4, Vector2(floorf(gx2), 226.0))
			gx2 += 32.0


# ---------------------------------------------------------------- card 8B: awake, at normal size

func _caller_gray(at: Vector2, since: float) -> void:
	if not _has("title_caller"):
		return
	var anim := "blink_gray" if sh.tex.has("title_caller") and preload("res://scripts/world1/sheet_data.gd").SHEETS["title_caller"].anims.has("blink_gray") else "blink"
	var f := 0 if since < 0.0 else sh.frame_at("title_caller", anim, 3.0 + since, true)   # skip the long dark hold: blink now
	sh.draw_frame(self, "title_caller", anim, f, at)


func _awake() -> void:
	_stars(60, 91)
	_strip("far", 160.0, hx + 186.0)
	var since := ct - 3.0
	_caller_gray(Vector2(hx + 389.0, 163.0), since)
	draw_rect(Rect2(0, 224, vw, 46), DARK)
	_ground_row(232.0, 0.0, vw)
	if _has("intro_poles"):
		sh.draw_frame(self, "intro_poles", "dead", 1, Vector2(hx + 300.0 - 12.0, 186.0))
	# the wire: lies on the ground from the tip to the fallen pole, then on east
	var tip := hx + 212.0
	draw_line(Vector2(tip, 231.0), Vector2(hx + 290.0, 231.0), DARK, 1.0)
	draw_line(Vector2(tip, 231.0), Vector2(hx + 260.0, 231.0), DrawUtil.GRAY, 1.0)
	draw_line(Vector2(hx + 290.0, 231.0), Vector2(hx + 320.0, WIRE_Y), DARK, 1.0)
	var last := Vector2(hx + 320.0, WIRE_Y)
	for sxi in range(int(hx + 322.0), int(vw) + 2, 2):
		var p := Vector2(float(sxi), _sag(float(sxi) - hx))
		draw_line(last, p, DARK, 1.0)
		last = p
	var hop := 0.0
	if ct >= 3.3 and ct < 3.6:
		hop = 6.0 * sin((ct - 3.3) / 0.3 * PI)
	J.spark(self, Vector2(hx + 204.0, 232.0 - hop).floor(), 1, 1.0, 1.0, "air" if hop > 0.0 else "stand", clock, 1)


func _ground_row(top: float, x0: float, x1: float) -> void:
	if not _has("ground"):
		draw_rect(Rect2(x0, top, x1 - x0, 270.0 - top), DARK)
		return
	var x := x0
	while x < x1:
		var y := top
		var row := "top"
		while y < 270.0:
			sh.draw_frame(self, "ground", row, DrawUtil.hash2(int(x - hx), int(y)) % 4, Vector2(floorf(x), y), false, NIGHT)
			row = "mid" if row == "top" else "deep"
			y += 16.0
		x += 16.0


# ---------------------------------------------------------------- card 9: up the hill to Last Relay

const SPARK9 := [Vector3(0.0, 24, 240), Vector3(1.8, 104, 240), Vector3(2.15, 142, 224), Vector3(2.5, 174, 208), Vector3(2.85, 212, 192)]
const MAST9 := [Vector3(0.0, 400, 128), Vector3(0.6, 400, 128), Vector3(2.1, 334, 128), Vector3(2.9, 304, 144), Vector3(3.7, 272, 160), Vector3(4.5, 248, 176)]


func _spark9() -> Vector2:
	var p := J.path(ct, SPARK9)
	if ct >= 1.8 and ct < 2.85:
		var k := int((ct - 1.8) / 0.35)
		var a: Vector3 = SPARK9[1 + k]
		var b: Vector3 = SPARK9[2 + k]
		p = J.arc(Vector2(a.y, a.z), Vector2(b.y, b.z), 8.0, (ct - a.x) / 0.35)
	if ct >= 5.0 and ct < 5.3:
		p.y -= 6.0 * sin((ct - 5.0) / 0.3 * PI)
	return p


func _mast9() -> Vector2:
	return J.path(ct, MAST9)


func _hill() -> void:
	_stars(60, 91)
	_strip("far", 160.0, hx)
	draw_rect(Rect2(0, 224, vw, 46), DARK)
	# flat ground, seven steps up, then the top running on to the right
	_ground_row(240.0, 0.0, hx + 128.0)
	for k in range(1, 8):
		_ground_row(240.0 - 16.0 * k, hx + 128.0 + 32.0 * (k - 1), hx + 128.0 + 32.0 * k)
	_ground_row(128.0, hx + 352.0, vw)
	# poles on the steps and the wire up to the house
	var poles := [Vector2(72, 177), Vector2(200, 129), Vector2(328, 65)]
	for p in poles:
		if _has("title_pole"):
			sh.draw_frame(self, "title_pole", "pole", 0, Vector2(hx + p.x, p.y), false, NIGHT)
	var pts := [Vector2(0.0, 181.0), Vector2(hx + 72.0 + 3.0, 181.0), Vector2(hx + 72.0 + 20.0, 181.0),
		Vector2(hx + 203.0, 133.0), Vector2(hx + 220.0, 133.0), Vector2(hx + 331.0, 69.0), Vector2(hx + 348.0, 69.0), Vector2(hx + 372.0, 84.0)]
	for i in range(1, pts.size()):
		draw_line(pts[i - 1], pts[i], DrawUtil.GRAY, 1.0)
	if _has("intro_far"):
		sh.draw_anim(self, "intro_far", "keeper_night", clock, Vector2(hx + 368.0, 64.0))
	elif _has("house"):
		sh.draw_frame(self, "house", "facades", 0, Vector2(hx + 368.0, 64.0))
	# Old Mast comes out with a lantern and walks down to meet the Spark
	if ct >= 0.6:
		var m := _mast9()
		var walking := ct < 4.5
		if _has("intro_npc"):
			sh.draw_anim(self, "intro_npc", "mast_lantern_walk" if walking else "mast_lantern_stand", clock, Vector2(hx + m.x - 8.0, m.y - 24.0).floor())
		elif _has("npc"):
			sh.draw_anim(self, "npc", "mast_idle", clock, Vector2(hx + m.x - 8.0, m.y - 24.0).floor())
	var s := _spark9()
	var pose := "run" if ct < 1.8 else ("air" if ct < 2.85 or (ct >= 5.0 and ct < 5.3) else "stand")
	J.spark(self, Vector2(hx + s.x, s.y).floor(), 1, 1.0, 1.0, pose, clock, 1)


# ---------------------------------------------------------------- card 10: out of the window, east

func _window() -> void:
	_stars(80, 33)
	_strip("far", 150.0, hx + 140.0)
	var since := -1.0
	if ct >= 4.7:
		since = ct - 4.7
	elif ct >= 2.5:
		since = ct - 2.5
	_caller_gray(Vector2(hx + 343.0, 153.0), since)
	if _has("intro_far"):
		sh.draw_frame(self, "intro_far", "gate_far", 0, Vector2(hx + 270.0, 136.0))
	draw_rect(Rect2(0, 214, vw, 56), DARK)
	# the line running east on tiny poles
	var ticks := [[120, 214], [170, 211], [216, 208], [258, 205], [296, 203], [330, 201]]
	var last := Vector2(hx + 92.0, 214.0)
	for t in ticks:
		var top := Vector2(hx + float(t[0]), float(t[1]) - 6.0)
		draw_rect(Rect2(top.x, top.y, 1, 6), DARK)
		draw_rect(Rect2(top.x - 1.0, top.y, 3, 1), DARK)
		draw_line(last, top, DrawUtil.GRAY, 1.0)
		last = top
	draw_line(last, Vector2(hx + 388.0, 199.0), DrawUtil.GRAY, 1.0)
	# the room around the window
	draw_rect(Rect2(0, 0, hx + 92.0, 270), DrawUtil.BG)
	draw_rect(Rect2(hx + 388.0, 0, vw, 270), DrawUtil.BG)
	draw_rect(Rect2(0, 0, vw, 74), DrawUtil.BG)
	draw_rect(Rect2(0, 214, vw, 56), DrawUtil.BG)
	if _has("intro_window"):
		sh.draw_frame(self, "intro_window", "frame", 0, Vector2(hx + 80.0, 64.0))
	else:
		draw_rect(Rect2(hx + 88.0, 214.0, 304.0, 6.0), DARK)
	var hop := 0.0
	if ct >= 2.8 and ct < 3.1:
		hop = 6.0 * sin((ct - 2.8) / 0.3 * PI)
	J.spark(self, Vector2(hx + 150.0, 214.0 - hop).floor(), 1, 1.0, 1.0, "air" if hop > 0.0 else "stand", clock, 1)


# ---------------------------------------------------------------- text and the skip bar

func _text_done_at() -> float:
	var c: Dictionary = CARDS[card]
	if card == 6:
		return 5.05
	if card == 7:
		return 2.9 + float(str(c.lines[1]).length()) / 40.0
	return float(c.in) + float(str(c.lines[0]).length() + str(c.lines[1]).length()) / 40.0 + 0.25


func _shown(line: int) -> String:
	var c: Dictionary = CARDS[card]
	var s := str(c.lines[line])
	if typed_full:
		return s
	var start := float(c.in)
	if card == 6 and line == 1:
		# typed in step with the rings
		var parts := ["ONCE .", "ONCE . TWICE .", "ONCE . TWICE . THREE TIMES"]
		var shown := ""
		for k in 3:
			if ct >= RINGS[k][1]:
				shown = parts[k]
		return shown
	if card == 7 and line == 1:
		start = 2.9
	elif line == 1:
		start = float(c.in) + float(str(c.lines[0]).length()) / 40.0 + 0.25
	return s.substr(0, clampi(int((ct - start) * 40.0), 0, s.length()))


func _draw_text() -> void:
	var c: Dictionary = CARDS[card]
	if ct < float(c.in) and not typed_full:
		return
	var out := float(c.out)
	if ct >= out + 0.12:
		return
	var col := DARK if ct >= out else DrawUtil.GRAY
	for i in 2:
		var s := _shown(i)
		if s == "":
			continue
		var full := str(c.lines[i])
		var x := floorf(vw / 2.0 - DrawUtil.text_width(full, 2) / 2.0)   # lines grow from a fixed left edge
		DrawUtil.text_shadow(self, Vector2(x, 28.0 + 16.0 * i), s, col, 2)


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
