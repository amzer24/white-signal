extends RefCounted
## A World 1 level file (levels/world1/*.txt) and its moving parts.
## Port of tools/levels/levelkit.py. Keep the two in step: the level maps are
## proven against the Python rules, and this is what the game plays.

const ROWS := 17              # one screen; a level may be any multiple of this tall
const T := 16.0
const SOLID := "#=?CUBLZpFYQEA%t"
const ONE_WAY := "-"
const CHANNEL := {"1": 0, "2": 1}   # World 2 channel blocks and the channel they belong to
const BUMPABLE := "?CUhiBYQ"         # blocks that knock out an enemy standing on them
const PERIODIC := {
	"X": {"period": 2.0, "phase": 0.0},
	"T": {"period": 2.0, "phase": 0.0},
	"m": {"period": 4.0, "phase": 0.0, "dx": 4.0, "dy": 0.0},
}
const FLYER := {"range": 6.0, "amp": 12.0, "period": 2.0}   # World 3 wave flyer defaults

var id := ""
var name := ""
var meta := {}
var grid: Array = []          # `rows` strings
var rows := ROWS              # the level's height in tiles
var width := 0
var screens: Array = []       # [col0, width, title]
var overrides := {}           # "X#2" -> {key: value}

var movers: Array = []
var presses: Array = []
var vents: Array = []
var gates: Array = []
var plates: Array = []
var loose := {}               # Vector2i -> index
var loose_land := {}          # Vector2i -> [fall frames, plate index or 0]
var debris: Array = []
var droppers: Array = []
var springs: Array = []
var rings: Array = []
var walkers: Array = []
var pipes: Array = []
var npcs: Array = []          # {i, c, r, id}
var arms: Array = []          # World 3 sweep arms: {i, cx, cy, len, speed, start}
var gust := Vector2(-1, -1)   # World 3 `gust: period,on` header, or (-1, -1) for steady wind
var turrets: Array = []       # World 4 relay turrets: {i, c, r, x0, y, d, n, off, speed, life}
var echoes: Array = []        # World 4 echoes: {i, x, y, speed, wake}
var static_wall := {}         # World 4 `static:` header: {dir, speed, delay, stop}, or empty
var doors: Array = []         # {i, c, r, to, house, to_c, to_r}
var fuses: Array = []         # World 2 fuse cells
var relay := {}               # World 2 boss: {c, r, period} or empty
var has_channels := false
var hints: Array = []
var start := Vector2i(1, 13)
var goal := Vector2i(-1, -1)
var midway := Vector2i(-1, -1)
var lever := Vector2i(-1, -1)
var warden := Vector2i(-1, -1)
var _found := {}              # find() answers: tile -> [Vector2i]


static func load_file(level_id: String):
	var L = load("res://scripts/world1/w1_level.gd").new()
	L.id = level_id
	L._parse(FileAccess.get_file_as_string(path_for(level_id)))
	L._build()
	return L


## "2-3" lives in levels/world2/, the test room in levels/world1/.
## Centres of a sweep arm's static balls, one every 8 px out from the hub.
func arm_dots(a: Dictionary, at_t: int) -> Array:
	var ang := (float(a.start) + float(a.speed) * at_t * (1.0 / 60.0)) * (PI / 180.0)   # same order as math.radians
	var out: Array = []
	for k in range(1, int(a.len) + 1):
		out.append(Vector2(float(a.cx) + cos(ang) * 8.0 * k, float(a.cy) + sin(ang) * 8.0 * k))
	return out


## Centres of every bolt in flight, as [x, y, turret index]: a turret fires on
## frames where (frame + off) % n == 0, from frame 0 on, and each bolt flies
## until it reaches the first solid tile in its row (levelkit bolts).
func bolts(at_t: int) -> Array:
	var out: Array = []
	for tu in turrets:
		var n: int = tu.n
		var off: int = tu.off
		var f: int = (at_t + off) / n * n - off
		while f >= 0 and at_t - f < int(tu.life):
			out.append([float(tu.x0) + float(tu.d) * float(tu.speed) * (at_t - f) * (1.0 / 60.0), float(tu.y), int(tu.i)])
			f -= n
	return out


