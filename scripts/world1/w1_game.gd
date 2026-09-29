extends Node2D
## World 1: the playable mode. Runs the proven rules in w1_sim.gd and draws them
## with the World 1 art, sound and effects. Keys: arrows/A-D move, Space/W/Up
## jump, Shift dash, Down/S enter pipe, Esc/P pause, R restart, F screen
## shader, 0-4 jump to test room or 1-1 to 1-4 (from the pause screen).

const Level := preload("res://scripts/world1/w1_level.gd")
const Sim := preload("res://scripts/world1/w1_sim.gd")
const Sheets := preload("res://scripts/world1/sheets.gd")
const ScreenFit := preload("res://scripts/screen_fit.gd")
const J := preload("res://scripts/world1/juice.gd")
const T := 16.0
const ROWS := 17

const ORDER := ["test-room", "1-1", "1-2", "1-3", "1-4", "2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "3-3", "3-4"]
## Each level's 8-bit loop (assets/audio/sfx8/). A level header can name another with `music:`.
const MUSIC8 := {
	"test-room": "m_training", "1-1": "m_1_1", "1-1-bonus": "m_1_1_bonus",
	"1-2": "m_1_2", "1-3": "m_1_3", "1-4": "m_1_4",
	"2-1": "m_2_1", "2-2": "m_2_2", "2-3": "m_2_3", "2-4": "m_2_4",
	"3-1": "m_3_1", "3-2": "m_3_2", "3-3": "m_3_3", "3-4": "m_3_4",
}
const START_LIVES := 5
const MUSIC_DB := -9.0   # the 8-bit loops are mono at full level
const SFX_TRIM := -5.0   # effects sat too loud over the 8-bit music
## Each world's four colours, darkest first. The art is drawn in four greys and
## the atmosphere pass maps them onto these (shaders/world1/world_fx.gdshader).
const TINTS := {
	"test": [Color("#0b0b0b"), Color("#3a3a3a"), Color("#8a8a8a"), Color("#f2f2f2")],
	"1": [Color("#0a0c12"), Color("#343c4d"), Color("#8190a8"), Color("#eef2f8")],   # cold first light
	"2": [Color("#0f0a05"), Color("#4a3418"), Color("#b8863a"), Color("#fcebc4")],   # sodium lamps
	"3": [Color("#0c0a12"), Color("#3a3150"), Color("#9b8bb4"), Color("#f5effb")],   # violet dawn
	"village": [Color("#0d0907"), Color("#473226"), Color("#b08866"), Color("#f7e8d2")],   # warm windows
}
const AMBIENCE := {"1": "amb_w1", "2": "amb_w2", "3": "amb_w3", "village": "amb_village"}
const STORY_PATH := "res://levels/story/npcs.json"
## Tally's shop. Prices are in shards. The lantern is kept for good. (The shard
## compass used to be sold here; it is now the Pip tuner, one of Dot's gifts.)
const SHOP := [
	{"id": "life", "name": "EXTRA LIFE", "price": 40, "icon": 0, "note": "GIVES YOU ONE MORE LIFE."},
	{"id": "charge", "name": "CHARGED START", "price": 25, "icon": 1,
		"note": "START YOUR NEXT LEVEL WITH CHARGE, SO YOU CAN SURVIVE ONE HIT."},
	{"id": "lantern", "name": "LANTERN", "price": 60, "icon": 3,
		"note": "YOUR LIGHT REACHES MUCH FURTHER IN THE DARK. YOURS TO KEEP."},
]
const CAM_LEAD := 32.0         # px the camera looks ahead of a running Spark
const CAM_LEAD_SPEED := 40.0   # px per second the look-ahead drifts
const CAM_DEAD_ZONE := 16.0    # px the Spark can move before the camera follows

var sh: Sheets
var L: Level
var S: Sim
var level_id := "test-room"
var lives := START_LIVES
var shards := 0
var earned := 0            # shards collected this game, spent or not: every 100 is a free life
var life_note_t := -99.0   # when the last 100-shard life was given, for the banner
var handoff := -1.0        # seconds since the intro handed over, while the Spark wakes by Old Mast
var lantern_talk := false  # Old Mast holds his lantern through that first talk
var big := {}             # level id -> {"c,r": true}: the Pips set free (the `O` tiles, once big shards)
var best := {}            # level id -> seconds
var time_left := 300.0
var run_time := 0.0
var warned := false
var state := "card"       # card, play, dead, clear, pipe, gameover, pause, done
var state_t := 0.0
var pause_from := "play"
var cam_x := 0.0
var cam_lead := 0.0
var cam_y := 0.0           # tall levels scroll up and down too
var clock := 0.0
var shake := 0.0
var hitstop := 0
var fx: Array = []        # [kind, pos, start clock, seed, extra]
var ghosts: Array = []    # [pos, start clock, sx, sy]
var anims := {}           # key -> start clock (springs, rings, plates...)
var spawn_at := Vector2i(-1, -1)
var return_to := {}       # {"level": id, "cell": Vector2i} when inside a bonus room
var bonus_keep := {}      # bonus room id -> what was taken there, until this life ends
var pipe_travel := false  # load_level is moving through a pipe, not starting afresh
var clear_from_y := 0.0
var clear_bonus := ""
var clear_paid := false
var sfx := {}
var sfx_players: Array = []
var music: AudioStreamPlayer
var music_fade: Tween
var relay_hum: AudioStreamPlayer
var arm_whir: AudioStreamPlayer   # World 3 sweep arms on screen
var in_updraft := false
var ground_sheet := "ground"   # World 2 swaps in its own ground and blocks
var block_sheet := "block"
var post: ColorRect
var seed_n := 1
var progress_path := "user://w1_progress.json"   # captures and tests use their own
var pause_page := "main"   # main, settings, levels
var pause_sel := 0
var save := {}             # {"level", "lives", "shards"}: where CONTINUE starts
var unlocked: Array = ["test-room"]
var filter_on := true
var saved_t := -9.0        # clock when the game last saved, for the HUD note
## How the title screen started this scene: "continue" or "new".
static var start_mode := "continue"
static var intro_handoff := false   # set by the story intro: wake up next to Old Mast
static var progress_override := ""  # tests that reach the game through a scene change use their own save
var fxmat: ShaderMaterial   # the atmosphere pass
var lamps_lit := {}         # lamp cell -> clock it lit
var flash_t := -9.0         # clock of the last lightning strike
var next_flash := 0.0
var ambience: AudioStreamPlayer
var story := {}             # levels/story/npcs.json
var flags: Array = []       # story flags: met_<id>, w1_clear, w2_clear
var items := {}             # shop items kept for good: lantern (and compass, from older saves)
var gifts: Array = []       # Dot's gifts for Pips brought home; kept through New Game, like the Pips
var pip_call_t := -9.0      # clock when a trapped Pip last called out
var charge_next := false    # bought a charged start for the next level
var here: Array = []        # the people standing in this level
var talk := {}              # the conversation in progress
var shop_sel := 0
var voice: AudioStreamPlayer
var down_prev := false
var up_prev := false
var hold_jump := false      # ignore a jump still held from closing a bubble
var board_open := false     # the level list was opened from the switchboard
var stick_held := {}        # pad axis -> pushed past halfway, so one push is one menu step
var level_info := {}        # level id -> {name, big}, read once for the switchboard
var ui_clear: Array = []    # screen rects of text, menus and bubbles, which the dark must not cover
var world_off := Vector2.ZERO   # where the level is drawn this frame: -camera plus shake
var dither: ImageTexture   # 2x2 checker of DARK, for far silhouettes
var fx_rect: ColorRect
const NPC_LIFT := Color(1.4, 1.4, 1.4)        # villagers a step brighter than the grey world around them
const INTERIOR_DIM := Color(0.45, 0.45, 0.45)   # house walls sit back so the people in front read clearly
var vw := 480.0           # view width: 480 on 16:9, up to 720 on wide screens
var hx := 0.0             # left edge of the centred 480 px column for the HUD and menus


func _ready() -> void:
	sh = Sheets.new()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(0, 0, DrawUtil.DARK)
	img.set_pixel(1, 1, DrawUtil.DARK)
	dither = ImageTexture.create_from_image(img)
	RenderingServer.set_default_clear_color(DrawUtil.BG)
	for n in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/sfx8/manifest.json"))
	for s in man.sounds:
		sfx[s.name] = load("res://assets/audio/sfx8/" + str(s.file))
	relay_hum = AudioStreamPlayer.new()
	relay_hum.bus = "SFX"
	relay_hum.volume_db = -4.0 + SFX_TRIM
	if sfx.has("relay_hum"):
		var hum: AudioStream = sfx["relay_hum"]
		if hum is AudioStreamWAV and hum.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			hum.loop_mode = AudioStreamWAV.LOOP_FORWARD
			hum.loop_begin = 0
			hum.loop_end = int(hum.get_length() * hum.mix_rate)
		relay_hum.stream = hum
	add_child(relay_hum)
	voice = AudioStreamPlayer.new()
	voice.bus = "SFX"
	voice.volume_db = -4.0 + SFX_TRIM
	add_child(voice)
	var st_data = JSON.parse_string(FileAccess.get_file_as_string(STORY_PATH))
	if st_data is Dictionary:
		story = st_data
	arm_whir = AudioStreamPlayer.new()
	arm_whir.bus = "SFX"
	arm_whir.volume_db = -14.0 + SFX_TRIM
	if sfx.has("arm_whir"):
		var wh: AudioStream = sfx["arm_whir"]
		if wh is AudioStreamWAV and wh.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wh.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wh.loop_end = int(wh.get_length() * wh.mix_rate)
		arm_whir.stream = wh
	add_child(arm_whir)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = MUSIC_DB
	add_child(music)
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 9
	add_child(fx_layer)
	fx_rect = ColorRect.new()
	fx_rect.size = Vector2(480, 270)
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fxmat = ShaderMaterial.new()
	fxmat.shader = load("res://shaders/world1/world_fx.gdshader")
	fx_rect.material = fxmat
	fx_layer.add_child(fx_rect)
	ambience = AudioStreamPlayer.new()
	ambience.bus = "SFX"
	ambience.volume_db = -12.0
	add_child(ambience)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var copy := BackBufferCopy.new()   # the CRT pass reads the tinted picture
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	layer.add_child(copy)
	post = ColorRect.new()
	post.size = Vector2(480, 270)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/world1/signal_crt.gdshader")
	post.material = mat
	layer.add_child(post)
	get_tree().root.size_changed.connect(_fit_screen)
	_fit_screen()
	if progress_override != "":
		progress_path = progress_override
	_load_progress()
	post.visible = filter_on
	if start_mode == "continue" and not save.is_empty() and FileAccess.file_exists(Level.path_for(str(save.level))):
		lives = int(save.get("lives", START_LIVES))
		shards = int(save.get("shards", 0))
		earned = int(save.get("earned", shards))
		load_level(str(save.level))
	else:
		# a new game: the story and Tally's items start again. Pips, Dot's gifts and best times stay.
		save = {}
		lives = _start_lives()
		if start_mode == "new":
			flags = []
			items = {}
			charge_next = false
		if intro_handoff:
			# straight from the story intro: the Spark lies by Old Mast and he speaks first
			intro_handoff = false
			load_level("village", Vector2i(7, 13), false)
			handoff = 0.0
		else:
			load_level("village")  # a new game starts in Last Relay
	start_mode = "continue"


# ================================================================ levels

func load_level(id: String, cell := Vector2i(-1, -1), card := true) -> void:
	level_id = id
	board_open = false
	if not pipe_travel:
		bonus_keep.clear()
	L = Level.load_file(id)
	# Worlds 2 and 3 swap in their own ground and blocks
	var wn := _world()
	ground_sheet = "ground_w%s" % wn if wn in ["2", "3"] and _has_sheet("ground_w%s" % wn) else "ground"
	block_sheet = "block_w%s" % wn if wn in ["2", "3"] and _has_sheet("block_w%s" % wn) else "block"
	if relay_hum:
		relay_hum.stop()
	if arm_whir:
		arm_whir.stop()
	in_updraft = false
	if ORDER.has(id) or id == "village":
		_write_save(id)  # autosave at the start of every level
	lamps_lit.clear()
	next_flash = clock + 4.0
	var tint: Array = TINTS["test"] if id == "test-room" else TINTS.get(_world(), TINTS["test"])
	for k in 4:
		fxmat.set_shader_parameter("ramp%d" % k, tint[k])
	var amb: String = AMBIENCE.get(_world(), "")
	if sfx.has(amb) and (ambience.stream != sfx[amb] or not ambience.playing):
		var st: AudioStream = sfx[amb]
		if st is AudioStreamWAV and st.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_end = int(st.get_length() * st.mix_rate)
		ambience.stream = st
		ambience.play()
	spawn_at = cell
	time_left = _level_time()
	run_time = 0.0
	warned = false
	_reset_sim(false)
	_pick_people()
	if charge_next and ORDER.has(id) and id != "test-room":
		S.charged = true  # Tally's charged start
		charge_next = false
		_save_progress()
	# music is the level's 8-bit loop; a level without one is quiet
	var want := str(L.meta.get("music", MUSIC8.get(id, "")))
	var mstream: AudioStream = sfx.get(want)
	if mstream is AudioStreamWAV and mstream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		mstream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		mstream.loop_end = int(mstream.get_length() * mstream.mix_rate)
	if music_fade:
		music_fade.kill()
		music_fade = null
	music.volume_db = MUSIC_DB
	if mstream == null:
		music.stop()
		music.stream = null
	elif music.stream != mstream or not music.playing:
		music.stream = mstream
		music.play()
	_set_state("card" if card else "play")


func _reset_sim(keep_checkpoint: bool) -> void:
	var lit: bool = keep_checkpoint and S != null and S.lit
	S = Sim.new(L)
	S.lit = lit
	var at: Vector2i = L.start
	if spawn_at.x >= 0:
		at = spawn_at
	if lit and L.midway.x >= 0:
		at = L.midway
	S.place(at)
	cam_x = _cam_target(true)
	cam_y = _cam_y_target(true)
	fx.clear()
	ghosts.clear()
	anims.clear()


## Seconds on the clock. The village has no clock, so it never runs out.
func _level_time() -> float:
	return 999.0 if str(L.meta.get("hub", "")) != "" else float(L.meta.get("time", "300"))


## "1" or "2": the world this level belongs to (the test room counts as World 1).
## The village and its houses are "village".
func _world() -> String:
	if level_id.begins_with("village"):
		return "village"
	var w := level_id.get_slice("-", 0)
	return w if w.is_valid_int() else "1"


func _set_state(s: String) -> void:
	if state == "pause" and s != "pause":
		hold_jump = true   # a jump pressed to leave the menu is not a jump
	if s != "play":
		# the looping machine sounds only check themselves during play
		if relay_hum and relay_hum.playing:
			relay_hum.stop()
		if arm_whir and arm_whir.playing:
			arm_whir.stop()
	state = s
	state_t = 0.0


# ================================================================ frame

func _physics_process(delta: float) -> void:
	clock += delta
	if ScreenFit.stale(get_tree().root):
		_fit_screen()
	state_t += delta
	if handoff >= 0.0 and state != "pause":
		_handoff_frame(delta)
	if lantern_talk and state != "talk":
		lantern_talk = false
	shake = maxf(0.0, shake - delta * 18.0)
	match state:
		"card":
			if state_t > 1.6:
				_set_state("play")
		"play":
			_play_frame(delta)
		"talk":
			_talk_frame(delta)
		"shop":
			_shop_frame()
		"dead":
			if state_t > 1.1:
				if not _is_hub():
					lives -= 1
				if lives <= 0:
					_fade_music()
					_play("game_over")
					_set_state("gameover")
				else:
					time_left = _level_time()
					warned = false
					bonus_keep.clear()   # a new life finds the bonus room full again
					_reset_sim(true)
					_restart_music()
					_set_state("card")
		"gameover":
			if state_t > 3.4:
				lives = _start_lives()
				shards = 0
				earned = 0
				load_level("test-room" if level_id == "test-room" else "village")
		"clear":
			_clear_frame()
		"pipe":
			S.y += 0.6
			if state_t > 0.6:
				_enter_pipe()
		"done":
			if _world() == "1" and state_t - delta <= 1.6 and state_t > 1.6:
				_play("arc_learn")
			if state_t > (7.0 if _world() == "1" else 5.0):
				load_level("village")  # a world cleared: back to Last Relay
	if state == "card":
		cam_x = _cam_target(true)
		cam_y = _cam_y_target(true)
	else:
		_follow_camera(delta)
	_update_atmosphere()
	queue_redraw()


## After the intro: black, a circle opens on the Spark lying in the grass by
## Old Mast, it gets up, and his first talk opens by itself.
func _handoff_frame(delta: float) -> void:
	var before := handoff
	handoff += delta
	if before < 1.1 and handoff >= 1.1:
		_play("land_soft", 0.0, -6.0)
		_fx("dust", Vector2(S.x, S.y + 7.0))
	if handoff >= 1.4:
		handoff = -1.0
		for n in here:
			if str(n.id) == "mast":
				lantern_talk = true
				_start_talk(n)
				break


func _play_frame(delta: float) -> void:
	if handoff >= 0.0:
		return   # nothing moves until Old Mast has spoken
	if hitstop > 0:
		hitstop -= 1
		return
	var tap_down := _down_pressed()
	if tap_down:
		var u := _usable()
		if not u.is_empty():
			_use(u)
			return
	var dir := int(signf(Input.get_axis("move_left", "move_right")))
	var jump := Input.is_action_pressed("jump")
	if hold_jump:
		hold_jump = jump
		jump = false
	var dash := Input.is_action_just_pressed("dash")
	var down := Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) \
		or Input.is_joy_button_pressed(_pad(), JOY_BUTTON_DPAD_DOWN) or Input.get_joy_axis(_pad(), JOY_AXIS_LEFT_Y) > 0.6
	S.can_arc = _has_arc()
	S.arc_press = Input.is_action_just_pressed("attack")
	var prev_t: int = S.t
	S.advance(dir, jump, dash, down)
	S.update_walkers()
	if level_id == "village" and dir > 0 and S.x >= (L.width - 2) * T:
		# walking on east past the signpost follows the line to the next level
		_play("door_open")
		load_level(_next_level())
		return
	while not S.bumps.is_empty() and S.t - int(S.bumps[0][1]) > 12:
		S.bumps.pop_front()   # the hop is over; the list is read for every block on screen
	if S.dash_t > 0.0 and S.t % 2 == 0:
		ghosts.append([Vector2(S.x, S.y + 7.0), clock, S.sx_anim, S.sy_anim])
	for e in S.events:
		_on_event(e)
	_machine_sounds(prev_t)
	_pip_calls()
	if not _is_hub():
		time_left -= delta
	run_time += delta
	if time_left <= 100.0 and not warned:
		warned = true
		_play("timer_warning")
	if time_left <= 0.0 and S.dead == "":
		S.charged = false
		S.hurt("fell")
		_on_event({"k": "death", "x": S.x, "y": S.y})
	if S.won:
		clear_from_y = S.y
		clear_paid = false
		_fade_music()
		_set_state("clear")
	elif S.dead != "":
		_fade_music()
		_set_state("dead")


