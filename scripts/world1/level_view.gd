extends Node2D
## Renders a real World 1 level file (levels/world1/*.txt) with the new tiles,
## so the art can be judged on the actual maps. Read-only: it parses the same
## format as tools/levels/levelkit.py (legend, [objects] timings) and animates
## presses, vents, movers, walkers and hoppers as pure functions of `clock`.

const J := preload("res://scripts/world1/juice.gd")
const ROWS := 17
const T := 16.0
const GROUNDISH := "#F"
const SOLID := "#=?CUBLZpF"

var sh
var clock := 0.0
var scroll := 0.0       # left edge of the view in world px
var level_id := ""
var grid: Array = []    # 17 strings
var width := 0
var overrides := {}     # "X#2" -> {key: value}
var level_name := ""

var presses: Array = []
var vents: Array = []
var movers: Array = []
var walkers: Array = []
var hoppers: Array = []
var gates: Array = []
var goal := Vector2i(-1, -1)

func load_level(id: String) -> void:
	level_id = id
	grid = []
	overrides = {}
	var rows: Array = []
	for _i in ROWS:
		rows.append("")
	var f := FileAccess.open("res://levels/world1/%s.txt" % id, FileAccess.READ)
	if f == null:
		push_warning("level_view: cannot open %s" % id)
		return
	var block: Array = []
	var section := "head"
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("== "):
			_flush(block, rows)
			block = []
			section = "grid"
			continue
		if line.strip_edges() == "[objects]":
			_flush(block, rows)
			block = []
			section = "objects"
			continue
		if section == "head":
			if line.begins_with("name:"):
				level_name = line.substr(5).strip_edges()
		elif section == "grid":
			if line.strip_edges() != "":
				block.append(line.strip_edges(false, true))
		elif section == "objects":
			var parts := line.strip_edges().split(" ", false)
			if parts.size() >= 2 and parts[0].contains("#"):
				var kv := {}
				for p in parts.slice(1):
					var bits: PackedStringArray = p.split("=")
					if bits.size() == 2:
						kv[bits[0]] = bits[1]
				overrides[parts[0]] = kv
	_flush(block, rows)
	grid = rows
	width = (grid[0] as String).length()
	_build_objects()

func _flush(block: Array, rows: Array) -> void:
	if block.size() != ROWS:
		return
	var w := 0
	for l in block:
		w = maxi(w, (l as String).length())
	for n in ROWS:
		rows[n] = str(rows[n]) + (block[n] as String).rpad(w, ".")

func at(c: int, r: int) -> String:
	if r < 0:
		return "."
	if c < 0 or c >= width:
		return "#" if r >= 0 and r < ROWS else "."
	if r >= ROWS:
		return "."
	return (grid[r] as String)[c]

func _opt(key: String, field: String, def: float) -> float:
	if overrides.has(key) and overrides[key].has(field):
		return float(overrides[key][field])
	return def

func _floor_below(c: int, r: int) -> int:
	var rr := r + 1
	while rr < ROWS and not SOLID.contains(at(c, rr)):
		rr += 1
	return rr

func _build_objects() -> void:
	presses = []
	vents = []
	movers = []
	walkers = []
	hoppers = []
	gates = []
	goal = Vector2i(-1, -1)
	var nx := 0
	var nt := 0
	var nm := 0
	var seen := {}
	for c in width:
		for r in ROWS:
			var ch := at(c, r)
			match ch:
				"X":
					nx += 1
					var key := "X#%d" % nx
					var bottom := (int(_opt(key, "to", -1)) + 1) if overrides.has(key) and overrides[key].has("to") else _floor_below(c, r)
					presses.append({"c": c, "y0": r * T, "y1": bottom * T - T,
						"period": _opt(key, "period", 2.0), "phase": _opt(key, "phase", 0.0)})
				"T":
					nt += 1
					var key2 := "T#%d" % nt
					vents.append({"c": c, "r": r, "period": _opt(key2, "period", 2.0), "phase": _opt(key2, "phase", 0.0)})
				"m":
					if seen.has(Vector2i(c, r)):
						continue
					nm += 1
					var n := 0
					while at(c + n, r) == "m":
						seen[Vector2i(c + n, r)] = true
						n += 1
					var key3 := "m#%d" % nm
					movers.append({"c": c, "r": r, "n": n, "period": _opt(key3, "period", 4.0),
						"phase": _opt(key3, "phase", 0.0), "dx": _opt(key3, "dx", 4.0), "dy": _opt(key3, "dy", 0.0)})
				"w", "k":
					var span := _walk_span(c, r)
					var e := {"x": c * T + 8.0, "floor": (r + 1) * T, "min": span.x, "max": span.y, "c": c}
					if ch == "w":
						walkers.append(e)
					else:
						hoppers.append(e)
				"|":
					if at(c, r - 1) != "|":
						var h := 0
						while at(c, r + h) == "|":
							h += 1
						gates.append({"c": c, "r": r, "h": h})
				"G":
					goal = Vector2i(c, r)