## The wall of static's leading edge at frame t: a y when it rises, an x when
## it chases (levelkit static_front).
func static_front(base: float, at_t: int) -> float:
	var moved: float = float(static_wall.speed) * maxf(0.0, at_t * (1.0 / 60.0) - float(static_wall.delay))
	if str(static_wall.dir) == "up":
		return maxf(float(static_wall.stop), base - moved)
	return minf(float(static_wall.stop), base + moved)


## Where the wall starts: below or left of the level, or after a respawn at
## the midway beacon, five tiles below or ten tiles behind it (levelkit static_base).
func static_base(from_midway: bool) -> float:
	if str(static_wall.dir) == "up":
		return float((midway.y + 6) * T) if from_midway and midway.x >= 0 else float(rows * T + 8.0)
	return float((midway.x - 10) * T) if from_midway and midway.x >= 0 else -48.0


## Wind tiles blow all the time, or with a `gust: period,on` header only for
## the first `on` seconds of every `period`.
func gust_on(at_t: int) -> bool:
	if gust.x <= 0.0:
		return true
	return fposmod(at_t * (1.0 / 60.0), gust.x) < gust.y


static func path_for(level_id: String) -> String:
	if level_id.begins_with("village"):
		return "res://levels/village/%s.txt" % level_id
	var world := level_id.get_slice("-", 0)
	return "res://levels/world%s/%s.txt" % [world if world.is_valid_int() else "1", level_id]


## A level's name and how many big shards it holds, read without building the
## level: the switchboard lists every level at once.
static func summary(level_id: String) -> Dictionary:
	var out := {"name": level_id, "big": 0}
	var section := "head"
	for raw in FileAccess.get_file_as_string(path_for(level_id)).split("\n"):
		var line: String = raw.strip_edges(false, true)
		if line.begins_with("== "):
			section = "grid"
		elif line.strip_edges() == "[objects]":
			section = "objects"
		elif section == "head" and line.begins_with("name:"):
			out.name = line.substr(5).strip_edges()
		elif section == "grid":
			out.big += line.count("O")
	return out


func _parse(text: String) -> void:
	var lines: Array = []
	var block: Array = []
	var title := ""
	var section := "head"
	for raw in text.split("\n"):
		var line: String = raw.strip_edges(false, true)
		if line.begins_with("== "):
			_flush(block, lines, title)
			block = []
			title = line.trim_prefix("== ").trim_suffix(" ==").strip_edges()
			section = "grid"
			continue
		if line.strip_edges() == "[objects]":
			_flush(block, lines, title)
			block = []
			section = "objects"
			continue
		if section == "head":
			if line.contains(":") and not line.begins_with("#"):
				var k := line.get_slice(":", 0).strip_edges()
				meta[k] = line.substr(line.find(":") + 1).strip_edges()
		elif section == "grid":
			if line.strip_edges() != "":
				block.append(line)
		elif section == "objects":
			var parts := line.strip_edges().split(" ", false)
			if parts.size() >= 2 and parts[0].contains("#"):
				var kv := {}
				for p in parts.slice(1):
					if p.contains("="):
						var v := p.get_slice("=", 1)
						kv[p.get_slice("=", 0)] = float(v) if v.is_valid_float() else v
				overrides[parts[0]] = kv
	_flush(block, lines, title)
	grid = lines
	rows = grid.size()
	width = grid[0].length()
	name = meta.get("name", id)


func _flush(block: Array, lines: Array, title: String) -> void:
	if block.is_empty():
		return
	assert(block.size() % ROWS == 0 and (lines.is_empty() or block.size() == lines.size()),
		"screen '%s' has %d rows" % [title, block.size()])
	if lines.is_empty():
		for i in block.size():
			lines.append("")
	var w := 0
	for l in block:
		w = maxi(w, l.length())
	screens.append([lines[0].length(), w, title])
	for n in block.size():
		lines[n] += (block[n] as String).rpad(w, ".")