func _clear_frame() -> void:
	var base: float = (L.goal.y + 1) * T - 7.0
	if state_t < 1.0:
		S.x = L.goal.x * T + 4.0
		S.y = lerpf(clear_from_y, base, state_t)
		S.face = 1
	elif not clear_paid:
		clear_paid = true
		_play("level_clear")
		var h: float = S.won_height
		# the higher up the mast you touched it, the bigger the bonus, shown where you touched it
		var touch := Vector2(L.goal.x * T + 8.0, clear_from_y)
		if h > 0.85:
			lives += 1
			clear_bonus = "TIP OF THE MAST . 1UP"
			_play("extra_life")
			_fx("big_text", touch, "1UP")
		else:
			var n := 1 + int(h * 9.0)
			_add_shards(n)
			clear_bonus = "MAST BONUS . %d SHARDS" % n
			_fx("big_text", touch, "+%d" % n)
		if not best.has(level_id) or run_time < float(best[level_id]):
			best[level_id] = run_time
		if not flags.has("clear_" + level_id):
			flags.append("clear_" + level_id)   # this game's progress: New Game clears it, best times stay
		_save_progress()
	elif state_t < 3.2:
		S.x += 1.2
		S.y = base
		S.anim_t += 0.2
	else:
		var i := ORDER.find(level_id)
		if level_id.ends_with("-4"):
			var flag := "w%s_clear" % _world()
			if not flags.has(flag):
				flags.append(flag)
			if _world() == "1":
				items["arc"] = true   # World 1's reward: the Arc
			_save_progress()
			_play("world_clear")
			_set_state("done")
		elif i >= 0 and i + 1 < ORDER.size():
			load_level(ORDER[i + 1])
		else:
			load_level("1-1")


func _enter_pipe() -> void:
	var charged: bool = S.charged   # Charge goes through the pipe with you
	pipe_travel = true
	if level_id.ends_with("-bonus"):
		# what was taken here stays taken if you come back down the pipe this life
		bonus_keep[level_id] = {"taken": S.taken.duplicate(), "tiles": S.tiles.duplicate(), "killed": S.killed.keys()}
		if not return_to.is_empty():
			var back: Dictionary = return_to
			return_to = {}
			load_level(back.level, back.cell, false)
			_restore_level(back)
			spawn_at = Vector2i(-1, -1)   # the pipe exit is not a checkpoint
		else:
			# no remembered entry point: use the exit the bonus room's pipe names
			var bp: Dictionary = L.pipes[0] if L.pipes.size() > 0 else {}
			load_level(str(bp.get("to", "1-1")), Vector2i(int(bp.get("to_c", 2)), int(bp.get("to_r", 13))), false)
		S.charged = S.charged or charged
		pipe_travel = false
		return
	var target := ""
	var back_cell := Vector2i(-1, -1)
	for p in L.pipes:
		if absf(S.x - (int(p.c) * T + 16.0)) < 20.0:
			target = str(p.get("to", ""))
			# come back out on the ground just past the pipe
			var bc := int(p.c) + 3
			back_cell = Vector2i(bc, L.floor_below(bc, int(p.r)) - 1)
	if target == "":
		pipe_travel = false
		_set_state("play")
		return
	return_to = {"level": level_id, "cell": back_cell, "taken": S.taken.duplicate(), "tiles": S.tiles.duplicate(),
		"killed": S.killed.keys(), "lit": S.lit, "time_left": time_left, "run_time": run_time}
	load_level(target, Vector2i(-1, -1), false)
	if bonus_keep.has(target):
		var kept: Dictionary = bonus_keep[target]
		S.taken = kept.taken.duplicate()
		S.tiles = kept.tiles.duplicate()
		for n in kept.killed:
			S.killed[n] = -100000
	S.charged = S.charged or charged
	pipe_travel = false


## Back out of a bonus room: the level is as you left it, with the shards you
## took gone, used blocks still used, beaten enemies still gone and the clock
## where it was.
func _restore_level(back: Dictionary) -> void:
	if not back.has("taken"):
		return
	S.taken = back.taken
	S.tiles = back.tiles
	for n in back.killed:
		S.killed[n] = -100000
	S.lit = back.lit
	time_left = back.time_left
	run_time = back.run_time


# ================================================================ events

func _on_event(e: Dictionary) -> void:
	var k: String = e.k
	var pos := Vector2(float(e.get("x", S.x)), float(e.get("y", S.y)))
	match k:
		"jump", "wall_kick", "dash", "land_soft":
			_play(k)
			if k == "wall_kick":
				_fx("dust", pos)
		"land_hard":
			_play(k)
			_fx("dust", pos)
			shake = maxf(shake, 2.0)
		"drop":
			_play("land_soft", 0.0, -4.0)
			_fx("dust", pos)
		"stomp":
			_play("stomp_%d" % mini(int(e.chain), 3))
			_fx("stomp", pos)
			hitstop = 3
			shake = maxf(shake, 3.0)
		"walker_squish":
			_play("walker_squish")
			_fx("stomp", pos)
		"arc":
			_play("arc_swing")
			anims["arc"] = clock
		"arc_hit":
			_play("arc_hit")
			_fx("arc_hit", pos)
			hitstop = maxi(hitstop, 3)
			shake = maxf(shake, 1.5)
		"wall_break":
			_play("wall_break")
			_fx("crack_break", pos)
			_fx("debris", pos)
			shake = maxf(shake, 3.0)
		"walker_drop":
			_play_at("walker_squish", pos)
		"spiky_knock":
			_play("spiky_knock")
			_fx("stomp", pos)
			shake = maxf(shake, 2.0)
		"spiky_hurt":
			_play("spiky_hurt")
		"channel_switch":
			_play("channel_switch")
			anims["channel"] = clock
			shake = maxf(shake, 1.0)
		"channel_arm":
			_play("channel_arm")
		"channel_swap":
			_play_at("channel_swap", Vector2(float(L.relay.c) * T, 0))
			anims["channel"] = clock
		"fuse_blow":
			_play("fuse_blow")
			_fx("burst", pos)
			shake = maxf(shake, 3.0)
		"relay_overload":
			_play("relay_overload")
			_play("relay_down", 1.5)
			shake = maxf(shake, 6.0)
			relay_hum.stop()
		"bump_block", "bump_used":
			_play(k)
		"brick_break":
			_play(k)
			_fx("debris", pos)
			shake = maxf(shake, 2.0)
		"shard":
			_play("shard")
			_add_shards(1)
			_fx("sparkle", pos)
		"big_shard":
			# (the rules still call it a big shard, so the proven levels stay proven)
			var cell: Vector2i = e.cell
			if _pip_home_at(cell.x, cell.y):
				return   # this Pip is already home with Dot
			if not big.has(level_id):
				big[level_id] = {}
			big[level_id]["%d,%d" % [cell.x, cell.y]] = true
			_play("pip_free")
			_fx("pip_break", Vector2(cell.x * T, cell.y * T))
			_fx("pip_fly", pos)
			_fx("light", pos)
			_fx("text", pos, "PIP SET FREE . %d OF %d HOME" % [_pips_home(), _pips_total()])
			_save_progress()
		"extra_life":
			lives += 1
			_play("extra_life")
			_fx("text", pos, "1UP")
		"charge_get":
			_play("charge_get")
			_fx("light", pos)
			_fx("text", pos, "CHARGE")
		"charge_lose":
			_play("charge_lose")
			_fx("burst", pos)
			shake = maxf(shake, 4.0)
		"death":
			_play("death")
			_fx("burst", pos)
			shake = maxf(shake, 5.0)
		"spring":
			_play("spring")
			anims["spring:%d" % int(pos.x)] = clock
		"lift_ring":
			_play("lift_ring")
			_fx("light", pos)
		"checkpoint":
			_play("checkpoint")
			_fx("light", pos + Vector2(0, -8))
		"mast_touch":
			_play("mast_touch")
			_play("mast_slide", 0.25)
		"loose_floor_shake", "loose_ceiling_crack", "dropper_tell", "plate_click", "lever_pull":
			_play_at(k, pos)
		"loose_floor_fall", "loose_ceiling_fall":
			_play_at(k, pos)
		"loose_floor_land", "loose_ceiling_land":
			_play_at(k, pos)
			_fx("dust", pos)
		"dropper_slam":
			_play_at(k, pos)
			_fx("dust", pos)
			shake = maxf(shake, 4.0)
		"gate_open", "gate_close":
			_play(k)
		"bridge_collapse":
			_play(k)
			shake = maxf(shake, 4.0)
		"warden_fall":
			_play("warden_fall")
		"pipe":
			_play("bump_used")
			S.x = float(e.pipe.c) * T + 16.0
			_set_state("pipe")


func _machine_sounds(prev_t: int) -> void:
	## Presses, vents and hoppers only make noise when they are on screen.
	for p in L.presses:
		if not _on_screen(float(p.x)):
			continue
		var a: float = S.press_s(p, prev_t)
		var b: float = S.press_s(p, S.t)
		if a < 0.0 or b < 0.0:
			continue
		var rest := float(p.period) - 1.07
		if a < rest - 0.3 and b >= rest - 0.3:
			_play("press_shake", 0.0, -6.0)
		if a < rest + 0.12 and b >= rest + 0.12:
			_play("press_slam")
			shake = maxf(shake, 2.0)
	for v in L.vents:
		if not _on_screen(float(v.x)):
			continue
		var a2: float = S.vent_phase(v, prev_t)
		var b2: float = S.vent_phase(v, S.t)
		if a2 < 0.45 and b2 >= 0.45:
			_play("spike_warn", 0.0, -8.0)
		if a2 < 0.6 and b2 >= 0.6:
			_play("spike_pop", 0.0, -4.0)
	_wind_sounds(prev_t)
	var arms_seen := false
	for a in L.arms:
		arms_seen = arms_seen or _on_screen(float(a.cx))
	if arms_seen and state == "play" and not arm_whir.playing and arm_whir.stream != null:
		arm_whir.play()
	elif (not arms_seen or state != "play") and arm_whir.playing:
		arm_whir.stop()
	for n in L.walkers.size():
		var w: Dictionary = L.walkers[n]
		if str(w.kind) == "flyer" and not S.killed.has(n) and (S.t + n * 17) % 45 == 0 and _on_screen(S.walker_pos(n).x):
			_play("flyer_flap", 0.0, -10.0)
		if str(w.kind) == "hopper" and not S.killed.has(n) and S.t % 96 == 0 and _on_screen(S.walker_pos(n).x):
			_play("hopper_hop", 0.0, -6.0)
		if str(w.kind) == "hopper" and not S.killed.has(n) and S.t % 96 == 29 and _on_screen(S.walker_pos(n).x):
			_play("hopper_land", 0.0, -6.0)
	# the relay hums while it runs and is on screen
	if not L.relay.is_empty():
		var on := S.relay_down < 0 and _on_screen(float(L.relay.c) * T + 24.0) and state == "play"
		if on and not relay_hum.playing:
			relay_hum.play()
		elif not on and relay_hum.playing:
			relay_hum.stop()
	if L.warden.x >= 0 and S.lever_t < 0 and S.t % 150 == 0 and _on_screen(S.warden_pos(S.t).x):
		_play("warden_hop")