## Walkers turn at walls and at ledges, so they pace between two fixed x.
func _walk_span(c: int, r: int) -> Vector2:
	var lo := float(c * T + 8)
	var hi := lo
	var x := lo
	while true:
		var nx := x - 1.0
		var cc := int(floorf((nx - 7.0) / T))
		if SOLID.contains(at(cc, r)) or at(cc, r) == "|" or not (SOLID.contains(at(cc, r + 1)) or at(cc, r + 1) == "-"):
			break
		x = nx
		if x < 0.0:
			break
	lo = x
	x = hi
	while true:
		var nx2 := x + 1.0
		var cc2 := int(floorf((nx2 + 7.0) / T))
		if SOLID.contains(at(cc2, r)) or at(cc2, r) == "|" or not (SOLID.contains(at(cc2, r + 1)) or at(cc2, r + 1) == "-"):
			break
		x = nx2
		if x > width * T:
			break
	hi = x
	return Vector2(lo, hi)

# ================================================================== drawing

func _draw() -> void:
	if sh == null or grid.is_empty():
		return
	var cam := floorf(scroll)
	draw_rect(Rect2(0, 0, 480, 270), DrawUtil.BG)
	_draw_sky(cam)
	draw_set_transform(Vector2(-cam, 0))
	var c0 := int(cam / T) - 1
	var c1 := c0 + 32
	for r in ROWS:
		for c in range(c0, c1 + 1):
			if c < 0 or c >= width:
				continue
			_draw_tile(c, r)
	_draw_objects(cam)
	draw_set_transform(Vector2.ZERO)
	DrawUtil.text_shadow(self, Vector2(6, 14), "WORLD %s . %s" % [level_id, level_name], DrawUtil.GRAY)

func _draw_sky(cam: float) -> void:
	# far stars, parallax 0.1, world-indexed so they never swim
	var off := floorf(cam * 0.1)
	for i in 90:
		var h := DrawUtil.hash2(i, 77)
		var x := fposmod(float(h % 4800) - off, 480.0)
		var y := float((h >> 8) % 200)
		draw_rect(Rect2(x, y, 1, 1), DrawUtil.GRAY if h % 11 == 0 else DrawUtil.DARK)
	if goal.x >= 0 and level_id == "1-4":
		var wx := goal.x * T + 8.0
		var sx := (wx - (cam + 240.0)) * 0.2 + 240.0
		sh.draw_anim(self, "gate_transmitter", "dormant", clock, Vector2(sx - 64.0, 224.0 - 224.0),
			false, Color(1, 1, 1, 0.7))

