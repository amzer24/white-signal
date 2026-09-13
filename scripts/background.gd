extends Node2D
## Ditherpunk parallax backdrop — three BIOMES (one per zone) built from baked
## silhouettes placed in world space, plus shared sky/dune/cable layers.
## Lives INSIDE a CanvasLayer(-1); parallax is manual, driven by the camera.
##
## Parallax rule: an element anchored at world x `wx` with speed `s` is drawn at
## screen x = (wx - cam_center) * s + 240, so it is centred on screen exactly
## when the camera is centred on it, at any depth. Biome-specific layers fade
## with their zone weight so a far RUINS hall doesn't haunt the FLATS.

const W := 480.0
const H := 270.0
const GROUND := 230.0  # world y of the main floor line

var _tex := {}  # baked silhouettes
var _t := 0.0

func _ready() -> void:
	_bake_all()

func _process(d: float) -> void:
	_t += d
	queue_redraw()

# =============================================================== baking
func _bake(texture_id: String, w: int, h: int, fn: Callable) -> void:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	fn.call(img)
	_tex[texture_id] = ImageTexture.create_from_image(img)

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)

func _bake_all() -> void:
	# --- Z0 FLATS -----------------------------------------------------------
	# dead broadcast sun: dithered disc with dropped scanlines (it's a signal, not a star)
	_bake("sun", 72, 72, func(img: Image) -> void:
		var r := 34.0
		for y in 72:
			if y % 4 == 3:
				continue
			for x in 72:
				var dx := x - 36.0
				var dy := y - 36.0
				var d := sqrt(dx * dx + dy * dy) / r
				if d > 1.0:
					continue
				var edge := d > 0.82
				if edge and DrawUtil.bayer(x, y) > int((1.0 - d) / 0.18 * 16.0):
					continue
				var band := int((y + 36) / 9.0) % 3 == 0
				_px(img, x, y, Color("242424") if band else Color("1c1c1c"))
	)
	# flat mesas (far)
	for i in 3:
		_bake("mesa%d" % i, 200, 44, func(img: Image) -> void:
			var seed_v := i * 977
			var x := 0
			while x < 200:
				var h: int = 18 + (DrawUtil.hash2(int(x / 12.0) + seed_v, i) % 5) * 3
				if x < 24:
					h = mini(h, 6 + x)
				if x > 176:
					h = mini(h, 6 + (200 - x))
				_fill(img, x, 44 - h, 12, h, Color("171717"))
				_fill(img, x, 44 - h, 12, 1, Color("222222"))
				x += 12
			# strata
			for y in range(30, 44, 4):
				for xx in range(0, 200, 3):
					if DrawUtil.hash2(xx, y + seed_v) % 3 == 0:
						_px(img, xx, y, Color("0e0e0e"))
		)
	# fallen pylon: a lattice tower lying at ~25°
	_bake("pylon_fallen", 110, 60, func(img: Image) -> void:
		for i in 100:
			var x := 4 + i
			var y := 52 - int(i * 0.42)
			_fill(img, x, y, 1, 4, Color("161616"))
			_fill(img, x, y - 6, 1, 2, Color("161616"))
			if i % 9 == 0:
				_fill(img, x, y - 6, 1, 10, Color("1e1e1e"))
			if i % 9 == 4:
				for k in 6:
					_px(img, x + k, y - 6 + k, Color("1a1a1a"))
		# base stub + broken foot
		_fill(img, 0, 46, 8, 14, Color("1a1a1a"))
		_fill(img, 2, 40, 3, 6, Color("1e1e1e"))
	)
	# crashed satellite hull: a cracked cylinder with one solar wing, half sunk
	_bake("satellite", 90, 40, func(img: Image) -> void:
		for y in range(14, 34):
			var half := int(sqrt(maxf(0.0, 100.0 - float(y - 24) * float(y - 24))))
			_fill(img, 30 - int(half / 3.0), y, 40 + int(half / 3.0) * 2, 1, Color("181818"))
		for y in range(16, 32, 3):
			_fill(img, 24, y, 52, 1, Color("111111"))
		# wing (tilted panel grid)
		for k in 28:
			_fill(img, 60 + k, 30 - int(k / 2.0), 1, 6, Color("1c1c1c"))
			if k % 4 == 0:
				_fill(img, 60 + k, 30 - int(k / 2.0), 1, 6, Color("262626"))
		# cracked nose + dead light
		_fill(img, 18, 20, 6, 8, Color("1c1c1c"))
		_fill(img, 20, 22, 2, 2, Color("2e2e2e"))
		# sunk into crust
		_fill(img, 10, 33, 76, 7, Color("101010"))
	)
	# --- Z1 RUINS -----------------------------------------------------------
	# freestanding broken arch — what's left of a relay hall doorway
	_bake("arch", 70, 90, func(img: Image) -> void:
		_fill(img, 4, 30, 12, 60, Color("161616"))
		_fill(img, 54, 44, 12, 46, Color("161616"))
		for a in 40:
			var ang := PI + a / 40.0 * PI * 0.62
			var x := int(35 + cos(ang) * 30)
			var y := int(34 + sin(ang) * 26)
			_fill(img, x, y, 6, 5, Color("161616"))
			if a % 5 == 0:
				_fill(img, x + 2, y + 1, 2, 1, Color("222222"))
		# stone courses + a lit sliver where the keystone cracked
		for y in range(34, 90, 6):
			_fill(img, 4, y, 12, 1, Color("101010"))
			_fill(img, 54, y, 12, 1, Color("101010"))
		_fill(img, 26, 12, 1, 4, Color("3a3a3a"))
		_fill(img, 0, 86, 70, 4, Color("111111"))
	)
	for i in 4:
		_bake("hall%d" % i, 140, 100, func(img: Image) -> void:
			var sv := 31 * (i + 1)
			var body := Color("151515")
			# broken roofline
			var x := 0
			while x < 140:
				var top: int = 8 + (DrawUtil.hash2(int(x / 8.0), sv) % 4) * 5
				if x < 10 or x > 124:
					top += 20
				_fill(img, x, top, 8, 100 - top, body)
				_fill(img, x, top, 8, 1, Color("1f1f1f"))
				x += 8
			# arched windows (transparent = sky shows through), some lit
			var wx := 14
			while wx < 120:
				var wy := 34 + (DrawUtil.hash2(wx, sv) % 2) * 26
				if DrawUtil.hash2(wx, sv + 5) % 4 != 0:
					_fill(img, wx, wy + 3, 8, 12, Color(0, 0, 0, 0))
					_fill(img, wx + 1, wy + 1, 6, 2, Color(0, 0, 0, 0))
					_fill(img, wx + 2, wy, 4, 1, Color(0, 0, 0, 0))
					if DrawUtil.hash2(wx, sv + 9) % 7 == 0:
						_fill(img, wx + 2, wy + 8, 4, 4, Color("2a2a2a"))
				wx += 22
			# floor rubble
			for k in 30:
				var rx := DrawUtil.hash2(k, sv) % 140
				_fill(img, rx, 92 + k % 6, 3 + k % 4, 2, Color("1b1b1b"))
		)
	# collapsed dish: a tilted bowl arc with rim dots + struts
	_bake("dish", 120, 70, func(img: Image) -> void:
		for a in 90:
			var ang := PI * 1.05 + a / 90.0 * PI * 0.9
			var x := int(60 + cos(ang) * 56)
			var y := int(40 + sin(ang) * 30)
			_fill(img, x, y, 3, 3, Color("1a1a1a"))
			if a % 6 == 0:
				_fill(img, x + 1, y - 1, 1, 1, DrawUtil.GRAY)
		# inner mesh
		for a in 45:
			var ang := PI * 1.1 + a / 45.0 * PI * 0.8
			var x := int(60 + cos(ang) * 44)
			var y := int(44 + sin(ang) * 22)
			_px(img, x, y, Color("161616"))
		# feed horn + struts
		_fill(img, 58, 20, 4, 6, Color("222222"))
		for k in 24:
			_px(img, 40 + k, 60 - k, Color("1e1e1e"))
			_px(img, 80 - k, 60 - k, Color("1e1e1e"))
		_fill(img, 20, 60, 80, 4, Color("141414"))
	)
	_bake("pillar", 14, 70, func(img: Image) -> void:
		_fill(img, 3, 8, 8, 62, Color("1c1c1c"))
		_fill(img, 5, 8, 1, 62, Color("262626"))
		_fill(img, 1, 62, 12, 8, Color("222222"))
		# broken capital
		_fill(img, 0, 4, 14, 4, Color("242424"))
		_fill(img, 9, 0, 5, 4, Color(0, 0, 0, 0))
		_fill(img, 0, 0, 6, 4, Color("242424"))
	)
	# --- Z2 GATE ------------------------------------------------------------
	# the GATE spire: tapered lattice tower with rings, seen from the zone entrance
	_bake("spire", 70, 230, func(img: Image) -> void:
		for y in range(6, 230):
			var f := float(y - 6) / 224.0
			var half := int(3 + f * 30)
			_fill(img, 35 - half, y, half * 2, 1, Color("1c1c1c"))
			# lit face on the left, shadow dither on the right
			for x in range(35 - half, 35 + half):
				if x > 35 and DrawUtil.bayer(x, y) < 5:
					_px(img, x, y, Color("121212"))
				elif x < 35 - half + 2:
					_px(img, x, y, Color("2a2a2a"))
			if y % 28 == 0:
				_fill(img, 35 - half - 4, y, half * 2 + 8, 2, Color("2e2e2e"))
				_fill(img, 35 - half - 4, y + 2, 2, 6, Color("1a1a1a"))
				_fill(img, 35 + half + 2, y + 2, 2, 6, Color("1a1a1a"))
		# tip + beacon
		_fill(img, 34, 0, 2, 8, Color("2a2a2a"))
		_fill(img, 33, 2, 4, 2, DrawUtil.GRAY)
	)
	_bake("pylon_tall", 30, 150, func(img: Image) -> void:
		_fill(img, 13, 0, 4, 150, Color("1c1c1c"))
		for y in range(0, 150, 3):
			_px(img, 12 + int(y / 3.0) % 2 * 5, y, Color("262626"))
		for ay in [18, 48, 82]:
			_fill(img, 2, ay, 26, 2, Color("242424"))
			_fill(img, 2, ay + 2, 1, 5, Color("222222"))
			_fill(img, 27, ay + 2, 1, 5, Color("222222"))
		_fill(img, 14, 0, 2, 2, Color("2e2e2e"))
	)
	# transformer yard — a row of boxes, insulators and a lit control panel
	_bake("yard", 110, 50, func(img: Image) -> void:
		for k in 4:
			var bx := 4 + k * 27
			_fill(img, bx, 20, 20, 26, Color("161616"))
			_fill(img, bx, 20, 20, 1, Color("222222"))
			_fill(img, bx + 2, 24, 16, 1, Color("101010"))
			_fill(img, bx + 2, 34, 16, 1, Color("101010"))
			# insulators
			for j in 3:
				_fill(img, bx + 3 + j * 6, 12, 2, 8, Color("1c1c1c"))
				_fill(img, bx + 2 + j * 6, 14, 4, 1, Color("262626"))
				_fill(img, bx + 2 + j * 6, 17, 4, 1, Color("262626"))
		# overhead bus bar
		_fill(img, 0, 10, 110, 1, Color("1c1c1c"))
		# fence
		for x in range(0, 110, 4):
			_fill(img, x, 40, 1, 10, Color("141414"))
		_fill(img, 0, 46, 110, 4, Color("101010"))
	)
	for i in 3:
		_bake("cliff%d" % i, 120, 130, func(img: Image) -> void:
			var sv := 71 * (i + 1)
			var x := 0
			while x < 120:
				var top: int = 6 + (DrawUtil.hash2(int(x / 6.0), sv) % 6) * 3
				_fill(img, x, top, 6, 130 - top, Color("181818"))
				_fill(img, x, top, 6, 1, Color("262626"))
				x += 6
			for y in range(20, 130, 7):
				var xx := 0
				while xx < 120:
					if DrawUtil.hash2(xx, y + sv) % 5 < 3:
						_fill(img, xx, y, 4, 1, Color("111111"))
					xx += 4
			for y in range(10, 130):
				for xx in range(0, 120, 2):
					if DrawUtil.bayer(xx, y) < 2 and DrawUtil.hash2(xx, y + sv) % 3 == 0:
						_px(img, xx, y, Color("222222"))
		)