func _add_shards(n: int) -> void:
	# Shards are Tally's currency, so they are never taken away: every 100
	# collected gives a free life on top.
	var before := earned
	shards += n
	earned += n
	for k in range(before / 100, earned / 100):
		lives += 1
		_play("extra_life")
		life_note_t = clock


func _play(name: String, delay := 0.0, db := 0.0) -> void:
	if not sfx.has(name):
		return
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(_play.bind(name, 0.0, db))
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx[name]
			p.volume_db = db + SFX_TRIM
			p.play()
			return
	sfx_players[0].stream = sfx[name]
	sfx_players[0].volume_db = db + SFX_TRIM
	sfx_players[0].play()


## Fades the level music out so a jingle (level clear, world clear, game over)
## plays on its own. The next level starts its music again.
## After a death the level music starts again from the top.
func _restart_music() -> void:
	if music_fade:
		music_fade.kill()
		music_fade = null
	if music.stream == null:
		return
	music.volume_db = MUSIC_DB
	music.play()


func _fade_music() -> void:
	if music_fade:
		music_fade.kill()
	music_fade = create_tween()
	music_fade.tween_property(music, "volume_db", -40.0, 0.35)
	music_fade.tween_callback(music.stop)


func _play_at(name: String, pos: Vector2) -> void:
	if _on_screen(pos.x):
		_play(name)


func _on_screen(wx: float) -> bool:
	return wx > cam_x - 48.0 and wx < cam_x + vw + 48.0


func _fx(kind: String, pos: Vector2, extra := "") -> void:
	seed_n += 1
	fx.append([kind, pos, clock, seed_n, extra])


# ================================================================ input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event is InputEventJoypadMotion:
		# a stick sends a stream of events: only the push past halfway counts
		var was: bool = stick_held.get(event.axis, false)
		stick_held[event.axis] = absf(event.axis_value) >= 0.5
		if was or not stick_held[event.axis]:
			return
	if not event.is_pressed():
		return
	var start: bool = event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START
	if event is InputEventKey and event.keycode == KEY_F and state != "pause":
		_set_filter(not post.visible)
		return
	if state == "pause":
		_pause_input(event, start)
		get_viewport().set_input_as_handled()
		return
	var esc: bool = event is InputEventKey and event.keycode in [KEY_ESCAPE, KEY_P]
	if (esc or start) and state in ["play", "card"]:
		pause_from = state
		pause_page = "main"
		pause_sel = 0
		_set_state("pause")
		_play("pause")
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode == KEY_R and state == "play":
		_restart_life()


func _restart_life() -> void:
	S.charged = false
	S.hurt("fell")
	_on_event({"k": "death", "x": S.x, "y": S.y})
	_fade_music()
	_set_state("dead")


# ================================================================ pause menu

const PAUSE_MAIN := ["RESUME", "RESTART LEVEL", "LEVEL SELECT", "SETTINGS", "SAVE AND QUIT"]
const PAUSE_SETTINGS := ["MUSIC", "EFFECTS", "SCREEN FILTER", "SCREEN SHAKE", "FLASHES", "FULLSCREEN", "BACK"]


func _pause_rows() -> Array:
	match pause_page:
		"settings":
			return PAUSE_SETTINGS
		"main":
			var main: Array = PAUSE_MAIN.duplicate()
			if _is_hub():
				main.erase("RESTART LEVEL")
			else:
				main.insert(main.find("SETTINGS"), "RETURN TO LAST RELAY")
			return main
		"levels":
			var rows: Array = []
			for id in ORDER:
				if unlocked.has(id):
					rows.append(id)
			rows.append("BACK")
			return rows
	return PAUSE_MAIN


func _pause_input(event: InputEvent, start: bool) -> void:
	if pause_page == "saved":
		return
	var key := -1
	if event is InputEventKey:
		key = event.keycode
	# is_action_pressed, not is_action: a stick axis matches both of its directions
	var up := event.is_action_pressed("ui_up") or key == KEY_W
	var down := event.is_action_pressed("ui_down") or key == KEY_S
	var left := event.is_action_pressed("ui_left") or key == KEY_A
	var right := event.is_action_pressed("ui_right") or key == KEY_D
	var ok := event.is_action("ui_accept") or event.is_action("jump")
	var back := event.is_action("ui_cancel") or start or key in [KEY_ESCAPE, KEY_P, KEY_BACKSPACE]
	if key >= KEY_0 and key <= KEY_9 and OS.is_debug_build():  # testing shortcut: jump to any level
		load_level(ORDER[key - KEY_0])
		return
	var rows := _pause_rows()
	if up or down:
		pause_sel = posmod(pause_sel + (1 if down else -1), rows.size())
		_play("menu_move")
	elif (left or right) and pause_page == "settings":
		_pause_adjust(1 if right else -1)
	elif back:
		if pause_page == "main":
			_set_state(pause_from)
		elif board_open:
			board_open = false
			_set_state("play")
			_play("menu_back")
		else:
			_back_to_main()
			_play("menu_back")
	elif ok:
		_pause_choose(str(rows[pause_sel]))


func _pause_choose(row: String) -> void:
	_play("menu_confirm")
	match pause_page:
		"main":
			match row:
				"RESUME":
					_set_state(pause_from)
				"RESTART LEVEL":
					# back to the very start, and it costs a life like any other restart,
					# so restarting can't refill a level's shards for free
					S.lit = false
					_restart_life()
				"LEVEL SELECT":
					pause_page = "levels"
					pause_sel = maxi(0, _pause_rows().find(level_id))
				"SETTINGS":
					pause_page = "settings"
					pause_sel = 0
				"RETURN TO LAST RELAY":
					load_level("village")
				"SAVE AND QUIT":
					var at := level_id
					if _is_hub():
						at = "village"
					elif level_id.ends_with("-bonus"):
						at = str(return_to.get("level", "1-1"))
					_write_save(at)
					_play("save_done")
					pause_page = "saved"
					get_tree().create_timer(0.45).timeout.connect(
						func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
		"levels":
			if row == "BACK" and board_open:
				board_open = false
				_set_state("play")
			elif row == "BACK":
				_back_to_main()
			else:
				board_open = false
				load_level(row)
		"settings":
			if row == "BACK":
				_back_to_main()
			else:
				_pause_adjust(1)


func _back_to_main() -> void:
	var from := "LEVEL SELECT" if pause_page == "levels" else "SETTINGS"
	pause_page = "main"
	pause_sel = maxi(0, _pause_rows().find(from))


func _pause_adjust(dir: int) -> void:
	match str(PAUSE_SETTINGS[pause_sel]):
		"MUSIC":
			AppSettings.set_volume("music", snappedf(AppSettings.music_volume + 0.1 * dir, 0.1))
		"EFFECTS":
			AppSettings.set_volume("effects", snappedf(AppSettings.sfx_volume + 0.1 * dir, 0.1))
		"SCREEN FILTER":
			_set_filter(not post.visible)
		"SCREEN SHAKE":
			AppSettings.toggle_shake()
		"FLASHES":
			AppSettings.toggle_flashes()
		"FULLSCREEN":
			AppSettings.toggle_fullscreen()
	_play("menu_move")


func _set_filter(on: bool) -> void:
	post.visible = on
	filter_on = on
	_save_progress()


func _pause_value(row: String) -> String:
	match row:
		"MUSIC":
			return _bar(AppSettings.music_volume)
		"EFFECTS":
			return _bar(AppSettings.sfx_volume)
		"SCREEN FILTER":
			return "ON" if post.visible else "OFF"
		"SCREEN SHAKE":
			return "ON" if AppSettings.camera_shake else "OFF"
		"FLASHES":
			return "REDUCED" if AppSettings.reduced_flashes else "FULL"
		"FULLSCREEN":
			return "ON" if AppSettings.fullscreen else "OFF"
	return ""


func _bar(v: float) -> String:
	var n := int(roundf(v * 10.0))
	return "#".repeat(n) + ".".repeat(10 - n)


func _draw_pause() -> void:
	draw_rect(Rect2(-hx, 17, vw, 253), Color(DrawUtil.BG, 0.9))
	if pause_page == "saved":
		_center("SAVED", 120, DrawUtil.WHITE, 2)
		return
	var title: String = {"main": "PAUSED", "settings": "SETTINGS", "levels": "LEVEL SELECT"}[pause_page]
	if board_open:
		title = "SWITCHBOARD"
	_center(title, 34, DrawUtil.WHITE, 2)
	var rows := _pause_rows()
	var y0 := 70.0 if rows.size() <= 7 else 58.0
	var step := 18.0 if rows.size() <= 7 else minf(15.0, floorf((226.0 - y0) / rows.size()))
	for i in rows.size():
		var row := str(rows[i])
		var y := y0 + i * step
		var sel := i == pause_sel
		if sel:
			draw_rect(Rect2(120, y - 4, 240, step - 2), DrawUtil.WHITE)
		var col := DrawUtil.BG if sel else DrawUtil.GRAY
		if pause_page == "settings" and row != "BACK":
			DrawUtil.text(self, Vector2(132, y), row, col)
			var v := _pause_value(row)
			DrawUtil.text(self, Vector2(348 - DrawUtil.text_width(v), y), v, col)
		elif pause_page == "levels" and row != "BACK":
			_draw_level_row(row, y, col, sel)
		else:
			DrawUtil.text(self, Vector2(240 - DrawUtil.text_width(row) / 2.0, y), row, col)
	var foot := "ARROWS CHOOSE . ENTER OR SPACE SELECT . ESC BACK"
	if pause_page == "settings":
		foot = "LEFT AND RIGHT CHANGE . ESC BACK . SETTINGS SAVE AUTOMATICALLY"
	_center(foot, 236, DrawUtil.GRAY)
	if pause_page == "main":
		var where := "WORLD %s . %s" % [str(L.meta.get("world", "1")), str(L.name)]
		if level_id == "test-room":
			where = "TRAINING YARD"
		elif _is_hub():
			where = "LAST RELAY . " + str(L.name)
		_center(where, 190, DrawUtil.GRAY)
		if best.has(level_id):
			_center("BEST TIME %s" % DrawUtil.fmt_time(float(best[level_id])), 202, DrawUtil.GRAY)
		if str(rows[pause_sel]) == "RESTART LEVEL":
			_center("COSTS ONE LIFE", 214, DrawUtil.GRAY)


## A switchboard row: the level and its name, NEXT on the level the signpost
## leads to, and its Pips on the right, filled in once they are home.
func _draw_level_row(id: String, y: float, col: Color, sel: bool) -> void:
	var info := _level_info(id)
	DrawUtil.text(self, Vector2(132, y), "TRAINING YARD" if id == "test-room" else id + "  " + str(info.name), col)
	if id == _next_level() and not flags.has("clear_" + id):
		DrawUtil.text(self, Vector2(286, y), "NEXT", DrawUtil.BG if sel else DrawUtil.WHITE)
	var got: int = (big.get(id, {}) as Dictionary).size()
	var total: int = info.big
	for i in total:
		# on the white bar the Pip's eyes and hollow middle are white
		_pip_glyph(Vector2(342 - (total - 1 - i) * 9, y - 1), col, i >= got, DrawUtil.WHITE if sel else DrawUtil.BG)


## A level's name and big shard count, read from its file once.
func _level_info(id: String) -> Dictionary:
	if not level_info.has(id):
		level_info[id] = Level.summary(id)
	return level_info[id]


# ================================================================ pips

## Every level that holds Pips: the training yard, the twelve levels and the bonus room.
func _pip_levels() -> Array:
	return ORDER + ["1-1-bonus"]


func _pips_total() -> int:
	var n := 0
	for id in _pip_levels():
		n += int(_level_info(id).big)
	return n


func _pips_home() -> int:
	var n := 0
	for id in _pip_levels():
		n += (big.get(id, {}) as Dictionary).size()
	return n


func _pip_home_at(c: int, r: int) -> bool:
	return big.has(level_id) and big[level_id].has("%d,%d" % [c, r])


## Lives at the start of a game: five, plus one for each of Dot's hearts.
func _start_lives() -> int:
	return START_LIVES + int(gifts.has("heart1")) + int(gifts.has("heart2"))


## A trapped Pip calls out every couple of seconds while the Spark is near,
## louder the closer it is, so players can hunt them by ear.
func _pip_calls() -> void:
	if clock - pip_call_t < 2.2:
		return
	var near := 1e9
	for cell in L.find("O"):
		if S.taken.has(cell) or _pip_home_at(cell.x, cell.y):
			continue
		near = minf(near, Vector2(S.x, S.y).distance_to(Vector2(cell.x * T + 8, cell.y * T + 8)))
	if near < 220.0:
		pip_call_t = clock
		_play("pip_call", 0.0, lerpf(-2.0, -16.0, near / 220.0))


## A tiny Pip for the HUD and the switchboard: a rounded body with two eyes, or
## an outline while it is still trapped. `inner` is the colour behind it.
func _pip_glyph(at: Vector2, col: Color, hollow: bool, inner := DrawUtil.BG) -> void:
	draw_rect(Rect2(at.x + 1, at.y, 4, 6), col)
	draw_rect(Rect2(at.x, at.y + 1, 6, 4), col)
	if hollow:
		draw_rect(Rect2(at.x + 1, at.y + 1, 4, 4), inner)
	else:
		draw_rect(Rect2(at.x + 1, at.y + 2, 1, 1), inner)
		draw_rect(Rect2(at.x + 4, at.y + 2, 1, 1), inner)


## The Pips you have brought home, hopping about beside Dot's switchboard.
func _draw_pip_crowd(v: Vector2i) -> void:
	var n := mini(_pips_home(), 24)
	var step := minf(8.0, 110.0 / maxf(1.0, float(n)))
	for i in n:
		var x := v.x * T + 20.0 + i * step
		var y := v.y * T + (3.0 if i % 3 == 1 else 0.0)   # a ragged little crowd, not a queue
		sh.draw_anim(self, "pip", "hop", clock + i * 0.17, Vector2(floorf(x), y), i % 2 == 1)


## Dot's side of the Pips: any gifts now due, then how many are home. Gifts are
## given once and kept through New Game, like the Pips themselves.
func _keeper_lines(who: Dictionary, lines: Array) -> Array:
	var out: Array = lines.duplicate()
	var home := _pips_home()
	var total := _pips_total()
	var gave := false
	for g in who.get("gifts", []):
		var id := str(g.id)
		var at := total if int(g.at) < 0 else int(g.at)
		if home >= at and not gifts.has(id):
			gifts.append(id)
			out.append_array(g.lines)
			if id in ["life", "heart1", "heart2"]:
				lives += 1
			gave = true
	if gave:
		_play("pip_home")
		_save_progress()
	var said: Dictionary = who.get("progress", {})
	var next := -1
	for g in who.get("gifts", []):
		var at := total if int(g.at) < 0 else int(g.at)
		if at > home and (next < 0 or at < next):
			next = at
	var line := str(said.get("rest", ""))
	if home >= total:
		line = str(said.get("all", ""))
	elif next > 0:
		line = str(said.get("next", ""))
	line = line.replace("{home}", str(home)).replace("{total}", str(total)).replace("{need}", str(next - home))
	if line != "":
		out.append(line)
	return out


## "2-1  RAIL HOPPERS": where the signpost leads next, or "" once every level is cleared.
func _next_label() -> String:
	var id := _next_level()
	if flags.has("clear_" + id):
		return ""
	return id + "  " + str(_level_info(id).name)


# ================================================================ save

## Where the next session continues from. Written at the start of every level
## (after a clear, a game over or a level pick) and by SAVE AND QUIT.
func _write_save(at_level: String) -> void:
	save = {"level": at_level, "lives": lives, "shards": shards, "earned": earned}
	if not unlocked.has(at_level):
		unlocked.append(at_level)
	if _save_progress():
		saved_t = clock   # the HUD only says saved when it was


# ================================================================ camera

func _cam_target(snap: bool) -> float:
	if snap:
		cam_lead = 0.0
	var span: float = L.width * T
	if span <= vw:
		return floorf((span - vw) / 2.0)   # a room narrower than the screen sits in the middle
	return clampf(S.x - vw / 2.0 + cam_lead, 0.0, span - vw)


## Wide screens (scripts/screen_fit.gd): the view widens to fill the window, and
## the HUD, menus and cards stay in a 480 px column in the middle.
func _fit_screen() -> void:
	var win := get_tree().root
	ScreenFit.fit(win)
	vw = float(win.content_scale_size.x)
	hx = floorf((vw - 480.0) / 2.0)
	fx_rect.size = Vector2(vw, 270)
	post.size = Vector2(vw, 270)
	fxmat.set_shader_parameter("view", Vector2(vw, 270))
	(post.material as ShaderMaterial).set_shader_parameter("logical", Vector2(vw, 270))


func _exit_tree() -> void:
	ScreenFit.reset(get_tree().root)   # the older scenes draw at a fixed 480 px


## The camera looks ahead only while you keep running one way, and the look-ahead
## drifts over slowly, so tapping left and right does not swing the view. Small
## moves inside the dead zone do not move the camera at all.
func _follow_camera(delta: float) -> void:
	if absf(S.vx) > 60.0:
		cam_lead = move_toward(cam_lead, CAM_LEAD * signf(S.vx), CAM_LEAD_SPEED * delta)
	var focus := _cam_target(false)
	var want := cam_x
	if focus > cam_x + CAM_DEAD_ZONE:
		want = focus - CAM_DEAD_ZONE
	elif focus < cam_x - CAM_DEAD_ZONE:
		want = focus + CAM_DEAD_ZONE
	cam_x = lerpf(cam_x, want, minf(1.0, delta * 6.0))
	cam_y = lerpf(cam_y, _cam_y_target(false), minf(1.0, delta * 5.0))


## Vertical camera for tall levels. It settles on the height you stand at, and
## only follows a jump when you leave the middle band of the screen, so normal
## jumps don't bob the view. One-screen levels never scroll.
func _cam_y_target(snap: bool) -> float:
	var top := maxf(0.0, L.rows * T - 270.0)
	if top <= 2.0:
		return 0.0
	var want := cam_y
	var screen_y: float = S.y - cam_y
	if snap or S.on_floor:
		want = S.y - 170.0
	elif screen_y < 70.0:
		want = S.y - 70.0
	elif screen_y > 210.0:
		want = S.y - 210.0
	return clampf(want, 0.0, top)


# ================================================================ drawing

func _draw() -> void:
	var cam := floorf(cam_x)
	var off := Vector2.ZERO
	if shake > 0.0 and AppSettings.camera_shake:
		var h := DrawUtil.hash2(int(clock * 60.0), 7)
		off = Vector2(float(h % 5) - 2.0, float((h >> 4) % 5) - 2.0) * minf(1.0, shake / 3.0)
	ui_clear.clear()
	if state in ["pause", "shop", "gameover", "done"]:
		ui_clear.append(Rect2(0, 0, vw, 270))   # a whole-screen menu
	draw_rect(Rect2(0, 0, vw, 270), DrawUtil.BG)
	_draw_sky(cam)
	var camy := floorf(cam_y)
	world_off = Vector2(-cam, -camy) + off.round()
	draw_set_transform(world_off)
	var c0 := int(cam / T) - 3
	var c1 := c0 + int(vw / T) + 4
	var r0 := maxi(0, int(camy / T) - 3)
	if state == "pipe":
		_draw_player()  # behind the tiles, so the Spark sinks into the pipe
	_draw_interior()
	var r1 := mini(L.rows, r0 + 22)
	for r in range(r0, r1):
		for c in range(maxi(c0, 0), mini(c1, L.width)):
			_draw_tile(c, r)
	# the mast stands six tiles above its base, so it can show while its base is below the rows drawn
	if L.goal.y >= r1 and L.goal.y < r1 + 7 and L.goal.x >= c0 and L.goal.x < c1:
		_draw_tile(L.goal.x, L.goal.y)
	_draw_objects()
	_draw_people()
	_draw_hints()
	if state != "pipe":
		_draw_player()
	_draw_fx()
	_draw_weather()
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0, 0, vw, 16), DrawUtil.BG)
	draw_rect(Rect2(0, 16, vw, 1), DrawUtil.DARK)
	draw_set_transform(Vector2(hx, 0))
	_draw_hud()
	draw_set_transform(Vector2.ZERO)
	_draw_compass()
	_draw_bubble()
	draw_set_transform(Vector2(hx, 0))
	_draw_shop()
	_draw_overlay()
	draw_set_transform(Vector2.ZERO)
	_draw_handoff_iris()
	_upload_clear()


