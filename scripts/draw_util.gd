extends Object
class_name DrawUtil
## 1-bit palette + bayer dither + tile renderer + 3x5 pixel font (all draw_rect).

const BG := Color("0b0b0b")
const DARK := Color("3a3a3a")
const GRAY := Color("8a8a8a")
const WHITE := Color("f2f2f2")
const MORTAR := Color("232323")
const EDGE := Color("484848")

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

static func bayer(x: int, y: int) -> int:
	return BAYER[((y & 3) << 2) | (x & 3)]

## deterministic per-world-coord noise (no swimming while scrolling)
static func hash2(x: int, y: int) -> int:
	var h := x * 374761393 + y * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7fffffff

# ---------------------------------------------------------------- pixel font
## 3x5 glyphs, 1px advance gap. Uppercase only (text is upper-cased on draw).
const GLYPH_W := 3
const GLYPH_H := 5
const FONT := {
	"A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"],
	"C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"],
	"E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
	"G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"],
	"I": ["111", "010", "010", "010", "111"], "J": ["001", "001", "001", "101", "010"],
	"K": ["101", "101", "110", "101", "101"], "L": ["100", "100", "100", "100", "111"],
	"M": ["101", "111", "101", "101", "101"], "N": ["110", "101", "101", "101", "101"],
	"O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"],
	"Q": ["010", "101", "101", "110", "011"], "R": ["110", "101", "110", "101", "101"],
	"S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"],
	"U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"],
	"W": ["101", "101", "101", "111", "101"], "X": ["101", "101", "010", "101", "101"],
	"Y": ["101", "101", "010", "010", "010"], "Z": ["111", "001", "010", "100", "111"],
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["110", "001", "010", "100", "111"], "3": ["111", "001", "011", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	".": ["000", "000", "000", "000", "010"], ":": ["000", "010", "000", "010", "000"],
	"/": ["001", "001", "010", "100", "100"], "-": ["000", "000", "111", "000", "000"],
	"+": ["000", "010", "111", "010", "000"], "=": ["000", "111", "000", "111", "000"],
	"?": ["111", "001", "011", "000", "010"], "!": ["010", "010", "010", "000", "010"],
	"[": ["110", "100", "100", "100", "110"], "]": ["011", "001", "001", "001", "011"],
	"(": ["010", "100", "100", "100", "010"], ")": ["010", "001", "001", "001", "010"],
	",": ["000", "000", "000", "010", "100"], "'": ["010", "010", "000", "000", "000"],
	">": ["100", "010", "001", "010", "100"], "<": ["001", "010", "100", "010", "001"],
	"^": ["010", "101", "000", "000", "000"], "~": ["000", "011", "110", "000", "000"],
	"%": ["101", "001", "010", "100", "101"], "_": ["000", "000", "000", "000", "111"],
	"*": ["010", "111", "010", "000", "000"], "#": ["010", "111", "111", "111", "010"],
	"@": ["010", "111", "010", "111", "010"], "|": ["010", "010", "010", "010", "010"],
	"\"": ["101", "101", "000", "000", "000"],
	" ": ["000", "000", "000", "000", "000"],
}

static func text_width(s: String, scale := 1) -> int:
	return maxi(0, s.length() * (GLYPH_W + 1) - 1) * scale

## Draws pixel text. `pos` = top-left (align LEFT), top-center (CENTER) or top-right (RIGHT).
static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color, scale := 1,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	s = s.to_upper()
	var w := text_width(s, scale)
	var x := int(roundf(pos.x))
	var y := int(roundf(pos.y))
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= int(w / 2.0)
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= w
	for ch in s:
		var g: Array = FONT.get(ch, FONT["?"])
		for row in GLYPH_H:
			var bits: String = g[row]
			var c := 0
			while c < GLYPH_W:
				if bits[c] == "1":
					var run := 1
					while c + run < GLYPH_W and bits[c + run] == "1":
						run += 1
					ci.draw_rect(Rect2(x + c * scale, y + row * scale, run * scale, scale), col)
					c += run
				else:
					c += 1
		x += (GLYPH_W + 1) * scale