# =============================================================== drawing
func _sx(wx: float, s: float, ccx: float) -> float:
	return roundf((wx - ccx) * s + 240.0)

func _sy(wy: float, s: float, cy: float) -> float:
	return roundf(wy - cy * s)

## zone weights from the camera centre (smoothstep across ±150px of each boundary)
func _zone_weights(ccx: float) -> PackedFloat32Array:
	if RunState.level.has("biome"):
		var fixed := PackedFloat32Array([0.0, 0.0, 0.0])
		fixed[int(RunState.level.biome)] = 1.0
		return fixed
	var zs: Array = RunState.level.zones
	var w := PackedFloat32Array([0.0, 0.0, 0.0])
	for i in 3:
		var x0 := float(zs[i].x0)
		var x1 := float(zs[i].x1)
		var a := 1.0 if i == 0 else smoothstep(x0 - 150.0, x0 + 150.0, ccx)
		var b := 1.0 if i == 2 else 1.0 - smoothstep(x1 - 150.0, x1 + 150.0, ccx)
		w[i] = a * b
	return w

func _tex_at(texture_id: String, wx: float, wy: float, s: float, ccx: float, cy: float, a: float) -> void:
	if a <= 0.02:
		return
	var tex: Texture2D = _tex[texture_id]
	var x := _sx(wx, s, ccx) - tex.get_width() / 2.0
	var y := _sy(wy, s, cy) - tex.get_height()
	if x + tex.get_width() < 0.0 or x > W:
		return
	draw_texture(tex, Vector2(x, y), Color(1, 1, 1, a))