## Tells the atmosphere pass which parts of the screen are text or menus, so a
## dark stretch never hides them.
func _upload_clear() -> void:
	if fxmat == null:
		return
	var rects: Array = []
	for r in ui_clear.slice(0, 16):
		rects.append(Vector4(r.position.x, r.position.y, r.end.x, r.end.y))
	fxmat.set_shader_parameter("clear_count", rects.size())
	while rects.size() < 16:
		rects.append(Vector4.ZERO)
	fxmat.set_shader_parameter("clear_rects", rects)


func _draw_sky(cam: float) -> void:
	if str(L.meta.get("interior", "")) != "":
		return  # indoors: the room is drawn with the tiles
	var off := floorf(cam * 0.1)
	for i in int(90.0 * vw / 480.0):
		var h := DrawUtil.hash2(i, 77)
		var x := fposmod(float(h % 4800) - off, vw)
		var y := float((h >> 8) % 200) + 20.0
		draw_rect(Rect2(x, y, 1, 1), DrawUtil.GRAY if h % 11 == 0 else DrawUtil.DARK)
	# the dead broadcast sun, barely moving
	var sun := Vector2(hx + 360.0 - cam * 0.04, 150.0)
	for yy in range(-44, 45, 2):
		var w := sqrt(maxf(0.0, 44.0 * 44.0 - yy * yy))
		if (int(yy + 44) / 2) % 5 == 4:
			continue
		draw_rect(Rect2(floorf(sun.x - w), sun.y + yy, floorf(w * 2.0), 1), DrawUtil.DARK)
	# far silhouettes, 0.3 parallax; in tall levels they sink as you climb
	var fo := cam * 0.3
	var hz := floorf((maxf(0.0, L.rows * T - 270.0) - cam_y) * 0.2)
	if _is_hub() and _has_sheet("backdrop_village"):
		# Last Relay: warm rooftops and aerials, a few windows still lit
		var vs: Vector2 = sh.size("backdrop_village")
		var vo := cam * 0.2
		var vfirst := int(floor(vo / vs.x))
		for slot in range(vfirst, vfirst + int(vw / vs.x) + 2):
			var piece := DrawUtil.hash2(slot, 523) % 4
			sh.draw_frame(self, "backdrop_village", "pieces", piece,
				Vector2(floorf(slot * vs.x - vo), 232.0 - vs.y + hz), false, Color(1, 1, 1, 0.7))
		return
	if _world() == "3" and _has_sheet("backdrop_w3"):
		# World 3: far masts, a dish and cloud banks, joined edge to edge
		var bs: Vector2 = sh.size("backdrop_w3")
		var bo := cam * 0.2
		var bfirst := int(floor(bo / bs.x))
		for slot in range(bfirst, bfirst + int(vw / bs.x) + 2):
			# never the same piece twice in a row (the pieces join in any other order)
			var bp := DrawUtil.hash2(slot, 733) % 4
			if bp == DrawUtil.hash2(slot - 1, 733) % 4:
				bp = (bp + 1) % 4
			sh.draw_frame(self, "backdrop_w3", "pieces", bp,
				Vector2(floorf(slot * bs.x - bo), 232.0 - bs.y + hz), false, Color(1, 1, 1, 0.7))
		return
	if ground_sheet == "ground_w2":
		# World 2: relay towers, pylons and gantries from the backdrop sheet
		# pieces join edge to edge every 96 px on one horizon, parallax 0.2, 70 %
		# opacity: mostly pylons, a tower, gantry or hut every third or fourth slot
		var fs: Vector2 = sh.size("backdrop_w2")
		var po := cam * 0.2
		var first := int(floor(po / fs.x))
		var prev := -1
		for slot in range(first, first + int(vw / fs.x) + 2):
			var piece := 1
			var hb := DrawUtil.hash2(slot, 911)
			if posmod(slot, 7) in [0, 3] or hb % 11 == 0:
				piece = [0, 2, 3][hb % 3]
				if piece == prev:
					piece = [0, 2, 3][(hb + 1) % 3]
			prev = piece
			sh.draw_frame(self, "backdrop_w2", "pieces", piece,
				Vector2(floorf(slot * fs.x - po), 232.0 - fs.y + hz), false, Color(1, 1, 1, 0.7))
		return
	for i in 24:
		var h2 := DrawUtil.hash2(i, 311)
		var bx := fposmod(float(i * 64) - fo, 24.0 * 64.0) - 64.0
		var bh := 20.0 + float(h2 % 50)
		draw_texture_rect(dither, Rect2(floorf(bx), 224.0 - bh + hz, 40.0 + float(h2 % 20), bh + 46.0), true)
		if h2 % 7 == 0:
			draw_rect(Rect2(floorf(bx) + 8.0, 224.0 - bh + 6.0 + hz, 1, 1), DrawUtil.GRAY)
	if L.goal.x >= 0 and level_id == "1-4":
		var wx: float = L.goal.x * T + 8.0
		var sx := (wx - (cam + vw / 2.0)) * 0.2 + vw / 2.0
		sh.draw_anim(self, "gate_transmitter", "awake" if state == "clear" else "dormant", clock,
			Vector2(sx - 64.0, 0.0), false, Color(1, 1, 1, 0.7))


func _age(key: String) -> float:
	return clock - float(anims[key]) if anims.has(key) else 99.0


