extends RefCounted
class_name Props
## Biome dressing — bespoke pixel props that stand on platform lips.
## Purely decorative: placed deterministically (world-coord hash), never within
## PROP_CLEAR px of a spike / spring / sign / beacon / goal, only on static
## ground/block platforms. Each prop is baked once into a texture; a few have a
## tiny per-frame animated overlay (lamp glow, pip blink, puddle shimmer).
##
## Palette rule (GDD §4): props are DARK bodies with GRAY detail; WHITE only for
## a single lit pixel. They must never read as a platform, hazard or pickup.

const PROP_CLEAR := 22.0
const STEP := 14  # placement probe interval along a platform lip

const BG := DrawUtil.BG
const DARK := DrawUtil.DARK
const GRAY := DrawUtil.GRAY
const WHITE := DrawUtil.WHITE
const MID := Color("262626")
const LOW := Color("1a1a1a")

var tex := {}          # name -> ImageTexture
var placed: Array = [] # {name, pos(Vector2 top-left), zone, anim}

# ============================================================== baking helpers
func _bake(texture_id: String, w: int, h: int, fn: Callable) -> void:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	fn.call(img)
	tex[texture_id] = ImageTexture.create_from_image(img)

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var rr := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if rr.size.x > 0 and rr.size.y > 0:
		img.fill_rect(rr, c)

## paint from an ASCII sprite: '.' clear, '#' DARK, '+' MID, '-' LOW, 'o' GRAY, '*' WHITE, 'b' BG
static func _art(img: Image, rows: Array) -> void:
	var map := {"#": DARK, "+": MID, "-": LOW, "o": GRAY, "*": WHITE, "b": BG}
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if map.has(ch):
				_px(img, x, y, map[ch])

