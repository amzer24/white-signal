extends RefCounted
## World 1 rules: the Spark's movement and every tile's behaviour, one frame at
## a time. Port of tools/levels/physics.py and sim.py, plus the Mario layer the
## proofs do not need (bump blocks, CHARGE, pickups). With `proof_mode` on, the
## extras that change the terrain are off, so a route proven in Python replays
## here frame for frame.

const Level := preload("res://scripts/world1/w1_level.gd")

const DT := 1.0 / 60.0
const T := 16.0
const MAX_RUN := 135.0
const ACCEL := 1150.0
const AIR_ACCEL := 780.0
const FRICTION := 1500.0
const GRAVITY := 920.0
const JUMP_VEL := 325.0
const SHORT_HOP := 0.45
const COYOTE := 0.10
const BUFFER := 0.12
const MAX_FALL := 390.0
const DASH_SPEED := 340.0
const DASH_TIME := 0.13
const DASH_EXIT := 170.0
const OVERSPEED_DECAY := 350.0
const WALL_SLIDE := 60.0
const WALL_GRACE := 0.12
const KICK_LOCK := 0.16
const KICK_X := 1.0            # wall kick speed, times MAX_RUN (player.gd uses 1.15)
const AIR_FRICTION := 500.0    # slowdown in the air when no direction is held
const HALF_W := 6.0
const HALF_H := 7.0
const STOMP_BOUNCE := 230.0
const STOMP_GRACE := 6          # frames after a stomp when pressing jump still bounces high
const STOMP_DEPTH := 14.0       # a falling Spark this deep into an enemy's top still stomps it
const SPRING_POWER := 500.0
const RING_LIFT := 300.0
const EPS := 0.001
const WIND_SIDE := 900.0     # World 3 side wind, px/s/s, up to WIND_MAX
const WIND_MAX := 190.0
const WIND_UP := 1600.0      # updraft, up to RISE_MAX
const RISE_MAX := 210.0
const ARC_TIME := 0.12         # the Arc: how long its hit box stays out
const ARC_COOLDOWN := 0.3      # time from one Arc to the next
const ARC_REACH := 18.0        # px in front of the Spark's edge

var L: RefCounted
var proof_mode := false

# --- the Spark -------------------------------------------------------------
var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var on_floor := false
var coyote := 0.0
var buffer := 0.0
var held := false
var face := 1
var dash_t := 0.0
var dash_dir := 1
var dash_ready := true
var wall_grace := 0.0
var wall_dir := 0
var wall_top := 0.0
var spring_t := 0.0
var on_wall := false
var kick_t := 0.0
var invuln := 0.0
var charged := false
var sx_anim := 1.0
var sy_anim := 1.0
var anim_t := 0.0

# --- the level's state -----------------------------------------------------
var t := 0
var loose_trig := {}        # Vector2i -> frame it was stepped on
var debris_trig := {}       # index -> frame
var dropper_trig := {}      # index -> frame
var plates_state := {}      # index -> [first press frame, last press frame]
var killed := {}            # walker index -> frame
var walker_fall := {}       # walker index -> [x, y, vy] once its on_floor is gone
var ring_used := {}         # ring index -> frame
var lever_t := -1
var stomp_chain := 0
var stomp_at := -99         # frame of the last stomp
var boarded := {}           # mover index -> frame (start=ride girders)
var tiles := {}             # Vector2i -> "used" / "broken" / "revealed"
var taken := {}             # Vector2i -> true for collected shards
var bumps: Array = []       # [cell, frame] for the block hop animation
var toggles := 0            # channel switch bumps so far
var fuses := {}             # blown fuse cell -> frame
var relay_down := -1        # frame the relay went down
var drop_held := false      # Down is held this frame (drop through girders)
var pending := {}           # channel blocks the Spark is inside; solid once it leaves
var lit := false            # midway beacon touched
var dead := ""
var won := false
var won_height := 0.0
var events: Array = []      # this frame's events, for sound and effects
var can_arc := false        # the Arc is learned (the game sets this)
var arc_press := false      # attack pressed this frame (the game sets this before advance)
var arc_t := 0.0            # time left on the Arc's hit box
var arc_cd := 0.0
var arc_face := 1
var echo_pos: Array = []    # World 4: [x, y] for each echo (plain floats, as in sim.py)
var echo_moving: Array = [] # true while that echo drifts, for its sounds
var echo_killed := {}       # echo index -> frame the Arc scattered it (play only)
var static_base := 0.0      # where the wall of static starts this life


func _init(level: RefCounted) -> void:
	L = level
	for e in L.echoes:
		echo_pos.append([float(e.x), float(e.y)])
		echo_moving.append(false)


func place(cell: Vector2i) -> void:
	x = cell.x * T + 8.0
	y = (cell.y + 1) * T - HALF_H - 0.5
	vx = 0.0
	vy = 0.0
	on_floor = false
	dash_ready = true
	dash_t = 0.0
	kick_t = 0.0
	spring_t = 0.0
	invuln = 0.5
	if not L.static_wall.is_empty():
		static_base = L.static_base(lit)   # after a respawn at the beacon it starts close behind


func ev(kind: String, data := {}) -> void:
	var e := data.duplicate()
	e["k"] = kind
	events.append(e)


# =========================================================== solidity

func loose_state(cell: Vector2i, at_t: int) -> String:
	if not loose_trig.has(cell):
		return "still"
	return "fallen" if at_t >= int(loose_trig[cell]) + 21 else "shaking"


func loose_fall_y(cell: Vector2i, at_t: int) -> float:
	## Top of a loose floor piece while it is falling, or -1.
	if not loose_trig.has(cell):
		return -1.0
	var fall := at_t - int(loose_trig[cell]) - 21
	if fall < 0 or fall >= int(L.loose_land[cell][0]):
		return -1.0
	return cell.y * T + 0.5 * GRAVITY * pow(fall * DT, 2.0)