func at(c: int, r: int) -> String:
	if r < 0:
		return "."
	if c < 0 or c >= width or r >= rows:
		return "#" if (c < 0 or c >= width) and r >= 0 else "."
	return grid[r][c]


## Tiles of `ch`, numbered left to right (column by column), as in levelkit.
## The grid never changes after loading, so each answer is kept: the game asks
## several times a frame. Callers must not change the returned array.
func find(ch: String) -> Array:
	if _found.has(ch):
		return _found[ch]
	var out: Array = []
	for c in width:
		for r in rows:
			if grid[r][c] == ch:
				out.append(Vector2i(c, r))
	_found[ch] = out
	return out


func opt(key: String, defaults: Dictionary) -> Dictionary:
	var d := defaults.duplicate()
	d.merge(overrides.get(key, {}), true)
	return d


func floor_below(c: int, r: int) -> int:
	var rr := r + 1
	while rr < rows and not SOLID.contains(at(c, rr)):
		rr += 1
	return rr


func _runs(ch: String, horizontal: bool) -> Array:
	var seen := {}
	var out: Array = []
	for c in width:
		for r in rows:
			if grid[r][c] != ch or seen.has(Vector2i(c, r)):
				continue
			var cells: Array = []
			if horizontal:
				var cc := c
				while cc < width and grid[r][cc] == ch:
					cells.append(Vector2i(cc, r))
					seen[Vector2i(cc, r)] = true
					cc += 1
			else:
				var rr := r
				while rr < rows and grid[rr][c] == ch:
					cells.append(Vector2i(c, rr))
					seen[Vector2i(c, rr)] = true
					rr += 1
			out.append(cells)
	return out