func _draw_tile(c: int, r: int) -> void:
	var ch: String = L.at(c, r)
	if ch == ".":
		return
	var p := Vector2(c * T, r * T)
	var t := clock
	var key := Vector2i(c, r)
	var st: String = S.tiles.get(key, "")
	match ch:
		"#":
			_draw_ground(c, r, p)
		"=":
			var lip: bool = L.at(c, r - 1) != "="
			var h := DrawUtil.hash2(c, r)
			var kind := 2 if h % 37 == 0 else (1 if h % 9 == 0 else (3 if h % 17 == 0 else 0))
			sh.draw_frame(self, block_sheet, "lip" if lip else "stacked", kind, p)
		"-":
			var l: bool = L.at(c - 1, r) != "-"
			var rr: bool = L.at(c + 1, r) != "-"
			sh.draw_frame(self, "girder", "static", 3 if l and rr else (0 if l else (2 if rr else 1)), p)
		"?", "C", "U":
			var hop := _bump_hop(key)
			if st == "used":
				sh.draw_frame(self, "bump_block", "used", 0, p - Vector2(0, hop))
			else:
				var anim: String = {"?": "shard", "C": "charge", "U": "life"}[ch]
				sh.draw_anim(self, "bump_block", anim, t + c * 0.37, p - Vector2(0, hop))
		"h", "i":
			if st != "":
				sh.draw_frame(self, "bump_block", "used", 0, p - Vector2(0, _bump_hop(key)))
			else:
				# the hint: a faint glint every few seconds where the hidden block is
				var ga := fposmod(t + c * 0.7, 3.0)
				if ga < 0.3:
					sh.draw_anim(self, "fx_sparkle", "twinkle", ga, p + Vector2(4, 4), false, Color(1, 1, 1, 0.55))
		"B":
			if st != "broken":
				sh.draw_frame(self, "brick", "idle", 0, p - Vector2(0, _bump_hop(key)))
		"%":
			if st != "broken":
				_draw_crack(c, r, p)
		"L":
			var ls: String = S.loose_state(key, S.t)
			if ls == "still":
				sh.draw_frame(self, "loose_floor", "still", 0, p)
			elif ls == "shaking":
				var age := (S.t - int(S.loose_trig[key])) / 60.0
				sh.draw_anim(self, "loose_floor", "shake", age, p + Vector2(1.0 if int(age * 40.0) % 2 == 0 else -1.0, 0))
			else:
				var land: Array = L.loose_land[key]
				var fall_t := S.t - int(S.loose_trig[key]) - 21
				if fall_t < int(land[0]):
					var yy := r * T + 0.5 * 920.0 * pow(fall_t / 60.0, 2.0)
					sh.draw_frame(self, "loose_floor", "fall", 0, Vector2(p.x, floorf(yy)))
				else:
					var land_r := L.floor_below(c, r) - 1
					if land_r < L.rows - 1:  # over a pit it has fallen off the screen
						sh.draw_frame(self, "loose_floor", "rubble", 0, Vector2(p.x, land_r * T))
		"Z":
			if S.lever_t < 0:
				sh.draw_frame(self, "bridge", "intact", 0, p)
			else:
				var snap: int = S.lever_t + 18 + 4 * absi(c - L.lever.x)
				if S.t < snap - 9:
					sh.draw_frame(self, "bridge", "intact", 0, p)
				elif S.t < snap:
					sh.draw_anim(self, "bridge", "stress", (S.t - snap + 9) / 60.0, p + Vector2(1.0 if S.t % 4 < 2 else -1.0, 0))
				else:
					var d := (S.t - snap) / 60.0
					if d < 1.2:
						sh.draw_anim(self, "bridge", "plank", d, p + Vector2((1 if c % 2 else -1) * d * 20.0, 0.5 * 920.0 * d * d))
		"^":
			sh.draw_anim(self, "spikes", "floor", t, p)
		"v":
			sh.draw_anim(self, "spikes", "ceiling", t, p)
		"F":
			var di := _debris_index(c, r)
			if di > 0 and S.debris_trig.has(di):
				var age2 := (S.t - int(S.debris_trig[di])) / 60.0
				if age2 < 0.4:
					sh.draw_anim(self, "loose_ceiling", "crack", age2, p)
					sh.draw_anim(self, "loose_ceiling", "dust", age2, p + Vector2(0, 16))
				else:
					sh.draw_frame(self, "loose_ceiling", "empty", 0, p)
			else:
				sh.draw_frame(self, "loose_ceiling", "intact", 0, p)
		"p":
			if L.at(c - 1, r) != "p" or (c - _pipe_start(c, r)) % 2 == 0:
				if (c - _pipe_start(c, r)) % 2 == 0:
					sh.draw_frame(self, "pipe", "mouth" if L.at(c, r - 1) != "p" else "body", 0, p)
					if L.at(c, r - 1) != "p":
						sh.draw_anim(self, "fx_hint", "down", t, p + Vector2(12, -12))
		"_":
			var pi := _plate_index(c, r)
			var down: bool = S.plates_state.has(pi) and S.t - int(S.plates_state[pi][1]) < 3
			sh.draw_frame(self, "plate", "down" if down else "up", 0, p)
		"K":
			if S.lever_t < 0:
				sh.draw_frame(self, "lever", "off", 0, p)
			else:
				sh.draw_anim(self, "lever", "pull", (S.t - S.lever_t) / 60.0, p)
		"S":
			var sa := _age("spring:%d" % int(p.x + 8))
			if sa < 0.3:
				sh.draw_anim(self, "spring", "bounce", sa, p)
			else:
				sh.draw_frame(self, "spring", "rest", 0, p)
		"R":
			var ri: int = L.rings.find(Vector2(c * T + 8, r * T + 8))
			var used: bool = S.ring_used.has(ri) and S.t - int(S.ring_used[ri]) <= 120
			if used:
				var ua := (S.t - int(S.ring_used[ri])) / 60.0
				sh.draw_anim(self, "lift_ring", "pop" if ua < 0.3 else "used", ua, p - Vector2(4, 4))
			else:
				sh.draw_anim(self, "lift_ring", "idle", t, p - Vector2(4, 4))
		"o":
			if not S.taken.has(key):
				var bob := roundf(sin(t * 4.0 + c) * 2.0)
				sh.draw_anim(self, "shard", "spin", t + c * 0.21, p + Vector2(0, bob))
		"O":
			# a Pip trapped in a glass insulator; once it is home, only the broken glass is left
			if S.taken.has(key) or _pip_home_at(c, r):
				sh.draw_frame(self, "pip", "empty", 0, p)
			else:
				sh.draw_anim(self, "pip", "trapped", t + c * 0.37, p)
		"M":
			if S.lit:
				sh.draw_anim(self, "beacon", "lit", t, p - Vector2(0, 16))
			else:
				sh.draw_frame(self, "beacon", "dark", 0, p - Vector2(0, 16))
		"G":
			var lit := state == "clear" or state == "done"
			sh.draw_frame(self, "mast", "base_lit" if lit else "pieces", 0, p)
			for k in range(1, 6):
				sh.draw_frame(self, "mast", "pieces", 1, p - Vector2(0, 16.0 * k))
			if lit:
				sh.draw_anim(self, "mast", "top_lit", t, p - Vector2(0, 96))
			else:
				sh.draw_frame(self, "mast", "pieces", 2, p - Vector2(0, 96))
			var flag_y := 90.0
			if state == "clear":
				flag_y = lerpf(90.0, 10.0, clampf(state_t, 0.0, 1.0))
			sh.draw_anim(self, "mast_flag", "lit" if lit else "wave", t, p - Vector2(16, flag_y))
		"|":
			pass  # gates draw with the moving parts
		"1", "2":
			var tag := "one" if ch == "1" else "two"
			var live: bool = int(Level.CHANNEL[ch]) == S.channel(S.t) and not S.pending.has(key)
			var left: int = S.relay_next_swap(S.t)
			if not live and left >= 0 and left <= 18 and int(Level.CHANNEL[ch]) != S.channel(S.t):
				sh.draw_anim(self, "channel_block", tag + "_arm", (18 - left) / 60.0, p)
			else:
				sh.draw_frame(self, "channel_block", tag + ("_solid" if live else "_off"), 0, p)
		"Y":
			var hy := _bump_hop(key)
			if _age("channel") < 0.15:
				sh.draw_anim(self, "channel_switch", "hit", _age("channel"), p - Vector2(0, hy))
			else:
				sh.draw_anim(self, "channel_switch", "one" if S.channel(S.t) == 0 else "two", t, p - Vector2(0, hy))
		"Q":
			if S.fuses.has(key):
				var fa := (S.t - int(S.fuses[key])) / 60.0
				if fa < 0.24:
					sh.draw_anim(self, "fuse", "blow", fa, p)
				else:
					sh.draw_frame(self, "fuse", "blown", 0, p)
			else:
				sh.draw_anim(self, "fuse", "live", t + c * 0.3, p)
		"J":
			if lamps_lit.has(key):
				var la := clock - float(lamps_lit[key])
				if la < 0.25:
					sh.draw_anim(self, "lamp", "ignite", la, p - Vector2(0, 16))
				else:
					sh.draw_anim(self, "lamp", "on", t + c * 0.3, p - Vector2(0, 16))
			else:
				sh.draw_frame(self, "lamp", "off", 0, p - Vector2(0, 16))
		"E":
			if key == Vector2i(int(L.relay.c), int(L.relay.r)):
				_draw_relay(p)
		"A":
			if _has_sheet("sweep_arm"):
				sh.draw_anim(self, "sweep_arm", "pivot", t, p)
			else:
				draw_rect(Rect2(p + Vector2(2, 2), Vector2(12, 12)), DrawUtil.GRAY)
		"<", ">", "u":
			_draw_wind(ch, c, r, p)


# ================================================================ atmosphere

## Level header keys (all look and sound only; the proofs ignore them):
##   dark: 60-89, 120-149   column ranges that are dark except near a light
##   weather: rain | static
##   lightning: yes
func _update_atmosphere() -> void:
	if fxmat == null or L == null:
		return
	fxmat.set_shader_parameter("cam", Vector2(floorf(cam_x), floorf(cam_y)))
	# dark stretches
	var ranges: Array = []
	for part in str(L.meta.get("dark", "")).split(",", false):
		var ab := part.strip_edges().split("-")
		if ab.size() == 2:
			ranges.append(Vector4(float(ab[0]) * T, (float(ab[1]) + 1.0) * T, 40.0, 1.0))
	while ranges.size() < 8:
		ranges.append(Vector4.ZERO)
	fxmat.set_shader_parameter("dark_ranges", ranges.slice(0, 8))
	fxmat.set_shader_parameter("dark_count", mini(8, str(L.meta.get("dark", "")).split(",", false).size()))
	# lights: the Spark, lit lamps, live fuses and big shards on screen
	var lights: Array = []
	if state != "dead" and state != "gameover":
		var reach := 90.0 if items.get("lantern", false) else 58.0   # Tally's lantern
		lights.append(Vector3(S.x, S.y, reach + sin(clock * 9.0) * 2.0 + (14.0 if S.charged else 0.0)))
	for cell in L.find("J"):
		var lp := Vector2(cell.x * T + 8, cell.y * T - 4)
		if not lamps_lit.has(cell) and absf(S.x - lp.x) < 28.0 and absf(S.y - (cell.y * T + 8)) < 40.0:
			lamps_lit[cell] = clock
			_play("lamp_on")
			_fx("light", lp)
		if lamps_lit.has(cell):
			var grow := clampf((clock - float(lamps_lit[cell])) / 0.4, 0.0, 1.0)
			lights.append(Vector3(lp.x, lp.y, 96.0 * grow + sin(clock * 5.0 + cell.x) * 2.0))
	if not L.relay.is_empty() and S.relay_down < 0:
		lights.append(Vector3(float(L.relay.c) * T + 24, float(L.relay.r) * T + 20, 64.0 + sin(clock * 3.0) * 4.0))
	for cell in L.fuses:
		if not S.fuses.has(cell):
			lights.append(Vector3(cell.x * T + 8, cell.y * T + 12, 26.0))
	for cell in L.find("O"):
		if not S.taken.has(cell) and not _pip_home_at(cell.x, cell.y) and _on_screen(cell.x * T):
			lights.append(Vector3(cell.x * T + 8, cell.y * T + 8, 30.0))
	lights = lights.slice(0, 24)
	fxmat.set_shader_parameter("light_count", lights.size())
	while lights.size() < 24:
		lights.append(Vector3.ZERO)
	fxmat.set_shader_parameter("lights", lights)
	# lightning
	var f := 0.0
	if str(L.meta.get("lightning", "")) != "" and state in ["play", "card"]:
		if clock >= next_flash:
			flash_t = clock
			seed_n += 1
			next_flash = clock + 6.0 + float(DrawUtil.hash2(seed_n, 5) % 50) / 10.0
			_play("thunder", 0.35)
		var a := clock - flash_t
		if AppSettings.reduced_flashes:
			f = 0.3 * clampf(1.0 - a / 0.6, 0.0, 1.0)
		elif a < 0.06:
			f = 1.0
		elif a < 0.11:
			f = 0.25
		elif a < 0.5:
			f = 0.9 * (1.0 - (a - 0.11) / 0.39)
	fxmat.set_shader_parameter("flash", f)


func _draw_weather() -> void:
	## Rain or signal static over the level, and fog low in tall levels.
	var kind := str(L.meta.get("weather", ""))
	var cam := Vector2(floorf(cam_x), floorf(cam_y))
	if L.rows > ROWS:
		var fy: float = L.rows * T - 40.0
		if fy < cam.y + 270.0:
			var fo := fposmod(clock * 6.0, 32.0)
			for i in int(vw / 32.0) + 2:
				var fx0 := floorf(cam.x / 32.0) * 32.0 + i * 32.0 - fo
				sh.draw_frame(self, "fog", "band", i % 4, Vector2(fx0, fy), false, Color(1, 1, 1, 0.8))
				sh.draw_frame(self, "fog", "band", (i + 2) % 4, Vector2(fx0 + 16.0, fy + 14.0), false, Color(1, 1, 1, 0.6))
	if kind == "":
		return
	var n := int((70.0 if kind == "rain" else 40.0) * vw / 480.0)
	for i in n:
		var h := DrawUtil.hash2(i, 431)
		var speed := 260.0 + float(h % 90) if kind == "rain" else 12.0 + float(h % 20)
		var x := fposmod(float(h % 997) * 7.3 - clock * (speed * 0.5 if kind == "rain" else 8.0), vw + 16.0) - 8.0  # rain slants 1 across per 2 down
		var y := fposmod(float((h >> 5) % 997) * 3.1 + clock * speed, 286.0) - 16.0
		var anim := "rain" if kind == "rain" else "static"
		if kind == "static" and (h + int(clock * 8.0)) % 5 == 0:
			continue
		sh.draw_frame(self, "weather", anim, h % 4, cam + Vector2(floorf(x), floorf(y)), false,
			Color(1, 1, 1, 0.55 if kind == "rain" else 0.8))


# ================================================================ World 3 wind

## Streaks in wind tiles: blowing while the wind is on, bunching up in the half
## second before a gust, nothing in the lull.
func _draw_wind(ch: String, c: int, r: int, p: Vector2) -> void:
	var h := DrawUtil.hash2(c, r * 3 + 1)
	if h % 3 != 0:
		return
	var on: bool = L.gust_on(S.t)
	if not on:
		if _gust_tell():
			if _has_sheet("wind"):
				sh.draw_anim(self, "wind", "gust_tell", fposmod(clock, 0.45), p, ch == ">", Color(1, 1, 1, 0.6))
		return
	if not _has_sheet("wind"):
		var o := fposmod(clock * 90.0 + h, 16.0)
		if ch == "u":
			draw_rect(Rect2(p + Vector2(float(h % 12) + 2, 16.0 - o), Vector2(1, 4)), DrawUtil.GRAY)
		else:
			draw_rect(Rect2(p + Vector2(o if ch == ">" else 16.0 - o, float(h % 12) + 2), Vector2(5, 1)), DrawUtil.GRAY)
		return
	sh.draw_anim(self, "wind", "up" if ch == "u" else "side", clock + float(h % 7) * 0.05, p, ch == ">", Color(1, 1, 1, 0.7))


## True in the half second before a gust starts.
func _gust_tell() -> bool:
	if L.gust.x <= 0.0:
		return false
	return fposmod(S.t / 60.0, L.gust.x) >= L.gust.x - 0.5


func _wind_sounds(prev_t: int) -> void:
	if L.gust.x > 0.0 and state == "play" and _level_has_wind():
		var a := fposmod(prev_t / 60.0, L.gust.x)
		var b := fposmod(S.t / 60.0, L.gust.x)
		if a < L.gust.x - 0.5 and b >= L.gust.x - 0.5:
			_play("gust_tell", 0.0, -6.0)
		if b < a:
			_play("gust", 0.0, -6.0)
	var ch: String = L.at(int(floor(S.x / T)), int(floor(S.y / T)))
	var up: bool = ch == "u" and L.gust_on(S.t)
	if up and not in_updraft:
		_play("updraft", 0.0, -6.0)
	in_updraft = up


func _level_has_wind() -> bool:
	return not (L.find("<").is_empty() and L.find(">").is_empty() and L.find("u").is_empty())


func _draw_relay(p: Vector2) -> void:
	## The World 2 boss cabinet: hums, shakes before each swap, flashes on the
	## swap, shows a blown lamp per fuse, then overloads and dies.
	if S.relay_down >= 0:
		var da := (S.t - S.relay_down) / 60.0
		if da < 0.48:
			sh.draw_anim(self, "relay", "overload", da, p + Vector2(1.0 if S.t % 4 < 2 else -1.0, 0))
		else:
			sh.draw_frame(self, "relay", "dead", 0, p)
		return
	var left: int = S.relay_next_swap(S.t)
	if left <= 18:
		sh.draw_anim(self, "relay", "tell", (18 - left) / 60.0, p + Vector2(1.0 if S.t % 4 < 2 else -1.0, 0))
	elif _age("channel") < 0.1:
		sh.draw_anim(self, "relay", "swap", _age("channel"), p)
	else:
		sh.draw_anim(self, "relay", "idle", clock, p)
	sh.draw_frame(self, "relay", "lamps", mini(S.fuses.size(), 3), p)