func gate_open(g: Dictionary, at_t: int) -> bool:
	if not plates_state.has(int(g.plate)):
		return false
	var ps: Array = plates_state[int(g.plate)]
	if at_t < int(ps[0]) + 15:
		return false
	if float(g.open) == 0.0:
		return true
	return at_t <= int(ps[1]) + int(float(g.open) * 60.0)


func gate_amount(g: Dictionary, at_t: int) -> float:
	## 0 closed .. 1 open, for drawing.
	if g.has("relay"):
		return 0.0 if relay_down < 0 else clampf(float(at_t - relay_down) / 15.0, 0.0, 1.0)
	if not plates_state.has(int(g.plate)):
		return 0.0
	var ps: Array = plates_state[int(g.plate)]
	var opened := clampf(float(at_t - int(ps[0])) / 15.0, 0.0, 1.0)
	if float(g.open) == 0.0:
		return opened
	var close_at := int(ps[1]) + int(float(g.open) * 60.0)
	return minf(opened, clampf(1.0 - float(at_t - close_at) / 15.0, 0.0, 1.0))


func channel(at_t: int, tg := -1, rd := -2) -> int:
	## 0 while channel ONE is live, 1 for TWO. A running relay swaps them on its
	## clock. Once it is down the channel stays where it was. Otherwise the
	## switches decide (sim.py channel).
	var tgl := toggles if tg < 0 else tg
	var down := relay_down if rd == -2 else rd
	if not L.relay.is_empty():
		var n := int(float(L.relay.period) * 60.0)
		return ((at_t if down < 0 else down) / n) % 2
	return tgl % 2


## Frames until the relay's next swap, or -1 when it isn't running.
func relay_next_swap(at_t: int) -> int:
	if L.relay.is_empty() or relay_down >= 0:
		return -1
	var n := int(float(L.relay.period) * 60.0)
	return n - at_t % n


func solid(c: int, r: int, at_t: int) -> bool:
	var ch: String = L.at(c, r)
	var key := Vector2i(c, r)
	if Level.CHANNEL.has(ch):
		return int(Level.CHANNEL[ch]) == channel(at_t) and not pending.has(key)
	match ch:
		"L":
			return loose_state(key, at_t) != "fallen"
		"Z":
			return lever_t < 0 or at_t < lever_t + 18 + 4 * absi(c - L.lever.x)
		"|":
			var g := gate_for(c, r)
			if g.has("relay"):
				return not (relay_down >= 0 and at_t >= relay_down + 15)
			return not gate_open(g, at_t)
		"B", "%":
			return tiles.get(key, "") != "broken"
		"h", "i":
			return not proof_mode and tiles.get(key, "") != ""   # revealed, then used: solid either way
	return Level.SOLID.contains(ch)


func gate_for(c: int, r: int) -> Dictionary:
	for g in L.gates:
		if int(g.c) == c and r >= int(g.r) and r * T < float(g.y) + float(g.h):
			return g
	return {}


func dropper_y(d: Dictionary, at_t: int) -> Array:
	## [top y, falling?] — tell 0.25 s, fall, wait 1.5 s, rise, then re-arm.
	if not dropper_trig.has(int(d.i)) or at_t < int(dropper_trig[int(d.i)]) + 15:
		return [float(d.y), false]
	var s := at_t - int(dropper_trig[int(d.i)]) - 15
	var yy: float = d.y
	var v := 0.0
	var n := 0
	while n < s and yy < float(d.y1):
		v = minf(420.0, v + 1400.0 * DT)
		yy = minf(float(d.y1), yy + v * DT)
		n += 1
	if yy < float(d.y1):
		return [yy, true]
	s -= n + 90
	if s <= 0:
		return [float(d.y1), false]
	return [maxf(float(d.y), float(d.y1) - 50.0 * DT * s), false]


func mover_rect(m: Dictionary, at_t: int) -> Rect2:
	var u := 0.0
	if str(m.get("start", "")) == "ride":
		if boarded.has(int(m.i)):
			u = minf(1.0, float(at_t - int(boarded[int(m.i)])) * DT / (float(m.period) / 2.0))
		u = 0.5 - 0.5 * cos(PI * u)
	else:
		u = 0.5 - 0.5 * cos(TAU * (at_t * DT / float(m.period) + float(m.phase)))
	return Rect2(float(m.x) + u * float(m.dx) * T, float(m.y) + u * float(m.dy) * T, float(m.w), 6.0)


func press_s(p: Dictionary, at_t: int) -> float:
	## seconds into the press cycle, or -1 while a synced press waits.
	var tt := at_t
	if p.has("sync"):
		var mi := int(str(p.sync).trim_prefix("m"))
		if not boarded.has(mi):
			return -1.0
		tt = at_t - int(boarded[mi])
	return fposmod(tt * DT / float(p.period) + float(p.phase), 1.0) * float(p.period)


func press_y(p: Dictionary, at_t: int) -> float:
	var s := press_s(p, at_t)
	if s < 0.0:
		return float(p.y0)
	var rest := float(p.period) - 0.12 - 0.35 - 0.6
	var y0: float = p.y0
	var y1: float = p.y1
	if s < rest:
		return y0
	s -= rest
	if s < 0.12:
		return y0 + (y1 - y0) * s / 0.12
	s -= 0.12
	if s < 0.35:
		return y1
	s -= 0.35
	return y1 - (y1 - y0) * s / 0.6


func vent_phase(v: Dictionary, at_t: int) -> float:
	return fposmod(at_t * DT / float(v.period) + float(v.phase), 1.0)