func _draw() -> void:
	if RunState.lab_active and RunState.lab_generated:
		draw_rect(Rect2(0,0,W,H),DrawUtil.BG)
		var camera := get_viewport().get_camera_2d()
		# One broadcast landmark, outside the repeating terrain textures.
		_tex_at("sun",700.0,105.0,0.06,camera.position.x,0.0,1.0)
		return
	var cam := get_viewport().get_camera_2d()
	# JS cam = view TOP-LEFT; Camera2D.position = view CENTER
	var cx := cam.position.x - W * 0.5 if cam else 0.0
	var cy := cam.position.y - H * 0.5 if cam else 0.0
	var ccx := cx + 240.0
	var t := _t
	var w := _zone_weights(ccx)

	draw_rect(Rect2(0, 0, W, H), DrawUtil.BG)
	_draw_sky(cx, cy, t, w)
	_draw_far(ccx, cy, t, w)
	_draw_dune_far(cx, cy, w)
	_draw_mid(ccx, cy, t, w)
	_draw_near(cx, cy, t, w)
	_draw_ambient(cx, cy, t, w)

# --------------------------------------------------------------- sky
func _draw_sky(cx: float, cy: float, t: float, w: PackedFloat32Array) -> void:
	# horizon depth bands — RUINS sits lower/darker, GATE glows toward the goal
	var bands := [Color("0e0e0e"), Color("131313"), Color("181818"), Color("1e1e1e")]
	var base_y := 168.0 - cy * 0.2 + w[1] * 10.0
	for b in bands.size():
		var y0 := base_y + b * 16.0
		draw_rect(Rect2(0, y0, W, H - y0), bands[b])
		if b > 0:
			var x := 0
			while x < int(W):
				if DrawUtil.bayer(x, int(y0)) < 6:
					draw_rect(Rect2(x, y0, 2, 2), bands[b - 1])
				elif DrawUtil.bayer(x, int(y0) + 5) < 3:
					draw_rect(Rect2(x, y0 + 5, 2, 2), bands[b - 1])
				x += 2
	# FLATS: the dead sun low on the horizon, barely moving
	if w[0] > 0.02:
		_tex_at("sun", 700.0, 190.0 - cy * 0.05, 0.06, cx + 240.0, cy, w[0])
	# GATE: sky glow strengthening toward the gate
	if w[2] > 0.02:
		var g: float = RunState.level.goal.position.x
		var gx := clampf((g - (cx + 240.0)) / 1400.0, 0.0, 1.0)  # 0 at gate, 1 far
		var a := (0.14 - gx * 0.09) * w[2]
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
			PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, a), Color(1, 1, 1, a * 0.4), Color(1, 1, 1, 0)]))
	# starfield (denser in RUINS)
	var star_n := 44 + int(w[1] * 20.0)
	for i in star_n:
		var sx: float = fposmod(i * 173.0 - cx * 0.1, W)
		var sy: int = 6 + (i * 57) % 150
		if (i * 7 + int(t * 1.5)) & 3 == 0:
			continue
		draw_rect(Rect2(roundf(sx), sy, 1, 1), DrawUtil.GRAY if i % 5 == 0 else Color("2a2a2a"))
	# signal-ghost pulse — dying waveform sweeps the sky every ~7s
	var t_in := fmod(t, 7.0) / 7.0
	if t_in < 0.35:
		var gx := t_in / 0.35 * (W + 140.0) - 70.0 - cx * 0.3
		var a := 0.55 * (1.0 - absf(t_in - 0.175) / 0.175)
		var gi := 0
		while gi < 64:
			var yy := sin(gi * 0.35 + t * 10.0) * (7.0 - gi * 0.09)
			if yy > -5.0 and yy < 5.0:
				draw_rect(Rect2(gx + gi, 66.0 + yy - cy * 0.3, 2, 1), Color(DrawUtil.GRAY, a))
			gi += 3