func _draw_ground(c: int, r: int, p: Vector2) -> void:
	var g := "#F"
	var top: bool = not g.contains(L.at(c, r - 1)) and r > 0
	var bottom: bool = not g.contains(L.at(c, r + 1)) and r < L.rows - 1
	var left: bool = not g.contains(L.at(c - 1, r))
	var right: bool = not g.contains(L.at(c + 1, r))
	var depth := 0
	while depth < 3 and g.contains(L.at(c, r - depth - 1)) and r - depth - 1 >= 0:
		depth += 1
	if r == 0:
		depth = 3
	var col := 3 if left and right else (0 if left else (2 if right else 1))
	var anim := "deep"
	if top:
		anim = "top"
	elif bottom:
		anim = "bottom"
		if col == 3:
			col = 1
	elif depth == 1:
		anim = "mid"
	var h := DrawUtil.hash2(c * 3 + 1, r * 5 + 2)
	if col == 1 and h % 9 == 0 and anim != "bottom":
		sh.draw_frame(self, ground_sheet, "alt", {"top": h % 2, "mid": 2, "deep": 3}[anim], p)
		return
	sh.draw_frame(self, ground_sheet, anim, col, p)


func _bump_hop(key: Vector2i) -> float:
	for b in S.bumps:
		if b[0] == key:
			var age := (S.t - int(b[1])) / 60.0
			if age < 0.2:
				return -J.bump_hop(age)  # bump_hop is an upward (negative) offset
	return 0.0


func _debris_index(c: int, r: int) -> int:
	for d in L.debris:
		if int(d.c) == c and int(d.r) == r:
			return int(d.i)
	return 0


func _plate_index(c: int, r: int) -> int:
	for p in L.plates:
		if int(p.c) == c and int(p.r) == r:
			return int(p.i)
	return 0


func _pipe_start(c: int, r: int) -> int:
	var s := c
	while L.at(s - 1, r) == "p":
		s -= 1
	return s


func _draw_objects() -> void:
	var t := clock
	# gates slide up into their wall
	for g in L.gates:
		var amt: float = S.gate_amount(g, S.t)
		var h: float = g.h
		var lift := floorf(amt * h)
		var n := int(h / T)
		for k in n:
			var yy: float = float(g.y) + k * T - lift
			if yy + T <= float(g.y):
				continue
			var part := Rect2(0, maxf(0.0, float(g.y) - yy), 16, 16)
			sh.draw_part(self, "gate", "pieces", 1 if k == n - 1 else 0, Vector2(float(g.x), yy), part)
		var cap := "cap_closed" if amt <= 0.0 else ("cap_open" if amt >= 1.0 else "cap_opening")
		sh.draw_anim(self, "gate", cap, t, Vector2(float(g.x), float(g.y) - 16.0))
	# loose ceiling chunks
	for di in S.debris_trig:
		var d: Dictionary = L.debris[di - 1]
		var s := S.t - int(S.debris_trig[di]) - 24
		if s >= 0:
			var yy := float(d.y) + 0.5 * 920.0 * pow(s / 60.0, 2.0)
			if yy < float(d.land):
				sh.draw_anim(self, "loose_ceiling", "chunk", s / 60.0, Vector2(float(d.x), floorf(yy)))
			elif yy < float(d.land) + 400.0:
				sh.draw_frame(self, "loose_ceiling", "landed", 0, Vector2(float(d.x), float(d.land) - 16.0))
	# presses
	for p in L.presses:
		var s2: float = S.press_s(p, S.t)
		var y0: float = p.y0
		var y: float = S.press_y(p, S.t)
		var rest := float(p.period) - 1.07
		var anim := "rest"
		var jx := 0.0
		if s2 >= rest - 0.3 and s2 < rest:
			anim = "warn"
			jx = 1.0 if int(s2 * 30.0) % 2 == 0 else -1.0
		elif s2 >= rest and s2 < rest + 0.12:
			anim = "slam"
		elif s2 >= rest + 0.12 and s2 < rest + 0.47:
			anim = "hold"
		var x: float = p.x
		var yy2 := y0
		while yy2 < y:
			sh.draw_part(self, "press", "shaft", 0, Vector2(x, yy2), Rect2(0, 0, 16, minf(16.0, y - yy2)))
			yy2 += 16.0
		if anim == "warn":
			sh.draw_anim(self, "press", "warn", s2 - rest + 0.3, Vector2(x + jx, y))
		else:
			sh.draw_frame(self, "press", anim, 0, Vector2(x, y))
		if anim == "hold":
			sh.draw_anim(self, "press_dust", "puff", s2 - rest - 0.12, Vector2(x - 16, float(p.y1)))
	# spike vents
	for v in L.vents:
		var sv: float = S.vent_phase(v, S.t)
		var a2 := "down"
		var tt := 0.0
		if sv >= 0.45 and sv < 0.6:
			a2 = "warn"
			tt = (sv - 0.45) * float(v.period)
		elif sv >= 0.6 and sv < 0.64:
			a2 = "rise"
			tt = (sv - 0.6) * float(v.period)
		elif sv >= 0.64 and sv < 0.95:
			a2 = "up"
			tt = (sv - 0.64) * float(v.period)
		elif sv >= 0.95:
			a2 = "retract"
			tt = (sv - 0.95) * float(v.period)
		sh.draw_anim(self, "spike_vent", a2, tt, Vector2(float(v.x), float(v.y)))
	# moving girders
	for m in L.movers:
		var rect: Rect2 = S.mover_rect(m, S.t)
		var n2: int = m.n
		var fr := int(t * 12.5) % 4
		for k in n2:
			var piece := "middle"
			if k == 0:
				piece = "left"
			elif k == n2 - 1:
				piece = "right"
			sh.draw_frame(self, "moving_girder", piece, fr, Vector2(rect.position.x + k * T, rect.position.y).round())
	# droppers
	for d in L.droppers:
		var dy: Array = S.dropper_y(d, S.t)
		var di := int(d.i)
		var anim2 := "idle"
		var at := t
		if S.dropper_trig.has(di):
			var age := (S.t - int(S.dropper_trig[di])) / 60.0
			if age < 0.25:
				anim2 = "tell"
				at = age
			elif dy[1]:
				anim2 = "fall"
			elif float(dy[0]) >= float(d.y1) - 0.5:
				anim2 = "land"
				at = age
			else:
				anim2 = "rise"
		sh.draw_anim(self, "dropper", anim2, at, Vector2(float(d.x), float(dy[0])))
	# sweep arms: a bar of static balls turning round the hub
	for a in L.arms:
		if not _on_screen(float(a.cx)):
			continue
		for d in L.arm_dots(a, S.t):
			if _has_sheet("sweep_arm"):
				sh.draw_anim(self, "sweep_arm", "dot", t + float(a.i) * 0.1, (d - Vector2(8, 8)).floor())
			else:
				draw_rect(Rect2((d - Vector2(3, 3)).floor(), Vector2(6, 6)), DrawUtil.WHITE)
	# walkers and hoppers
	for n3 in L.walkers.size():
		var w: Dictionary = L.walkers[n3]
		var kind: String = w.kind
		if kind == "flyer" and not _has_sheet("flyer"):
			kind = "walker"   # until the flyer art is in
		if S.walker_fall.has(n3):
			var fp: Vector2 = S.walker_pos(n3)
			var wf: Array = S.walker_fall[n3]
			if wf.size() > 3:
				if S.t - int(wf[3]) < 24:   # knocked out where it landed
					_cut_anim(kind, "knocked" if kind == "spiky" else "stomped", 0.3, Vector2(fp.x - 8, fp.y - 16))
				continue
			if fp.y < L.rows * T + 24.0:
				sh.draw_anim(self, kind, "stomped" if kind in ["walker", "flyer"] else "fall", 0.1, Vector2(fp.x - 8, fp.y - 16))
			continue
		if S.killed.has(n3):
			var ka := (S.t - int(S.killed[n3])) / 60.0
			if ka < 0.4 and not S.walker_fall.has(n3):
				var kp := S.walker_pos(n3)
				sh.draw_anim(self, kind, "knocked" if kind == "spiky" else "stomped", ka, Vector2(kp.x - 8, kp.y - 16))
			continue
		var wp: Vector2 = S.walker_pos(n3)
		if not _on_screen(wp.x):
			continue
		var path: PackedFloat32Array = w.path
		var i2 := mini(S.t, path.size() - 1)
		var right := i2 > 0 and path[i2] > path[i2 - 1]
		if kind == "hopper":
			var s4 := (S.t % 96) / 60.0
			var ha := "idle"
			if s4 < 0.48:
				ha = "jump" if s4 < 0.22 else "fall"
			elif s4 > 1.3:
				ha = "crouch"
			_cut_anim("hopper", ha, t, Vector2(wp.x - 8, wp.y - 16), right)
		elif kind == "flyer":
			_cut_anim("flyer", "fly", t + n3 * 0.13, Vector2(wp.x - 8, wp.y - 16), right)
		else:
			_cut_anim(kind, "walk", t, Vector2(wp.x - 8, wp.y - 16), right)
	# warden
	if L.warden.x >= 0:
		var wd: Vector2 = S.warden_pos(S.t)
		if wd.y < L.rows * T + 64.0:
			var wa := "walk"
			if S.lever_t >= 0 and S.t >= S.lever_t + 24:
				wa = "fall"
			elif (S.t % 150) < 33:
				wa = "hop"
			elif (S.t % 150) > 130:
				wa = "hop_tell"
			sh.draw_anim(self, "warden", wa, t, wd, S.x > wd.x + 16.0)


func _draw_hints() -> void:
	for h in L.hints:
		var p := Vector2(float(h.c) * T, float(h.r) * T)
		if not _on_screen(p.x):
			continue
		var txt := _plain(str(h.text))
		var marks := _marks(str(h.text))
		var w := DrawUtil.text_width(txt)
		draw_rect(Rect2(p.x - 2, p.y - 2, w + 4, 9), DrawUtil.BG)
		ui_clear.append(Rect2(p + world_off - Vector2(3, 3), Vector2(w + 6, 11)))
		DrawUtil.text(self, p, txt, DrawUtil.GRAY)
		# key words stand out: bright and underlined
		for k in txt.length():
			if k < marks.size() and marks[k] and txt[k] != " ":
				DrawUtil.text(self, p + Vector2(k * 4, 0), txt[k], DrawUtil.WHITE)
		_underline(p, txt, marks, 0, txt.length(), DrawUtil.WHITE)


func _draw_player() -> void:
	# dash afterimages
	var keep: Array = []
	for g in ghosts:
		var age := clock - float(g[1])
		if age < 0.2:
			J.spark_ghost(self, g[0], int(age / 0.07), g[2], g[3])
			keep.append(g)
	ghosts = keep
	if state == "dead" or state == "gameover":
		return
	var feet := Vector2(S.x, S.y + 7.0)
	if S.charged:
		sh.draw_anim(self, "fx_charge_glow", "glow", clock, feet - Vector2(12, 19))
	if S.invuln > 0.0 and state == "play" and int(clock * 14.0) % 2 == 0:
		return
	var pose := "stand"
	if not S.on_floor:
		pose = "slide" if S.on_wall and S.vy > 0.0 else "air"
	elif absf(S.vx) > 10.0:
		pose = "run"
	if state == "clear" and state_t < 1.0:
		pose = "slide"
	if handoff >= 0.0 and handoff < 1.1:
		J.spark(self, feet, 1, 1.2, 0.6, "lie", 0.0, -1)   # lying in the grass, eyes shut
		return
	J.spark(self, feet, S.face, S.sx_anim, S.sy_anim, pose, S.anim_t, 1 if S.dash_ready else 0)
	_draw_arc()


## The Arc while its hit box is out: a crackle of static in front of the Spark.
func _draw_arc() -> void:
	var age := _age("arc")
	if age >= 0.2 or S.dead != "":
		return   # the hit box is out for 0.12 s; the last frame, breaking up, shows to 0.2 s
	var box: Rect2 = S.arc_box()
	if _has_sheet("arc"):
		var feet_y: float = S.y + Sim.HALF_H + 0.5
		var at := Vector2(S.x + 4.0 if S.arc_face > 0 else S.x - 28.0, feet_y - 16.0)
		sh.draw_anim(self, "arc", "swing", age, at.floor(), S.arc_face < 0)
		return
	if S.arc_t <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 6:
		var u := float(k) / 5.0
		var px := box.position.x + (u if S.arc_face > 0 else 1.0 - u) * box.size.x
		var h := DrawUtil.hash2(k, int(clock * 30.0))
		pts.append(Vector2(floorf(px), floorf(S.y - 4.0 + float(h % 9) - 4.0)))
	draw_polyline(pts, DrawUtil.WHITE, 1.0)


## A cracked wall (%): the world's ground with cracks, which the Arc breaks.
func _draw_crack(c: int, r: int, p: Vector2) -> void:
	var wn := _world()
	if _has_sheet("crack"):
		var open_l: bool = not Level.SOLID.contains(L.at(c - 1, r))
		var open_r: bool = not Level.SOLID.contains(L.at(c + 1, r))
		var col := 3 if open_l and open_r else (0 if open_l else (2 if open_r else 1))
		sh.draw_frame(self, "crack", "w" + (wn if wn in ["2", "3"] else "1"), col, p)
		return
	draw_rect(Rect2(p, Vector2(16, 16)), DrawUtil.GRAY)
	draw_rect(Rect2(p, Vector2(16, 16)), DrawUtil.DARK, false, 1.0)
	draw_polyline(PackedVector2Array([p + Vector2(4, 2), p + Vector2(8, 7), p + Vector2(5, 11), p + Vector2(9, 14)]), DrawUtil.BG, 1.0)
	draw_line(p + Vector2(8, 7), p + Vector2(13, 5), DrawUtil.BG, 1.0)


## The Arc is learned by clearing World 1, and always there from World 2 on.
func _has_arc() -> bool:
	return items.get("arc", false) or flags.has("w1_clear") or _world() in ["2", "3"]


func _draw_fx() -> void:
	var keep: Array = []
	for f in fx:
		var kind: String = f[0]
		var pos: Vector2 = f[1]
		var age := clock - float(f[2])
		var sd: int = f[3]
		var life := 0.6
		match kind:
			"burst":
				J.burst(self, pos, age, sd, 14)
			"dust":
				J.dust(self, pos, age, sd, 6)
				life = 0.4
			"stomp":
				sh.draw_anim(self, "fx_burst", "stomp", age, pos - Vector2(16, 16))
				life = 0.35
			"debris":
				for i in 4:
					var dv := Vector2(-60.0 + i * 40.0, -160.0 + (i % 2) * 40.0)
					var dp := pos + dv * age + Vector2(0, 460.0 * age * age)
					sh.draw_anim(self, "brick_debris", "spin", age + i * 0.05, dp - Vector2(4, 4), i % 2 == 1)
				life = 0.9
			"arc_hit":
				if _has_sheet("arc_hit"):
					sh.draw_anim(self, "arc_hit", "hit", age, pos - Vector2(8, 8))
				else:
					sh.draw_anim(self, "fx_burst", "stomp", age, pos - Vector2(16, 16))
				life = 0.15
			"crack_break":
				if _has_sheet("crack"):
					sh.draw_anim(self, "crack", "break", age, pos - Vector2(8, 8))
				life = 0.28
			"sparkle":
				sh.draw_anim(self, "fx_sparkle", "twinkle", age, pos - Vector2(4, 4))
				life = 0.3
			"light":
				sh.draw_anim(self, "fx_light", "ring", age, pos - Vector2(24, 24))
				life = 0.5
			"pip_break":
				sh.draw_anim(self, "pip", "break", age, pos)
				life = 0.25
			"pip_fly":
				# the freed Pip wiggles up and away, home to Last Relay
				var fp := pos + Vector2(sin(age * 10.0) * 5.0, -40.0 * age - 220.0 * age * age)
				sh.draw_anim(self, "pip", "free", age, (fp - Vector2(8, 8)).floor())
				life = 1.3
			"big_text":
				var s2: String = f[4]
				var bp := pos + Vector2(-DrawUtil.text_width(s2, 2) / 2.0, -20.0 - age * 18.0)
				DrawUtil.text_shadow(self, bp.floor(), s2, DrawUtil.WHITE, 2)
				life = 1.6
			"text":
				var s: String = f[4]
				var tp := pos + Vector2(-DrawUtil.text_width(s) / 2.0, -12.0 - age * 24.0)
				DrawUtil.text_shadow(self, tp.floor(), s, DrawUtil.WHITE)
				life = 1.0
		if age < life:
			keep.append(f)
	fx = keep