func rects(at_t: int) -> Array:
	## Moving solids: [Rect2, one_way, kind, index]
	var out: Array = []
	for m in L.movers:
		out.append([mover_rect(m, at_t), true, "m", int(m.i)])
	for d in L.droppers:
		out.append([Rect2(float(d.x), float(dropper_y(d, at_t)[0]), 2 * T, 2 * T), false, "d", int(d.i)])
	return out


# =========================================================== movement

var _bumped: Array = []


func move(px: float, py: float, pvx: float, pvy: float) -> Array:
	var at_t := t + 1
	var fl := false
	var ow := false
	var wd := 0
	var wt := 0.0
	var nx := px + pvx * DT
	var top := py - HALF_H
	var bot := py + HALF_H - EPS
	if pvx != 0.0:
		var lead := nx + (HALF_W if pvx > 0.0 else -HALF_W)
		var c := int(floor((lead - (EPS if pvx > 0.0 else 0.0)) / T))
		for r in range(int(floor(top / T)), int(floor(bot / T)) + 1):
			if solid(c, r, at_t):
				nx = c * T - HALF_W if pvx > 0.0 else (c + 1) * T + HALF_W
				ow = true
				wd = 1 if pvx > 0.0 else -1
				var rr := r
				while solid(c, rr - 1, at_t):
					rr -= 1
				wt = rr * T
				pvx = 0.0
				break
		for rc in rects(at_t):
			var rect: Rect2 = rc[0]
			if rc[1] or not (top < rect.end.y and bot > rect.position.y):
				continue
			if pvx > 0.0 and px + HALF_W <= rect.position.x + EPS and nx + HALF_W > rect.position.x:
				nx = rect.position.x - HALF_W
				pvx = 0.0
				ow = true
				wd = 1
				wt = rect.position.y
			elif pvx < 0.0 and px - HALF_W >= rect.end.x - EPS and nx - HALF_W < rect.end.x:
				nx = rect.end.x + HALF_W
				pvx = 0.0
				ow = true
				wd = -1
				wt = rect.position.y
	var ny := py + pvy * DT
	var left := nx - HALF_W
	var right := nx + HALF_W - EPS
	var c0 := int(floor(left / T))
	var c1 := int(floor(right / T))
	if pvy > 0.0:
		var r := int(floor((ny + HALF_H) / T))
		var prev_feet := py + HALF_H
		for c in range(c0, c1 + 1):
			var ch: String = L.at(c, r)
			if solid(c, r, at_t) or (Level.ONE_WAY.contains(ch) and ch != "" and prev_feet <= r * T + EPS):
				ny = r * T - HALF_H
				pvy = 0.0
				fl = true
				break
		for rc in rects(at_t):
			var rect: Rect2 = rc[0]
			if right > rect.position.x and left < rect.end.x and prev_feet <= rect.position.y + 4.0 \
					and ny + HALF_H >= rect.position.y:
				ny = rect.position.y - HALF_H
				pvy = 0.0
				fl = true
	elif pvy < 0.0:
		var r := int(floor((ny - HALF_H) / T))
		for c in range(c0, c1 + 1):
			# a hidden block becomes solid when struck from below
			if not proof_mode and L.at(c, r) in ["h", "i"] and tiles.get(Vector2i(c, r), "") == "" \
					and py - HALF_H >= (r + 1) * T - 0.5:
				tiles[Vector2i(c, r)] = "revealed"
			if solid(c, r, at_t):
				_bumped.append(Vector2i(c, r))
				ny = (r + 1) * T + HALF_H
				pvy = 0.0
				break
	return [nx, ny, fl, ow, wd, wt, pvx, pvy]


