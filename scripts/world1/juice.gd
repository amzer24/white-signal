extends RefCounted
## Stateless juice helpers for World 1. Every effect is a pure function of the
## time since its event, so it can be scrubbed, replayed and captured frame
## exactly. Randomness comes from DrawUtil.hash2(seed, i), never randf().
## Colours stay in the four greys: particles go WHITE -> GRAY -> DARK as they age.

const BG := DrawUtil.BG
const DARK := DrawUtil.DARK
const GRAY := DrawUtil.GRAY
const WHITE := DrawUtil.WHITE

const GRAVITY := 500.0

static func _r(seed_v: int, i: int, k: int) -> float:
	return float(DrawUtil.hash2(seed_v * 131 + k, i * 7919 + k * 31) % 10000) / 10000.0

static func _age_col(age: float, life: float) -> Color:
	var f := age / life
	if f < 0.45:
		return WHITE
	if f < 0.8:
		return GRAY
	return DARK

# ------------------------------------------------------------------ time

## Hit-stop: remaps a clock so it freezes for `dur` seconds at each stop.
## stops = [Vector2(at, dur), ...] in clock seconds, sorted.
static func stopped(u: float, stops: Array) -> float:
	var out := u
	for s in stops:
		var st: Vector2 = s
		if u > st.x:
			out -= minf(u - st.x, st.y)
	return out

## Screen shake offset `age` seconds after a hit of strength `amp` px.
## Integer offsets only, decaying to zero over `dur`.
static func shake(age: float, amp: float, dur := 0.25, seed_v := 1) -> Vector2:
	if age < 0.0 or age > dur or amp <= 0.0:
		return Vector2.ZERO
	var a := amp * (1.0 - age / dur)
	var step := int(age * 60.0)
	return Vector2(roundf((_r(seed_v, step, 1) * 2.0 - 1.0) * a), roundf((_r(seed_v, step, 2) * 2.0 - 1.0) * a))

## Sum of several shakes: events = [Vector3(at, amp, dur), ...].
static func shake_sum(u: float, events: Array, seed_v := 1) -> Vector2:
	var o := Vector2.ZERO
	for e in events:
		var ev: Vector3 = e
		o += shake(u - ev.x, ev.y, ev.z, seed_v)
	return o

## Small hop for a bumped block: 0 -> -4 px -> 0 over 0.14 s.
static func bump_hop(age: float, height := 4.0, dur := 0.14) -> float:
	if age < 0.0 or age > dur:
		return 0.0
	return -roundf(sin(age / dur * PI) * height)

# ------------------------------------------------------------------ motion helpers

## Piecewise-linear keyframes: keys = [Vector3(t, x, y), ...].
static func path(u: float, keys: Array) -> Vector2:
	var first: Vector3 = keys[0]
	if u <= first.x:
		return Vector2(first.y, first.z)
	for i in range(1, keys.size()):
		var a: Vector3 = keys[i - 1]
		var b: Vector3 = keys[i]
		if u <= b.x:
			var f := (u - a.x) / maxf(b.x - a.x, 0.0001)
			return Vector2(lerpf(a.y, b.y, f), lerpf(a.z, b.z, f))
	var last: Vector3 = keys[keys.size() - 1]
	return Vector2(last.y, last.z)

## A jump arc from a to b peaking `h` px above the higher end. f in 0..1.
static func arc(a: Vector2, b: Vector2, h: float, f: float) -> Vector2:
	f = clampf(f, 0.0, 1.0)
	var p := a.lerp(b, f)
	p.y -= 4.0 * h * f * (1.0 - f)
	return p

## Position under gravity from rest at y0 after `age` s (clamped to floor).
static func fall_y(y0: float, age: float, floor_y: float, g := GRAVITY * 1.6) -> float:
	if age <= 0.0:
		return y0
	return minf(y0 + 0.5 * g * age * age, floor_y)

static func fall_time(dist: float, g := GRAVITY * 1.6) -> float:
	return sqrt(maxf(dist, 0.0) * 2.0 / g)

# ------------------------------------------------------------------ particles

## Upward spray of 1-2 px squares (JS burst()).
static func burst(ci: CanvasItem, at: Vector2, age: float, seed_v: int, n := 10, spread := 160.0,
		life := 0.55) -> void:
	if age < 0.0:
		return
	for i in n:
		var l := life * (0.6 + 0.4 * _r(seed_v, i, 3))
		if age > l:
			continue
		var v := Vector2((_r(seed_v, i, 1) - 0.5) * spread, -_r(seed_v, i, 2) * 150.0 - 30.0)
		var p := at + v * age + Vector2(0, 0.5 * GRAVITY * age * age)
		var s := 2.0 if _r(seed_v, i, 4) < 0.4 else 1.0
		ci.draw_rect(Rect2(p.floor(), Vector2(s, s)), _age_col(age, l))