func _build() -> void:
	var i := 1
	for cells in _runs("m", true):
		var o := opt("m#%d" % i, PERIODIC["m"])
		o.merge({"i": i, "x": cells[0].x * T, "y": cells[0].y * T, "w": cells.size() * T, "n": cells.size()}, true)
		movers.append(o)
		i += 1
	i = 1
	for p in find("X"):
		var o := opt("X#%d" % i, PERIODIC["X"])
		var bottom := (int(o["to"]) + 1 if o.has("to") else floor_below(p.x, p.y)) * T
		o.merge({"i": i, "c": p.x, "x": p.x * T, "y0": p.y * T, "y1": bottom - T}, true)
		presses.append(o)
		i += 1
	i = 1
	for p in find("T"):
		var o := opt("T#%d" % i, PERIODIC["T"])
		o.merge({"i": i, "c": p.x, "r": p.y, "x": p.x * T, "y": p.y * T}, true)
		vents.append(o)
		i += 1
	i = 1
	for cells in _runs("|", false):
		var o := opt("gate#%d" % i, {"open": 0.0, "plate": i})
		o.merge({"i": i, "c": cells[0].x, "r": cells[0].y, "x": cells[0].x * T, "y": cells[0].y * T, "h": cells.size() * T}, true)
		gates.append(o)
		i += 1
	i = 1
	for p in find("_"):
		plates.append({"i": i, "c": p.x, "r": p.y})
		i += 1
	i = 1
	for p in find("L"):
		loose[p] = i
		i += 1
	for p in loose:
		var land := floor_below(p.x, p.y)
		var plate := 0
		for pl in plates:
			if pl.c == p.x and pl.r < land and pl.r > p.y:
				plate = pl.i
		# with no floor below (a pit), the piece falls off the bottom of the screen
		var fall: float = (land - 1 - p.y) * T if land < rows else (rows + 1 - p.y) * T
		loose_land[p] = [fall_frames(fall), plate]
	i = 1
	for p in find("F"):
		debris.append({"i": i, "c": p.x, "r": p.y, "x": p.x * T, "y": p.y * T, "land": floor_below(p.x, p.y) * T})
		i += 1
	var seen := {}
	i = 1
	for p in find("D"):
		if seen.has(p):
			continue
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			seen[p + d] = true
		var land := mini(floor_below(p.x, p.y + 1), floor_below(p.x + 1, p.y + 1))
		droppers.append({"i": i, "c": p.x, "x": p.x * T, "y": p.y * T, "y1": land * T - 2 * T})
		i += 1
	for p in find("S"):
		springs.append(Vector2(p.x * T, p.y * T))
	for p in find("R"):
		rings.append(Vector2(p.x * T + 8, p.y * T + 8))
	for pair in [["w", "walker", 45.0], ["k", "hopper", 45.0], ["s", "spiky", 35.0], ["f", "flyer", 40.0]]:
		i = 1
		for p in find(pair[0]):
			var base := {"speed": pair[2], "dir": -1.0}
			if pair[0] == "f":
				base.merge(FLYER)
			var o := opt("%s#%d" % [pair[0], i], base)
			o.merge({"kind": pair[1], "i": i, "x": p.x * T + 8, "y": (p.y + 1) * T}, true)
			walkers.append(o)
			i += 1
	for w in walkers:
		w["path"] = walker_path(w)
	# World 3: sweep arms and gusts
	i = 1
	for p in find("A"):
		var o := opt("arm#%d" % i, {"len": 4.0, "speed": 90.0, "start": 0.0})
		o.merge({"i": i, "cx": p.x * T + 8, "cy": p.y * T + 8}, true)
		arms.append(o)
		i += 1
	var gparts := str(meta.get("gust", "")).split(",")
	if gparts.size() == 2:
		gust = Vector2(float(gparts[0]), float(gparts[1]))
	# World 4: turrets, echoes and a wall of static
	i = 1
	for p in find("t"):
		var o := opt("t#%d" % i, {"dir": -1.0, "period": 2.5, "phase": 0.0, "speed": 110.0})
		var d := 1 if float(o.dir) > 0.0 else -1
		var x0: float = (p.x + 1) * T + 4.0 if d > 0 else p.x * T - 4.0
		var cc: int = p.x + d
		while cc >= 0 and cc < width and not SOLID.contains(at(cc, p.y)) and absi(cc - p.x) <= 40:
			cc += d
		var wall: float = cc * T if d > 0 else (cc + 1) * T   # the face the bolt stops at
		var reach := maxf(0.0, (wall - x0) * d - 4.0)
		var n := int(floor(float(o.period) * 60.0 + 0.5))
		o.merge({"i": i, "c": p.x, "r": p.y, "x0": x0, "y": p.y * T + 8.0, "d": float(d), "n": n,
			"off": posmod(int(floor(float(o.phase) * n + 0.5)), n), "life": int(ceil(reach / (float(o.speed) * (1.0 / 60.0))))}, true)
		turrets.append(o)
		i += 1
	i = 1
	for p in find("e"):
		var o := opt("e#%d" % i, {"speed": 30.0, "wake": 150.0})
		o.merge({"i": i, "x": p.x * T + 8.0, "y": p.y * T + 8.0}, true)
		echoes.append(o)
		i += 1
	var sp := str(meta.get("static", "")).split(",")
	if sp.size() >= 3 and sp[0].strip_edges() in ["up", "right"]:
		var up := sp[0].strip_edges() == "up"
		static_wall = {"dir": sp[0].strip_edges(), "speed": float(sp[1]), "delay": float(sp[2])}
		if sp.size() > 3:
			static_wall["stop"] = int(sp[3]) * T
		else:
			static_wall["stop"] = -T * 4 if up else (width + 4) * T
	# the village: people and doors (look and talk only, nothing solid)
	i = 1
	for p in find("N"):
		var o := opt("npc#%d" % i, {"id": ""})
		o.merge({"i": i, "c": p.x, "r": p.y}, true)
		npcs.append(o)
		i += 1
	i = 1
	for p in find("H"):
		var o := opt("door#%d" % i, {"to": "", "house": -1.0})
		if o.has("c"):
			o["to_c"] = o.c
			o["to_r"] = o.get("r", 13)
		o.merge({"i": i, "c": p.x, "r": p.y}, true)
		doors.append(o)
		i += 1
	fuses = find("Q")
	var e := find("E")
	if e.size() > 0:  # column by column, so the first is the top-left
		relay = opt("relay#1", {"period": 2.5})
		relay.merge({"c": e[0].x, "r": e[0].y}, true)
	for c in width:
		for r in rows:
			if CHANNEL.has(grid[r][c]):
				has_channels = true
	i = 1
	var pipe_seen := {}
	for p in find("p"):
		if pipe_seen.has(p) or at(p.x, p.y - 1) == "p":
			continue
		pipe_seen[p] = true
		pipe_seen[p + Vector2i(1, 0)] = true
		var o := opt("p#%d" % i, {})
		# `c` and `r` in the override name where the pipe comes out in the other level
		if o.has("c"):
			o["to_c"] = o.c
			o["to_r"] = o.get("r", 13)
		o.merge({"i": i, "c": p.x, "r": p.y}, true)
		pipes.append(o)
		i += 1
	i = 1
	while overrides.has("hint#%d" % i):
		var h: Dictionary = overrides["hint#%d" % i]
		hints.append({"c": int(h.get("c", 0)), "r": int(h.get("r", 0)), "text": str(h.get("text", "")).replace("_", " ")})
		i += 1
	var s := find("P")
	if s.size() > 0:
		start = s[0]
	elif doors.size() > 0:  # house interiors: you start at the way out
		start = Vector2i(int(doors[0].c), int(doors[0].r))
	var g := find("G")
	if g.size() > 0:
		goal = g[0]
	var m := find("M")
	if m.size() > 0:
		midway = m[0]
	var k := find("K")
	if k.size() > 0:
		lever = k[0]
	var wd := find("W")
	if wd.size() > 0:
		warden = wd[0]