func step_player(dir: int, jump: bool, dash: bool) -> void:
	## physics.step: one frame of the Spark.
	kick_t = maxf(0.0, kick_t - DT)
	if kick_t > 0.0 and dir != 0:
		dir = face
	spring_t = maxf(0.0, spring_t - DT)
	buffer = maxf(0.0, buffer - DT)
	coyote = maxf(0.0, coyote - DT)
	wall_grace = maxf(0.0, wall_grace - DT)
	if jump and not held:
		buffer = BUFFER
	held = jump
	var accel := ACCEL if on_floor else AIR_ACCEL
	if dash_t > 0.0:
		dash_t -= DT
		vx = dash_dir * DASH_SPEED
		vy = 0.0
		if dash_t <= 0.0:
			vx = dash_dir * DASH_EXIT
	else:
		if dir > 0:
			vx = maxf(MAX_RUN, vx - OVERSPEED_DECAY * DT) if vx > MAX_RUN else minf(MAX_RUN, vx + accel * DT)
		elif dir < 0:
			vx = minf(-MAX_RUN, vx + OVERSPEED_DECAY * DT) if vx < -MAX_RUN else maxf(-MAX_RUN, vx - accel * DT)
		elif on_floor:
			var f := FRICTION * DT
			vx = 0.0 if absf(vx) <= f else vx - signf(vx) * f
		elif kick_t <= 0.0:
			var fa := AIR_FRICTION * DT
			vx = 0.0 if absf(vx) <= fa else vx - signf(vx) * fa
		else:
			vx *= (1.0 - 0.4 * DT)
	if on_floor:
		coyote = COYOTE
	# Down + jump on a thin girder drops through it instead of jumping. Moving
	# the feet a few px below the girder's top is enough: one-way tiles only
	# catch feet that were above them. (Play only: the level proofs never press Down.)
	if drop_held and buffer > 0.0 and on_floor and _on_girder_only():
		y += 3.0
		vy = 0.0
		on_floor = false
		coyote = 0.0
		buffer = 0.0
		ev("drop", {"x": x, "y": y + HALF_H})
	if buffer > 0.0 and coyote > 0.0 and not (spring_t > 0.0 and vy < 0.0):
		vy = -JUMP_VEL
		buffer = 0.0
		coyote = 0.0
		sx_anim = 0.72
		sy_anim = 1.32
		ev("jump")
	if not held and spring_t <= 0.0 and dash_t <= 0.0 and vy < -JUMP_VEL * SHORT_HOP:
		vy = -JUMP_VEL * SHORT_HOP
	if buffer > 0.0 and not on_floor and wall_grace > 0.0 and dash_t <= 0.0 and y + HALF_H >= wall_top - 4.0:
		vy = -JUMP_VEL * 0.95
		vx = -wall_dir * MAX_RUN * KICK_X
		buffer = 0.0
		coyote = 0.0
		wall_grace = 0.0
		face = -wall_dir
		kick_t = KICK_LOCK
		sx_anim = 0.75
		sy_anim = 1.3
		ev("wall_kick", {"x": x + wall_dir * HALF_W, "y": y})
	if dash and dash_ready and dash_t <= 0.0:
		dash_t = DASH_TIME
		dash_ready = false
		dash_dir = dir if dir != 0 else face
		face = dash_dir
		vy = 0.0
		invuln = maxf(invuln, 0.2)
		sx_anim = 1.35
		sy_anim = 0.65
		ev("dash")
	if dash_t <= 0.0:
		vy = minf(MAX_FALL, vy + GRAVITY * DT)
	if not on_floor and on_wall and vy > 0.0 and dash_t <= 0.0 and dir != 0 and dir == wall_dir:
		vy = minf(vy, WALL_SLIDE)
	# wind (a dash cuts straight through it)
	var wind := wind_at(x, y)
	if dash_t <= 0.0:
		if wind.x > 0.0 and vx < WIND_MAX:
			vx = minf(WIND_MAX, vx + wind.x * DT)
		elif wind.x < 0.0 and vx > -WIND_MAX:
			vx = maxf(-WIND_MAX, vx + wind.x * DT)
		if wind.y < 0.0 and vy > -RISE_MAX:
			vy = maxf(-RISE_MAX, vy + wind.y * DT)
	var was_floor := on_floor
	var fall_v := vy
	var m := move(x, y, vx, vy)
	x = m[0]
	y = m[1]
	on_floor = m[2]
	on_wall = m[3]
	vx = m[6]
	vy = m[7]
	if dir != 0 and kick_t <= 0.0:
		face = dir
	if on_floor:
		coyote = COYOTE
		dash_ready = true
		wall_grace = 0.0
	elif on_wall:
		wall_grace = WALL_GRACE
	if on_wall:
		wall_dir = m[4]
		wall_top = m[5]
	# look and feel only
	anim_t += DT * (11.0 if absf(vx) > 10.0 and on_floor else 3.0)
	sx_anim += (1.0 - sx_anim) * minf(1.0, DT * 10.0)
	sy_anim += (1.0 - sy_anim) * minf(1.0, DT * 10.0)
	if on_floor and not was_floor:
		var hard := fall_v > 260.0
		sx_anim = 1.35 if hard else 1.18
		sy_anim = 0.65 if hard else 0.8
		ev("land_hard" if hard else "land_soft", {"x": x, "y": y + HALF_H})


# =========================================================== one frame

## True when everything under the Spark's feet is thin girder: nothing solid,
## and not a moving girder.
func _on_girder_only() -> bool:
	var r := int(floor((y + HALF_H + 1.0) / T))
	var any := false
	for c in range(int(floor((x - HALF_W) / T)), int(floor((x + HALF_W - EPS) / T)) + 1):
		var ch: String = L.at(c, r)
		if solid(c, r, t):
			return false
		if Level.ONE_WAY.contains(ch) and ch != "":
			any = true
	if not any:
		return false
	for rc in rects(t):
		var rect: Rect2 = rc[0]
		if x + HALF_W > rect.position.x and x - HALF_W < rect.end.x and absf(y + HALF_H - rect.position.y) < 1.5:
			return false
	return true


func advance(dir: int, jump: bool, dash: bool, down := false) -> void:
	events.clear()
	invuln = maxf(0.0, invuln - DT)
	# carried by a moving girder or a rising dropper
	if on_floor:
		for rc in rects(t):
			var rect: Rect2 = rc[0]
			if x + HALF_W > rect.position.x and x - HALF_W < rect.end.x and absf(y + HALF_H - rect.position.y) < 1.5:
				if rc[2] == "m":
					var mv: Dictionary = L.movers[int(rc[3]) - 1]
					if str(mv.get("start", "")) == "ride" and not boarded.has(int(mv.i)):
						boarded[int(mv.i)] = t
				for rc2 in rects(t + 1):
					if rc2[2] == rc[2] and rc2[3] == rc[3]:
						var r2: Rect2 = rc2[0]
						x += r2.position.x - rect.position.x
						y += r2.position.y - rect.position.y
	# a jump pressed just after a stomp still gives the high bounce (sim.py advance)
	if jump and not held and vy < 0.0 and t - stomp_at <= STOMP_GRACE:
		vy = minf(vy, -JUMP_VEL - 40.0 * maxi(0, stomp_chain - 1))
	_bumped.clear()
	drop_held = down
	step_player(dir, jump, dash)
	t += 1
	_after_move(down)
	_arc()


