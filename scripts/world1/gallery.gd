extends Node2D
## Gallery pages: every World 1 and World 2 sheet and animation at true scale
## (1 art px = 1 game px), labelled with the 3x5 game font. One-shot animations replay
## after a short pause so every frame is seen.

const J := preload("res://scripts/world1/juice.gd")
const GRAY := DrawUtil.GRAY
const DARK := DrawUtil.DARK
const WHITE := DrawUtil.WHITE

const PAGES := ["TERRAIN AND BLOCKS", "TRAPS AND SWITCHES", "ACTORS AND PICKUPS", "GATE LANDMARK",
	"SWITCHYARD TILES AND ACTORS", "SWITCHYARD RELAY BOSS", "SWITCHYARD BACKDROP",
	"ATMOSPHERE: LAMP, LIGHT, WEATHER, FOG", "LAST RELAY: THE VILLAGE", "LAST RELAY: VILLAGE SHEETS"]

var sh
var page := 0
var clock := 0.0
var _dark_tex: ImageTexture = null

func _draw() -> void:
	if sh == null:
		return
	draw_rect(Rect2(0, 0, 480, 270), DrawUtil.BG)
	match page:
		0: _page_terrain()
		1: _page_traps()
		2: _page_actors()
		3: _page_landmark()
		4: _page_w2_tiles()
		5: _page_w2_relay()
		6: _page_w2_backdrop()
		7: _page_atmosphere()
		8: _page_village()
		9: _page_village_sheets()

# ------------------------------------------------------------------ helpers

## Time into a one-shot animation that replays every (length + pause) s.
func _replay(sheet: String, anim: String, pause := 0.7, offset := 0.0) -> float:
	var total: float = sh.length(sheet, anim) + pause
	return fposmod(clock + offset, total)

func _anim(sheet: String, anim: String, pos: Vector2, flip := false, offset := 0.0) -> void:
	sh.draw_anim(self, sheet, anim, _replay(sheet, anim, 0.7, offset), pos, flip)

func _frame(sheet: String, anim: String, frame: int, pos: Vector2) -> void:
	sh.draw_frame(self, sheet, anim, frame, pos)