## Shadowed text: BG drop shadow +1,+1 then the text.
static func text_shadow(ci: CanvasItem, pos: Vector2, s: String, col: Color, scale := 1,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	text(ci, pos + Vector2(scale, scale), s, BG, scale, align)
	text(ci, pos, s, col, scale, align)

## SHARD glyph (◆): 5x5 diamond, optionally hollow.
static func diamond(ci: CanvasItem, pos: Vector2, col: Color, hollow := false) -> void:
	var x := pos.x
	var y := pos.y
	ci.draw_rect(Rect2(x + 2, y, 1, 1), col)
	ci.draw_rect(Rect2(x + 1, y + 1, 3, 1), col)
	ci.draw_rect(Rect2(x, y + 2, 5, 1), col)
	ci.draw_rect(Rect2(x + 1, y + 3, 3, 1), col)
	ci.draw_rect(Rect2(x + 2, y + 4, 1, 1), col)
	if hollow:
		ci.draw_rect(Rect2(x + 2, y + 1, 1, 3), BG)
		ci.draw_rect(Rect2(x + 1, y + 2, 3, 1), BG)

# ---------------------------------------------------------------- tiles
## Tiles are BAKED once into an ImageTexture (per-pixel dither is far too slow to
## redraw every frame in GDScript). All coordinates fed to bayer()/hash2() are
## WORLD coords so patterns never swim. Baked image has a 2px top margin for tufts.
const TILE_MARGIN := 2

## Bakes a texture for platform rect `r`; draw it at r.position - (0, TILE_MARGIN).
## Callers cache the result (see entity_render.gd) — no static state here so
## nothing outlives the scene.
static func platform_texture(r: Rect2, type: String) -> ImageTexture:
	var img := Image.create(int(r.size.x), int(r.size.y) + TILE_MARGIN, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var p := TilePainter.new(img, int(r.position.x), int(r.position.y) - TILE_MARGIN)
	match type:
		"secret": _tile_secret(p, r)
		"girder": _tile_girder(p, r)
		"block", "pad": _tile_block(p, r)
		_:
			if r.size.y <= 12.0:
				_tile_girder(p, r)
			else:
				_tile_ground(p, r)
	return ImageTexture.create_from_image(img)

## Draw helper (world-coord rect → image-local fill).
class TilePainter:
	var img: Image
	var ox: int
	var oy: int
	func _init(i: Image, x: int, y: int) -> void:
		img = i
		ox = x
		oy = y
	func rect(x: float, y: float, w: float, h: float, col: Color) -> void:
		var rr := Rect2i(int(x) - ox, int(y) - oy, int(w), int(h)).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
		if rr.size.x > 0 and rr.size.y > 0:
			img.fill_rect(rr, col)

## GROUND — earthy slab: brick courses with worn/missing bricks, dither darkening
## toward the bottom, grass tufts, bright top lip, edge bevels.
static func _tile_ground(p: TilePainter, r: Rect2) -> void:
	var x0 := int(r.position.x)
	var y0 := int(r.position.y)
	var x1 := int(r.end.x)
	var y1 := int(r.end.y)
	p.rect(x0, y0, r.size.x, r.size.y, DARK)
	# brick courses (8x8, staggered) with per-brick wear
	var row := 0
	var yy := y0 + 3
	while yy < y1:
		var bh := mini(8, y1 - yy)
		p.rect(x0, yy, r.size.x, 1, MORTAR)
		var off := 0 if row % 2 == 0 else 4
		var xx := x0 + off
		while xx < x1:
			p.rect(xx, yy, 1, bh, MORTAR)
			var h := hash2(xx, yy)
			var bw := mini(8, x1 - xx)
			if h % 17 == 0 and bw >= 6 and bh >= 6:
				# missing brick → dark cavity with a lit lip
				p.rect(xx + 1, yy + 1, bw - 2, bh - 2, Color("1a1a1a"))
				p.rect(xx + 1, yy + 1, bw - 2, 1, Color("111111"))
			elif h % 7 == 0 and bw >= 4:
				# crack
				p.rect(xx + 2 + (h >> 4) % 3, yy + 2, 1, bh - 3, MORTAR)
			xx += 8
		yy += 8
		row += 1
	# depth: bayer-dither toward BG, denser toward the bottom (world-indexed)
	var depth := y1 - y0
	var wy := y0 + 6
	while wy < y1 - 2:
		var f := float(wy - y0) / float(depth)  # 0 top → 1 bottom
		var thr := int(f * 5.0)  # 0..4 of 16 → sparse, darkens toward the base
		var wx := x0 + 1
		while wx < x1 - 1:
			if bayer(wx, wy) < thr:
				p.rect(wx, wy, 1, 1, Color("222222"))
			wx += 1
		wy += 1
	# sparse bright specks on the upper half
	wy = y0 + 4
	while wy < y0 + int(depth / 2.0):
		var wx := x0 + 2
		while wx < x1 - 1:
			if hash2(wx, wy) % 23 == 0:
				p.rect(wx, wy, 2, 1, EDGE)
			wx += 3
		wy += 3
	# top lip + edges
	p.rect(x0, y0, r.size.x, 2, WHITE)
	p.rect(x0, y0 + 2, r.size.x, 1, GRAY)
	p.rect(x0, y0 + 3, 1, depth - 5, EDGE)
	p.rect(x1 - 1, y0 + 3, 1, depth - 5, Color("2a2a2a"))
	p.rect(x0, y1 - 2, r.size.x, 2, BG)
	# grass tufts / cracks along the lip
	var i := 0
	while i < int(r.size.x):
		var h: int = (absi(x0 + i) * 13 + 5) % 17
		if h < 3:
			p.rect(x0 + i, y0 - 2, 1, 2, WHITE)
			p.rect(x0 + i + 1, y0 - 2, 1, 1, WHITE)
		elif h == 9:
			p.rect(x0 + i, y0 - 1, 1, 1, GRAY)
		elif h > 14:
			p.rect(x0 + i, y0 + 3, 1, 3, BG)
		i += 7

## BLOCK — relay panelling: 16px panels, rivets at seams, vent slits, a rare
## status pip (dead-transmitter tech, not masonry).
static func _tile_block(p: TilePainter, r: Rect2) -> void:
	var x0 := int(r.position.x)
	var y0 := int(r.position.y)
	var x1 := int(r.end.x)
	var y1 := int(r.end.y)
	p.rect(x0, y0, r.size.x, r.size.y, DARK)
	# subtle field dither
	var wy := y0 + 3
	while wy < y1 - 2:
		var wx := x0 + 1
		while wx < x1 - 1:
			if bayer(wx, wy) < 2:
				p.rect(wx, wy, 1, 1, Color("303030"))
			wx += 1
		wy += 1
	# panel seams
	var px := x0
	while px < x1:
		if px > x0:
			p.rect(px, y0 + 3, 1, y1 - y0 - 5, MORTAR)
		var py := y0 + 3
		while py < y1 - 2:
			if py > y0 + 3:
				p.rect(x0, py, r.size.x, 1, MORTAR)
			var rx := px + 2 if px > x0 else x0 + 2
			p.rect(rx, py + 2, 1, 1, GRAY)
			var pw := mini(16, x1 - px)
			var ph := mini(16, y1 - 2 - py)
			if pw >= 12 and ph >= 10:
				var h := hash2(px, py)
				if h % 5 == 0:
					for k in 3:  # vent slits
						p.rect(px + 4, py + 4 + k * 2, pw - 8, 1, Color("1a1a1a"))
				elif h % 13 == 0:
					p.rect(px + pw - 5, py + 3, 2, 2, WHITE if h % 3 == 0 else Color("222222"))
			py += 16
		px += 16
	# top lip (thinner than ground: it's a shelf, not soil)
	p.rect(x0, y0, r.size.x, 1, WHITE)
	p.rect(x0, y0 + 1, r.size.x, 1, GRAY)
	p.rect(x0, y0 + 2, r.size.x, 1, EDGE)
	p.rect(x0, y0 + 3, 1, y1 - y0 - 5, EDGE)
	p.rect(x1 - 1, y0 + 3, 1, y1 - y0 - 5, Color("2a2a2a"))
	p.rect(x0, y1 - 2, r.size.x, 2, BG)
	# corner rivets
	p.rect(x0 + 1, y0 + 4, 2, 2, GRAY)
	p.rect(x1 - 3, y0 + 4, 2, 2, GRAY)

## GIRDER — thin ledge: rails + cross-hatch braces + end caps.
static func _tile_girder(p: TilePainter, r: Rect2) -> void:
	var x0 := int(r.position.x)
	var y0 := int(r.position.y)
	var x1 := int(r.end.x)
	var y1 := int(r.end.y)
	p.rect(x0, y0, r.size.x, r.size.y, DARK)
	if y1 - y0 - 3 >= 4:
		var wx := x0 + 1
		while wx < x1 - 1:
			var wy := y0 + 2
			while wy < y1 - 1:
				if ((wx + wy) & 3) == 0 or ((wx - wy) & 3) == 0:
					p.rect(wx, wy, 1, 1, MORTAR)
				wy += 1
			wx += 1
	p.rect(x0, y0, r.size.x, 1, WHITE)
	p.rect(x0, y0 + 1, r.size.x, 1, GRAY)
	p.rect(x0, y1 - 1, r.size.x, 1, BG)
	p.rect(x0, y1 - 2, r.size.x, 1, EDGE)
	p.rect(x0, y0, 2, r.size.y - 1, GRAY)
	p.rect(x1 - 2, y0, 2, r.size.y - 1, GRAY)

## SECRET — hidden route: near-black with a faint lip.
static func _tile_secret(p: TilePainter, r: Rect2) -> void:
	p.rect(r.position.x, r.position.y, r.size.x, r.size.y, Color("101010"))
	var wy := int(r.position.y) + 2
	while wy < int(r.end.y) - 1:
		var wx := int(r.position.x) + 1
		while wx < int(r.end.x) - 1:
			if bayer(wx, wy) < 2:
				p.rect(wx, wy, 1, 1, Color("1a1a1a"))
			wx += 1
		wy += 1
	p.rect(r.position.x, r.position.y, r.size.x, 1, Color("2a2a2a"))
	p.rect(r.position.x, r.end.y - 1, r.size.x, 1, BG)

static func fmt_time(t: float) -> String:
	var m := int(t / 60.0)
	var s := fmod(t, 60.0)
	return "%02d:%04.1f" % [m, s]