## The Arc: a short burst of static in front of the Spark. It knocks out any
## enemy it touches, spiked walkers included, and breaks cracked walls (%).
func _arc() -> void:
	arc_cd = maxf(0.0, arc_cd - DT)
	if arc_press and can_arc and arc_cd <= 0.0 and dead == "" and not won:
		arc_t = ARC_TIME
		arc_cd = ARC_COOLDOWN
		arc_face = face
		ev("arc", {"x": x, "y": y, "face": face})
	arc_press = false
	if arc_t <= 0.0 or dead != "":
		return
	arc_t -= DT
	var box := arc_box()
	for n in L.walkers.size():
		if killed.has(n):
			continue
		var wp := walker_pos(n)
		if box.intersects(Rect2(wp.x - 7, wp.y - 18, 14, 18)):
			killed[n] = t
			ev("arc_hit", {"x": wp.x, "y": wp.y - 9, "kind": str(L.walkers[n].kind)})
	for n in L.echoes.size():
		var ep: Array = echo_pos[n]
		if not echo_killed.has(n) and box.intersects(Rect2(float(ep[0]) - 6.0, float(ep[1]) - 6.0, 12.0, 12.0)):
			echo_killed[n] = t
			ev("echo_knock", {"x": ep[0], "y": ep[1]})
	for c in range(int(floor(box.position.x / T)), int(floor(box.end.x / T)) + 1):
		for r in range(int(floor(box.position.y / T)), int(floor(box.end.y / T)) + 1):
			var cell := Vector2i(c, r)
			if L.at(c, r) == "%" and tiles.get(cell, "") != "broken":
				tiles[cell] = "broken"
				ev("wall_break", {"x": c * T + 8.0, "y": r * T + 8.0})


## An echo near the Spark drifts toward it while the Spark faces away, and
## stops the moment the Spark faces it. Echoes pass through walls (sim.py move_echoes).
func _move_echoes() -> void:
	for n in L.echoes.size():
		if echo_killed.has(n):
			continue
		var e: Dictionary = L.echoes[n]
		var ep: Array = echo_pos[n]
		var ex: float = ep[0]
		var ey: float = ep[1]
		var dx: float = x - ex
		var dy: float = y - ey
		var near := absf(dx) < float(e.wake) and absf(dy) < float(e.wake) * 0.75
		var seen := face * dx < 0.0
		var moving := false
		if near and not seen:
			var dist := sqrt(dx * dx + dy * dy)
			if dist > 1.0:
				ex += dx / dist * float(e.speed) * DT
				ey += dy / dist * float(e.speed) * DT
				moving = true
		if moving and not echo_moving[n]:
			ev("echo_move", {"x": ex, "y": ey})
		elif not moving and echo_moving[n] and seen:
			ev("echo_hide", {"x": ex, "y": ey})
		echo_moving[n] = moving
		echo_pos[n] = [ex, ey]


func arc_box() -> Rect2:
	var x0 := x + HALF_W if arc_face > 0 else x - HALF_W - ARC_REACH
	return Rect2(x0, y - 8.0, ARC_REACH, 14.0)


func _hit(x0: float, y0: float, x1: float, y1: float) -> bool:
	return x - HALF_W < x1 and x + HALF_W > x0 and y - HALF_H < y1 and y + HALF_H > y0


func hurt(cause: String) -> bool:
	## Returns true if the Spark died. CHARGE absorbs one hit (not a fall, and
	## not the wall of static, which swallows you whole).
	var whole := cause == "fell" or cause == "static"
	if invuln > 0.0 and not whole:
		return false
	if charged and not whole:
		charged = false
		invuln = 1.2
		vy = -220.0
		ev("charge_lose", {"x": x, "y": y})
		return false
	dead = cause
	ev("death", {"x": x, "y": y, "cause": cause})
	return true