# --------------------------------------------------------------- far (0.2–0.3x)
func _draw_far(ccx: float, cy: float, t: float, w: PackedFloat32Array) -> void:
	# FLATS: mesas along the whole horizon of Z0
	for i in 6:
		var wx := -100.0 + i * 260.0
		_tex_at("mesa%d" % (i % 3), wx, 192.0, 0.2, ccx, cy, w[0])
	# world motif: antenna towers everywhere except the RUINS clutter (they fell there)
	var k := -1
	while k < 9:
		var wx := k * 640.0 + 180.0
		var sx := _sx(wx, 0.25, ccx)
		if sx > -30.0 and sx < W + 30.0:
			var a: float = 1.0 - w[1] * 0.85
			var th := 120.0 + fposmod(k * 37.0 + 200.0, 50.0)
			var ty := H - th - cy * 0.25
			draw_rect(Rect2(sx - 1, ty, 3, th), Color(Color("141414"), a))
			draw_rect(Rect2(sx - 9, ty + 18, 19, 2), Color(DrawUtil.DARK, a))
			draw_rect(Rect2(sx - 7, ty + 34, 15, 2), Color(DrawUtil.DARK, a))
			draw_rect(Rect2(sx - 11, H - 40, 23, 3), Color(DrawUtil.DARK, a))
			var lit: bool = (int(t) >> 1) % 3 != (k % 3)
			draw_rect(Rect2(sx, ty - 3, 1, 2), Color(DrawUtil.GRAY if lit else Color("222222"), a))
		k += 1
	# RUINS: arches punctuate the skyline
	_tex_at("arch", 1420.0, 206.0, 0.3, ccx, cy, w[1])
	_tex_at("arch", 2180.0, 206.0, 0.3, ccx, cy, w[1])
	# RUINS: broken halls form a skyline
	var halls: PackedFloat32Array = [1180.0, 1330.0, 1520.0, 1700.0, 1900.0, 2080.0, 2260.0, 2420.0]
	for i in halls.size():
		_tex_at("hall%d" % (i % 4), halls[i], 206.0, 0.3, ccx, cy, w[1])
	# GATE: the spire is anchored on the goal — a landmark you walk toward
	if w[2] > 0.02:
		var g: float = RunState.level.goal.position.x + 13.0
		_tex_at("spire", g, GROUND - 10.0, 0.2, ccx, cy, w[2])
		# signal arcs off the tip every ~4s
		var ph := fmod(t, 4.3)
		if ph < 0.18:
			var tip := Vector2(_sx(g, 0.2, ccx), _sy(GROUND - 10.0, 0.2, cy) - 230.0)
			var pts := PackedVector2Array([tip])
			var p := tip
			var dir := -1.0 if int(t * 7.0) % 2 == 0 else 1.0
			for s in 6:
				p += Vector2(dir * (4.0 + DrawUtil.hash2(s, int(t * 30.0)) % 9), -6.0 - DrawUtil.hash2(s + 7, int(t * 30.0)) % 8)
				pts.append(p)
			draw_polyline(pts, Color(DrawUtil.WHITE, 0.7 * w[2] * (1.0 - ph / 0.18)), 1.0)
		# tall lattice pylons marching toward it
		var px: float = 2480.0
		while px < 3700.0:
			_tex_at("pylon_tall", px, 212.0, 0.35, ccx, cy, w[2] * 0.9)
			px += 160.0

