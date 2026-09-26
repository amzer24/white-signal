extends Node2D
## One looping juice demo. Lives inside a clipping Control (the cell), draws
## everything as a pure function of `clock`, so a capture at a given time is
## always the same picture. Shake is applied with draw_set_transform, hit-stop
## by remapping the clock (Juice.stopped).

const J := preload("res://scripts/world1/juice.gd")

const BG := DrawUtil.BG
const DARK := DrawUtil.DARK
const GRAY := DrawUtil.GRAY
const WHITE := DrawUtil.WHITE

const W := 160.0
const H := 122.0

## kind -> [label, loop seconds]
const DEMOS := {
	"stomp": ["STOMP + HIT-STOP", 2.6],
	"dash": ["DASH AFTERIMAGES", 2.2],
	"bump": ["BLOCK BUMP HOP", 2.6],
	"brick": ["BRICK SHATTER", 2.6],
	"loose": ["LOOSE FLOOR CRUMBLE", 3.2],
	"press": ["PRESS SLAM", 2.0],
	"gate": ["PLATE + GATE RISE", 3.6],
	"bridge": ["LEVER + BRIDGE CHAIN", 4.4],
	"checkpoint": ["CHECKPOINT LIGHT-UP", 2.8],
	"mast": ["MAST SLIDE", 3.8],
	"shards": ["SHARD SPARKLE", 2.8],
	"charge": ["CHARGE GLOW", 4.4],
	"vents": ["SPIKE VENT WAVE", 2.0],
	"dropper": ["DROPPER", 4.4],
	"ceiling": ["LOOSE CEILING", 2.6],
	"rings": ["LIFT RINGS", 3.2],
	"spring": ["SPRING", 1.6],
	"tells": ["ENEMY TELLS", 3.2],
}

var sh  # sheets.gd instance, set by the showcase
var kind := "stomp"
var clock := 0.0

func period() -> float:
	return float(DEMOS[kind][1])

func label() -> String:
	return str(DEMOS[kind][0])

func _draw() -> void:
	if sh == null:
		return
	draw_rect(Rect2(-8, -8, W + 16, H + 16), BG)
	var u := fposmod(clock, period())
	call("_demo_" + kind, u)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0, 0, DrawUtil.text_width(label()) + 7, 11), BG)
	DrawUtil.text(self, Vector2(4, 3), label(), GRAY)
	# loop progress tick along the bottom edge
	draw_rect(Rect2(0, H - 1, floorf(W * u / period()), 1), DARK)

# ================================================================== helpers

func _shake(v: Vector2) -> void:
	draw_set_transform(v.round())

func _f(sheet: String, anim: String, frame: int, pos: Vector2, flip := false) -> void:
	sh.draw_frame(self, sheet, anim, frame, pos, flip)

func _a(sheet: String, anim: String, t: float, pos: Vector2, flip := false) -> void:
	sh.draw_anim(self, sheet, anim, t, pos, flip)

## Auto-tiled ground block from x0 to x1 (px, multiples of 16), top at y.
func _ground(x0: float, x1: float, y: float, open_left := true, open_right := true) -> void:
	var row := 0
	var yy := y
	while yy < H + 16.0:
		var anim := "top" if row == 0 else ("mid" if row == 1 else "deep")
		var x := x0
		while x < x1:
			var col := 1
			if x == x0 and open_left:
				col = 0
			elif x + 16.0 >= x1 and open_right:
				col = 2
			if x0 + 16.0 >= x1 and open_left and open_right:
				col = 3
			_f("ground", anim, col, Vector2(x, yy))
			x += 16.0
		yy += 16.0
		row += 1

## Ceiling: solid rows from the top down to y (bottom row shows the underside).
func _ceiling(x0: float, x1: float, y_bottom: float) -> void:
	var yy := y_bottom - 16.0
	var first := true
	while yy > -16.0:
		var x := x0
		while x < x1:
			if first:
				_f("ground", "bottom", 1, Vector2(x, yy))
			else:
				_f("ground", "deep", 1, Vector2(x, yy))
			x += 16.0
		yy -= 16.0
		first = false

func _spark(feet: Vector2, face := 1, pose := "stand", sx := 1.0, sy := 1.0, dash := -1, t := 0.0) -> void:
	J.spark(self, feet.floor(), face, sx, sy, pose, t, dash)

## Squash on landing, `age` s after touching down.
func _land_squash(age: float) -> Vector2:
	if age >= 0.0 and age < 0.1:
		return Vector2(1.3, 0.75)
	return Vector2.ONE

func _jitter(t: float, amp := 1.0) -> float:
	return (1.0 if int(t * 30.0) % 2 == 0 else -1.0) * amp