## Radial ring of sparks (stomp, pickups). No gravity.
static func ring_sparks(ci: CanvasItem, at: Vector2, age: float, seed_v: int, n := 8, speed := 90.0,
		life := 0.3) -> void:
	if age < 0.0 or age > life:
		return
	for i in n:
		var ang := TAU * float(i) / n + _r(seed_v, i, 1) * 0.4
		var d := speed * age * (1.0 - age / (life * 2.0))
		var p := at + Vector2(cos(ang), sin(ang)) * (3.0 + d)
		ci.draw_rect(Rect2(p.floor(), Vector2.ONE), _age_col(age, life))
		if age < life * 0.5:
			var q := at + Vector2(cos(ang), sin(ang)) * (1.0 + d * 0.6)
			ci.draw_rect(Rect2(q.floor(), Vector2.ONE), GRAY)

## Ground dust kicked sideways (landing, skids, slams).
static func dust(ci: CanvasItem, at: Vector2, age: float, seed_v: int, n := 6, spread := 70.0,
		life := 0.45) -> void:
	if age < 0.0:
		return
	for i in n:
		var l := life * (0.6 + 0.4 * _r(seed_v, i, 3))
		if age > l:
			continue
		var side := -1.0 if i % 2 == 0 else 1.0
		var v := Vector2(side * (0.3 + _r(seed_v, i, 1)) * spread, -_r(seed_v, i, 2) * 40.0 - 8.0)
		var p := at + Vector2(side * 2.0, 0) + v * age + Vector2(0, 0.5 * 120.0 * age * age)
		p.y = minf(p.y, at.y)
		var s := 2.0 if age < l * 0.4 else 1.0
		ci.draw_rect(Rect2(p.floor(), Vector2(s, s)), _age_col(age, l))

## Falling grit (loose ceiling tell, crumbling floor).
static func grit(ci: CanvasItem, at: Vector2, age: float, seed_v: int, n := 5, width := 10.0,
		life := 0.5) -> void:
	if age < 0.0:
		return
	for i in n:
		var t0 := _r(seed_v, i, 1) * life * 0.6
		var a := age - t0
		if a < 0.0 or a > life:
			continue
		var p := at + Vector2((_r(seed_v, i, 2) - 0.5) * width, 0.5 * GRAVITY * a * a)
		ci.draw_rect(Rect2(p.floor(), Vector2.ONE), GRAY if i % 3 else WHITE)

## Horizontal speed lines behind a dash.
static func speed_lines(ci: CanvasItem, from: Vector2, dir: float, age: float, seed_v: int, life := 0.2) -> void:
	if age < 0.0 or age > life:
		return
	for i in 4:
		var y := from.y - 12.0 + _r(seed_v, i, 1) * 12.0
		var ln := 10.0 + _r(seed_v, i, 2) * 14.0
		var x := from.x - dir * (6.0 + _r(seed_v, i, 3) * 18.0 + age * 60.0)
		var w := ln * (1.0 - age / life)
		ci.draw_rect(Rect2(Vector2(minf(x, x - dir * w), y).floor(), Vector2(maxf(1.0, w), 1)),
			WHITE if age < life * 0.4 else GRAY)

## Four-point glint.
static func glint(ci: CanvasItem, at: Vector2, age: float, size := 4.0, life := 0.24) -> void:
	if age < 0.0 or age > life:
		return
	var s := roundf(size * sin(age / life * PI))
	var col := WHITE if age < life * 0.6 else GRAY
	ci.draw_rect(Rect2(at.x - s, at.y, s * 2.0 + 1.0, 1), col)
	ci.draw_rect(Rect2(at.x, at.y - s, 1, s * 2.0 + 1.0), col)

## Expanding dithered square ring (shield break, light-up).
static func pulse_box(ci: CanvasItem, center: Vector2, age: float, start := 8.0, grow := 90.0,
		life := 0.3) -> void:
	if age < 0.0 or age > life:
		return
	var r := roundf(start + grow * age)
	var col := WHITE if age < life * 0.5 else GRAY
	var c := center.floor()
	var x := -r
	while x <= r:
		if int(x + c.x + c.y) % 2 == 0 or age < life * 0.3:
			ci.draw_rect(Rect2(c.x + x, c.y - r, 1, 1), col)
			ci.draw_rect(Rect2(c.x + x, c.y + r, 1, 1), col)
			ci.draw_rect(Rect2(c.x - r, c.y + x, 1, 1), col)
			ci.draw_rect(Rect2(c.x + r, c.y + x, 1, 1), col)
		x += 1.0