func _draw_tile(c: int, r: int) -> void:
	var ch := at(c, r)
	var p := Vector2(c * T, r * T)
	var t := clock
	match ch:
		"#":
			_draw_ground(c, r, p)
		"=":
			var lip := at(c, r - 1) != "="
			var h := DrawUtil.hash2(c, r)
			var kind := 0
			if h % 37 == 0:
				kind = 2
			elif h % 9 == 0:
				kind = 1
			elif h % 17 == 0:
				kind = 3
			sh.draw_frame(self, "block", "lip" if lip else "stacked", kind, p)
		"-":
			var l := at(c - 1, r) != "-"
			var rr := at(c + 1, r) != "-"
			sh.draw_frame(self, "girder", "static", 3 if l and rr else (0 if l else (2 if rr else 1)), p)
		"?":
			sh.draw_anim(self, "bump_block", "shard", t + c * 0.37, p)
		"C":
			sh.draw_anim(self, "bump_block", "charge", t, p)
		"U":
			sh.draw_anim(self, "bump_block", "life", t, p)
		"B":
			sh.draw_frame(self, "brick", "idle", 0, p)
		"L":
			sh.draw_frame(self, "loose_floor", "still", 0, p)
		"Z":
			sh.draw_frame(self, "bridge", "intact", 0, p)
		"^":
			sh.draw_anim(self, "spikes", "floor", t, p)
		"v":
			sh.draw_anim(self, "spikes", "ceiling", t, p)
		"F":
			sh.draw_frame(self, "loose_ceiling", "intact", 0, p)
		"p":
			var run_start := c
			while at(run_start - 1, r) == "p":
				run_start -= 1
			if (c - run_start) % 2 == 0:
				sh.draw_frame(self, "pipe", "mouth" if at(c, r - 1) != "p" else "body", 0, p)
				if at(c, r - 1) != "p":
					sh.draw_anim(self, "fx_hint", "down", t, p + Vector2(12, -12))
		"_":
			sh.draw_frame(self, "plate", "up", 0, p)
		"K":
			sh.draw_frame(self, "lever", "off", 0, p)
		"S":
			sh.draw_frame(self, "spring", "rest", 0, p)
		"R":
			sh.draw_anim(self, "lift_ring", "idle", t, p - Vector2(4, 4))
		"o":
			var bob := roundf(sin(t * 4.0 + c) * 2.0)
			sh.draw_anim(self, "shard", "spin", t + c * 0.21, p + Vector2(0, bob))
		"O":
			var bob2 := roundf(sin(t * 2.0 + c) * 2.0)
			sh.draw_anim(self, "big_shard", "spin", t, p - Vector2(4, 4 - bob2))
			var ang := t * 2.4
			draw_rect(Rect2((p + Vector2(8 + cos(ang) * 14.0, 8 + sin(ang) * 6.0)).floor(), Vector2.ONE), DrawUtil.WHITE)
		"M":
			sh.draw_frame(self, "beacon", "dark", 0, p - Vector2(0, 16))
		"G":
			sh.draw_frame(self, "mast", "pieces", 0, p)
			for k in range(1, 6):
				sh.draw_frame(self, "mast", "pieces", 1, p - Vector2(0, 16.0 * k))
			sh.draw_frame(self, "mast", "pieces", 2, p - Vector2(0, 96))
			sh.draw_anim(self, "mast_flag", "wave", t, p - Vector2(16, 90))
		"P":
			J.spark(self, p + Vector2(8, 16), 1, 1.0, 1.0, "stand", t, 1)
		"D":
			if at(c - 1, r) != "D" and at(c, r - 1) != "D":
				sh.draw_anim(self, "dropper", "idle", t + c, p)
		"W":
			pass  # drawn with the moving objects
		"|":
			var top := at(c, r - 1) != "|"
			var foot := at(c, r + 1) != "|"
			sh.draw_frame(self, "gate", "pieces", 1 if foot else 0, p)
			if top and SOLID.contains(at(c, r - 1)):
				sh.draw_frame(self, "gate", "cap_closed", 0, p - Vector2(0, 16))

func _draw_ground(c: int, r: int, p: Vector2) -> void:
	var top := not GROUNDISH.contains(at(c, r - 1)) and r > 0
	var bottom := not GROUNDISH.contains(at(c, r + 1)) and r < ROWS - 1
	var left := not GROUNDISH.contains(at(c - 1, r))
	var right := not GROUNDISH.contains(at(c + 1, r))
	var depth := 0
	while depth < 3 and GROUNDISH.contains(at(c, r - depth - 1)) and r - depth - 1 >= 0:
		depth += 1
	if r == 0:
		depth = 3
	var col := 1
	if left and right:
		col = 3
	elif left:
		col = 0
	elif right:
		col = 2
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
	if col == 1 and h % 9 == 0:
		if anim == "top":
			sh.draw_frame(self, "ground", "alt", h % 2, p)
			return
		if anim == "mid":
			sh.draw_frame(self, "ground", "alt", 2, p)
			return
		if anim == "deep":
			sh.draw_frame(self, "ground", "alt", 3, p)
			return
	sh.draw_frame(self, "ground", anim, col, p)