# --------------------------------------------------------------- mid (0.4–0.5x)
func _draw_mid(ccx: float, cy: float, t: float, w: PackedFloat32Array) -> void:
	# FLATS: fallen pylons + relay-ruin blocks with breathing lights (the shared deco)
	_tex_at("satellite", 300.0, 216.0, 0.5, ccx, cy, w[0])
	_tex_at("pylon_fallen", 520.0, 214.0, 0.5, ccx, cy, w[0])
	_tex_at("pylon_fallen", 1010.0, 214.0, 0.5, ccx, cy, w[0])
	for d in RunState.level.deco:
		var sx: float = _sx(d.pos.x, 0.5, ccx)
		var sy: float = _sy(d.pos.y, 0.5, cy)
		if sx < -100.0 or sx > W + 100.0:
			continue
		var zone_a: float = maxf(w[0], w[1]) * 0.9 + w[2] * 0.4
		draw_rect(Rect2(sx, sy, d.s, d.s), Color(DrawUtil.DARK, zone_a), false, 1.0)
		draw_rect(Rect2(sx + 4, sy + 4, d.s - 8, d.s - 8), Color(DrawUtil.DARK, zone_a), false, 1.0)
		var on: bool = (int(d.pos.x) >> 4) % 4 == int(t * 0.8) % 4
		draw_rect(Rect2(sx + d.s / 2.0, sy - 3, 2, 2), Color(DrawUtil.WHITE if on else DrawUtil.DARK, zone_a))
	# RUINS: collapsed dish, pillars strung with sagging cable
	_tex_at("dish", 1760.0, 208.0, 0.4, ccx, cy, w[1])
	var pillars: PackedFloat32Array = [1230.0, 1360.0, 1470.0, 1640.0, 1830.0, 1990.0, 2150.0, 2300.0, 2400.0]
	if w[1] > 0.02:
		for i in pillars.size():
			var px := pillars[i]
			_tex_at("pillar", px, 214.0, 0.5, ccx, cy, w[1])
			if i + 1 < pillars.size():
				var x0 := _sx(px, 0.5, ccx)
				var x1 := _sx(pillars[i + 1], 0.5, ccx)
				if x1 < 0.0 or x0 > W:
					continue
				var y0 := _sy(214.0 - 62.0, 0.5, cy)
				var sag := 10.0 + float(i % 3) * 5.0
				var prev := Vector2(x0, y0)
				for s in range(1, 9):
					var f := s / 8.0
					var p := Vector2(lerpf(x0, x1, f), y0 + sin(f * PI) * sag)
					draw_line(prev, p, Color(Color("222222"), w[1]), 1.0)
					prev = p
	# GATE: transformer yards with live panel lights
	for yx in [2760.0, 3320.0]:
		_tex_at("yard", yx, 220.0, 0.5, ccx, cy, w[2])
		if w[2] > 0.05:
			var sx := _sx(yx, 0.5, ccx)
			var sy := _sy(220.0, 0.5, cy)
			for k in 4:
				var on := int(t * 2.0 + k * 1.7) % 5 == 0
				draw_rect(Rect2(sx - 55 + 4 + k * 27 + 16, sy - 50 + 22, 2, 1), Color(DrawUtil.WHITE if on else Color("222222"), w[2]))
	# GATE: cliff slabs walling the approach
	var cliffs: PackedFloat32Array = [2440.0, 2620.0, 2850.0, 3080.0, 3290.0, 3520.0, 3760.0]
	for i in cliffs.size():
		_tex_at("cliff%d" % (i % 3), cliffs[i], 222.0, 0.5, ccx, cy, w[2])