func _after_move(down: bool) -> void:
	var px0 := x - HALF_W
	var px1 := x + HALF_W
	var py1 := y + HALF_H
	# blocks struck from below
	var toggles0 := toggles
	var down0 := relay_down
	for cell in _bumped:
		_bump(cell)
	if not L.relay.is_empty() and relay_down < 0:
		var left := relay_next_swap(t)
		if left == 18:
			ev("channel_arm")
		elif left == int(float(L.relay.period) * 60.0):
			ev("channel_swap")
	# channel blocks the Spark is inside when they turn solid stay open until it leaves
	if L.has_channels:
		var live_next := channel(t + 1)
		var live_now := channel(t, toggles0, down0)
		var pend := {}
		for c in range(int(floor(px0 / T)), int(floor((px1 - EPS) / T)) + 1):
			for r in range(int(floor((y - HALF_H) / T)), int(floor((py1 - EPS) / T)) + 1):
				var ch: String = L.at(c, r)
				if Level.CHANNEL.has(ch) and int(Level.CHANNEL[ch]) == live_next \
						and (pending.has(Vector2i(c, r)) or int(Level.CHANNEL[ch]) != live_now):
					pend[Vector2i(c, r)] = true
		pending = pend
	# loose floors: triggered by standing on them
	if on_floor:
		var r := int(floor((y + HALF_H + 1.0) / T))
		for c in range(int(floor(px0 / T)), int(floor((px1 - EPS) / T)) + 1):
			var key := Vector2i(c, r)
			if L.at(c, r) == "L" and not loose_trig.has(key):
				loose_trig[key] = t
				ev("loose_floor_shake", {"x": c * T + 8, "y": r * T})
	for key in loose_trig:
		var age := t - int(loose_trig[key])
		if age == 21:
			ev("loose_floor_fall", {"x": key.x * T + 8, "y": key.y * T})
		elif age == 21 + int(L.loose_land[key][0]) and L.floor_below(key.x, key.y) < L.rows:
			ev("loose_floor_land", {"x": key.x * T + 8, "y": key.y * T + 16})
	# a falling loose floor crushes the Spark if it comes down on top of it
	for key in loose_trig:
		var ly := loose_fall_y(key, t)
		if ly >= 0.0 and _hit(key.x * T + 2, ly + 2, key.x * T + 14, ly + 14) and y - HALF_H > ly + 6.0:
			if hurt("loose floor"):
				return
	# plates: pressed by the Spark or by fallen loose on_floor
	for p in L.plates:
		var x0 := int(p.c) * T
		var y0 := int(p.r) * T + T - 4.0
		var pressed := on_floor and _hit(x0, y0 - 2.0, x0 + T, y0 + 4.0)
		for cell in loose_trig:
			var land: Array = L.loose_land[cell]
			if int(land[1]) == int(p.i) and t >= int(loose_trig[cell]) + 21 + int(land[0]):
				pressed = true
		if pressed:
			if plates_state.has(int(p.i)):
				plates_state[int(p.i)][1] = t
			else:
				plates_state[int(p.i)] = [t, t]
				ev("plate_click", {"x": x0 + 8, "y": y0})
				ev("gate_open")
	# gates that just closed again
	for g in L.gates:
		if plates_state.has(int(g.plate)) and float(g.open) > 0.0:
			if t == int(plates_state[int(g.plate)][1]) + int(float(g.open) * 60.0) + 1:
				ev("gate_close")
	# loose ceilings
	for d in L.debris:
		var di := int(d.i)
		if not debris_trig.has(di) and absf(x - (float(d.x) + 8.0)) < 20.0 and y > float(d.y):
			debris_trig[di] = t
			ev("loose_ceiling_crack", {"x": float(d.x) + 8, "y": float(d.y) + 16})
	for di in debris_trig:
		var d: Dictionary = L.debris[di - 1]
		var s := t - int(debris_trig[di]) - 24
		if s == 0:
			ev("loose_ceiling_fall")
		if s >= 0:
			var yy := float(d.y) + 0.5 * GRAVITY * pow(s * DT, 2.0)
			if yy < float(d.land) and _hit(float(d.x) + 2, yy + 2, float(d.x) + 14, yy + 14):
				if hurt("loose ceiling"):
					return
			elif yy >= float(d.land) and float(d.y) + 0.5 * GRAVITY * pow((s - 1) * DT, 2.0) < float(d.land):
				ev("loose_ceiling_land", {"x": float(d.x) + 8, "y": float(d.land)})
	# droppers
	for d in L.droppers:
		var di := int(d.i)
		if dropper_trig.has(di) and not proof_mode:
			# re-arm once it is back at the top
			var back := dropper_y(d, t)
			if not back[1] and float(back[0]) <= float(d.y) and t > int(dropper_trig[di]) + 60:
				dropper_trig.erase(di)
		if not dropper_trig.has(di) and float(d.x) - 8.0 < x and x < float(d.x) + 40.0 and y > float(d.y) \
				and not (on_floor and absf(y + HALF_H - float(d.y)) < 2.0):
			dropper_trig[di] = t
			ev("dropper_tell", {"x": float(d.x) + 16, "y": float(d.y)})
		var dy := dropper_y(d, t)
		if dy[1] and _hit(float(d.x), dy[0], float(d.x) + 32, float(dy[0]) + 32) and y > float(dy[0]) + 16.0:
			if hurt("dropper"):
				return
		var prev := dropper_y(d, t - 1)
		if prev[1] and not dy[1] and dropper_trig.has(di):
			ev("dropper_slam", {"x": float(d.x) + 16, "y": float(d.y1) + 32})
	# static hazards
	var c0 := int(floor(px0 / T))
	var c1 := int(floor((px1 - EPS) / T))
	var r0 := int(floor((y - HALF_H) / T))
	var r1 := int(floor((py1 - EPS) / T))
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			var ch: String = L.at(c, r)
			if ch == "^" and _hit(c * T + 2, r * T + 6, c * T + 14, r * T + 16):
				if hurt("spikes"):
					return
			if ch == "v" and _hit(c * T + 2, r * T, c * T + 14, r * T + 10):
				if hurt("spikes"):
					return
	for v in L.vents:
		var ph := vent_phase(v, t)
		if ph >= 0.6 and _hit(float(v.x) + 2, float(v.y) + 6, float(v.x) + 14, float(v.y) + 16):
			if hurt("spike vent"):
				return
	for p in L.presses:
		var py := press_y(p, t)
		if py > float(p.y0) + 1.0 and _hit(float(p.x), float(p.y0), float(p.x) + T, py + T):
			if hurt("press"):
				return
	for a in L.arms:
		if absf(float(a.cx) - x) < float(a.len) * 8.0 + 20.0 and absf(float(a.cy) - y) < float(a.len) * 8.0 + 20.0:
			for d in L.arm_dots(a, t):
				if _hit(d.x - 3.0, d.y - 3.0, d.x + 3.0, d.y + 3.0):
					if hurt("sweep arm"):
						return
					break
	# World 4: turret bolts, echoes and the wall of static (sim.py after_move)
	for bo in L.bolts(t):
		if _hit(float(bo[0]) - 6.0, float(bo[1]) - 2.0, float(bo[0]) + 6.0, float(bo[1]) + 2.0):
			if hurt("bolt"):
				return
	if not L.echoes.is_empty():
		_move_echoes()
		for n in L.echoes.size():
			var ep: Array = echo_pos[n]
			if not echo_killed.has(n) and _hit(float(ep[0]) - 5.0, float(ep[1]) - 5.0, float(ep[0]) + 5.0, float(ep[1]) + 5.0):
				if hurt("echo"):
					return
	if not L.static_wall.is_empty():
		var front: float = L.static_front(static_base, t)
		var rising := str(L.static_wall.dir) == "up"
		if (rising and py1 > front + 2.0) or (not rising and px0 < front - 2.0):
			if hurt("static"):
				return
	# springs
	for sp in L.springs:
		var top: float = sp.y + 4.0
		if px1 > sp.x and px0 < sp.x + T and py1 > top - 10.0 and py1 < top + 26.0 and vy > -50.0:
			vy = -(SPRING_POWER + minf(80.0, absf(vx) * 0.3))
			spring_t = 0.3
			buffer = 0.0
			coyote = 0.0
			on_floor = false
			sx_anim = 0.7
			sy_anim = 1.4
			ev("spring", {"x": sp.x + 8, "y": sp.y + 12})
	# lift rings
	for i in L.rings.size():
		var rp: Vector2 = L.rings[i]
		if (not ring_used.has(i) or t - int(ring_used[i]) > 120) and absf(x - rp.x) < 12.0 and absf(y - rp.y) < 12.0:
			ring_used[i] = t
			dash_ready = true
			vy = minf(vy, -RING_LIFT)
			spring_t = 0.2
			ev("lift_ring", {"x": rp.x, "y": rp.y})
	# walkers and hoppers
	var chain := 0 if on_floor else stomp_chain
	for n in L.walkers.size():
		if killed.has(n):
			continue
		var w: Dictionary = L.walkers[n]
		var wpos := walker_pos(n)
		var wx: float = wpos.x
		var wy: float = wpos.y
		if walker_dropped(wx, wy, str(w.kind) == "flyer"):
			killed[n] = t
			if not proof_mode:
				walker_fall[n] = [wx, wy, 0.0]
			ev("walker_drop", {"x": wx, "y": wy - 9})
			continue
		if absf(wx - x) > 40.0:
			continue
		if _hit(wx - 7, wy - 18, wx + 7, wy):
			if str(w.kind) == "spiky":
				ev("spiky_hurt")
				if hurt("spiky"):
					return
			elif dash_t > 0.0:
				killed[n] = t
				ev("walker_squish", {"x": wx, "y": wy - 9, "dash": true})
			elif vy > 60.0 and py1 - (wy - 18.0) < STOMP_DEPTH:
				killed[n] = t
				chain += 1
				stomp_at = t
				vy = -(JUMP_VEL if held or buffer > 0.0 else STOMP_BOUNCE) - 40.0 * (chain - 1)
				on_floor = false
				sx_anim = 0.75
				sy_anim = 1.3
				ev("stomp", {"x": wx, "y": wy - 18, "chain": chain})
			else:
				if hurt(str(w.kind)):
					return
	stomp_chain = chain
	# warden
	if L.warden.x >= 0 and (lever_t < 0 or t < lever_t + 30):
		var wp := warden_pos(t)
		if _hit(wp.x + 2, wp.y + 2, wp.x + 30, wp.y + 32):
			if hurt("warden"):
				return
	# lever
	if L.lever.x >= 0 and lever_t < 0 and _hit(L.lever.x * T, L.lever.y * T, L.lever.x * T + T, L.lever.y * T + T):
		lever_t = t
		ev("lever_pull", {"x": L.lever.x * T + 8, "y": L.lever.y * T})
		ev("bridge_collapse")
	if lever_t >= 0 and t == lever_t + 24:
		ev("warden_fall")
	# pickups
	if not proof_mode:
		for c in range(c0 - 1, c1 + 2):
			for r in range(r0 - 1, r1 + 2):
				var ch2: String = L.at(c, r)
				if (ch2 == "o" or ch2 == "O") and not taken.has(Vector2i(c, r)) \
						and _hit(c * T + 3, r * T + 3, c * T + 13, r * T + 13):
					taken[Vector2i(c, r)] = true
					ev("big_shard" if ch2 == "O" else "shard", {"x": c * T + 8, "y": r * T + 8, "cell": Vector2i(c, r)})
		if L.midway.x >= 0 and not lit and absf(x - (L.midway.x * T + 8)) < 10.0 and absf(y - L.midway.y * T) < 24.0:
			lit = true
			ev("checkpoint", {"x": L.midway.x * T + 8, "y": L.midway.y * T})
		if down and on_floor:
			for p in L.pipes:
				if int(p.r) * T == y + HALF_H and x > int(p.c) * T + 2 and x < int(p.c) * T + 30:
					ev("pipe", {"pipe": p})
	# goal mast: 5 tiles tall above the base
	if L.goal.x >= 0 and _hit(L.goal.x * T + 4, (L.goal.y - 5) * T, L.goal.x * T + 12, L.goal.y * T + T):
		won = true
		won_height = clampf(((L.goal.y + 1) * T - y) / (6.0 * T), 0.0, 1.0)
		ev("mast_touch", {"height": won_height})
		return
	if y > L.rows * T + 24.0:
		hurt("fell")