func _text_pop(at: Vector2, age: float, s: String, life := 0.6) -> void:
	if age < 0.0 or age > life:
		return
	var p := at + Vector2(0, -roundf(age * 30.0))
	DrawUtil.text_shadow(self, p, s, WHITE if age < life * 0.6 else GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _fx(sheet: String, anim: String, age: float, center: Vector2) -> void:
	if age < 0.0 or age > sh.length(sheet, anim):
		return
	var s: Vector2 = sh.size(sheet)
	_a(sheet, anim, age, center - s / 2.0)

# ================================================================== page A

func _demo_stomp(u: float) -> void:
	var hit := 0.9
	var t := J.stopped(u, [Vector2(hit, 0.08)])
	var frozen := u > hit and u < hit + 0.08
	_shake(J.shake(u - hit, 2.0, 0.2, 3))
	_ground(0, 160, 96)
	# walker
	var wx := 124.0 - 30.0 * minf(t, hit) / hit
	if frozen:
		_f("walker", "turn", 1, Vector2(wx - 8, 80))
	elif t < hit:
		_a("walker", "walk", t, Vector2(wx - 8, 80))
	elif t < 1.3:
		_f("walker", "stomped", 0, Vector2(wx - 8, 80))
	_fx("fx_burst", "stomp", t - 1.3, Vector2(wx, 90))
	J.burst(self, Vector2(wx, 92), t - 1.3, 11, 8, 120.0, 0.45)
	# spark
	var top := Vector2(94, 82)
	if frozen:
		J.spark_flash(self, top)
	elif t < 0.3:
		_spark(Vector2(30, 96), 1, "stand")
	elif t < hit:
		var f := (t - 0.3) / (hit - 0.3)
		var st := 1.15 if f < 0.2 else 1.0
		_spark(J.arc(Vector2(30, 96), top, 40.0, f), 1, "air", 1.0 / st, st)
	elif t < 1.55:
		var f2 := (t - hit) / 0.65
		var sq := Vector2(1.3, 0.75) if t - hit < 0.06 else (Vector2(0.85, 1.2) if t - hit < 0.16 else Vector2.ONE)
		_spark(J.arc(top, Vector2(136, 96), 34.0, f2), 1, "air", sq.x, sq.y)
	else:
		var sq2 := _land_squash(t - 1.55)
		_spark(Vector2(136, 96), 1, "stand", sq2.x, sq2.y)
	_fx("fx_burst", "stomp", t - hit, top + Vector2(0, 2))
	J.ring_sparks(self, top + Vector2(0, 1), t - hit, 5, 10, 110.0, 0.28)
	_fx("fx_dust", "land", t - 1.55, Vector2(136, 92))
	_text_pop(top + Vector2(0, -24), t - hit, "+100")

func _dash_pos(t: float) -> Vector2:
	if t < 0.3:
		return Vector2(12 + t * 80.0, 96)
	if t < 0.58:
		return Vector2(36 + (t - 0.3) * 85.0, 96 - 38.0 * sin((t - 0.3) / 0.28 * PI / 2.0))
	if t < 0.76:
		return Vector2(60 + (t - 0.58) * 400.0, 58)
	return Vector2(132 + (t - 0.76) * 40.0, J.fall_y(58, t - 0.76, 96, 800.0))

func _demo_dash(u: float) -> void:
	var t := u
	var land := 0.76 + J.fall_time(38.0, 800.0)
	_shake(J.shake(t - 0.58, 1.0, 0.1, 5))
	_ground(0, 160, 96)
	# afterimages trail the dash and catch up once it ends
	for k in range(4, 0, -1):
		var tk := t - k * 0.035
		if tk >= 0.58 and tk <= 0.76:
			J.spark_ghost(self, _dash_pos(tk), k - 1, 1.35, 0.75)
	J.speed_lines(self, _dash_pos(t), 1.0, t - 0.6, 7, 0.22)
	J.ring_sparks(self, Vector2(60, 51), t - 0.58, 9, 8, 80.0, 0.22)
	var p := _dash_pos(minf(t, land))
	if t < 0.3:
		_spark(p, 1, "run", 1, 1, 1, t)
	elif t < 0.58:
		_spark(p, 1, "air", 1, 1, 1)
	elif t < 0.76:
		_spark(p, 1, "air", 1.35, 0.75, 0)
	elif t < land:
		_spark(p, 1, "air", 1, 1, 0)
	else:
		var sq := _land_squash(t - land)
		_spark(Vector2(p.x, 96), 1, "stand", sq.x, sq.y, 1)
	_fx("fx_dust", "land", t - land, Vector2(p.x, 92))
	_fx("fx_skid", "skid", t - land - 0.02, Vector2(p.x - 6, 92))

func _demo_bump(u: float) -> void:
	var t := u
	var hit := 0.42
	_shake(J.shake(t - hit, 1.0, 0.12, 2))
	_ground(0, 160, 96)
	# the other two blocks show their tells in context
	_a("bump_block", "charge", t, Vector2(40, 40))
	_a("bump_block", "life", t, Vector2(104, 40))
	# shard pops out of the top, then drops back in and bursts
	var a := t - hit
	if a >= 0.0 and a < 0.42:
		var sp := J.arc(Vector2(72, 30), Vector2(72, 26), 26.0, a / 0.42)
		_a("shard", "spin", a * 4.0, sp)
	var pop := Vector2(80, 30)
	J.ring_sparks(self, pop, a - 0.42, 13, 8, 70.0, 0.26)
	_fx("fx_sparkle", "twinkle", a - 0.42, pop)
	_text_pop(pop + Vector2(0, -10), a - 0.42, "+1")
	# block: hops and flashes when hit
	var hop := J.bump_hop(a)
	if t < hit:
		_a("bump_block", "shard", t, Vector2(72, 40))
	else:
		_a("bump_block", "hit", a, Vector2(72, 40 + hop))
	J.burst(self, Vector2(80, 56), a, 21, 5, 60.0, 0.3)
	# spark
	if t < 0.2:
		_spark(Vector2(80, 96), 1, "stand")
	elif t < hit:
		_spark(Vector2(80, 96 - 26.0 * sin((t - 0.2) / 0.22 * PI / 2.0)), 1, "air", 0.9, 1.12)
	else:
		var land := hit + J.fall_time(26.0, 800.0)
		if t < land:
			_spark(Vector2(80, J.fall_y(70, t - hit, 96, 800.0)), 1, "air")
		else:
			var sq := _land_squash(t - land)
			_spark(Vector2(80, 96), 1, "stand", sq.x, sq.y)
		_fx("fx_dust", "land", t - land, Vector2(80, 92))

func _demo_brick(u: float) -> void:
	var hit := 0.42
	var t := J.stopped(u, [Vector2(hit, 0.06)])
	var a := t - hit
	_shake(J.shake(u - hit, 2.0, 0.2, 4))
	_ground(0, 160, 96)
	_f("brick", "idle", 0, Vector2(56, 40))
	_f("brick", "idle", 0, Vector2(88, 40))
	if a < 0.0:
		_f("brick", "idle", 0, Vector2(72, 40))
	elif a < 0.08:
		_a("brick", "break", a, Vector2(72, 40 + J.bump_hop(a, 2.0, 0.08)))
	else:
		# four chunks fly out and spin
		var vel := [Vector2(-70, -170), Vector2(70, -170), Vector2(-45, -80), Vector2(45, -80)]
		var starts := [Vector2(72, 40), Vector2(80, 40), Vector2(72, 48), Vector2(80, 48)]
		for i in 4:
			var d := a - 0.08
			var v: Vector2 = vel[i]
			var s0: Vector2 = starts[i]
			var p := s0 + v * d + Vector2(0, 0.5 * 700.0 * d * d)
			if p.y < H + 8.0:
				_a("brick_debris", "spin", d + i * 0.06, p, i % 2 == 1)
		J.burst(self, Vector2(80, 48), a - 0.08, 31, 10, 140.0, 0.4)
	# spark (charged)
	var feet: Vector2
	var pose := "stand"
	var sq := Vector2.ONE
	var land := hit + J.fall_time(26.0, 800.0)
	if t < 0.2:
		feet = Vector2(80, 96)
	elif t < hit:
		feet = Vector2(80, 96 - 26.0 * sin((t - 0.2) / 0.22 * PI / 2.0))
		pose = "air"
	elif t < land:
		feet = Vector2(80, J.fall_y(70, t - hit, 96, 800.0))
		pose = "air"
	else:
		feet = Vector2(80, 96)
		sq = _land_squash(t - land)
	_a("fx_charge_glow", "glow", u, feet + Vector2(-12, -19))
	_spark(feet, 1, pose, sq.x, sq.y)
	_fx("fx_dust", "land", t - land, Vector2(80, 92))

func _loose_time(i: int) -> float:
	return (44.0 + 16.0 * i - 8.0) / 70.0

func _demo_loose(u: float) -> void:
	var t := u
	var fall_t := J.fall_time(16.0)
	var shakes := []
	for i in 4:
		shakes.append(Vector3(_loose_time(i) + 0.35 + fall_t, 1.0, 0.12))
	_shake(J.shake_sum(t, shakes, 6))
	_ground(0, 48, 80, true, false)
	_ground(48, 112, 112, false, false)
	_ground(112, 160, 80, false, true)
	for i in 4:
		var x := 48.0 + 16.0 * i
		var t0 := _loose_time(i)
		var a := t - t0
		if a < 0.0:
			_f("loose_floor", "still", 0, Vector2(x, 80))
		elif a < 0.35:
			_a("loose_floor", "shake", a, Vector2(x + _jitter(a), 80))
			J.grit(self, Vector2(x + 8, 92), a, 40 + i, 3, 12.0, 0.35)
		elif a < 0.35 + fall_t:
			_f("loose_floor", "fall", 0, Vector2(x, J.fall_y(80, a - 0.35, 96)))
		else:
			_f("loose_floor", "rubble", 0, Vector2(x, 96))
			J.dust(self, Vector2(x + 8, 111), a - 0.35 - fall_t, 50 + i, 6, 60.0, 0.4)
	var sx := minf(8.0 + 70.0 * t, 148.0)
	_spark(Vector2(sx, 80), 1, "run" if sx < 148.0 else "stand", 1, 1, -1, t)

func _press_state(s: float) -> Array:
	# [head_y, anim, frame, shake_x]  rest 0.93 (warn last 0.3), slam 0.12, hold 0.35, rise 0.6
	var y0 := 32.0
	var y1 := 80.0
	if s < 0.63:
		return [y0, "rest", 0, 0.0]
	if s < 0.93:
		return [y0, "warn", sh.frame_at("press", "warn", s - 0.63), _jitter(s)]
	if s < 1.05:
		return [lerpf(y0, y1, (s - 0.93) / 0.12), "slam", 0, 0.0]
	if s < 1.40:
		return [y1, "hold", 0, 0.0]
	return [lerpf(y1, y0, (s - 1.40) / 0.6), "rest", 0, 0.0]

func _draw_press(x: float, s: float, mount_y: float) -> void:
	var st := _press_state(s)
	var hy: float = st[0]
	var shx: float = st[3]
	_f("press", "shaft", 1, Vector2(x, mount_y))
	var yy := mount_y + 16.0
	while yy < hy:
		var h := minf(16.0, hy - yy)
		sh.draw_part(self, "press", "shaft", 0, Vector2(x, yy), Rect2(0, 0, 16, h))
		yy += 16.0
	_f("press", st[1], st[2], Vector2(x + shx, hy))

func _demo_press(u: float) -> void:
	var s := u
	_shake(J.shake(s - 1.05, 3.0, 0.22, 8))
	_ceiling(0, 160, 16)
	_ground(0, 160, 96)
	_draw_press(72, s, 16)
	_fx("press_dust", "puff", s - 1.05, Vector2(80, 88))
	J.dust(self, Vector2(80, 95), s - 1.05, 12, 10, 110.0, 0.4)
	var flinch := s > 1.05 and s < 1.15
	_spark(Vector2(28, 96), 1, "stand", 1.1 if flinch else 1.0, 0.9 if flinch else 1.0)

# ================================================================== page B

func _demo_gate(u: float) -> void:
	var t := u
	var press := 0.6
	var open_end := press + 0.4
	var close := 2.6
	_shake(J.shake(t - close - 0.1, 2.0, 0.18, 9))
	_ceiling(0, 160, 16)
	_ground(0, 160, 96)
	# plate
	var on_plate := t >= press and t < 0.98
	if t < press:
		_f("plate", "up", 0, Vector2(40, 80))
	elif on_plate:
		_a("plate", "press", t - press, Vector2(40, 80))
	else:
		_a("plate", "release", t - 0.98, Vector2(40, 80))
	# gate: slides up into its cap, slams back down when the timer runs out
	var lift := 0.0
	if t >= press and t < open_end:
		lift = 64.0 * ease((t - press) / 0.4, 0.5)
	elif t >= open_end and t < close:
		lift = 64.0
	elif t >= close and t < close + 0.1:
		lift = 64.0 * (1.0 - (t - close) / 0.1)
	for k in 4:
		var y := 32.0 + 16.0 * k - lift
		var top_cut := maxf(0.0, 32.0 - y)
		var part := Rect2(0, top_cut, 16, 16.0 - top_cut)
		sh.draw_part(self, "gate", "pieces", 1 if k == 3 else 0, Vector2(112, y), part)
	var cap_anim := "cap_closed"
	if (t >= press and t < open_end) or (t >= close - 0.6 and t < close + 0.1):
		cap_anim = "cap_opening"
	elif t >= open_end and t < close:
		cap_anim = "cap_open"
	_a("gate", cap_anim, t, Vector2(112, 16))
	_fx("fx_light", "ring", t - open_end, Vector2(120, 24))
	J.dust(self, Vector2(120, 95), t - press, 14, 6, 50.0, 0.35)
	J.dust(self, Vector2(120, 95), t - close - 0.1, 15, 10, 90.0, 0.4)
	# spark walks over the plate and through before it shuts
	var sx := 8.0 + 60.0 * t
	var face := 1
	var pose := "run"
	if sx > 150.0:
		sx = 150.0
		pose = "stand"
		face = -1
	_spark(Vector2(sx, 96), face, pose, 1, 1, -1, t)

func _bridge_snap(i: int) -> float:
	return 0.75 + 0.12 * i + 0.15

func _warden_x(t: float) -> float:
	var span := 56.0
	var d := fposmod(t * 25.0, span * 2.0)
	return 32.0 + (d if d < span else span * 2.0 - d)

func _demo_bridge(u: float) -> void:
	var t := u
	var pull := 0.45
	var shakes := []
	for i in 6:
		shakes.append(Vector3(_bridge_snap(i), 1.0, 0.1))
	# where is the warden when its tile goes?
	var warden_fall := 99.0
	for i in 6:
		var tx := 96.0 - 16.0 * i
		var wx := _warden_x(_bridge_snap(i))
		if wx + 8.0 >= tx and wx - 8.0 < tx + 16.0:
			warden_fall = _bridge_snap(i) + 0.05
			break
	shakes.append(Vector3(warden_fall, 2.0, 0.25))
	_shake(J.shake_sum(t, shakes, 10))
	_ground(0, 16, 80, true, false)
	_ground(112, 160, 80, false, true)
	# bridge collapses from the lever end
	for i in 6:
		var x := 96.0 - 16.0 * i
		var stress := _bridge_snap(i) - 0.15
		if t < stress:
			_f("bridge", "intact", 0, Vector2(x, 80))
		elif t < _bridge_snap(i):
			_a("bridge", "stress", t - stress, Vector2(x + _jitter(t), 80))
		else:
			var d := t - _bridge_snap(i)
			var y := 80.0 + 0.5 * 900.0 * d * d
			if y < H:
				_f("bridge", "snap", 0, Vector2(x + d * 10.0 * (1 if i % 2 else -1), y))
				_a("bridge", "plank", d, Vector2(x - 6 - d * 50.0, y - 4 + d * 20.0))
	# warden: paces, then falls with its tile
	if t < warden_fall:
		var wx2 := _warden_x(t)
		var dir := 1.0 if fposmod(t * 25.0, 112.0) < 56.0 else -1.0
		_a("warden", "walk", t, Vector2(wx2 - 16, 48), dir > 0.0)
	else:
		var d2 := t - warden_fall
		var wy := 48.0 + 0.5 * 700.0 * d2 * d2
		if wy < H:
			_a("warden", "fall", d2, Vector2(_warden_x(warden_fall) - 16, wy))
	# lever
	if t < pull:
		_f("lever", "off", 0, Vector2(128, 64))
	else:
		_a("lever", "pull", t - pull, Vector2(128, 64))
	_fx("fx_light", "ring", t - pull - 0.2, Vector2(136, 66))
	var sx := maxf(150.0 - 40.0 * t, 138.0)
	_spark(Vector2(sx, 80), -1, "run" if sx > 138.0 else "stand", 1, 1, -1, t)

func _demo_checkpoint(u: float) -> void:
	var t := u
	var lit := 1.0
	_shake(J.shake(t - lit, 1.0, 0.15, 11))
	_ground(0, 160, 96)
	if t < lit:
		_f("beacon", "dark", 0, Vector2(88, 64))
	elif t < lit + 0.13:
		_a("beacon", "ignite", t - lit, Vector2(88, 64))
	else:
		_a("beacon", "lit", t, Vector2(88, 64))
	var lamp := Vector2(96, 70)
	_fx("fx_light", "ring", t - lit, lamp)
	J.ring_sparks(self, lamp, t - lit, 16, 12, 120.0, 0.35)
	for k in 3:
		J.glint(self, lamp + Vector2(-10 + k * 10, -8 + (k % 2) * 14), t - lit - 0.15 - k * 0.12, 3.0)
	if t > lit:
		# the lit lamp throws a thin dithered cone of light on the floor
		for x in range(-10, 11):
			if int(x + 96) % 2 == 0:
				draw_rect(Rect2(96 + x, 96, 1, 1), GRAY if absi(x) < 6 else DARK)
	var sx := 8.0 + 80.0 * t
	if sx < 176.0:
		_spark(Vector2(sx, 96), 1, "run", 1, 1, -1, t)

func _demo_mast(u: float) -> void:
	var touch := 0.75
	var t := J.stopped(u, [Vector2(touch, 0.1)])
	var frozen := u > touch and u < touch + 0.1
	var fy := 104.0
	_shake(J.shake(u - touch, 2.0, 0.2, 12))
	_ground(0, 160, fy)
	var lit := t >= touch or frozen
	# mast: base on the floor, 5 pole tiles, top
	_f("mast", "base_lit" if lit else "pieces", 0, Vector2(112, 88))
	for k in 4:
		_f("mast", "pieces", 1, Vector2(112, 24 + 16.0 * k))
	if lit:
		_a("mast", "top_lit", t, Vector2(112, 8))
	else:
		_f("mast", "pieces", 2, Vector2(112, 8))
	# flag slides down with the spark
	var flag_y := 14.0
	if t > touch + 0.1:
		flag_y = lerpf(14.0, 76.0, clampf((t - touch - 0.1) / 0.65, 0.0, 1.0))
	_a("mast_flag", "lit" if lit else "wave", t, Vector2(96, flag_y))
	# spark
	var grab := Vector2(111, 46)
	if frozen:
		J.spark_flash(self, grab)
	elif t < 0.2:
		_spark(Vector2(40, fy), 1, "stand")
	elif t < touch:
		_spark(J.arc(Vector2(40, fy), grab, 50.0, (t - 0.2) / (touch - 0.2)), 1, "air")
	elif t < touch + 0.75:
		var f := clampf((t - touch - 0.1) / 0.65, 0.0, 1.0)
		var feet := Vector2(111, lerpf(46.0, 100.0, f))
		_spark(feet, 1, "slide")
		if int(t * 20.0) % 2 == 0 and f < 1.0:
			draw_rect(Rect2(118, feet.y - 2, 1, 1), WHITE)
			draw_rect(Rect2(117 + (int(t * 40.0) % 3), feet.y + 1, 1, 1), GRAY)
	else:
		var hop_t := t - touch - 0.75
		if hop_t < 0.3:
			_spark(J.arc(Vector2(111, 100), Vector2(140, fy), 16.0, hop_t / 0.3), 1, "air")
		else:
			var sq := _land_squash(hop_t - 0.3)
			_spark(Vector2(140, fy), -1, "stand", sq.x, sq.y)
		_fx("fx_dust", "land", hop_t - 0.3, Vector2(140, fy - 4))
	_fx("fx_light", "ring", t - touch, Vector2(118, 40))
	J.ring_sparks(self, Vector2(118, 40), t - touch, 17, 10, 100.0, 0.3)
	_text_pop(Vector2(84, 30), t - touch, "+800", 0.9)

func _collect_time(target: Vector2) -> float:
	var steps := 90
	for i in steps:
		var tt := 0.31 + 0.84 * float(i) / steps
		var p := _shard_run(tt)
		if absf(p.x - target.x) < 8.0 and target.y > p.y - 18.0 and target.y < p.y + 2.0:
			return tt
	return 99.0

func _shard_run(t: float) -> Vector2:
	if t < 0.31:
		return Vector2(8 + 90.0 * t, 96)
	if t < 1.15:
		return J.arc(Vector2(36, 96), Vector2(112, 96), 42.0, (t - 0.31) / 0.84)
	return Vector2(112 + minf((t - 1.15) * 60.0, 10.0), 96)

func _demo_shards(u: float) -> void:
	var t := u
	_ground(0, 160, 96)
	var xs := [44.0, 58.0, 72.0, 86.0, 100.0]
	for i in 5:
		var c := Vector2(xs[i], 62 + sin(t * 4.0 + i) * 2.0).round()
		var ct := _collect_time(Vector2(xs[i], 62))
		if t < ct:
			_a("shard", "spin", t + i * 0.13, c - Vector2(8, 8))
			var gt := fposmod(t * 0.9 + i * 0.37, 1.0)
			J.glint(self, c + Vector2(4, -5), gt * 1.2 - 0.9, 3.0, 0.24)
		else:
			J.ring_sparks(self, c, t - ct, 20 + i, 8, 90.0, 0.25)
			_fx("fx_sparkle", "twinkle", t - ct, c)
			_text_pop(c + Vector2(0, -12), t - ct, "+1", 0.4)
	# big shard: orbiting sparks and a slow glint
	var bc := Vector2(136, 44 + sin(t * 2.0) * 2.0).round()
	_a("big_shard", "spin", t, bc - Vector2(12, 12))
	for k in 3:
		var ang := t * 2.4 + k * TAU / 3.0
		var sp := bc + Vector2(cos(ang) * 14.0, sin(ang) * 6.0)
		draw_rect(Rect2(sp.floor(), Vector2.ONE), WHITE if sin(ang) > 0.0 else GRAY)
	_fx("fx_sparkle", "twinkle", fposmod(t, 1.1) - 0.8, bc + Vector2(8, -10))
	var p := _shard_run(t)
	var pose := "run" if t < 0.31 or (t > 1.15 and t < 1.32) else ("air" if t < 1.15 else "stand")
	_spark(p, 1, pose, 1, 1, -1, t)
	_fx("fx_dust", "land", t - 1.15, Vector2(112, 92))

func _demo_charge(u: float) -> void:
	var grab := 1.4
	var hurt := 3.18
	var t := J.stopped(u, [Vector2(grab, 0.1), Vector2(hurt, 0.1)])
	_shake(J.shake(u - grab, 2.0, 0.18, 13) + J.shake(u - hurt, 3.0, 0.25, 14))
	_ground(0, 160, 96)
	var hit := 0.42
	var a := t - hit
	# CHARGE cell rises out of the block, hovers until taken
	if a > 0.0 and t < grab:
		var iy := 40.0 - 16.0 * clampf(a / 0.38, 0.0, 1.0)
		var bob := 0.0 if a < 0.38 else roundf(sin(t * 6.0))
		_a("pickups", "charge", t, Vector2(72, iy + bob))
	if t < hit:
		_a("bump_block", "charge", t, Vector2(72, 40))
	else:
		_a("bump_block", "hit", a, Vector2(72, 40 + J.bump_hop(a)))
	# spark route
	var feet: Vector2
	var pose := "stand"
	var face := 1
	var land1 := hit + J.fall_time(26.0, 800.0)
	if t < 0.2:
		feet = Vector2(80, 96)
	elif t < hit:
		feet = Vector2(80, 96 - 26.0 * sin((t - 0.2) / 0.22 * PI / 2.0))
		pose = "air"
	elif t < land1:
		feet = Vector2(80, J.fall_y(70, t - hit, 96, 800.0))
		pose = "air"
	elif t < 0.95:
		feet = Vector2(lerpf(80.0, 104.0, (t - land1) / (0.95 - land1)), 96)
		pose = "run"
	elif t < 1.45:
		feet = J.arc(Vector2(104, 96), Vector2(80, 40), 18.0, (t - 0.95) / 0.5)
		pose = "air"
		face = -1
	elif t < 1.7:
		feet = Vector2(80, 40)
	elif t < 2.05:
		feet = J.arc(Vector2(80, 40), Vector2(108, 96), 14.0, (t - 1.7) / 0.35)
		pose = "air"
	elif t < hurt:
		feet = Vector2(108, 96)
	else:
		feet = J.arc(Vector2(108, 96), Vector2(94, 96), 10.0, clampf((t - hurt) / 0.25, 0.0, 1.0))
		pose = "air" if t < hurt + 0.25 else "stand"
	var charged := t >= grab and t < hurt
	if charged:
		_a("fx_charge_glow", "glow", t, feet + Vector2(-12, -19))
	var blink := t > hurt + 0.1 and int(t * 14.0) % 2 == 0
	if u > grab and u < grab + 0.1:
		J.spark_flash(self, feet)
	elif not blink:
		_spark(feet, face, pose, 1, 1, -1, t)
	_fx("fx_light", "ring", t - grab, feet + Vector2(0, -7))
	J.pulse_box(self, feet + Vector2(0, -7), t - grab, 8.0, 60.0, 0.25)
	_text_pop(Vector2(80, 14), t - grab, "CHARGE", 0.8)
	# the hit that eats the charge
	J.pulse_box(self, feet + Vector2(0, -7), t - hurt, 6.0, 110.0, 0.3)
	J.ring_sparks(self, feet + Vector2(0, -7), t - hurt, 22, 12, 130.0, 0.3)
	var wx := 175.0 - 45.0 * (t - 2.0)
	if t > 2.0:
		if t < hurt:
			_a("walker", "walk", t, Vector2(wx - 8, 80))
		else:
			var back := 175.0 - 45.0 * (hurt - 2.0) + maxf(0.0, t - hurt - 0.15) * 45.0
			if t < hurt + 0.15:
				_a("walker", "turn", t - hurt, Vector2(back - 8, 80))
			else:
				_a("walker", "walk", t, Vector2(back - 8, 80), true)

# ================================================================== page C

func _vent_frame(s: float) -> Array:
	# s = cycle position 0..1 (period 2 s). Down 60%, up 40%.
	if s < 0.45:
		return ["down", 0, 0.0]
	if s < 0.6:
		return ["warn", sh.frame_at("spike_vent", "warn", (s - 0.45) * 2.0), _jitter(s * 2.0)]
	if s < 0.64:
		return ["rise", sh.frame_at("spike_vent", "rise", (s - 0.6) * 2.0), 0.0]
	if s < 0.95:
		return ["up", sh.frame_at("spike_vent", "up", (s - 0.64) * 2.0), 0.0]
	return ["retract", sh.frame_at("spike_vent", "retract", (s - 0.95) * 2.0), 0.0]

func _demo_vents(u: float) -> void:
	_ground(0, 160, 96)
	for i in 8:
		var x := 16.0 + 16.0 * i
		var s := fposmod(u / 2.0 + 0.12 * (7 - i), 1.0)
		var st := _vent_frame(s)
		var jx: float = st[2]
		_f("spike_vent", st[0], st[1], Vector2(x + jx, 80))
	# the Spark rides the gap in the wave
	var s0 := fposmod(u / 2.0, 1.0)
	var x0 := 8.0 + 136.0 * s0
	_spark(Vector2(x0, 72 if s0 > 0.02 and s0 < 0.98 else 96), 1, "run", 1, 1, -1, u)
	# a girder to run on above the wave
	for i in 9:
		_f("girder", "static", 0 if i == 0 else (2 if i == 8 else 1), Vector2(8 + 16.0 * i, 72))

func _demo_dropper(u: float) -> void:
	var t := u
	var trig := 0.6
	var drop := trig + 0.15
	var fall_t := J.fall_time(48.0, 1800.0)
	var land := drop + fall_t
	var rise := land + 1.5
	_shake(J.shake(t - land, 3.0, 0.25, 15))
	_ceiling(0, 160, 16)
	_ground(0, 160, 96)
	var y := 16.0
	if t < trig:
		_a("dropper", "idle", t, Vector2(64, y))
	elif t < drop:
		_a("dropper", "tell", t - trig, Vector2(64 + _jitter(t), y))
	elif t < land:
		y = J.fall_y(16, t - drop, 64, 1800.0)
		_f("dropper", "fall", 0, Vector2(64, y))
		for k in 3:
			draw_rect(Rect2(68 + k * 11, y - 6 - k * 3, 1, 5), GRAY)
	elif t < rise:
		_a("dropper", "land", t - land, Vector2(64, 64))
	else:
		y = maxf(16.0, 64.0 - (t - rise) * 30.0)
		_a("dropper", "rise" if y > 16.0 else "idle", t, Vector2(64, y))
	_fx("press_dust", "puff", t - land, Vector2(80, 88))
	J.dust(self, Vector2(80, 95), t - land, 16, 12, 120.0, 0.45)
	var sx := minf(8.0 + 90.0 * t, 140.0)
	var face := 1 if sx < 140.0 else -1
	var flinch := t > land and t < land + 0.1
	_spark(Vector2(sx, 96), face, "run" if sx < 140.0 else "stand", 1.1 if flinch else 1.0, 0.9 if flinch else 1.0, -1, t)

func _demo_ceiling(u: float) -> void:
	var t := u
	var pass_t := 0.89
	var drop := pass_t + 0.4
	var fall_t := J.fall_time(64.0)
	var land := drop + fall_t
	_shake(J.shake(t - land, 1.0, 0.15, 17))
	_ceiling(0, 160, 32)
	_ground(0, 160, 96)
	if t < pass_t:
		_f("loose_ceiling", "intact", 0, Vector2(80, 16))
	elif t < drop:
		_a("loose_ceiling", "crack", t - pass_t, Vector2(80 + _jitter(t), 16))
		_a("loose_ceiling", "dust", t - pass_t, Vector2(80, 32))
		J.grit(self, Vector2(88, 32), t - pass_t, 18, 6, 10.0, 0.4)
	else:
		_f("loose_ceiling", "empty", 0, Vector2(80, 16))
	if t >= drop and t < land:
		_a("loose_ceiling", "chunk", t - drop, Vector2(80, J.fall_y(16, t - drop, 80)))
	elif t >= land:
		_f("loose_ceiling", "landed", 0, Vector2(80, 80))
		J.dust(self, Vector2(88, 95), t - land, 19, 8, 80.0, 0.4)
	var sx := minf(8.0 + 90.0 * t, 150.0)
	_spark(Vector2(sx, 96), 1 if sx < 150.0 else -1, "run" if sx < 150.0 else "stand", 1, 1, -1, t)

func _ring_route(t: float) -> Vector2:
	if t < 0.2:
		return Vector2(16, 80)
	if t < 0.5:
		return J.arc(Vector2(16, 80), Vector2(38, 62), 18.0, (t - 0.2) / 0.3)
	if t < 0.62:
		return Vector2(38, 62).lerp(Vector2(64, 55), (t - 0.5) / 0.12)
	if t < 0.92:
		return J.arc(Vector2(64, 55), Vector2(80, 44), 22.0, (t - 0.62) / 0.3)
	if t < 1.02:
		return Vector2(80, 44).lerp(Vector2(104, 47), (t - 0.92) / 0.1)
	if t < 1.55:
		return J.arc(Vector2(104, 47), Vector2(140, 80), 26.0, (t - 1.02) / 0.53)
	return Vector2(140, 80)

func _demo_rings(u: float) -> void:
	var t := u
	var pops := [0.62, 1.02]
	var centers := [Vector2(64, 48), Vector2(104, 40)]
	_shake(J.shake(t - 0.62, 1.0, 0.1, 20) + J.shake(t - 1.02, 1.0, 0.1, 21))
	_ground(0, 32, 80, true, false)
	_ground(128, 160, 80, false, true)
	for i in 2:
		var c: Vector2 = centers[i]
		var pt: float = pops[i]
		var tl := c - Vector2(12, 12)
		if t < pt:
			_a("lift_ring", "idle", t, tl)
		elif t < 1.55:
			_a("lift_ring", "pop", t - pt, tl)
		else:
			_a("lift_ring", "idle", t, tl)
		_fx("fx_light", "ring", t - pt, c)
		_fx("fx_light", "ring", t - 1.55 - i * 0.05, c)
	# dash ghosts for the two dashes
	for k in range(4, 0, -1):
		var tk := t - k * 0.03
		if (tk >= 0.5 and tk <= 0.62) or (tk >= 0.92 and tk <= 1.02):
			J.spark_ghost(self, _ring_route(tk), k - 1, 1.3, 0.8)
	var p := _ring_route(t)
	var dashing := (t >= 0.5 and t < 0.62) or (t >= 0.92 and t < 1.02)
	var dash_pip := 1
	if t >= 0.5 and t < 0.62 or (t >= 0.92 and t < 1.02):
		dash_pip = 0
	if t < 0.2 or t >= 1.55:
		var sq := _land_squash(t - 1.55)
		_spark(p, 1, "stand", sq.x, sq.y, 1)
	else:
		_spark(p, 1, "air", 1.3 if dashing else 1.0, 0.8 if dashing else 1.0, dash_pip)
	_fx("fx_dust", "land", t - 1.55, Vector2(140, 76))

func _demo_spring(u: float) -> void:
	var t := u
	var fall := J.fall_time(97.0, 1600.0)
	_ground(0, 160, 96)
	var feet: Vector2
	var sq := Vector2.ONE
	var pose := "air"
	if t < fall:
		feet = Vector2(80, J.fall_y(-10, t, 87, 1600.0))
		sq = Vector2(0.9, 1.15)
		_f("spring", "rest", 0, Vector2(72, 80))
	else:
		var a := t - fall
		_a("spring", "bounce", a, Vector2(72, 80))
		if a < 0.05:
			feet = Vector2(80, 91)
			sq = Vector2(1.35, 0.7)
			pose = "stand"
		else:
			var b := a - 0.05
			feet = Vector2(80, 83.0 - (400.0 * b - 0.5 * 700.0 * b * b))
			sq = Vector2(0.8, 1.3) if b < 0.15 else Vector2.ONE
		_fx("fx_dust", "land", a, Vector2(80, 92))
		J.dust(self, Vector2(80, 95), a, 23, 6, 70.0, 0.3)
	_spark(feet, 1, pose, sq.x, sq.y)

func _walker_state(t: float) -> Array:
	# paces between x 20 and 70 at 45 px/s, 2 turn-tell frames (0.12 s) at each end
	var leg := 50.0 / 45.0
	var cyc := (leg + 0.12) * 2.0
	var s := fposmod(t, cyc)
	if s < leg:
		return [70.0 - 45.0 * s, "walk", false, s]
	if s < leg + 0.12:
		return [20.0, "turn", false, s - leg]
	s -= leg + 0.12
	if s < leg:
		return [20.0 + 45.0 * s, "walk", true, s]
	return [70.0, "turn", true, s - leg]

func _demo_tells(u: float) -> void:
	var t := u
	_ground(0, 160, 96)
	var ws := _walker_state(t)
	var wx: float = ws[0]
	_a("walker", ws[1], ws[3], Vector2(wx - 8, 80), ws[2])
	# hopper: idle, 0.24 s crouch tell, jump, land
	var s := fposmod(t, 1.6)
	var hp := Vector2(112, 80)
	if s < 0.6:
		_a("hopper", "idle", s, hp)
	elif s < 0.84:
		_a("hopper", "crouch", s - 0.6, hp + Vector2(_jitter(s), 0))
	elif s < 1.4:
		var f := (s - 0.84) / 0.56
		var y := 80.0 - 34.0 * 4.0 * f * (1.0 - f)
		_f("hopper", "jump" if f < 0.5 else "fall", 0, Vector2(112, y))
	else:
		_a("hopper", "land", s - 1.4, hp)
	_fx("fx_dust", "land", s - 1.4, Vector2(120, 92))
	DrawUtil.text(self, Vector2(45, 104), "TURN TELL", DARK, 1, HORIZONTAL_ALIGNMENT_CENTER)
	DrawUtil.text(self, Vector2(120, 104), "HOP TELL", DARK, 1, HORIZONTAL_ALIGNMENT_CENTER)
