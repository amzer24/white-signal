extends Object
class_name DrawUtil
## 1-bit palette + bayer dither + the brick-tile platform renderer (JS port).

const BG := Color("0b0b0b")
const DARK := Color("3a3a3a")
const GRAY := Color("8a8a8a")
const WHITE := Color("f2f2f2")

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

static func bayer(x: int, y: int) -> int:
	return BAYER[((y & 3) << 2) | (x & 3)]

static func tile_platform(ci: CanvasItem, r: Rect2, secret: bool, tufts: bool) -> void:
	ci.draw_rect(r, Color("101010") if secret else DARK)
	var mortar := Color("222222") if secret else Color("232323")
	var row := 0
	var yy := r.position.y + 3.0
	while yy < r.end.y:
		ci.draw_rect(Rect2(r.position.x, yy, r.size.x, 1), mortar)
		var off := 0.0 if row % 2 == 0 else 4.0
		var xx := r.position.x + off
		while xx < r.end.x:
			ci.draw_rect(Rect2(xx, yy, 1, minf(8.0, r.end.y - yy)), mortar)
			xx += 8.0
		yy += 8.0
		row += 1
	# dither indexed by WORLD coords (no swimming while scrolling)
	var spk := Color("1a1a1a") if secret else Color("484848")
	var wy := int(r.position.y) + 4
	while wy < int(r.end.y) - 1:
		var wx := int(r.position.x) + 2
		while wx < int(r.end.x) - 1:
			if bayer(wx, wy) < 3:
				ci.draw_rect(Rect2(wx, wy, 2, 1), spk)
			wx += 4
		wy += 4
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), WHITE)
	ci.draw_rect(Rect2(r.position.x, r.position.y + 2, r.size.x, 1), GRAY)
	if tufts and not secret and r.size.y >= 12.0:
		var i := 0
		while i < int(r.size.x):
			var h := int(abs(int(r.position.x) + i) * 13 + 5) % 17
			if h < 3:
				ci.draw_rect(Rect2(r.position.x + i, r.position.y - 2, 1, 2), WHITE)
				ci.draw_rect(Rect2(r.position.x + i + 1, r.position.y - 2, 1, 1), WHITE)
			elif h > 14:
				ci.draw_rect(Rect2(r.position.x + i, r.position.y + 3, 1, 3), BG)
			i += 7
	ci.draw_rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2), BG)
	ci.draw_rect(Rect2(r.position.x + 1, r.position.y + 4, 2, 2), GRAY)
	ci.draw_rect(Rect2(r.end.x - 3, r.position.y + 4, 2, 2), GRAY)

static func fmt_time(t: float) -> String:
	var m := int(t / 60.0)
	var s := fmod(t, 60.0)
	return "%02d:%04.1f" % [m, s]