# --------------------------------------------------------------- near (0.5–1.4x)
func _amp(w: PackedFloat32Array) -> float:
	# dune amplitude — flatten in the RUINS (rubble field) and GATE (rock)
	return 1.0 - w[1] * 0.5 - w[2] * 0.6

func _draw_dune_far(cx: float, cy: float, w: PackedFloat32Array) -> void:
	var amp := _amp(w)
	var x2 := 0
	while x2 < int(W):
		var wx2 := x2 + cx * 0.5
		var ry := roundf(196.0 + (sin(wx2 * 0.011) * 18.0 + sin(wx2 * 0.031 + 2.2) * 8.0) * amp - cy * 0.5)
		draw_rect(Rect2(x2, ry, 3, H - ry + 40.0), Color("101010"))
		draw_rect(Rect2(x2, ry, 3, 1), Color("1c1c1c"))
		x2 += 3

func _draw_near(cx: float, cy: float, t: float, w: PackedFloat32Array) -> void:
	var amp := _amp(w)
	# waveform dunes 0.65x with pale crest
	var x3 := 0
	while x3 < int(W):
		var wx3 := x3 + cx * 0.65
		var ry2 := roundf(208.0 + (sin(wx3 * 0.02) * 14.0 + sin(wx3 * 0.053 + 1.7) * 6.0) * amp - cy * 0.65)
		draw_rect(Rect2(x3, ry2, 2, H - ry2 + 40.0), Color("141414"))
		draw_rect(Rect2(x3, ry2, 2, 1), DrawUtil.GRAY if (x3 >> 1) % 2 == 0 else DrawUtil.DARK)
		x3 += 2
	# RUINS: rubble scatter on the near dune line
	if w[1] > 0.05:
		var rx := 0
		while rx < int(W):
			var wx := rx + cx * 0.65
			if DrawUtil.hash2(int(int(wx) / 6.0), 3) % 4 == 0:
				var ry3 := roundf(208.0 + (sin(wx * 0.02) * 14.0 + sin(wx * 0.053 + 1.7) * 6.0) * amp - cy * 0.65)
				var hh := 2 + DrawUtil.hash2(int(int(wx) / 6.0), 4) % 4
				draw_rect(Rect2(rx, ry3 - hh, 3 + hh % 3, hh), Color(Color("1a1a1a"), w[1]))
			rx += 6
	# GATE light pillar — breathing, visible across the zone
	var gx2 := roundf(RunState.level.goal.position.x + 13.0 - cx)
	if gx2 > -20.0 and gx2 < W + 20.0:
		var breathe := 0.10 + sin(t * 1.1) * 0.04
		draw_rect(Rect2(gx2 - 8, 0, 16, H), Color(DrawUtil.WHITE, breathe))
		draw_rect(Rect2(gx2 - 4, 0, 8, H), Color(DrawUtil.WHITE, breathe + 0.06))
	# foreground cables 1.15x + deepest cables 1.4x
	var x4 := 0
	while x4 < int(W):
		var wx4 := x4 + cx * 1.15
		var cy2 := roundf(252.0 + sin(wx4 * 0.03) * 7.0 - cy)
		if cy2 > H - 30.0:
			draw_rect(Rect2(x4, cy2, 3, 1), Color("1e1e1e"))
		var wx5 := x4 + cx * 1.4
		var cy3 := roundf(262.0 + sin(wx5 * 0.017) * 6.0 - cy * 1.4)
		if cy3 > H - 14.0 and cy3 < H:
			draw_rect(Rect2(x4, cy3, 3, 1), Color("151515"))
		x4 += 3
	# fog band (thicker in the RUINS)
	draw_rect(Rect2(0, 205.0 - cy, W, 30), Color(DrawUtil.GRAY, 0.08 + w[1] * 0.05))