func _draw_objects(_cam: float) -> void:
	var t := clock
	for pr in presses:
		var s := fposmod(t / float(pr.period) + float(pr.phase), 1.0) * float(pr.period)
		var rest := float(pr.period) - 0.12 - 0.35 - 0.6
		var y0: float = pr.y0
		var y1: float = pr.y1
		var y := y0
		var anim := "rest"
		var fr := 0
		var jx := 0.0
		if s < rest - 0.3:
			pass
		elif s < rest:
			anim = "warn"
			fr = sh.frame_at("press", "warn", s)
			jx = 1.0 if int(s * 30.0) % 2 == 0 else -1.0
		elif s < rest + 0.12:
			y = lerpf(y0, y1, (s - rest) / 0.12)
			anim = "slam"
		elif s < rest + 0.47:
			y = y1
			anim = "hold"
		else:
			y = lerpf(y1, y0, (s - rest - 0.47) / 0.6)
		var x := float(pr.c) * T
		var yy := y0
		while yy < y:
			sh.draw_part(self, "press", "shaft", 0, Vector2(x, yy), Rect2(0, 0, 16, minf(16.0, y - yy)))
			yy += 16.0
		sh.draw_frame(self, "press", anim, fr, Vector2(x + jx, y))
		if anim == "hold":
			sh.draw_anim(self, "press_dust", "puff", s - rest - 0.12, Vector2(x - 16, y1))
	for v in vents:
		var sv := fposmod(t / float(v.period) + float(v.phase), 1.0)
		var anim2 := "down"
		var f2 := 0
		if sv >= 0.45 and sv < 0.6:
			anim2 = "warn"
			f2 = sh.frame_at("spike_vent", "warn", sv * 2.0)
		elif sv >= 0.6 and sv < 0.64:
			anim2 = "rise"
			f2 = sh.frame_at("spike_vent", "rise", (sv - 0.6) * 2.0)
		elif sv >= 0.64 and sv < 0.95:
			anim2 = "up"
			f2 = sh.frame_at("spike_vent", "up", (sv - 0.64) * 2.0)
		elif sv >= 0.95:
			anim2 = "retract"
			f2 = sh.frame_at("spike_vent", "retract", (sv - 0.95) * 2.0)
		sh.draw_frame(self, "spike_vent", anim2, f2, Vector2(float(v.c) * T, float(v.r) * T))
	for m in movers:
		var ph := t / float(m.period) + float(m.phase)
		var u := 0.5 - 0.5 * cos(TAU * ph)
		var vel := sin(TAU * ph)
		var ox := u * float(m.dx) * T
		var oy := u * float(m.dy) * T
		var n: int = m.n
		var fr3 := int(t * 12.5) % 4
		if vel < 0.0:
			fr3 = 3 - fr3
		if absf(vel) < 0.08:
			fr3 = 0
		for k in n:
			var piece := "middle"
			if k == 0:
				piece = "left"
			elif k == n - 1:
				piece = "right"
			sh.draw_frame(self, "moving_girder", piece, fr3, Vector2(float(m.c + k) * T + ox, float(m.r) * T + oy).round())
	for w in walkers:
		var span: float = float(w.max) - float(w.min)
		if span <= 1.0:
			sh.draw_anim(self, "walker", "walk", t, Vector2(float(w.x) - 8, float(w.floor) - 16))
			continue
		var cyc := span * 2.0 / 45.0
		var s3 := fposmod(t + float(w.c) * 0.7, cyc)
		var d := s3 * 45.0
		var x3: float
		var face_right := false
		# starts walking left (dir -1) from its spawn
		var start_off: float = float(w.max) - float(w.x)
		d = fposmod(d + start_off, span * 2.0)
		if d < span:
			x3 = float(w.max) - d
		else:
			x3 = float(w.min) + (d - span)
			face_right = true
		var near_end := minf(x3 - float(w.min), float(w.max) - x3) < 4.0
		sh.draw_anim(self, "walker", "turn" if near_end else "walk", t, Vector2(x3 - 8, float(w.floor) - 16), face_right)
	for hp in hoppers:
		var s4 := fposmod(t + float(hp.c) * 0.3, 1.6)
		var base := Vector2(float(hp.x) - 8, float(hp.floor) - 16)
		if s4 < 0.6:
			sh.draw_anim(self, "hopper", "idle", s4, base)
		elif s4 < 0.84:
			sh.draw_anim(self, "hopper", "crouch", s4 - 0.6, base)
		elif s4 < 1.4:
			var f4 := (s4 - 0.84) / 0.56
			sh.draw_frame(self, "hopper", "jump" if f4 < 0.5 else "fall", 0, base - Vector2(0, roundf(136.0 * f4 * (1.0 - f4))))
		else:
			sh.draw_anim(self, "hopper", "land", s4 - 1.4, base)
	for r in ROWS:
		for c in width:
			if at(c, r) == "W" and at(c - 1, r) != "W" and at(c, r - 1) != "W":
				var wx := c * T + fposmod(t * 20.0, 64.0)
				if fposmod(t * 20.0, 128.0) >= 64.0:
					wx = c * T + 64.0 - fposmod(t * 20.0, 64.0)
				sh.draw_anim(self, "warden", "walk", t, Vector2(wx - 16.0 + 16.0, r * T))