# ============================================================== asset designs
func bake_all() -> void:
	# ---------------------------------------------------------- Z0 SALT FLATS
	# salt crystal cluster — pale spikes growing from a crust
	_bake("salt", 11, 8, func(img: Image) -> void:
		_art(img, [
			".....o.....",
			"....o*o....",
			"..o.o*o.o..",
			".o*.o#o.*o.",
			".o#o.#.o#o.",
			"o##o###o##o",
			"o#########o",
			"-#########-",
		]))
	# dead shrub — wire-brush twigs, one gray tip
	_bake("shrub", 12, 9, func(img: Image) -> void:
		_art(img, [
			"..o.........",
			"..#....#....",
			"#.#.#..#.#..",
			".##.#.##.#..",
			"..###.###...",
			"...#####....",
			"....###.....",
			"....##......",
			"...-##-.....",
		]))
	# marker post — a leaning survey pole with a tattered flag
	_bake("post", 6, 13, func(img: Image) -> void:
		_art(img, [
			".o....",
			".#oo..",
			".#.oo.",
			".#..o.",
			".#....",
			".#....",
			".#....",
			"..#...",
			"..#...",
			"..#...",
			"..#...",
			".-#-..",
			"-###-.",
		]))
	# half-buried dish rim — the flats are a graveyard of receivers
	_bake("rim", 16, 6, func(img: Image) -> void:
		_art(img, [
			"....oooooooo....",
			"..oo#......#oo..",
			".o#..........#o.",
			"o#............#o",
			"#..............#",
			"-..............-",
		]))
	# pebbles / crust cracks
	_bake("pebbles", 12, 3, func(img: Image) -> void:
		_art(img, [
			".o...oo....o",
			"o#o.o##o..o#",
			"###.####.-##",
		]))
	# signal stone — a small standing slab with a carved glyph
	_bake("stone", 8, 9, func(img: Image) -> void:
		_art(img, [
			"..####..",
			".##oo##.",
			".#o##o#.",
			".#o##o#.",
			".##oo##.",
			".######.",
			".##..##.",
			"-######-",
			"-######-",
		]))

	# ---------------------------------------------------------- Z1 RELAY RUINS
	# rubble heap — brick chunks with mortar
	_bake("rubble", 16, 6, func(img: Image) -> void:
		_art(img, [
			".....##.........",
			"..##.##o..##....",
			".##o###o.##o.##.",
			"###o##.o####o##o",
			"##-####-###-###o",
			"################",
		]))
	# broken pipe — bent stub with a drip (animated)
	_bake("pipe", 9, 11, func(img: Image) -> void:
		_art(img, [
			"...oo....",
			"..o##o...",
			"..o##o...",
			"..o##oo..",
			"..o###o..",
			"..o###o..",
			"..o##o...",
			"..o##o...",
			".oo##oo..",
			".o####o..",
			"-######-.",
		]))
	# cable coil — a spool of dead line
	_bake("coil", 11, 7, func(img: Image) -> void:
		_art(img, [
			"...ooooo...",
			".oo#####oo.",
			"o##o###o##o",
			"o#o#####o#o",
			"o##o###o##o",
			".oo#####oo.",
			"-#########-",
		]))
	# column stub — the base of a snapped pillar
	_bake("stub", 9, 8, func(img: Image) -> void:
		_art(img, [
			"..#o..#..",
			".##o.###.",
			".##o####.",
			".##o####.",
			".##o####.",
			"o##o####o",
			"#########",
			"-#######-",
		]))
	# hazard sign — tilted plate on a post, X glyph
	_bake("sign", 8, 12, func(img: Image) -> void:
		_art(img, [
			".oooooo.",
			"o*....*o",
			"o.*..*.o",
			"o..**..o",
			"o..**..o",
			"o.*..*.o",
			"o*....*o",
			".oooooo.",
			"...#....",
			"...#....",
			"...#....",
			"..-#-...",
		]))
	# puddle — static water, shimmer animated on top
	_bake("puddle", 18, 2, func(img: Image) -> void:
		_art(img, [
			"..--++++++++--....",
			".--++++++++++--...",
		]))
	# fallen girder — a bent beam across the floor
	_bake("beam", 20, 5, func(img: Image) -> void:
		_art(img, [
			"...............oooo.",
			"........oooooo#####.",
			"..ooooo#######+++#..",
			"oo#####++++###.....",
			"###++++........-....",
		]))

	# ---------------------------------------------------------- Z2 GATE APPROACH
	# conduit box — transformer with a status pip (animated)
	_bake("conduit", 11, 10, func(img: Image) -> void:
		_art(img, [
			"...o...o...",
			"ooooooooooo",
			"o#########o",
			"o#+++++++#o",
			"o#+#####+#o",
			"o#+#####+#o",
			"o#+++++++#o",
			"o#########o",
			"ooooooooooo",
			"-#.......#-",
		]))
	# cable bundle — thick lines clamped to the floor
	_bake("bundle", 18, 4, func(img: Image) -> void:
		_art(img, [
			"..o......o......o.",
			"ooooooooooooooooo.",
			"#+#+#+#+#+#+#+#+#+",
			"##################",
		]))
	# lamp post — lit head, glow animated
	_bake("lamp", 7, 17, func(img: Image) -> void:
		_art(img, [
			".ooooo.",
			"o#***#o",
			"o#***#o",
			".o###o.",
			"..o#o..",
			"...#...",
			"...#...",
			"...#...",
			"...#...",
			"...#...",
			"...#...",
			"...#...",
			"...#...",
			"...#...",
			"..o#o..",
			".o###o.",
			"-#####-",
		]))
	# floor grate
	_bake("grate", 14, 3, func(img: Image) -> void:
		_art(img, [
			"oooooooooooooo",
			"o-o-o-o-o-o-oo",
			"oooooooooooooo",
		]))
	# gate crystal shard — a splinter of the transmitter, lit tip
	_bake("shard", 7, 13, func(img: Image) -> void:
		_art(img, [
			"...*...",
			"...o...",
			"..oo#..",
			"..o##..",
			".oo###.",
			".o####.",
			".o####.",
			"oo#####",
			"o######",
			"o######",
			"o######",
			"-#####-",
			"-#####-",
		]))
	# warning stripes — painted on the lip at edges of Z2 platforms
	_bake("stripes", 16, 2, func(img: Image) -> void:
		_art(img, [
			"oo##oo##oo##oo##",
			"#oo##oo##oo##oo#",
		]))
	# antenna stub — small dead whip antenna with a base box
	_bake("whip", 6, 14, func(img: Image) -> void:
		_art(img, [
			"...o..",
			"...#..",
			"...#..",
			"..#...",
			"..#...",
			"..#...",
			"..#...",
			"..#...",
			"..#...",
			"..#...",
			".o#o..",
			"o####o",
			"o#++#o",
			"-####-",
		]))

# prop_choices per zone: [name, weight]. Heavier = more common.
const ZONE_SETS := [
	[["salt", 4], ["shrub", 3], ["post", 1], ["rim", 1], ["pebbles", 4], ["stone", 1]],
	[["rubble", 4], ["pipe", 2], ["coil", 2], ["stub", 2], ["sign", 1], ["puddle", 3], ["beam", 1]],
	[["conduit", 2], ["bundle", 3], ["lamp", 1], ["grate", 3], ["shard", 1], ["stripes", 2], ["whip", 2]],
]
const ZONE_DENSITY := [16, 26, 24]  # % chance per probe