# ------------------------------------------------------------------ the Spark

## The Spark, drawn exactly like scripts/spark_visual.gd (12x14 white block,
## visor, scarf, legs), from explicit pose values instead of a player node.
## `feet` = bottom-centre. pose: "stand", "run", "air", "slide", "lie".
static func spark(ci: CanvasItem, feet: Vector2, face := 1, sx := 1.0, sy := 1.0, pose := "stand",
		anim_t := 0.0, dash_ready := -1) -> void:
	var w := maxf(4.0, roundf(12.0 * sx))
	var h := maxf(6.0, roundf(14.0 * sy))
	var bx := floorf(feet.x - w / 2.0)
	var by := floorf(feet.y - h)
	ci.draw_rect(Rect2(bx - 1, by - 1, w + 2, h + 2), BG)
	ci.draw_rect(Rect2(bx, by, w, h), WHITE)
	ci.draw_rect(Rect2(bx - 1 if face > 0 else bx + w, by + 1, 1, 3), WHITE)
	var vx := bx + w - 6.0 if face > 0 else bx + 2.0
	ci.draw_rect(Rect2(vx, by + 3, 4, 3), BG)
	ci.draw_rect(Rect2(vx + (0.0 if face > 0 else 3.0), by + 3, 1, 1), GRAY)
	var fl := int(anim_t * 2.0) % 2
	var scx := bx - 3.0 if face > 0 else bx + w + 1.0
	ci.draw_rect(Rect2(scx, by + 4 + fl, 3, 2), GRAY)
	ci.draw_rect(Rect2(scx - 2.0 if face > 0 else scx + 2.0, by + 5.0 - fl, 2, 1), GRAY)
	if pose == "lie":
		# eyes shut: the visor closes to a line, no legs
		ci.draw_rect(Rect2(vx, by + 3, 4, 3), WHITE)
		ci.draw_rect(Rect2(vx, by + 4, 4, 1), BG)
	elif pose == "air":
		ci.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), BG)
		ci.draw_rect(Rect2(bx + w - 5, by + h - 3, 3, 3), BG)
	elif pose == "run":
		var fr := int(anim_t * 10.0) % 2
		ci.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2 + (0 if fr == 1 else 1)), BG)
		ci.draw_rect(Rect2(bx + w - 5, by + h - 3 - (1 if fr == 1 else 0), 3, 2 + (1 if fr == 1 else 0)), BG)
	elif pose == "slide":
		ci.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), BG)
		ci.draw_rect(Rect2(bx + w - 1.0 if face > 0 else bx - 2.0, by + h - 5, 3, 2), BG)
	else:
		ci.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), BG)
		ci.draw_rect(Rect2(bx + w - 5, by + h - 2, 3, 2), BG)
	if dash_ready >= 0:
		ci.draw_rect(Rect2(bx + w / 2.0 - 1, by - 5, 3, 3), WHITE if dash_ready == 1 else DARK)
		ci.draw_rect(Rect2(bx + w / 2.0, by - 4, 1, 1), BG)

## Flat silhouette of the Spark for dash afterimages. Older ghosts go darker
## (GRAY, then a GRAY outline, then DARK), which keeps the four-grey rule.
static func spark_ghost(ci: CanvasItem, feet: Vector2, level: int, sx := 1.0, sy := 1.0) -> void:
	var w := maxf(4.0, roundf(12.0 * sx))
	var h := maxf(6.0, roundf(14.0 * sy))
	var r := Rect2(floorf(feet.x - w / 2.0), floorf(feet.y - h), w, h)
	match level:
		0:
			ci.draw_rect(r, GRAY)
		1:
			ci.draw_rect(r, GRAY, false, 1.0)
			ci.draw_rect(r.grow(-2), DARK)
		_:
			ci.draw_rect(r.grow(-1), DARK)

## Spark flash: solid white body with a dark outline (pickup, hit).
static func spark_flash(ci: CanvasItem, feet: Vector2) -> void:
	ci.draw_rect(Rect2(floorf(feet.x - 7), floorf(feet.y - 15), 14, 16), BG)
	ci.draw_rect(Rect2(floorf(feet.x - 6), floorf(feet.y - 14), 12, 14), WHITE)