func _bump(cell: Vector2i) -> void:
	var ch: String = L.at(cell.x, cell.y)
	var at := Vector2(cell.x * T + 8, cell.y * T)
	# switches, fuses and knock-outs change the level, so they run in proof mode too
	if ch == "Y":
		toggles += 1
		bumps.append([cell, t])
		ev("channel_switch", {"x": at.x, "y": at.y})
	elif ch == "Q" and not fuses.has(cell):
		fuses[cell] = t
		ev("fuse_blow", {"x": at.x, "y": at.y + 8})
		if not L.relay.is_empty() and fuses.size() == L.fuses.size() and relay_down < 0:
			relay_down = t
			ev("relay_overload")
	if Level.BUMPABLE.contains(ch):
		# anything standing on a struck block is knocked out (Mario rule)
		for n in L.walkers.size():
			if killed.has(n):
				continue
			var wp := walker_pos(n)
			if absf(wp.x - at.x) < 12.0 and absf(wp.y - cell.y * T) < 2.0:
				killed[n] = t
				ev("spiky_knock" if str(L.walkers[n].kind) == "spiky" else "walker_squish", {"x": wp.x, "y": wp.y - 9})
	if proof_mode:
		return
	var state: String = tiles.get(cell, "")
	if ch in ["?", "C", "U"] and state == "":
		tiles[cell] = "used"
		bumps.append([cell, t])
		ev("bump_block", {"x": at.x, "y": at.y})
		if ch == "?":
			ev("shard", {"x": at.x, "y": at.y - 8, "popped": true})
		elif ch == "C":
			charged = true
			ev("charge_get", {"x": at.x, "y": at.y - 8})
		else:
			ev("extra_life", {"x": at.x, "y": at.y - 8})
	elif ch == "h" and state == "revealed":
		tiles[cell] = "used"
		bumps.append([cell, t])
		ev("extra_life", {"x": at.x, "y": at.y - 8})
	elif ch == "i" and state == "revealed":
		# a hidden shard block: a spray of five shards
		tiles[cell] = "used"
		bumps.append([cell, t])
		ev("bump_block", {"x": at.x, "y": at.y})
		for k in 5:
			ev("shard", {"x": at.x - 16.0 + k * 8.0, "y": at.y - 8.0 - float(k % 2) * 6.0, "popped": true})
	elif ch == "B":
		if charged:
			tiles[cell] = "broken"
			ev("brick_break", {"x": at.x, "y": at.y + 8})
		else:
			bumps.append([cell, t])
			ev("bump_used", {"x": at.x, "y": at.y})
	elif ch in ["?", "C", "U"]:
		bumps.append([cell, t])
		ev("bump_used", {"x": at.x, "y": at.y})


