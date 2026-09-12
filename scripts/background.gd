extends Node2D
## The 10-layer ditherpunk background — verbatim port of JS drawBackground().
## Lives INSIDE a CanvasLayer(-1) (CanvasLayer itself can't draw); parallax is
## manual like the JS original, driven by the viewport camera.

const W := 480.0
const H := 270.0

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	var cx := cam.position.x if cam else 0.0
	var cy := cam.position.y if cam else 0.0
	var t := Time.get_ticks_msec() / 1000.0
	var zone: int = RunState.cur_zone

	draw_rect(Rect2(0, 0, W, H), DrawUtil.BG)

	# 1. dithered horizon depth bands (subtle y-parallax)
	var bands := [Color("0e0e0e"), Color("131313"), Color("181818"), Color("1e1e1e")]
	var base_y := 168.0 - cy * 0.2
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

	# 2. static starfield (denser in RUINS)
	var star_n := 60 if zone == 1 else 44
	for i in star_n:
		var sx: float = fposmod(i * 173.0 - cx * 0.1, W)
		var sy: int = 6 + (i * 57) % 150
		if (i * 7 + int(t * 1.5)) & 3 == 0:
			continue
		draw_rect(Rect2(roundf(sx), sy, 1, 1), DrawUtil.GRAY if i % 5 == 0 else Color("2a2a2a"))

	# 3. drifting STATIC specks (denser in RUINS)
	var n := 26 if zone == 1 else 14
	for i in n:
		var sx2: float = fposmod(i * 97.0 + floorf(t * 2.2) * 29.0 + float(i * i * 7), W)
		var sy2: float = 10.0 + fposmod(i * 83.0 + floorf(t * 1.3) * 41.0, 140.0)
		if (i + int(t * 6.0)) & 3 == 0:
			continue
		draw_rect(Rect2(sx2, sy2, 1, 1), DrawUtil.GRAY if i % 4 == 0 else Color("2e2e2e"))

	# 4. signal-ghost pulse — dying waveform sweeps the sky every ~7s
	var t_in := fmod(t, 7.0) / 7.0
	if t_in < 0.35:
		var gx := t_in / 0.35 * (W + 140.0) - 70.0 - cx * 0.3
		var a := 0.55 * (1.0 - absf(t_in - 0.175) / 0.175)
		var gx_i := 0
		while gx_i < 64:
			var yy := sin(gx_i * 0.35 + t * 10.0) * (7.0 - gx_i * 0.09)
			if yy > -5.0 and yy < 5.0:
				draw_rect(Rect2(gx + gx_i, 66.0 + yy - cy * 0.3, 2, 1), Color(DrawUtil.GRAY, a))
			gx_i += 3

	# 5. far antenna towers 0.25x (+ y response)
	var k := -1
	while k < 9:
		var wx := k * 640.0 + 180.0
		var sx3 := roundf(wx - cx * 0.25)
		if sx3 > -30.0 and sx3 < W + 30.0:
			var th := 120.0 + fposmod(k * 37.0 + 200.0, 50.0)
			var ty := H - th - cy * 0.25
			draw_rect(Rect2(sx3 - 1, ty, 3, th), Color("141414"))
			draw_rect(Rect2(sx3 - 9, ty + 18, 19, 2), DrawUtil.DARK)
			draw_rect(Rect2(sx3 - 7, ty + 34, 15, 2), DrawUtil.DARK)
			draw_rect(Rect2(sx3 - 11, H - 40, 23, 3), DrawUtil.DARK)
			var lit: bool = (int(t) >> 1) % 3 != (k % 3)
			draw_rect(Rect2(sx3, ty - 3, 1, 2), DrawUtil.GRAY if lit else Color("222222"))
		k += 1

	# 6. relay-ruin blocks 0.5x with breathing lights
	for d in LevelData.DATA.deco:
		var sx4: float = d.pos.x - cx * 0.5
		var sy4: float = d.pos.y - cy * 0.5
		if sx4 < -100.0 or sx4 > W + 100.0:
			continue
		draw_rect(Rect2(sx4, sy4, d.s, d.s), DrawUtil.DARK, false, 1.0)
		draw_rect(Rect2(sx4 + 4, sy4 + 4, d.s - 8, d.s - 8), DrawUtil.DARK, false, 1.0)
		var on: bool = (int(d.pos.x) >> 4) % 4 == int(t * 0.8) % 4
		draw_rect(Rect2(sx4 + d.s / 2.0, sy4 - 3, 2, 2), DrawUtil.WHITE if on else DrawUtil.DARK)

	# 7. far dunes 0.5x
	var x2 := 0
	while x2 < int(W):
		var wx2 := x2 + cx * 0.5
		var ry := roundf(196.0 + sin(wx2 * 0.011) * 18.0 + sin(wx2 * 0.031 + 2.2) * 8.0 - cy * 0.5)
		draw_rect(Rect2(x2, ry, 3, H - ry + 40.0), Color("101010"))
		draw_rect(Rect2(x2, ry, 3, 1), Color("1c1c1c"))
		x2 += 3

	# 8. waveform dunes 0.65x with pale crest
	var x3 := 0
	while x3 < int(W):
		var wx3 := x3 + cx * 0.65
		var ry2 := roundf(208.0 + sin(wx3 * 0.02) * 14.0 + sin(wx3 * 0.053 + 1.7) * 6.0 - cy * 0.65)
		draw_rect(Rect2(x3, ry2, 2, H - ry2 + 40.0), Color("141414"))
		draw_rect(Rect2(x3, ry2, 2, 1), DrawUtil.GRAY if (x3 >> 1) % 2 == 0 else DrawUtil.DARK)
		x3 += 2

	# 9. GATE light pillar — breathing, visible across the zone
	var gx2 := roundf(LevelData.DATA.goal.position.x + 13.0 - cx)
	if gx2 > -20.0 and gx2 < W + 20.0:
		var breathe := 0.10 + sin(t * 1.1) * 0.04
		draw_rect(Rect2(gx2 - 8, 0, 16, H), Color(DrawUtil.WHITE, breathe))
		draw_rect(Rect2(gx2 - 4, 0, 8, H), Color(DrawUtil.WHITE, breathe + 0.06))

	# 10. foreground cables 1.15x + deepest cables 1.4x
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

	# fog band
	draw_rect(Rect2(0, 205.0 - cy, W, 30), Color(DrawUtil.GRAY, 0.08))