func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 480, 16), DrawUtil.BG)
	draw_rect(Rect2(0, 16, 480, 1), DrawUtil.DARK)
	var y := 5.0
	J.spark(self, Vector2(12, 13), 1, 0.7, 0.7)
	DrawUtil.text(self, Vector2(20, y), "X%02d" % lives, DrawUtil.WHITE)
	if S.charged:
		sh.draw_frame(self, "pickups", "charge", 0, Vector2(40, 0))
	if _has_arc() and _has_sheet("arc_icon") and not _is_hub():
		sh.draw_frame(self, "arc_icon", "hud", 0 if S.arc_cd <= 0.0 else 1, Vector2(54, 3))
	sh.draw_frame(self, "shard", "spin", 0, Vector2(70, 0))
	DrawUtil.text(self, Vector2(86, y), "%02d" % shards, DrawUtil.WHITE)
	var title := "WORLD %s" % (L.meta.get("world", "1") if level_id != "test-room" else "1 TRAINING YARD")
	if level_id.ends_with("-bonus"):
		title = "BONUS ROOM"
	elif _is_hub():
		title = "LAST RELAY"
		if _next_label() != "":
			title += " . NEXT " + _next_label() + " >"   # the signpost at the east end
	DrawUtil.text(self, Vector2(240 - DrawUtil.text_width(title) / 2.0, y), title, DrawUtil.GRAY)
	if clock - life_note_t < 3.0 and state != "pause":
		var n := earned / 100 * 100
		var note := "%d SHARDS . YOU EARNED AN EXTRA LIFE AND KEEP YOUR SHARDS" % n
		var nw := DrawUtil.text_width(note) + 10
		draw_rect(Rect2(240 - nw / 2.0, 22, nw, 13), Color(DrawUtil.BG, 0.85))
		ui_clear.append(Rect2(hx + 240 - nw / 2.0, 22, nw, 13))
		DrawUtil.text(self, Vector2(240 - DrawUtil.text_width(note) / 2.0, 25), note,
			DrawUtil.WHITE if int(clock * 6.0) % 2 == 0 or clock - life_note_t > 1.0 else DrawUtil.GRAY)
	if _is_hub():
		if clock - saved_t < 1.6 and state != "pause":
			DrawUtil.text_shadow(self, Vector2(440, 22), "SAVED", DrawUtil.GRAY)
		return
	var total := L.find("O").size()
	var got: int = (big.get(level_id, {}) as Dictionary).size()
	for i in total:
		_pip_glyph(Vector2(330 + i * 9, 6), DrawUtil.WHITE if i < got else DrawUtil.GRAY, i >= got)
	var tcol := DrawUtil.WHITE if time_left > 100.0 or int(clock * 4.0) % 2 == 0 else DrawUtil.GRAY
	DrawUtil.text(self, Vector2(412, y), "TIME %03d" % maxi(0, int(ceil(time_left))), tcol)
	if clock - saved_t < 1.6 and state != "pause":
		DrawUtil.text_shadow(self, Vector2(440, 22), "SAVED", DrawUtil.GRAY)
		ui_clear.append(Rect2(hx + 438, 20, 26, 10))


func _center(text: String, y: float, col: Color, scale := 1) -> void:
	var w := DrawUtil.text_width(text, scale)
	DrawUtil.text_shadow(self, Vector2(240 - w / 2.0, y), text, col, scale)
	ui_clear.append(Rect2(hx + 238 - w / 2.0, y - 2, w + 5, 6 * scale + 4))


## The intro's closing circle in reverse: black, then a circle opening on the Spark.
func _draw_handoff_iris() -> void:
	if handoff < 0.0 or handoff >= 0.9:
		return
	if handoff < 0.3:
		draw_rect(Rect2(0, 0, vw, 270), DrawUtil.BG)
		return
	var u := (handoff - 0.3) / 0.6
	if AppSettings.reduced_flashes:
		draw_rect(Rect2(0, 0, vw, 270), Color(DrawUtil.BG, 1.0 - u))
		return
	var r := 520.0 * (1.0 - (1.0 - u) * (1.0 - u))
	var c := Vector2(S.x - floorf(cam_x), S.y + 1.0 - floorf(cam_y))
	draw_arc(c, r + 500.0, 0.0, TAU, 96, DrawUtil.BG, 1000.0)


func _draw_overlay() -> void:
	match state:
		"card":
			var a := clampf(1.6 - state_t, 0.0, 1.0) if state_t > 0.9 else 1.0
			draw_rect(Rect2(-hx, 17, vw, 253), Color(DrawUtil.BG, a))
			if a > 0.5:
				var head := "TRAINING YARD" if level_id == "test-room" else "WORLD " + str(L.meta.get("world", ""))
				var sub := "TRY OUT EVERY WORLD 1 MOVE AND TRAP, ONE AT A TIME" if level_id == "test-room" else str(L.name)
				if _is_hub():
					head = "LAST RELAY"
					sub = "THE LAST STATION ON THE LINE THAT STILL HUMS"
				_center(head, 100, DrawUtil.WHITE, 2)
				_center(sub, 124, DrawUtil.GRAY)
				J.spark(self, Vector2(214, 160), 1)
				DrawUtil.text(self, Vector2(228, 152), "X %d" % lives, DrawUtil.WHITE)
				ui_clear.append(Rect2(hx + 204, 146, 64, 20))
				if L.meta.has("owns") and level_id != "test-room":
					_center(str(L.meta.owns).to_upper(), 190, DrawUtil.GRAY)
		"pause":
			_draw_pause()
		"dead":
			if state_t > 0.5:
				draw_rect(Rect2(-hx, 17, vw, 253), Color(DrawUtil.BG, clampf((state_t - 0.5) * 2.0, 0.0, 1.0)))
		"gameover":
			draw_rect(Rect2(-hx, 17, vw, 253), DrawUtil.BG)
			_center("SIGNAL LOST", 110, DrawUtil.WHITE, 2)
			_center("GAME OVER", 140, DrawUtil.GRAY)
		"clear":
			if state_t > 1.0:
				_center("LEVEL CLEAR", 60, DrawUtil.WHITE, 2)
				_center(clear_bonus, 86, DrawUtil.WHITE)
				_center("TIME %s" % DrawUtil.fmt_time(run_time), 100, DrawUtil.GRAY)
		"done":
			draw_rect(Rect2(-hx, 17, vw, 253), Color(DrawUtil.BG, 0.9))
			var w := _world()
			_center("WORLD %s CLEAR" % w, 96, DrawUtil.WHITE, 2)
			if w == "1":
				_center("YOU LIT THE GATE, AND THE CALL GROWS LOUDER", 128, DrawUtil.GRAY)
				if state_t > 1.6:
					_center("YOU LEARNED THE ARC", 160, DrawUtil.WHITE, 2)
					_center("PRESS %s TO THROW IT . IT KNOCKS OUT ANY ENEMY AND BREAKS CRACKED WALLS" % GameInput.action_label("attack"), 186, DrawUtil.GRAY)
			elif w == "2":
				_center("THE RELAY CAN REST . NOW THE LINE CLIMBS INTO THE AERIALS", 128, DrawUtil.GRAY)
			else:
				_center("YOU LIT THE SPIRE . WORLD 4, DEAD AIR, IS COMING SOON", 128, DrawUtil.GRAY)


# ================================================================ village and people

## Last Relay, the hub village: people you talk to (Down), doors into houses,
## Tally's shop and the switchboard level select. Who says what lives in
## levels/story/npcs.json. Nothing here touches the level proofs.
func _is_hub() -> bool:
	return level_id.begins_with("village")


func _has_sheet(name: String) -> bool:
	return sh.tex.has(name)


## "met_wren&!w1_clear": every term must hold, "!" means not, "" is always true.
func _cond(c: String) -> bool:
	for term in c.split("&", false):
		var t := term.strip_edges()
		var want := not t.begins_with("!")
		if flags.has(t.trim_prefix("!")) != want:
			return false
	return true


## Who stands in this level. Decided when the level loads, so someone you have
## just met does not vanish mid-conversation.
func _pick_people() -> void:
	here.clear()
	_send_home()
	for n in L.npcs:
		var who: Dictionary = story.get(str(n.id), {})
		var show: Dictionary = who.get("show", {})
		if show.has(level_id) and _cond(str(show[level_id])):
			here.append(n)


## Someone waiting in a level (shown there while "!met_<id>") goes home to Last
## Relay once you have cleared that level, even if you ran past without talking.
func _send_home() -> void:
	for id in story:
		var show = story[id].get("show", {}) if story[id] is Dictionary else {}
		for lvl in show:
			var met := "met_" + str(id)
			if str(show[lvl]) == "!" + met and flags.has("clear_" + str(lvl)) and not flags.has(met):
				flags.append(met)


## The person, door or switchboard you can use with Down, or {}.
func _usable() -> Dictionary:
	if not S.on_floor:
		return {}
	var row := int(floor((S.y + 7.0) / T)) - 1
	for n in here:
		if absf(S.x - (n.c * T + 8)) < 26.0 and absi(int(n.r) - row) <= 1:
			return {"kind": "npc", "n": n}
	for d in L.doors:
		if absf(S.x - (d.c * T + 8)) < 10.0 and absi(int(d.r) - row) <= 1:
			return {"kind": "door", "d": d}
	for v in L.find("V"):
		if absf(S.x - (v.x * T + 8)) < 16.0 and absi(v.y - row) <= 1:
			return {"kind": "board"}
	return {}


func _use(u: Dictionary) -> void:
	match str(u.kind):
		"npc":
			_start_talk(u.n)
		"door":
			var d: Dictionary = u.d
			var to := str(d.get("to", ""))
			if to == "":
				var msg := "LOCKED."
				if int(d.get("house", -1)) == 0:
					msg = "OLD MAST'S HOUSE. THROUGH THE CRACKED WINDOW, YOU CAN SEE A HALF-FINISHED REPAIR ON HIS BENCH."
				_start_talk({"id": "", "c": d.c, "r": d.r}, [msg])
				return
			_play("door_open")
			if to == "next":
				load_level(_next_level())
			elif d.has("to_c"):
				load_level(to, Vector2i(int(d.to_c), int(d.to_r)), false)
			else:
				load_level(to, Vector2i(-1, -1), false)
		"board":
			_play("menu_confirm")
			board_open = true
			pause_from = "play"
			pause_page = "levels"
			pause_sel = maxi(0, _pause_rows().find(_next_level()))   # start on where the line goes next
			_set_state("pause")


## The first level you haven't cleared yet, in order. The training yard is optional.
func _next_level() -> String:
	for id in ORDER:
		if id != "test-room" and not flags.has("clear_" + id):
			return id
	return ORDER[ORDER.size() - 1]


func _start_talk(n: Dictionary, fixed: Array = []) -> void:
	var lines: Array = fixed
	var entry := {}
	if fixed.is_empty():
		var who: Dictionary = story.get(str(n.id), {})
		for e in who.get("talk", []):
			if _cond(str(e.get("when", ""))):
				entry = e
				break
		lines = entry.get("lines", ["..."])
		if who.has("gifts"):
			lines = _keeper_lines(who, lines)
	talk = {"n": n, "lines": lines, "i": 0, "shown": 0.0, "entry": entry}
	S.vx = 0.0
	_play("talk_open")
	_set_state("talk")


func _talk_frame(delta: float) -> void:
	var line := _plain(str(talk.lines[talk.i]))
	var before := int(talk.shown)
	talk.shown = minf(float(line.length()), float(talk.shown) + delta * 40.0)
	# one voice blip every two letters, each a little higher or lower
	var id := "voice_" + str(talk.n.get("id", ""))
	for k in range(before, int(talk.shown)):
		if k % 2 == 0 and line[k] != " " and sfx.has(id):
			voice.stream = sfx[id]
			voice.pitch_scale = 0.94 + float(DrawUtil.hash2(k, int(talk.i) + 3) % 13) / 100.0
			voice.play()
	var down := _down_pressed()
	if not (Input.is_action_just_pressed("jump") or down) or state_t < 0.15:
		return
	if talk.shown < line.length():
		talk.shown = float(line.length())
		return
	if talk.i + 1 < talk.lines.size():
		talk.i += 1
		talk.shown = 0.0
		_play("talk_next")
		return
	# the conversation is over
	var entry: Dictionary = talk.entry
	for f in entry.get("set", []):
		if not flags.has(f):
			flags.append(f)
	_save_progress()
	hold_jump = true
	if entry.get("shop", false):
		shop_sel = 0
		_set_state("shop")
	else:
		_set_state("play")


func _shop_frame() -> void:
	var n := SHOP.size() + 1
	var down := _down_pressed()
	var up := _up_pressed()
	if state_t < 0.15:
		return
	if up:
		shop_sel = posmod(shop_sel - 1, n)
		_play("menu_move")
	elif down:
		shop_sel = posmod(shop_sel + 1, n)
		_play("menu_move")
	elif Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("ui_cancel"):
		hold_jump = true
		_set_state("play")
	elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
		if shop_sel == SHOP.size():
			hold_jump = true
			_set_state("play")
			return
		var item: Dictionary = SHOP[shop_sel]
		if _owned(str(item.id)) or shards < int(item.price):
			_play("shop_deny")
			return
		shards -= int(item.price)
		match str(item.id):
			"life":
				lives += 1
			"charge":
				charge_next = true
			_:
				items[str(item.id)] = true
		_play("shop_buy")
		_fx("light", Vector2(S.x, S.y - 12))
		_write_save("village")


func _owned(id: String) -> bool:
	return (id == "charge" and charge_next) or bool(items.get(id, false))


## The pad in use, for reading Down and Up directly.
func _pad() -> int:
	return maxi(GameInput.active_device, 0)