# --------------------------------------------------------------- ambient FX
func _draw_ambient(cx: float, cy: float, t: float, w: PackedFloat32Array) -> void:
	# drifting STATIC specks (everywhere; denser in RUINS)
	var n := 14 + int(w[1] * 12.0)
	for i in n:
		var sx2: float = fposmod(i * 97.0 + floorf(t * 2.2) * 29.0 + float(i * i * 7), W)
		var sy2: float = 10.0 + fposmod(i * 83.0 + floorf(t * 1.3) * 41.0, 140.0)
		if (i + int(t * 6.0)) & 3 == 0:
			continue
		draw_rect(Rect2(sx2, sy2, 1, 1), DrawUtil.GRAY if i % 4 == 0 else Color("2e2e2e"))
	# FLATS: wind — dust streaks racing right, low over the ground
	if w[0] > 0.05:
		for i in 10:
			var speed := 90.0 + float(i % 4) * 30.0
			var sx := fposmod(i * 131.0 + t * speed - cx * 0.9, W + 40.0) - 20.0
			var sy := 150.0 + (i * 37) % 90 - cy * 0.9
			draw_rect(Rect2(sx, sy, 6 + i % 5, 1), Color(Color("2a2a2a"), w[0]))
	# RUINS: static rain — short drops falling through the halls
	if w[1] > 0.05:
		var rain_tier := mini(2, int(RunState.relay_time / 40.0)) if RunState.level.get("rain_pressure", false) else 0
		for i in 22 + rain_tier * 16:
			var sx := fposmod(i * 67.0 + float(i * i * 3) - cx * 0.6, W)
			var sy := fposmod(i * 53.0 + t * (140.0 + float(i % 5) * 25.0), H + 20.0) - 10.0
			draw_rect(Rect2(sx, sy, 1, 3), Color(Color("3a3a3a"), w[1] * 0.8))
	# GATE: signal sparks rising toward the spire
	if w[2] > 0.05:
		for i in 16:
			var sx := fposmod(i * 89.0 + sin(t * 1.3 + i) * 6.0 - cx * 0.7, W)
			var sy := H - fposmod(i * 41.0 + t * (26.0 + float(i % 4) * 9.0), H + 10.0)
			var bright := (i + int(t * 5.0)) % 3 == 0
			draw_rect(Rect2(sx, sy, 1, 1), Color(DrawUtil.WHITE if bright else DrawUtil.GRAY, w[2] * 0.8))