func _label(pos: Vector2, s: String, col := GRAY) -> void:
	DrawUtil.text(self, pos, s, col, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _section(pos: Vector2, s: String) -> void:
	DrawUtil.text(self, pos, s, WHITE)
	draw_rect(Rect2(pos.x, pos.y + 7, DrawUtil.text_width(s), 1), DARK)

## A row of labelled cells, each `w` px apart. items = [[label, sheet, anim, frame(-1 = play)], ...]
func _row(x: float, y: float, w: float, items: Array) -> void:
	for i in items.size():
		var it: Array = items[i]
		var sheet: String = it[1]
		var sz: Vector2 = sh.size(sheet)
		var px := x + i * w + (w - sz.x) / 2.0
		var fr: int = it[3]
		if fr < 0:
			_anim(sheet, it[2], Vector2(px, y), false, i * 0.21)
		else:
			_frame(sheet, it[2], fr, Vector2(px, y))
		_label(Vector2(x + i * w + w / 2.0, y + sz.y + 3), it[0])

# ------------------------------------------------------------------ pages

func _page_terrain() -> void:
	_section(Vector2(8, 16), "GROUND #  (AUTO-TILED)")
	# 5x3 slab
	for r in 3:
		var anim: String = ["top", "mid", "deep"][r]
		for c in 5:
			var col := 0 if c == 0 else (2 if c == 4 else 1)
			if r == 0 and c == 2:
				_frame("ground", "alt", 0, Vector2(8 + c * 16, 28 + r * 16))
			else:
				_frame("ground", anim, col, Vector2(8 + c * 16, 28 + r * 16))
	# floating ledge with an underside
	for c in 3:
		var col2 := 0 if c == 0 else (2 if c == 2 else 1)
		_frame("ground", "top", col2, Vector2(100 + c * 16, 28))
		_frame("ground", "bottom", col2, Vector2(100 + c * 16, 44))
	# column and single
	_frame("ground", "top", 3, Vector2(160, 28))
	_frame("ground", "mid", 3, Vector2(160, 44))
	_frame("ground", "deep", 3, Vector2(160, 60))
	_frame("ground", "bottom", 3, Vector2(184, 28))
	for i in 4:
		_frame("ground", "alt", i, Vector2(208 + i * 18, 28))
	_label(Vector2(48, 80), "SLAB")
	_label(Vector2(124, 64), "LEDGE")
	_label(Vector2(168, 80), "COLUMN")
	_label(Vector2(192, 48), "ONE")
	_label(Vector2(242, 48), "VARIANTS")

	_section(Vector2(290, 16), "BLOCK =   GIRDER -")
	for c in 3:
		_frame("block", "lip", [0, 2, 3][c], Vector2(290 + c * 16, 28))
		_frame("block", "stacked", [1, 0, 1][c], Vector2(290 + c * 16, 44))
	for c in 4:
		_frame("girder", "static", 0 if c == 0 else (2 if c == 3 else 1), Vector2(350 + c * 16, 28))
	_frame("girder", "static", 3, Vector2(420, 28))
	var mf := int(clock * 12.5) % 4
	for c in 4:
		sh.draw_frame(self, "moving_girder", "left" if c == 0 else ("right" if c == 3 else "middle"), mf,
			Vector2(350 + c * 16 + roundf(sin(clock * 1.5) * 10.0), 52))
	_label(Vector2(314, 64), "PANELS")
	_label(Vector2(386, 40), "ONE-WAY")
	_label(Vector2(390, 64), "MOVING m")

	_section(Vector2(8, 92), "BUMP BLOCKS ? C U   HIDDEN h   BRICK B")
	_row(8, 104, 30, [
		["SHARD", "bump_block", "shard", -1], ["CHARGE", "bump_block", "charge", -1],
		["1UP", "bump_block", "life", -1], ["HIT", "bump_block", "hit", -1],
		["USED", "bump_block", "used", 0], ["REVEAL", "hidden_block", "reveal", -1],
	])
	_row(190, 104, 30, [
		["BRICK", "brick", "idle", 0], ["BUMP", "brick", "bumped", -1], ["BREAK", "brick", "break", -1],
	])
	for i in 4:
		sh.draw_frame(self, "brick_debris", "spin", (int(clock * 16.0) + i) % 4, Vector2(290 + i * 11, 108))
	_label(Vector2(308, 123), "DEBRIS")
	# brick hop in context: a charged bump breaks the middle brick on a loop
	var bt := fposmod(clock, 1.6)
	_frame("brick", "idle", 0, Vector2(350, 104))
	_frame("brick", "idle", 0, Vector2(382, 104))
	if bt < 0.6:
		_frame("brick", "idle", 0, Vector2(366, 104 + J.bump_hop(bt - 0.4)))
	elif bt < 0.68:
		sh.draw_anim(self, "brick", "break", bt - 0.6, Vector2(366, 104))
	else:
		var d := bt - 0.68
		for i in 4:
			var v: Vector2 = [Vector2(-60, -150), Vector2(60, -150), Vector2(-40, -70), Vector2(40, -70)][i]
			var p := Vector2(370 + (i % 2) * 8, 106 + int(i / 2.0) * 8) + v * d + Vector2(0, 350.0 * d * d)
			if p.y < 150.0:
				sh.draw_frame(self, "brick_debris", "spin", (int(d * 16.0) + i) % 4, p)
	_label(Vector2(382, 123), "SHATTER")

	_section(Vector2(8, 136), "LOOSE FLOOR L    BRIDGE Z    PIPE p")
	_row(4, 148, 28, [
		["STILL", "loose_floor", "still", 0], ["SHAKE", "loose_floor", "shake", -1],
		["FALL", "loose_floor", "fall", 0], ["RUBBLE", "loose_floor", "rubble", 0],
		["ON PLATE", "loose_floor", "rubble", 1],
	])
	for c in 3:
		_frame("bridge", "intact", 0, Vector2(146 + c * 16, 148))
	_label(Vector2(170, 167), "BRIDGE")
	_row(196, 148, 28, [
		["STRESS", "bridge", "stress", -1], ["SNAP", "bridge", "snap", 0], ["PLANK", "bridge", "plank", -1],
	])
	_frame("pipe", "body", 0, Vector2(300, 164))
	_anim("pipe", "mouth", Vector2(300, 148))
	sh.draw_anim(self, "fx_hint", "down", clock, Vector2(312, 136))
	_label(Vector2(316, 183), "PIPE")

	_section(Vector2(8, 196), "SPIKES ^ AND v")
	for c in 4:
		sh.draw_anim(self, "spikes", "floor", clock + c * 0.05, Vector2(8 + c * 16, 208))
		sh.draw_anim(self, "spikes", "ceiling", clock, Vector2(90 + c * 16, 208))
	_label(Vector2(40, 227), "FLOOR (BLINK)")
	_label(Vector2(122, 227), "CEILING")
	_section(Vector2(170, 196), "LOOSE STEPS IN A ROW")
	# a crumble cycle on a strip of 5 loose tiles
	for c in 5:
		var lt := fposmod(clock - c * 0.18, 2.4)
		var x := 170.0 + c * 16
		if lt < 0.6:
			_frame("loose_floor", "still", 0, Vector2(x, 212))
		elif lt < 0.95:
			sh.draw_anim(self, "loose_floor", "shake", lt - 0.6, Vector2(x + (1 if int(lt * 30.0) % 2 else -1), 212))
		elif lt < 1.15:
			_frame("loose_floor", "fall", 0, Vector2(x, J.fall_y(212, lt - 0.95, 236)))
		else:
			_frame("loose_floor", "rubble", 0, Vector2(x, 236))
	draw_rect(Rect2(170, 252, 80, 1), DARK)

func _page_traps() -> void:
	_section(Vector2(8, 16), "SPIKE VENT T")
	_row(8, 28, 26, [
		["DOWN", "spike_vent", "down", 0], ["WARN", "spike_vent", "warn", -1], ["RISE", "spike_vent", "rise", -1],
		["UP", "spike_vent", "up", -1], ["DROP", "spike_vent", "retract", -1],
	])
	# wave: five vents on a clock
	for i in 5:
		var s := fposmod(clock / 2.0 + 0.12 * (4 - i), 1.0)
		var anim := "down"
		var fr := 0
		if s >= 0.45 and s < 0.6:
			anim = "warn"
			fr = sh.frame_at("spike_vent", "warn", s * 2.0)
		elif s >= 0.6 and s < 0.64:
			anim = "rise"
			fr = 1
		elif s >= 0.64 and s < 0.95:
			anim = "up"
			fr = sh.frame_at("spike_vent", "up", s * 2.0)
		elif s >= 0.95:
			anim = "retract"
		sh.draw_frame(self, "spike_vent", anim, fr, Vector2(144 + i * 16, 28))
	_label(Vector2(184, 47), "WAVE")

	_section(Vector2(240, 16), "LOOSE CEILING F")
	var ct := fposmod(clock, 2.2)
	for c in 3:
		_frame("ground", "bottom", 1, Vector2(240 + c * 16, 28))
	if ct < 0.6:
		_frame("loose_ceiling", "intact", 0, Vector2(256, 28))
	elif ct < 1.0:
		sh.draw_anim(self, "loose_ceiling", "crack", ct - 0.6, Vector2(256, 28))
		sh.draw_anim(self, "loose_ceiling", "dust", ct - 0.6, Vector2(256, 44))
	else:
		_frame("loose_ceiling", "empty", 0, Vector2(256, 28))
		if ct < 1.3:
			sh.draw_anim(self, "loose_ceiling", "chunk", ct - 1.0, Vector2(256, J.fall_y(28, ct - 1.0, 60)))
		else:
			_frame("loose_ceiling", "landed", 0, Vector2(256, 60))
	draw_rect(Rect2(240, 76, 48, 1), DARK)
	_label(Vector2(264, 80), "TELL, DROP")
	_row(300, 28, 30, [
		["CHUNK", "loose_ceiling", "chunk", -1], ["DUST", "loose_ceiling", "dust", -1], ["RUBBLE", "loose_ceiling", "landed", 0],
	])

	_section(Vector2(8, 92), "PRESS X")
	# working press between a ceiling and the floor (real 2 s timing)
	for c in 3:
		_frame("ground", "bottom", 1, Vector2(8 + c * 16, 102))
		_frame("ground", "top", 1, Vector2(8 + c * 16, 182))
	var s2 := fposmod(clock, 2.0)
	var hy := 118.0
	var an := "rest"
	var jx := 0.0
	if s2 >= 0.63 and s2 < 0.93:
		an = "warn"
		jx = 1.0 if int(s2 * 30.0) % 2 == 0 else -1.0
	elif s2 >= 0.93 and s2 < 1.05:
		an = "slam"
		hy = lerpf(118.0, 166.0, (s2 - 0.93) / 0.12)
	elif s2 >= 1.05 and s2 < 1.4:
		an = "hold"
		hy = 166.0
	elif s2 >= 1.4:
		hy = lerpf(166.0, 118.0, (s2 - 1.4) / 0.6)
	var yy := 118.0
	while yy < hy:
		sh.draw_part(self, "press", "shaft", 0, Vector2(24, yy), Rect2(0, 0, 16, minf(16.0, hy - yy)))
		yy += 16.0
	sh.draw_anim(self, "press", an, s2 - 0.63, Vector2(24 + jx, hy))
	if s2 >= 1.05 and s2 < 1.4:
		sh.draw_anim(self, "press_dust", "puff", s2 - 1.05, Vector2(8, 166))
	_row(64, 104, 26, [
		["REST", "press", "rest", 0], ["WARN", "press", "warn", -1], ["SLAM", "press", "slam", 0],
		["HOLD", "press", "hold", 0], ["SHAFT", "press", "shaft", 0], ["MOUNT", "press", "shaft", 1],
	])
	_anim("press_dust", "puff", Vector2(82, 140))
	_label(Vector2(106, 159), "SLAM DUST")

	_section(Vector2(230, 92), "DROPPER D")
	_row(230, 102, 48, [
		["IDLE", "dropper", "idle", -1], ["TELL", "dropper", "tell", -1], ["FALL", "dropper", "fall", 0],
		["LAND", "dropper", "land", 0], ["RISE", "dropper", "rise", -1],
	])

	_section(Vector2(8, 200), "PLATE _  GATE |  LEVER K  SPRING S")
	_row(8, 214, 26, [
		["UP", "plate", "up", 0], ["PRESS", "plate", "press", -1], ["DOWN", "plate", "down", 0],
	])
	_row(90, 214, 26, [
		["OFF", "lever", "off", 0], ["PULL", "lever", "pull", -1], ["ON", "lever", "on", 0],
	])
	_row(172, 214, 30, [
		["REST", "spring", "rest", 0], ["BOUNCE", "spring", "bounce", -1],
	])
	# gate assembly, rising on a loop
	var gt := fposmod(clock, 3.0)
	var lift := 0.0
	var cap := "cap_closed"
	if gt >= 0.8 and gt < 1.2:
		lift = 48.0 * ease((gt - 0.8) / 0.4, 0.5)
		cap = "cap_opening"
	elif gt >= 1.2 and gt < 2.4:
		lift = 48.0
		cap = "cap_open" if gt < 1.8 else "cap_opening"
	elif gt >= 2.4 and gt < 2.5:
		lift = 48.0 * (1.0 - (gt - 2.4) / 0.1)
	for k in 4:
		var gy := 190.0 + 16.0 * k - 16.0 - lift
		var cut := maxf(0.0, 190.0 - gy)
		sh.draw_part(self, "gate", "pieces", 1 if k == 3 else 0, Vector2(250, gy), Rect2(0, cut, 16, 16.0 - cut))
	sh.draw_anim(self, "gate", cap, gt, Vector2(250, 174))
	draw_rect(Rect2(244, 238, 28, 1), DARK)
	_label(Vector2(258, 242), "GATE")
	_row(280, 196, 26, [
		["CLOSED", "gate", "cap_closed", 0], ["BLINK", "gate", "cap_opening", -1], ["OPEN", "gate", "cap_open", 0],
	])
	_row(280, 228, 26, [["BARS", "gate", "pieces", 0], ["FOOT", "gate", "pieces", 1]])

func _page_actors() -> void:
	_section(Vector2(8, 16), "WALKER w")
	_row(8, 28, 26, [
		["WALK", "walker", "walk", -1], ["TURN", "walker", "turn", -1], ["STOMP", "walker", "stomped", 0],
	])
	_section(Vector2(96, 16), "HOPPER k")
	_row(96, 28, 26, [
		["IDLE", "hopper", "idle", -1], ["CROUCH", "hopper", "crouch", -1], ["JUMP", "hopper", "jump", 0],
		["FALL", "hopper", "fall", 0], ["LAND", "hopper", "land", 0], ["STOMP", "hopper", "stomped", 0],
	])
	_section(Vector2(260, 16), "WARDEN W")
	_row(258, 26, 44, [
		["WALK", "warden", "walk", -1], ["HOP TELL", "warden", "hop_tell", -1], ["HOP", "warden", "hop", 0],
		["FALL", "warden", "fall", -1], ["HURT", "warden", "hurt", -1],
	])

	_section(Vector2(8, 76), "PICKUPS")
	_row(8, 90, 30, [
		["SHARD", "shard", "spin", -1], ["CHARGE", "pickups", "charge", -1], ["1UP", "pickups", "life", -1],
	])
	sh.draw_anim(self, "big_shard", "spin", clock, Vector2(104, 86))
	for k in 3:
		var ang := clock * 2.4 + k * TAU / 3.0
		var sp := Vector2(116, 98) + Vector2(cos(ang) * 14.0, sin(ang) * 6.0)
		draw_rect(Rect2(sp.floor(), Vector2.ONE), WHITE if sin(ang) > 0.0 else GRAY)
	_label(Vector2(116, 113), "BIG SHARD")
	_row(140, 86, 34, [
		["RING", "lift_ring", "idle", -1], ["POP", "lift_ring", "pop", -1], ["USED", "lift_ring", "used", 0],
	])

	_section(Vector2(260, 76), "BEACON M   MAST G")
	_row(256, 90, 26, [
		["DARK", "beacon", "dark", 0], ["IGNITE", "beacon", "ignite", -1], ["LIT", "beacon", "lit", -1],
	])
	# assembled mast, flag waving; the lit one beside it
	for m in 2:
		var mx := 356.0 + m * 44.0
		_frame("mast", "base_lit" if m == 1 else "pieces", 0, Vector2(mx, 170))
		for k in 5:
			_frame("mast", "pieces", 1, Vector2(mx, 90 + 16.0 * k))
		if m == 1:
			sh.draw_anim(self, "mast", "top_lit", clock, Vector2(mx, 74))
		else:
			_frame("mast", "pieces", 2, Vector2(mx, 74))
		sh.draw_anim(self, "mast_flag", "lit" if m == 1 else "wave", clock, Vector2(mx - 16, 80 + (m * fposmod(clock * 60.0, 80.0))))
	_label(Vector2(364, 190), "MAST")
	_label(Vector2(408, 190), "TOUCHED")

	_section(Vector2(8, 130), "EFFECTS")
	_row(8, 146, 26, [
		["DUST", "fx_dust", "land", -1], ["SKID", "fx_skid", "skid", -1], ["SPARK", "fx_sparkle", "twinkle", -1],
		["HINT", "fx_hint", "down", -1],
	])
	_row(112, 138, 40, [["BURST", "fx_burst", "stomp", -1]])
	_row(152, 130, 52, [["LIGHT", "fx_light", "ring", -1]])
	# Spark with the CHARGE aura
	var feet := Vector2(228, 168)
	sh.draw_anim(self, "fx_charge_glow", "glow", clock, feet + Vector2(-12, -19))
	J.spark(self, feet, 1, 1.0, 1.0, "stand", clock, 1)
	_label(Vector2(228, 176), "CHARGE")
	# dash ghosts, static
	for k in range(3, 0, -1):
		J.spark_ghost(self, Vector2(262 + (3 - k) * 10, 168), k - 1, 1.35, 0.75)
	J.spark(self, Vector2(300, 168), 1, 1.35, 0.75, "air", clock, 0)
	_label(Vector2(282, 176), "DASH GHOSTS")

	_section(Vector2(8, 200), "THE SPARK IS UNCHANGED")
	J.spark(self, Vector2(20, 236), 1, 1.0, 1.0, "stand", clock, 1)
	J.spark(self, Vector2(44, 236), 1, 1.0, 1.0, "run", clock, 1)
	J.spark(self, Vector2(68, 232), 1, 1.0, 1.0, "air", clock, 0)
	J.spark(self, Vector2(92, 236), 1, 1.3, 0.75, "stand", clock, 1)
	for c in 7:
		_frame("ground", "top", 0 if c == 0 else (2 if c == 6 else 1), Vector2(8 + c * 16, 236))

func _page_landmark() -> void:
	sh.draw_anim(self, "gate_transmitter", "dormant", clock, Vector2(20, 14))
	sh.draw_anim(self, "gate_transmitter", "awake", clock, Vector2(170, 14))
	_label(Vector2(84, 244), "DORMANT")
	_label(Vector2(234, 244), "AWAKE")
	var notes := [
		"FAR LAYER, PARALLAX 0.2X",
		"DARK SILHOUETTE, ONE LIT PIXEL",
		"ARCS CRACKLE EVERY 4 S",
		"AWAKE AFTER THE GATE IS LIT:",
		"ARCS EVERY SECOND, LAMPS ON",
		"",
		"IN GAME: 70% OPACITY BEHIND",
		"THE PLAY LAYER (SEE 1-4)",
	]
	for i in notes.size():
		DrawUtil.text(self, Vector2(318, 60 + i * 10), notes[i], GRAY)

# ------------------------------------------------------------------ World 2: the Switchyard

## Which channel is solid `t` seconds into a loop that swaps every `period` s,
## whether the other one is in its 0.3 s arm tell, and the time into the period.
func _channel(t: float, period := 2.0) -> Array:
	var k := int(floorf(t / period))
	var into := fposmod(t, period)
	return [1 + (k % 2), into >= period - 0.3, into]

func _chan_block(ch: int, state: Array, period: float, pos: Vector2) -> void:
	var nm := "one" if ch == 1 else "two"
	if ch == int(state[0]):
		_frame("channel_block", nm + "_solid", 0, pos)
	elif bool(state[1]):
		sh.draw_anim(self, "channel_block", nm + "_arm", float(state[2]) - (period - 0.3), pos)
	else:
		_frame("channel_block", nm + "_off", 0, pos)

func _ground_strip(sheet: String, x: float, y: float, n: int, anim := "top") -> void:
	for c in n:
		_frame(sheet, anim, 0 if c == 0 else (2 if c == n - 1 else 1), Vector2(x + c * 16, y))

func _page_w2_tiles() -> void:
	_section(Vector2(8, 16), "GROUND #  RAIL YARD")
	for r in 3:
		var anim: String = ["top", "mid", "deep"][r]
		for c in 5:
			var col := 0 if c == 0 else (2 if c == 4 else 1)
			if r == 0 and c == 2:
				_frame("ground_w2", "alt", 0, Vector2(8 + c * 16, 28 + r * 16))
			elif r == 1 and c == 3:
				_frame("ground_w2", "alt", 2, Vector2(8 + c * 16, 28 + r * 16))
			else:
				_frame("ground_w2", anim, col, Vector2(8 + c * 16, 28 + r * 16))
	for c in 3:
		var col2 := 0 if c == 0 else (2 if c == 2 else 1)
		_frame("ground_w2", "top", col2, Vector2(100 + c * 16, 28))
		_frame("ground_w2", "bottom", col2, Vector2(100 + c * 16, 44))
	_frame("ground_w2", "top", 3, Vector2(160, 28))
	_frame("ground_w2", "mid", 3, Vector2(160, 44))
	_frame("ground_w2", "deep", 3, Vector2(160, 60))
	_frame("ground_w2", "bottom", 3, Vector2(184, 28))
	for i in 4:
		_frame("ground_w2", "alt", i, Vector2(208 + i * 18, 28))
	_label(Vector2(48, 80), "SLAB")
	_label(Vector2(124, 64), "LEDGE")
	_label(Vector2(168, 80), "COLUMN")
	_label(Vector2(192, 48), "ONE")
	_label(Vector2(242, 48), "VARIANTS")

	_section(Vector2(290, 16), "BLOCK =  SWITCH BOXES")
	for c in 3:
		_frame("block_w2", "lip", [0, 2, 3][c], Vector2(290 + c * 16, 28))
		_frame("block_w2", "stacked", [1, 0, 1][c], Vector2(290 + c * 16, 44))
	for i in 4:
		_frame("block_w2", "lip", i, Vector2(350 + i * 18, 28))
		_frame("block_w2", "stacked", i, Vector2(350 + i * 18, 48))
	_label(Vector2(314, 64), "STACK")
	_label(Vector2(384, 68), "PLAIN VENT PIP BOLT")

	_section(Vector2(8, 88), "CHANNEL BLOCKS 1 2   SWITCH Y")
	_row(4, 100, 28, [
		["ONE", "channel_block", "one_solid", 0], ["OFF", "channel_block", "one_off", 0],
		["ARM", "channel_block", "one_arm", -1], ["TWO", "channel_block", "two_solid", 0],
		["OFF", "channel_block", "two_off", 0], ["ARM", "channel_block", "two_arm", -1],
	])
	_row(176, 100, 28, [
		["ONE", "channel_switch", "one", -1], ["TWO", "channel_switch", "two", -1],
		["HIT", "channel_switch", "hit", -1],
	])
	# live: the Spark bumps the switch every 2 s and the channels swap
	var st := fposmod(clock, 4.0)
	var live := 1 if st < 2.0 else 2
	var since := fposmod(st, 2.0)
	if since < 0.15:
		sh.draw_anim(self, "channel_switch", "hit", since, Vector2(272, 100 + J.bump_hop(since)))
	else:
		sh.draw_anim(self, "channel_switch", "one" if live == 1 else "two", clock, Vector2(272, 100))
	var jump := absf(sin(clamp(since, 0.0, 0.5) * TAU)) * 14.0 if since < 0.5 else 0.0
	J.spark(self, Vector2(280, 134 - jump), 1, 1.0, 1.0, "air" if jump > 0.0 else "stand", clock, 0)
	for c in 3:
		_frame("channel_block", "one_solid" if live == 1 else "one_off", 0, Vector2(300 + c * 16, 100))
		_frame("channel_block", "two_solid" if live == 2 else "two_off", 0, Vector2(356 + c * 16, 100))
	_label(Vector2(334, 119), "BUMP SWAPS")
	# clocked: the arm flickers for 0.3 s before a block turns solid
	var ch: Array = _channel(clock)
	for c in 2:
		_chan_block(1, ch, 2.0, Vector2(420 + c * 16, 88))
		_chan_block(2, ch, 2.0, Vector2(420 + c * 16, 104))
	_label(Vector2(436, 123), "ON A CLOCK")

	_section(Vector2(8, 136), "SPIKED WALKER")
	_row(4, 148, 26, [
		["WALK", "spiky", "walk", -1], ["TURN", "spiky", "turn", -1],
		["KNOCKED", "spiky", "knocked", 0], ["FALL", "spiky", "fall", 0],
	])
	# patrol: walks, tells for 0.24 s at each end, turns
	var pt := fposmod(clock, 4.0)
	var px := 0.0
	var face_right := false
	var anim2 := "walk"
	if pt < 1.76:
		px = 176.0 - pt * 40.0
	elif pt < 2.0:
		px = 105.6
		anim2 = "turn"
	elif pt < 3.76:
		px = 105.6 + (pt - 2.0) * 40.0
		face_right = true
	else:
		px = 176.0
		anim2 = "turn"
	sh.draw_anim(self, "spiky", anim2, pt, Vector2(px, 176), face_right)
	_ground_strip("ground_w2", 104, 192, 6)
	# the Spark for scale: solid white, the teeth stay grey
	J.spark(self, Vector2(20, 208), 1, 1.0, 1.0, "stand", clock, 1)
	_ground_strip("ground_w2", 4, 208, 2)
	_label(Vector2(20, 227), "SPARK")

	_section(Vector2(214, 136), "FUSE Q")
	_ground_strip("ground_w2", 214, 148, 4, "bottom")
	var ft := fposmod(clock, 2.4)
	if ft < 1.0:
		sh.draw_anim(self, "fuse", "live", ft, Vector2(230, 164))
	elif ft < 1.24:
		sh.draw_anim(self, "fuse", "blow", ft - 1.0, Vector2(230, 164))
	else:
		_frame("fuse", "blown", 0, Vector2(230, 164))
	if ft >= 0.8 and ft < 1.0:
		J.spark(self, Vector2(238, 196 - (ft - 0.8) * 60.0), 1, 1.0, 1.0, "air", clock, 0)
	_row(284, 148, 28, [
		["LIVE", "fuse", "live", -1], ["BLOW", "fuse", "blow", -1], ["BLOWN", "fuse", "blown", 0],
	])

	_section(Vector2(284, 190), "STEPS ON A 1.5 S CLOCK")
	var ct: Array = _channel(clock, 1.5)
	for i in 6:
		_chan_block(1 + (i % 2), ct, 1.5, Vector2(284 + i * 20, 236 - i * 5))
	_ground_strip("ground_w2", 284, 244, 8)

func _page_w2_relay() -> void:
	_section(Vector2(8, 16), "RELAY  3X3 BOSS")
	_row(4, 28, 62, [
		["IDLE", "relay", "idle", -1], ["TELL", "relay", "tell", -1], ["SWAP", "relay", "swap", -1],
		["OVERLOAD", "relay", "overload", -1], ["DEAD", "relay", "dead", 0],
	])
	_section(Vector2(8, 94), "LAMPS  DRAWN OVER IDLE")
	for k in 4:
		var lp := Vector2(11 + k * 62, 106)
		sh.draw_anim(self, "relay", "idle", clock, lp)
		_frame("relay", "lamps", k, lp)
		_label(Vector2(lp.x + 24, 157), "%d BLOWN" % k)

	# a fight on a loop: swaps every 2 s after a 0.3 s tell, one lamp blows per
	# swap, then it overloads and dies
	_section(Vector2(320, 16), "FIGHT LOOP")
	var t := fposmod(clock, 10.0)
	var pos := Vector2(400, 196)
	var blown := mini(int(t / 2.0), 3)
	var into := fposmod(t, 2.0)
	if t < 8.0:
		var jx := 0.0
		if into >= 1.7:
			jx = 1.0 if int(into * 30.0) % 2 == 0 else -1.0
			sh.draw_anim(self, "relay", "tell", into - 1.7, pos + Vector2(jx, 0))
		elif into < 0.1 and t >= 2.0:
			sh.draw_anim(self, "relay", "swap", into, pos)
		else:
			sh.draw_anim(self, "relay", "idle", clock, pos)
		_frame("relay", "lamps", blown, pos + Vector2(jx, 0))
	elif t < 8.48:
		sh.draw_anim(self, "relay", "overload", t - 8.0, pos)
	else:
		_frame("relay", "dead", 0, pos)
	var ch: Array = _channel(t) if t < 8.0 else [1, false, 0.0]
	for c in 4:
		_chan_block(1, ch, 2.0, Vector2(290 + c * 16, 196))
		_chan_block(2, ch, 2.0, Vector2(322 + c * 16, 164))
	for c in 3:
		_frame("fuse", "blown" if c < blown or t >= 8.0 else "live", 0, Vector2(330 + c * 36, 40))
	_ground_strip("ground_w2", 320, 24, 8, "bottom")
	_ground_strip("ground_w2", 272, 244, 13)
	_label(Vector2(380, 70), "BLOW A FUSE, A LAMP GOES")
	_label(Vector2(330, 232), "SWAPS EVERY 2 S")

func _page_w2_backdrop() -> void:
	# far layer at 0.2x parallax against the rail at 1x; the piece is picked by slot
	var scroll := clock * 40.0
	var far := scroll * 0.2
	var first := int(floorf(far / 96.0))
	for k in range(first, first + 7):
		var piece := _piece_for_slot(k)
		var x := k * 96.0 - far
		sh.draw_frame(self, "backdrop_w2", "pieces", piece, Vector2(x, 116), false, Color(1, 1, 1, 0.7))
		_label(Vector2(x + 48, 104), ["TOWER", "PYLON", "GANTRY", "HUT"][piece], DARK)
	var near := fposmod(scroll, 16.0)
	for c in 32:
		_frame("ground_w2", "top", 1, Vector2(c * 16 - near, 244))
	var notes := [
		"SWITCHYARD FAR LAYER.  70% OPACITY, PARALLAX 0.2X",
		"PIECES ARE 96 WIDE, LAID EDGE TO EDGE, SO THE CABLES JOIN",
		"MOSTLY PYLONS. A TOWER, GANTRY OR HUT EVERY FEW SLOTS",
	]
	for i in notes.size():
		DrawUtil.text(self, Vector2(8, 20 + i * 10), notes[i], GRAY)

## Pylons, with a tower, gantry or hut every third or fourth slot and never two
## of the same non-pylon piece side by side.
func _piece_for_slot(k: int) -> int:
	var cycle := posmod(int(floorf(k / 7.0)), 3)
	match posmod(k, 7):
		3:
			return [0, 2, 3][cycle]
		6:
			return [2, 3, 0][cycle]
	return 1

# ------------------------------------------------------------------ atmosphere

const LIGHT := 256.0   # light_mask frame size; the light sits at its centre

## The light_mask sheet turned inside out: dark where the mask is transparent,
## clear where it is lit. Built once, so the demo can lay darkness over a scene.
func _darkness_tex() -> ImageTexture:
	if _dark_tex == null:
		var img: Image = sh.tex["light_mask"].get_image()
		img.convert(Image.FORMAT_RGBA8)
		var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		var dark := DrawUtil.BG
		var clear := Color(dark, 0.0)
		for y in img.get_height():
			for x in img.get_width():
				out.set_pixel(x, y, clear if img.get_pixel(x, y).a > 0.5 else dark)
		_dark_tex = ImageTexture.create_from_image(out)
	return _dark_tex

## Covers `region` in darkness except for one light_mask frame centred on
## `centre`. frame < 0 means no light at all.
func _darkness(region: Rect2, centre: Vector2, frame: int, alpha: float) -> void:
	var col := Color(DrawUtil.BG, alpha)
	if frame < 0:
		draw_rect(region, col)
		return
	var s := Rect2(centre.floor() - Vector2(LIGHT, LIGHT) / 2.0, Vector2(LIGHT, LIGHT))
	var i := region.intersection(s)
	if i.has_area():
		draw_texture_rect_region(_darkness_tex(), i,
			Rect2(i.position - s.position + Vector2(frame * LIGHT, 0), i.size), Color(1, 1, 1, alpha))
	var y0 := maxf(region.position.y, s.position.y)
	var y1 := minf(region.end.y, s.end.y)
	for r in [
		Rect2(region.position.x, region.position.y, region.size.x, s.position.y - region.position.y),
		Rect2(region.position.x, s.end.y, region.size.x, region.end.y - s.end.y),
		Rect2(region.position.x, y0, s.position.x - region.position.x, y1 - y0),
		Rect2(s.end.x, y0, region.end.x - s.end.x, y1 - y0),
	]:
		var rr: Rect2 = r
		if rr.size.x > 0.0 and rr.size.y > 0.0:
			draw_rect(rr, col)

func _page_atmosphere() -> void:
	# ---- a dark room: the Spark walks past a lamp, it lights and the dark pulls back
	var room := Rect2(0, 12, 240, 248)
	_ground_strip("ground", 0, 228, 15)
	for c in 15:
		_frame("ground", "mid", 0 if c == 0 else (2 if c == 14 else 1), Vector2(c * 16, 244))
	for k in 3:
		_frame("block", "stacked" if k < 2 else "lip", 0, Vector2(32, 212 - k * 16))
	_frame("block", "lip", 2, Vector2(176, 212))
	for c in 3:
		_frame("girder", "static", c, Vector2(56 + c * 16, 150))
		_frame("girder", "static", c, Vector2(160 + c * 16, 132))
	var lamp_cell := Vector2(112, 212)
	var lamp_pos := lamp_cell - Vector2(0, 16)
	var bulb := lamp_pos + Vector2(8, 8)
	var t := fposmod(clock, 9.0)
	var spark_x := 16.0 + t * 44.0
	var lit_at := (lamp_cell.x + 8.0 - 16.0) / 44.0
	var since := t - lit_at
	var mask := -1
	var mask_name := "NONE, LAMP OFF"
	if since >= 0.0:
		var ig: float = sh.length("lamp", "ignite")
		if since < ig:
			mask = 0 if since < ig * 0.6 else 1
		elif since < 4.0:
			mask = 1
		elif since < 6.0:
			mask = 2
		else:
			mask = 0
		mask_name = ["SMALL R56", "MEDIUM R88", "LARGE R120"][mask]
	_darkness(room, bulb, mask, 0.94)
	# the lamp and the Spark sit above the dark: both are lights
	if since < 0.0:
		_frame("lamp", "off", 0, lamp_pos)
	elif since < sh.length("lamp", "ignite"):
		sh.draw_anim(self, "lamp", "ignite", since, lamp_pos)
	else:
		sh.draw_anim(self, "lamp", "on", since, lamp_pos)
	if spark_x < 236.0:
		J.spark(self, Vector2(spark_x, 228), 1, 1.0, 1.0, "run", clock, 1)
	_section(Vector2(8, 16), "LAMP LIGHTS AS YOU PASS")
	DrawUtil.text(self, Vector2(8, 26), "MASK: " + mask_name, GRAY)
	draw_rect(Rect2(240, 12, 1, 248), DARK)

	# ---- lamp frames
	_section(Vector2(248, 16), "LAMP")
	_row(244, 28, 26, [["OFF", "lamp", "off", 0], ["IGNITE", "lamp", "ignite", -1], ["ON", "lamp", "on", -1]])

	# ---- weather frames
	_section(Vector2(330, 16), "WEATHER")
	for i in 4:
		_frame("weather", "rain", i, Vector2(326 + i * 18, 26))
		_frame("weather", "static", i, Vector2(326 + i * 18, 48))
	_label(Vector2(362, 42), "RAIN")
	_label(Vector2(362, 63), "STATIC")
	_row(404, 26, 30, [["SPLASH", "weather", "splash", -1]])
	for i in 3:
		_frame("weather", "splash", i, Vector2(404 + i * 18, 46))

	# ---- a rain field: drops fall along their slant and splash on the floor
	_section(Vector2(248, 72), "RAIN AND STATIC")
	var floor_y := 152.0
	_ground_strip("ground", 244, floor_y, 15)
	var fall := 0.32
	var life: float = fall + sh.length("weather", "splash")
	for i in 22:
		var u := clock + i * 0.131
		var k := int(floorf(u / life))
		var into := fposmod(u, life)
		var hit_x := 262.0 + fposmod(i * 53.7 + k * 97.3, 200.0)
		if into < fall:
			var dy := (1.0 - into / fall) * 56.0
			sh.draw_frame(self, "weather", "rain", (i + k) % 4, Vector2(hit_x + dy * 0.5 - 8.0, floor_y - 12.0 - dy))
		else:
			sh.draw_anim(self, "weather", "splash", into - fall, Vector2(hit_x - 8.0, floor_y - 16.0))
	var tick := int(clock * 12.0)
	for i in 3:
		var h := DrawUtil.hash2(tick, i)
		if h % 3 != 0:
			var sp := Vector2(252 + h % 210, 84 + int(h / 211.0) % 52)
			sh.draw_frame(self, "weather", "static", (h >> 4) % 4, sp.floor())

	# ---- fog, tiled low in a deep drop in a mixed order, drifting
	_section(Vector2(248, 176), "FOG IN A DEEP DROP")
	var left := 276.0
	var right := 444.0
	var order := [0, 2, 1, 3, 3, 0, 1, 2]
	for band in 2:
		var y := 236.0 + band * 10.0
		var off := fposmod(clock * (6.0 if band == 0 else -4.0), 32.0)
		for k in range(-1, 7):
			var x := left + k * 32.0 + off
			var a := maxf(x, left)
			var b := minf(x + 32.0, right)
			if b > a:
				var fr: int = order[posmod(k - int(floorf(clock * (6.0 if band == 0 else -4.0) / 32.0)) + band * 3, 8)]
				sh.draw_part(self, "fog", "band", fr, Vector2(x, y), Rect2(a - x, 0, b - a, 16))
	for r in 4:
		var anim: String = "top" if r == 0 else ("mid" if r == 1 else "deep")
		_frame("ground", anim, 3 if r > 0 else 2, Vector2(left - 16, 196 + r * 16))
		_frame("ground", anim, 3 if r > 0 else 0, Vector2(right, 196 + r * 16))
	_ground_strip("ground", 244, 196, 2)
	_ground_strip("ground", right, 196, 2)
	_label(Vector2(360, 200), "FRAMES JOIN IN ANY ORDER", DARK)
	for i in 4:
		_frame("fog", "band", i, Vector2(282 + i * 36, 214))

# ------------------------------------------------------------------ Last Relay village

const NPC_IDS := ["mast", "tally", "wren", "brace", "dot", "hum"]
const NPC_LINES := [
	"THE RELAY STILL HUMS. SO DO I.",
	"PARTS FOR SHARDS. FAIR TRADE.",
	"I CAN HEAR THE LINE SINGING!",
	"LEAVE THAT HANDLE WHERE IT IS.",
	"PICK A JACK. I WILL PATCH YOU IN.",
	"MMMMMM. ALL PHASES GOOD.",
]

## Draws an NPC standing in cell (cx, cy): top-left = (cell x, cell y - 8).
func _npc(id: String, cell: Vector2, talking: bool, t: float, flip := false) -> void:
	sh.draw_anim(self, "npc", id + ("_talk" if talking else "_idle"), t, cell - Vector2(0, 8), flip)

## A speech bubble built from the 8x8 bubble parts, its tail tip near `tip`.
func _bubble(tip: Vector2, s: String) -> void:
	var cols := int(ceilf((DrawUtil.text_width(s) + 8) / 8.0))
	var w := maxi(3, cols)
	var h := 3
	var tail_col := 1
	var origin := (tip - Vector2(tail_col * 8 + 3, h * 8 + 6)).floor()
	origin.x = clampf(origin.x, 2.0, 478.0 - w * 8.0)
	for r in h:
		for c in w:
			var col := 0 if c == 0 else (2 if c == w - 1 else 1)
			var row := 0 if r == 0 else (2 if r == h - 1 else 1)
			var part := row * 3 + col
			if r == h - 1 and c == tail_col:
				part = 9
			_frame("bubble", "parts", part, origin + Vector2(c * 8, r * 8))
	DrawUtil.text(self, origin + Vector2(w * 4.0, 10), s, WHITE, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _page_village() -> void:
	# far rooftops, slow parallax, 70% opacity, every bottom on the floor line
	var far := clock * 6.0
	var first := int(floorf(far / 96.0))
	for k in range(first, first + 7):
		var piece := posmod(k * 3 + int(k / 4.0), 4)
		sh.draw_frame(self, "backdrop_village", "pieces", piece, Vector2(k * 96.0 - far, 96), false, Color(1, 1, 1, 0.7))
	var floor_y := 224.0
	var cy := floor_y - 16.0
	for c in 30:
		_frame("ground", "top", 1, Vector2(c * 16, floor_y))
		_frame("ground", "mid", 1, Vector2(c * 16, floor_y + 16))
	# five houses, doors on cells 40, 120, 200, 280, 360
	for k in 5:
		var door := Vector2(40 + k * 80, cy)
		_frame("house", "facades", k, door - Vector2(24, 48))
		if k == 1:   # the shop door opens and shuts on a loop
			_frame("house", "door", 1 if fposmod(clock, 3.0) < 1.4 else 0, door - Vector2(0, 16))
		if k == 0:   # talk prompt over the keeper's door
			sh.draw_anim(self, "bubble", "prompt", clock, door + Vector2(0, -38))
	sh.draw_anim(self, "switchboard", "use" if fposmod(clock, 4.0) < 0.5 else "idle", fposmod(clock, 4.0),
		Vector2(424 - 8, cy - 16))
	_frame("village_props", "props", 1, Vector2(460, cy))
	_frame("village_props", "props", 0, Vector2(84, cy))
	_frame("village_props", "props", 2, Vector2(164, cy))
	_frame("village_props", "props", 5, Vector2(324, cy))
	_frame("village_props", "props", 4, Vector2(404, cy))
	# villagers; one talks at a time, 2.5 s each
	var cells := [Vector2(4, cy), Vector2(144, cy), Vector2(232, cy), Vector2(304, cy), Vector2(444, cy), Vector2(388, cy)]
	var talker := int(floorf(clock / 2.5)) % 6
	for i in 6:
		var talking := i == talker and fposmod(clock, 2.5) < 1.9
		_npc(NPC_IDS[i], cells[i], talking, clock + i * 0.13, i == 0)
	if fposmod(clock, 2.5) < 1.9:
		var tc: Vector2 = cells[talker]
		_bubble(tc + Vector2(8, -12), NPC_LINES[talker])
	J.spark(self, Vector2(260, floor_y), 1, 1.0, 1.0, "stand", clock, 1)
	DrawUtil.text(self, Vector2(8, 16), "LAST RELAY. HUB VILLAGE IN A WORKING RELAY STATION", GRAY)
	DrawUtil.text(self, Vector2(8, 26), "DOORS ON CELLS, NPCS STAND ON THE FLOOR, ONE TALKS AT A TIME", DARK)

func _page_village_sheets() -> void:
	# ---- villagers: idle, talk, idle mirrored
	_section(Vector2(8, 16), "VILLAGERS  IDLE / TALK / MIRRORED")
	for i in 6:
		var x := 8.0 + i * 78.0
		var id: String = NPC_IDS[i]
		sh.draw_anim(self, "npc", id + "_idle", clock + i * 0.1, Vector2(x, 28))
		sh.draw_anim(self, "npc", id + "_talk", clock, Vector2(x + 20, 28))
		sh.draw_anim(self, "npc", id + "_idle", clock + i * 0.1, Vector2(x + 40, 28), true)
		_label(Vector2(x + 28, 55), id.to_upper())
	# ---- room built from the interior tiles
	_section(Vector2(8, 66), "INSIDE: A ROOM FROM THE TILES")
	var room := [
		[0, 1, 0, 8, 0, 0, 1, 8, 0, 0],
		[0, 3, 0, 0, 9, 1, 0, 0, 4, 0],
		[10, 0, 4, 1, 0, 5, 6, 7, 0, 3],
	]
	for r in room.size():
		for c in 10:
			_frame("interior", "tiles", room[r][c], Vector2(8 + c * 16, 78 + r * 16))
	for c in 10:
		_frame("interior", "tiles", 2, Vector2(8 + c * 16, 126))
	_npc("tally", Vector2(104, 110), fposmod(clock, 2.0) < 1.0, clock)
	J.spark(self, Vector2(40, 126), 1, 1.0, 1.0, "stand", clock, 1)
	for i in 11:
		_frame("interior", "tiles", i, Vector2(8 + i * 17, 150))
		_label(Vector2(16 + i * 17, 168), str(i), DARK)
	# ---- shop, props, switchboard
	_section(Vector2(200, 66), "SHOP ITEMS")
	_row(196, 78, 30, [["LIFE", "shop_items", "icons", 0], ["CHARGE", "shop_items", "icons", 1],
		["SHARDS", "shop_items", "icons", 2], ["LAMP", "shop_items", "icons", 3], ["SOLD", "shop_items", "icons", 4]])
	_section(Vector2(400, 66), "SWITCHBOARD")
	_row(396, 76, 40, [["IDLE", "switchboard", "idle", -1], ["USE", "switchboard", "use", -1]])
	_section(Vector2(200, 106), "PROPS")
	_row(196, 118, 32, [["BENCH", "village_props", "props", 0], ["SIGN", "village_props", "props", 1],
		["CRATE", "village_props", "props", 2], ["LAMP", "village_props", "props", 3],
		["MAST", "village_props", "props", 4], ["REEL", "village_props", "props", 5]])
	# ---- bubble parts, a bubble, the prompt
	_section(Vector2(200, 150), "BUBBLE PARTS  AND PROMPT")
	for i in 10:
		_frame("bubble", "parts", i, Vector2(200 + i * 12, 162))
	sh.draw_anim(self, "bubble", "prompt", clock, Vector2(330, 158))
	_label(Vector2(338, 177), "PROMPT")
	_bubble(Vector2(410, 192), "HELLO, SPARK.")
	# ---- door and facades, small
	_section(Vector2(8, 184), "DOORS")
	# door art is 16x32 at the top-left of its 64x64 frame
	for i in 2:
		_frame("house", "door", i, Vector2(12 + i * 24, 196))
		_label(Vector2(20 + i * 24, 231), ["SHUT", "OPEN"][i])
	DrawUtil.text(self, Vector2(64, 196), "FACADES AND BACKDROP ARE ON THE", DARK)
	DrawUtil.text(self, Vector2(64, 206), "PREVIOUS PAGE, AT TRUE SCALE", DARK)