## Down, on the frame it goes down (the level code reads Down as held).
func _down_pressed() -> bool:
	var d := Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) \
		or Input.is_joy_button_pressed(_pad(), JOY_BUTTON_DPAD_DOWN) or Input.get_joy_axis(_pad(), JOY_AXIS_LEFT_Y) > 0.6
	var pressed := d and not down_prev
	down_prev = d
	return pressed


func _up_pressed() -> bool:
	var u := Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) \
		or Input.is_joy_button_pressed(_pad(), JOY_BUTTON_DPAD_UP) or Input.get_joy_axis(_pad(), JOY_AXIS_LEFT_Y) < -0.6
	var pressed := u and not up_prev
	up_prev = u
	return pressed


func _draw_people() -> void:
	## House fronts and doors, the switchboard, props and people, in the level.
	for d in L.doors:
		var dp := Vector2(d.c * T, d.r * T)
		var house := int(d.get("house", -1))
		if not _has_sheet("house"):
			draw_rect(Rect2(dp + Vector2(2, -16), Vector2(12, 32)), DrawUtil.DARK)
			continue
		if house >= 0:
			sh.draw_frame(self, "house", "facades", house, dp - Vector2(24, 48))
		if str(d.get("to", "")) == "next":
			sh.draw_frame(self, "village_props", "props", 1, dp)
			var nl := _next_label()
			if nl != "":
				# the signpost says where the line goes next
				var tw := DrawUtil.text_width(nl)
				var right := minf(dp.x + 8.0 + tw / 2.0, L.width * T - 20.0)
				draw_rect(Rect2(right - tw - 3.0, dp.y - 22.0, tw + 6.0, 19.0), Color(DrawUtil.BG, 0.8))
				DrawUtil.text(self, Vector2(right - DrawUtil.text_width("NEXT"), dp.y - 20.0), "NEXT", DrawUtil.GRAY)
				DrawUtil.text(self, Vector2(right - tw, dp.y - 12.0), nl, DrawUtil.WHITE)
		elif house >= 0:
			var open := str(d.get("to", "")) != "" and absf(S.x - (d.c * T + 8)) < 10.0 and state == "play"
			sh.draw_frame(self, "house", "door", 1 if open else 0, dp - Vector2(0, 16))
		else:
			sh.draw_frame(self, "interior", "tiles", 10, dp)
	for v in L.find("V"):
		if _has_sheet("switchboard"):
			sh.draw_anim(self, "switchboard", "idle", clock, Vector2(v.x * T - 8, v.y * T - 16))
		if level_id == "village":
			_draw_pip_crowd(v)
	if _has_sheet("village_props"):
		for ch in ["b", "c", "n", "g"]:
			var frame: int = {"b": 0, "c": 2, "n": 4, "g": 1}[ch]
			for cell in L.find(ch):
				sh.draw_frame(self, "village_props", "props", frame, Vector2(cell.x * T, cell.y * T))
	for n in here:
		var np := Vector2(n.c * T, n.r * T)
		if not _has_sheet("npc"):
			draw_rect(Rect2(np + Vector2(4, -6), Vector2(8, 22)), DrawUtil.GRAY)
			continue
		var talking: bool = state == "talk" and talk.n.get("i", -1) == n.i \
			and talk.shown < _plain(str(talk.lines[talk.i])).length()
		var anim := str(n.id) + ("_talk" if talking else "_idle")
		if str(n.id) == "mast" and (handoff >= 0.0 or lantern_talk) and _has_sheet("intro_npc"):
			_cut_anim("intro_npc", "mast_lantern_look" if handoff >= 0.0 else "mast_lantern_stand", clock, np - Vector2(0, 8), S.x > np.x + 8.0, NPC_LIFT)
			continue
		_cut_anim("npc", anim, clock + n.c * 0.3, np - Vector2(0, 8), S.x > np.x + 8.0, NPC_LIFT)
	if state == "play" and not _usable().is_empty():
		var at := Vector2(S.x - 8, S.y - 32 + roundf(sin(clock * 5.0)))
		if _has_sheet("bubble"):
			sh.draw_anim(self, "bubble", "prompt", clock, at.floor())
		else:
			DrawUtil.text_shadow(self, at.floor(), "V", DrawUtil.WHITE)


## Characters get a one-pixel dark outline so they stand out from any wall or
## backdrop behind them.
func _cut_anim(sheet: String, anim: String, at: float, pos: Vector2, flip := false, mod := Color.WHITE) -> void:
	var f := sh.frame_at(sheet, anim, at)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		sh.draw_frame(self, sheet, anim, f, pos + o, flip, Color.BLACK)
	sh.draw_frame(self, sheet, anim, f, pos, flip, mod)


func _draw_interior() -> void:
	## Inside a house: panelled walls with a lamp, a window, shelves and a poster.
	if str(L.meta.get("interior", "")) == "" or not _has_sheet("interior"):
		return
	for r in range(5, 14):
		for c in range(2, L.width - 2):
			var f := 1 if (c * 3 + r) % 7 == 0 else 0
			if r == 5 and c % 8 == 5:
				f = 8
			elif r == 8 and c % 10 == 6:
				f = 3
			elif r == 11 and c % 9 == 2:
				f = 4
			elif r == 9 and c % 13 == 10:
				f = 9
			sh.draw_frame(self, "interior", "tiles", f, Vector2(c * T, r * T), false, INTERIOR_DIM)


func _draw_bubble() -> void:
	## The speech bubble: the line types out over the speaker, with their name on top.
	if state != "talk":
		return
	var n: Dictionary = talk.n
	var raw := str(talk.lines[talk.i])
	var full := _plain(raw)
	var marks := _marks(raw)
	var rows := _wrap(full, 40)
	var w := 0
	for r in rows:
		w = maxi(w, DrawUtil.text_width(r))
	w = int(ceil((w + 14) / 8.0)) * 8
	var h := int(ceil((rows.size() * 9 + 12) / 8.0)) * 8
	var who: Dictionary = story.get(str(n.get("id", "")), {})
	var anchor := Vector2(n.c * T + 8, n.r * T - 12) - Vector2(floorf(cam_x), floorf(cam_y))
	var x := clampf(anchor.x - w / 2.0, 6.0, vw - 6.0 - w)
	var y := clampf(anchor.y - h - 8.0, 30.0, 262.0 - h)
	var box := Rect2(floorf(x), floorf(y), w, h)
	ui_clear.append(Rect2(box.position.x - 1, box.position.y - 11, box.size.x + 2, box.size.y + 20))   # name above, tail below
	if _has_sheet("bubble"):
		_nine(box)
		# the tail replaces one bottom-edge part and hangs below the bubble
		var tx := box.position.x + clampf(floorf((anchor.x - 4.0 - box.position.x) / 8.0) * 8.0, 8.0, box.size.x - 16.0)
		var tail := Vector2(tx, box.end.y - 8.0)
		sh.draw_frame(self, "bubble", "parts", 9, tail.floor())
	else:
		draw_rect(box, DrawUtil.BG)
		draw_rect(box, DrawUtil.GRAY, false)
	var name := str(who.get("name", ""))
	if name != "":
		DrawUtil.text_shadow(self, box.position + Vector2(6, -9), name, DrawUtil.GRAY)
	# type the line out, wrapped where the full line wraps so words don't jump
	var left := int(talk.shown)
	var start := 0
	for i in rows.size():
		if left <= 0:
			break
		var at := box.position + Vector2(7, 7 + i * 9)
		DrawUtil.text(self, at, str(rows[i]).substr(0, left), DrawUtil.WHITE)
		_underline(at, str(rows[i]), marks, start, left, DrawUtil.GRAY)
		left -= str(rows[i]).length() + 1
		start += str(rows[i]).length() + 1
	if talk.shown >= full.length() and int(clock * 3.0) % 2 == 0:
		DrawUtil.diamond(self, box.end - Vector2(9, 6), DrawUtil.WHITE)


func _nine(box: Rect2) -> void:
	var p := box.position
	var e := box.end - Vector2(8, 8)
	for yy in range(int(p.y) + 8, int(e.y), 8):
		for xx in range(int(p.x) + 8, int(e.x), 8):
			sh.draw_frame(self, "bubble", "parts", 4, Vector2(xx, yy))
		sh.draw_frame(self, "bubble", "parts", 3, Vector2(p.x, yy))
		sh.draw_frame(self, "bubble", "parts", 5, Vector2(e.x, yy))
	for xx in range(int(p.x) + 8, int(e.x), 8):
		sh.draw_frame(self, "bubble", "parts", 1, Vector2(xx, p.y))
		sh.draw_frame(self, "bubble", "parts", 7, Vector2(xx, e.y))
	sh.draw_frame(self, "bubble", "parts", 0, p)
	sh.draw_frame(self, "bubble", "parts", 2, Vector2(e.x, p.y))
	sh.draw_frame(self, "bubble", "parts", 6, Vector2(p.x, e.y))
	sh.draw_frame(self, "bubble", "parts", 8, e)


## Key words in dialogue and hints are written *LIKE THIS* in the text files.
## The asterisks aren't shown: the words are drawn underlined instead.
static func _plain(s: String) -> String:
	return s.replace("*", "")


## One true/false per character of the plain text: is it a key word?
static func _marks(s: String) -> Array:
	var out: Array = []
	var on := false
	for ch in s:
		if ch == "*":
			on = not on
			continue
		out.append(on)
	return out


## Underlines the key-word characters of one row (4 px per character).
func _underline(at: Vector2, row: String, marks: Array, start: int, count: int, col: Color) -> void:
	for k in mini(count, row.length()):
		if start + k < marks.size() and marks[start + k]:
			draw_rect(Rect2(at.x + k * 4, at.y + 6, 4 if k + 1 < row.length() and start + k + 1 < marks.size() and marks[start + k + 1] else 3, 1), col)


func _wrap(s: String, width: int) -> Array:
	var out: Array = []
	var cur := ""
	for word in s.split(" "):
		if cur == "":
			cur = word
		elif (cur + " " + word).length() <= width:
			cur += " " + word
		else:
			out.append(cur)
			cur = word
	out.append(cur)
	return out


func _draw_shop() -> void:
	if state != "shop":
		return
	draw_rect(Rect2(60, 34, 360, 200), Color(DrawUtil.BG, 0.95))
	draw_rect(Rect2(60, 34, 360, 1), DrawUtil.GRAY)
	draw_rect(Rect2(60, 233, 360, 1), DrawUtil.GRAY)
	_center("TALLY'S PARTS", 44, DrawUtil.WHITE, 2)
	var have := "YOU HAVE %d SHARDS" % shards
	var hx := floorf(240.0 - (DrawUtil.text_width(have) + 18) / 2.0)
	sh.draw_frame(self, "shard", "spin", 0, Vector2(hx, 64))
	DrawUtil.text(self, Vector2(hx + 18, 69), have, DrawUtil.GRAY)
	for i in SHOP.size() + 1:
		var y := 92.0 + i * 20.0
		var sel := i == shop_sel
		if sel:
			draw_rect(Rect2(76, y - 5, 328, 18), DrawUtil.WHITE)
		var col := DrawUtil.BG if sel else DrawUtil.GRAY
		if i == SHOP.size():
			DrawUtil.text(self, Vector2(240 - DrawUtil.text_width("LEAVE") / 2.0, y + 1), "LEAVE", col)
			continue
		var item: Dictionary = SHOP[i]
		var owned := _owned(str(item.id))
		if _has_sheet("shop_items"):
			sh.draw_frame(self, "shop_items", "icons", 4 if owned else int(item.icon), Vector2(82, y - 4))
		DrawUtil.text(self, Vector2(104, y + 1), str(item.name), col)
		var price := "OWNED" if owned else "%d" % int(item.price)
		DrawUtil.text(self, Vector2(396 - DrawUtil.text_width(price), y + 1), price, col)
	if shop_sel < SHOP.size():
		_center(str(SHOP[shop_sel].note), 200, DrawUtil.GRAY)
	_center("UP AND DOWN CHOOSE . JUMP BUYS . DASH LEAVES", 218, DrawUtil.GRAY)


func _draw_compass() -> void:
	## With Dot's Pip tuner, a blinking diamond at the screen edge points to the
	## nearest Pip still trapped. (Older saves may have bought it as the shard compass.)
	if not (gifts.has("tuner") or items.get("compass", false)) or _is_hub() or state != "play":
		return
	var best_d := 1e9
	var target := Vector2.ZERO
	for cell in L.find("O"):
		if S.taken.has(cell) or (big.has(level_id) and big[level_id].has("%d,%d" % [cell.x, cell.y])):
			continue
		var wp := Vector2(cell.x * T + 8, cell.y * T + 8)
		var dd := wp.distance_to(Vector2(S.x, S.y))
		if dd < best_d:
			best_d = dd
			target = wp
	if best_d >= 1e9 or int(clock * 3.0) % 3 == 0:
		return
	var sp := target - Vector2(floorf(cam_x), floorf(cam_y))
	var edge := Vector2(clampf(sp.x, 10.0, vw - 10.0), clampf(sp.y, 26.0, 260.0))
	if edge.distance_to(sp) < 1.0:
		return  # already on screen
	DrawUtil.diamond(self, edge.floor(), DrawUtil.WHITE)
	ui_clear.append(Rect2(edge.floor() - Vector2(3, 3), Vector2(11, 11)))


# ================================================================ progress

func _load_progress() -> void:
	var path := progress_path
	if not FileAccess.file_exists(path) and FileAccess.file_exists(path + ".tmp"):
		path += ".tmp"   # a save was cut off between writing and swapping in
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		# keep the unreadable file: the next autosave would otherwise replace it for good
		DirAccess.copy_absolute(path, progress_path + ".bad")
		return
	big = _typed(data.get("big"), {})
	best = _typed(data.get("best"), {})
	save = _typed(data.get("save"), {})
	unlocked = _typed(data.get("unlocked"), ["test-room"])
	# levels finished before level select existed count as reached
	for id in best:
		if not unlocked.has(id):
			unlocked.append(id)
	filter_on = _typed(data.get("filter"), true)
	flags = _typed(data.get("flags"), [])
	items = _typed(data.get("items"), {})
	charge_next = _typed(data.get("charge_next"), false)
	gifts = _typed(data.get("gifts"), [])
	# saves from before this game's clears were kept (version 1): best times stand in
	if float(_typed(data.get("v"), 1.0)) < 2.0 and not save.is_empty():
		for id in best:
			if not flags.has("clear_" + str(id)):
				flags.append("clear_" + str(id))


## A saved value, or `fallback` when it is missing or the wrong type.
func _typed(v, fallback):
	return v if typeof(v) == typeof(fallback) else fallback


## Writes a copy, then swaps it in, so a save cut off halfway never replaces a
## good one. False when the save could not be written.
func _save_progress() -> bool:
	var tmp := progress_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"big": big, "best": best, "save": save, "unlocked": unlocked,
		"filter": filter_on, "flags": flags, "items": items, "charge_next": charge_next, "gifts": gifts, "v": 2}))
	f.close()
	return DirAccess.rename_absolute(tmp, progress_path) == OK