## Push from the wind tile at the Spark's centre, in px/s/s (sim.py wind_at).
func wind_at(px: float, py: float) -> Vector2:
	var ch: String = L.at(int(floor(px / T)), int(floor(py / T)))
	if not (ch == "<" or ch == ">" or ch == "u") or not L.gust_on(t):
		return Vector2.ZERO
	if ch == "u":
		return Vector2(0.0, -WIND_UP)
	return Vector2(WIND_SIDE if ch == ">" else -WIND_SIDE, 0.0)


func walker_pos(n: int) -> Vector2:
	var w: Dictionary = L.walkers[n]
	if walker_fall.has(n):
		var f: Array = walker_fall[n]
		return Vector2(f[0], f[1])
	var path: PackedFloat32Array = w.path
	var wx: float = path[mini(t, path.size() - 1)]
	var wy: float = w.y
	if str(w.kind) == "hopper":
		var s := (t % 96) * DT
		wy -= maxf(0.0, 220.0 * s - 0.5 * GRAVITY * s * s) if s < 0.48 else 0.0
	elif str(w.kind) == "flyer":
		wy += float(w.amp) * sin(TAU * t * DT / float(w.period))
	return Vector2(wx, wy)


func _on_walker(wx: float, wy: float, x0: float, y0: float, x1: float, y1: float) -> bool:
	return wx - 7 < x1 and wx + 7 > x0 and wy - 18 < y1 and wy > y0


func walker_dropped(wx: float, wy: float, flyer := false) -> bool:
	## A walker is lost when the floor under it falls away, or when something
	## heavy lands on it: a falling loose floor, a press, a dropper or a loose
	## ceiling chunk (sim.py walker_dropped).
	for p in L.presses:
		var py := press_y(p, t)
		if py > float(p.y0) + 1.0 and _on_walker(wx, wy, float(p.x), float(p.y0), float(p.x) + T, py + T):
			return true
	for d in L.droppers:
		var dy := dropper_y(d, t)
		if dy[1] and _on_walker(wx, wy, float(d.x), float(dy[0]), float(d.x) + 32, float(dy[0]) + 32):
			return true
	for di in debris_trig:
		var db: Dictionary = L.debris[di - 1]
		var s := t - int(debris_trig[di]) - 24
		if s >= 0:
			var yy := float(db.y) + 0.5 * GRAVITY * pow(s * DT, 2.0)
			if yy < float(db.land) and _on_walker(wx, wy, float(db.x) + 2, yy + 2, float(db.x) + 14, yy + 14):
				return true
	var c := int(floor(wx / T))
	var r := int(floor(wy / T))
	var ch: String = L.at(c, r)
	if flyer:
		return false  # flyers never stand on anything
	if ch == "L" and loose_state(Vector2i(c, r), t) == "fallen":
		return true
	if ch == "Z" and not solid(c, r, t):
		return true
	if (ch == "B" or ch == "%") and tiles.get(Vector2i(c, r), "") == "broken":
		return true   # a brick broken or a cracked wall opened under it
	for cell in loose_trig:
		var ly := loose_fall_y(cell, t)
		var lx: float = cell.x * T
		if ly >= 0.0 and wx - 7 < lx + 14 and wx + 7 > lx + 2 and wy - 18 < ly + 14 and wy > ly + 2 and wy - 9 > ly + 8:
			return true
	return false


func update_walkers() -> void:
	## Walkers that lost their floor fall until they hit something solid, where
	## they are knocked out (drawing only).
	for n in walker_fall:
		var f: Array = walker_fall[n]
		if f.size() > 3:
			continue
		f[2] = minf(MAX_FALL, float(f[2]) + GRAVITY * DT)
		var ny := float(f[1]) + float(f[2]) * DT
		var c := int(floor(float(f[0]) / T))
		var r := int(floor(ny / T))
		if ny > float(f[1]) + 1.0 and r < L.rows and solid(c, r, t) and not solid(c, int(floor((float(f[1]) - 1.0) / T)), t):
			f[1] = r * T
			f.append(t)   # landed: frame it hit the ground
		else:
			f[1] = ny


func warden_pos(at_t: int) -> Vector2:
	var wc: Vector2i = L.warden
	var x0: float = wc.x * T
	var lo: float = x0 - 5 * T
	var hi: float = x0 + 3 * T
	var span: float = hi - lo
	var s := fposmod(at_t * 40.0 * DT, 2.0 * span)
	var wx: float = lo + (s if s < span else 2.0 * span - s)
	var hop := (at_t % 150) * DT
	var wy: float = wc.y * T - (maxf(0.0, 250.0 * hop - 0.5 * GRAVITY * hop * hop) if hop < 0.55 else 0.0)
	if lever_t >= 0 and at_t >= lever_t + 24:
		var ft := (at_t - lever_t - 24) * DT
		wy += 0.5 * GRAVITY * ft * ft
	return Vector2(wx, wy)