# ============================================================== placement
func place_all() -> void:
	placed.clear()
	var L := RunState.level
	# keep-out x-ranges [x0, x1] (props live on lips, so x is what matters)
	var avoid: Array = []
	for s in L.spikes:
		avoid.append([s.r.position.x, s.r.end.x])
	for s in L.springs:
		avoid.append([s.r.position.x, s.r.end.x])
	for s in L.signs:
		avoid.append([s.pos.x - 6.0, s.pos.x + 6.0])
	for c in L.checkpoints:
		avoid.append([c.pos.x - 6.0, c.pos.x + 14.0])
	for fixture_data in L.get("fixtures", []):
		avoid.append([fixture_data.pos.x - 24.0, fixture_data.pos.x + 24.0])
	avoid.append([L.goal.position.x - 10.0, L.goal.end.x + 10.0])
	avoid.append([L.spawn.x - 10.0, L.spawn.x + 10.0])

	for p in L.platforms:
		if p.type == "secret":
			continue
		var r: Rect2 = p.r
		if r.size.x < 36.0:
			continue
		var zone := int(L.get("biome", RunState.zone_of(r.position.x)))
		var prop_choices: Array = ZONE_SETS[zone]
		var total := 0
		for e in prop_choices:
			total += int(e[1])
		var x := int(r.position.x) + 8
		var last_x := -999
		while x < int(r.end.x) - 8:
			var h := DrawUtil.hash2(x, int(r.position.y))
			if h % 100 < ZONE_DENSITY[zone] and x - last_x >= STEP:
				var ok := true
				for rg in avoid:
					if float(x) + 20.0 > float(rg[0]) - PROP_CLEAR and float(x) < float(rg[1]) + PROP_CLEAR:
						ok = false
						break
				if ok:
					# stripes only near platform edges; everything else anywhere
					var pick := (h >> 8) % total
					var name := ""
					for e in prop_choices:
						pick -= int(e[1])
						if pick < 0:
							name = e[0]
							break
					if name == "stripes" and x > int(r.position.x) + 24 and x < int(r.end.x) - 40:
						name = "grate"
					var t: Texture2D = tex[name]
					if x + t.get_width() <= int(r.end.x) - 2:
						placed.append({
							"name": name,
							"pos": Vector2(x, r.position.y - t.get_height() + 1),
							"zone": zone,
							"seed": h,
						})
						last_x = x
			x += STEP

# ============================================================== drawing
func draw(ci: CanvasItem, t: float, cam_tl: Vector2) -> void:
	for p in placed:
		var pos: Vector2 = p.pos
		if pos.x < cam_tl.x - 24.0 or pos.x > cam_tl.x + 500.0:
			continue
		var tx: Texture2D = tex[p.name]
		ci.draw_texture(tx, pos)
		var ph := float(p.seed % 13)
		match p.name:
			"lamp":
				# breathing glow cone below the head
				var a := 0.05 + 0.03 * sin(t * 2.0 + ph)
				ci.draw_colored_polygon(PackedVector2Array([
					Vector2(pos.x + 1, pos.y + 3), Vector2(pos.x + 6, pos.y + 3),
					Vector2(pos.x + 13, pos.y + 17), Vector2(pos.x - 6, pos.y + 17),
				]), Color(WHITE, a))
				ci.draw_rect(Rect2(pos.x - 4, pos.y + 16, 15, 1), Color(WHITE, a * 1.5))
			"conduit":
				var on := int(t * 1.5 + ph) % 4 == 0
				ci.draw_rect(Rect2(pos.x + 3, pos.y, 1, 1), WHITE if on else LOW)
				ci.draw_rect(Rect2(pos.x + 7, pos.y, 1, 1), LOW if on else GRAY)
			"pipe":
				# drip: falls from the pipe mouth over ~1.2s, per-prop phase
				var d := fmod(t * 0.8 + ph * 0.3, 1.0)
				if d < 0.7:
					ci.draw_rect(Rect2(pos.x + 4, pos.y + 5 + d * 10.0, 1, 1), GRAY)
			"puddle":
				# shimmer: a gray pixel sliding along the surface
				var sx := int(fmod(t * 9.0 + ph * 3.0, 14.0))
				ci.draw_rect(Rect2(pos.x + 2 + sx, pos.y, 2, 1), Color(GRAY, 0.6))
			"shard":
				var a := 0.4 + 0.4 * absf(sin(t * 1.7 + ph))
				ci.draw_rect(Rect2(pos.x + 3, pos.y, 1, 1), Color(WHITE, a))
				ci.draw_rect(Rect2(pos.x + 2, pos.y - 1, 3, 1), Color(WHITE, a * 0.3))
			"whip":
				# sway: the whip tip flicks a pixel in the wind
				var sway := int(sin(t * 3.0 + ph) * 1.5)
				ci.draw_rect(Rect2(pos.x + 3 + sway, pos.y, 1, 2), GRAY)
			"salt":
				# rare sparkle
				if int(t * 6.0 + ph) % 23 == 0:
					ci.draw_rect(Rect2(pos.x + 5, pos.y, 1, 1), WHITE)