static func fall_frames(dist: float) -> int:
	var y := 0.0
	var vy := 0.0
	var n := 0
	while y < dist:
		vy = minf(390.0, vy + 920.0 / 60.0)
		y += vy / 60.0
		n += 1
	return n


## Walkers turn at walls and ledges, so their route is a fixed loop (levelkit).
## Walked until the third turn, then that back-and-forth repeats.
func walker_path(w: Dictionary, frames := 60 * 700) -> PackedFloat32Array:
	var xs := PackedFloat32Array()
	if str(w.kind) == "flyer":
		# a flyer ignores the ground and swings `range` tiles out and back
		var span: float = float(w.range) * T
		var n := maxi(1, int(span / (float(w.speed) / 60.0) + 0.5))
		for k in frames:
			var u := 0.0 if span <= 0.0 else 1.0 - absf(float(k % (2 * n)) / n - 1.0)
			xs.append(float(w.x) + float(w.dir) * span * u)
		return xs
	var turns: Array = []
	var x: float = w.x
	var d: float = w.dir
	var row := int(w.y / T) - 1
	while xs.size() < frames:
		var nx := x + d * float(w.speed) / 60.0
		var edge := nx + d * 7.0
		var c := int(floor(edge / T))
		var wall := SOLID.contains(at(c, row)) or at(c, row) == "|"
		var ground := SOLID.contains(at(c, row + 1)) or ONE_WAY.contains(at(c, row + 1))
		if wall or not ground:
			d = -d
			turns.append(xs.size())
		else:
			x = nx
		xs.append(x)
		if turns.size() == 3:
			var loop := xs.slice(int(turns[0]) + 1, int(turns[2]) + 1)
			while xs.size() < frames:
				xs.append_array(loop)
	return xs.slice(0, frames)
