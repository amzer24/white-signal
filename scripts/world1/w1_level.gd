extends RefCounted
## A World 1 level file (levels/world1/*.txt) and its moving parts.
## Port of tools/levels/levelkit.py. Keep the two in step: the level maps are
## proven against the Python rules, and this is what the game plays.

const ROWS := 17              # one screen; a level may be any multiple of this tall
const T := 16.0
const SOLID := "#=?CUBLZpFYQE"
const ONE_WAY := "-"
const CHANNEL := {"1": 0, "2": 1}   # World 2 channel blocks and the channel they belong to
const BUMPABLE := "?CUhiBYQ"         # blocks that knock out an enemy standing on them
const PERIODIC := {
	"X": {"period": 2.0, "phase": 0.0},
	"T": {"period": 2.0, "phase": 0.0},
	"m": {"period": 4.0, "phase": 0.0, "dx": 4.0, "dy": 0.0},
}

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


static func load_file(level_id: String):
	var L = load("res://scripts/world1/w1_level.gd").new()
	L.id = level_id
	L._parse(FileAccess.get_file_as_string(path_for(level_id)))
	L._build()
	return L


## "2-3" lives in levels/world2/, the test room in levels/world1/.
static func path_for(level_id: String) -> String:
	if level_id.begins_with("village"):
		return "res://levels/village/%s.txt" % level_id
	var world := level_id.get_slice("-", 0)
	return "res://levels/world%s/%s.txt" % [world if world.is_valid_int() else "1", level_id]


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
func find(ch: String) -> Array:
	var out: Array = []
	for c in width:
		for r in rows:
			if grid[r][c] == ch:
				out.append(Vector2i(c, r))
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
	for pair in [["w", "walker", 45.0], ["k", "hopper", 45.0], ["s", "spiky", 35.0]]:
		i = 1
		for p in find(pair[0]):
			var o := opt("%s#%d" % [pair[0], i], {"speed": pair[2], "dir": -1.0})
			o.merge({"kind": pair[1], "i": i, "x": p.x * T + 8, "y": (p.y + 1) * T}, true)
			walkers.append(o)
			i += 1
	for w in walkers:
		w["path"] = walker_path(w)
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
