extends Object
class_name LevelData
## Port of level.js — pure data, verbatim coordinates (y identical: y-down both).

const DATA := {
	"name": "GEOMETRY FLATS v2",
	"width": 3800,
	"height": 270,
	"spawn": Vector2(36, 187),
	"kill_y": 300.0,
	"goal": Rect2(3700, 150, 26, 80),
	"zones": [
		{"x0": 0, "x1": 1150, "name": "Z0 . FLATS", "sub": "learn to move"},
		{"x0": 1150, "x1": 2420, "name": "Z1 . RUINS", "sub": "crumble + spring"},
		{"x0": 2420, "x1": 3800, "name": "Z2 . GATE", "sub": "climb + sprint"},
	],
	"platforms": [
		{"r": Rect2(0, 230, 380, 40), "type": "ground"},
		{"r": Rect2(410, 230, 220, 40), "type": "ground"},
		{"r": Rect2(660, 230, 200, 40), "type": "ground"},
		{"r": Rect2(800, 186, 16, 44), "type": "block"},
		{"r": Rect2(880, 210, 50, 60), "type": "block"},
		{"r": Rect2(930, 190, 50, 80), "type": "block"},
		{"r": Rect2(980, 170, 50, 100), "type": "block"},
		{"r": Rect2(1030, 170, 140, 20), "type": "block"},
		{"r": Rect2(1210, 230, 260, 40), "type": "ground"},
		{"r": Rect2(1760, 230, 120, 40), "type": "ground"},
		{"r": Rect2(1940, 230, 120, 40), "type": "ground"},
		{"r": Rect2(1990, 150, 110, 12), "type": "block"},
		{"r": Rect2(2060, 230, 380, 40), "type": "ground"},
		{"r": Rect2(2100, 170, 160, 12), "type": "block"},
		{"r": Rect2(2440, 230, 200, 40), "type": "ground"},
		{"r": Rect2(2436, 120, 16, 80), "type": "block"},
		{"r": Rect2(2548, 120, 16, 110), "type": "block"},
		{"r": Rect2(2520, 75, 140, 20), "type": "block"},
		{"r": Rect2(2700, 230, 300, 40), "type": "ground"},
		{"r": Rect2(3040, 230, 760, 40), "type": "ground"},
		{"r": Rect2(3220, 190, 80, 12), "type": "block"},
		{"r": Rect2(3340, 190, 80, 12), "type": "block"},
		{"r": Rect2(1882, 254, 56, 10), "type": "secret"},
		{"r": Rect2(2060, 92, 48, 12), "type": "block"},
		{"r": Rect2(2140, 92, 48, 12), "type": "block"},
		{"r": Rect2(2220, 92, 48, 12), "type": "block"},
		{"r": Rect2(2380, 100, 96, 12), "type": "secret"},
	],
	"crumbles": [
		{"r": Rect2(1500, 205, 70, 12)},
		{"r": Rect2(1580, 205, 70, 12)},
		{"r": Rect2(1660, 205, 70, 12)},
		{"r": Rect2(2740, 195, 60, 10)},
		{"r": Rect2(2810, 195, 60, 10)},
		{"r": Rect2(2880, 195, 60, 10)},
	],
	"springs": [
		{"r": Rect2(1946, 212, 24, 18), "power": 540.0},
		{"r": Rect2(3118, 212, 24, 18), "power": 500.0},
	],
	"movers": [
		{"r": Rect2(1210, 170, 60, 10), "axis": "x", "range": 30.0, "speed": 1.2, "phase": 0.0},
		{"r": Rect2(2640, 190, 60, 10), "axis": "y", "range": 45.0, "speed": 1.3, "phase": 1.0},  # spans the 2640-2700 gap exactly
	],
	"spikes": [
		{"r": Rect2(1380, 218, 48, 12)},
		{"r": Rect2(2180, 218, 60, 12)},
		{"r": Rect2(3180, 218, 48, 12)},
		{"r": Rect2(3480, 218, 72, 12)},
	],
	"gems": [
		Vector2(450, 190), Vector2(700, 190), Vector2(808, 150), Vector2(1080, 130),
		Vector2(1615, 165), Vector2(1892, 238), Vector2(1912, 238),
		Vector2(1960, 175), Vector2(1990, 130), Vector2(2040, 110),
		Vector2(2180, 140), Vector2(2220, 140),
		Vector2(2500, 170), Vector2(2590, 40),
		Vector2(2770, 155), Vector2(2840, 155), Vector2(2910, 155),
		Vector2(3120, 150), Vector2(3100, 175), Vector2(3140, 175),
		Vector2(3260, 150), Vector2(3380, 150),
		Vector2(2180, 72), Vector2(2420, 80),
	],
	"enemies": [
		{"r": Rect2(1820, 212, 14, 18), "min_x": 1780.0, "max_x": 1866.0, "speed": 50.0},
		{"r": Rect2(2120, 212, 14, 18), "min_x": 2070.0, "max_x": 2360.0, "speed": 70.0},
		{"r": Rect2(3100, 212, 14, 18), "min_x": 3060.0, "max_x": 3300.0, "speed": 85.0},
		{"r": Rect2(3500, 212, 14, 18), "min_x": 3420.0, "max_x": 3660.0, "speed": 100.0},
	],
	"checkpoints": [
		{"pos": Vector2(880, 210)},
		{"pos": Vector2(1760, 230)},
		{"pos": Vector2(2460, 230)},
		{"pos": Vector2(3040, 230)},
	],
	"signs": [
		{"pos": Vector2(80, 208), "text": "ARROWS MOVE"},
		{"pos": Vector2(450, 208), "text": "HOLD JUMP = HIGHER"},
		{"pos": Vector2(730, 208), "text": "WALL: HOLD IN + JUMP"},
		{"pos": Vector2(1240, 208), "text": "CRUMBLE! KEEP MOVING"},
		{"pos": Vector2(1855, 208), "text": "SPRING UP: HOLD RIGHT"},
		{"pos": Vector2(2030, 208), "text": "HIGH LINE UP TOP"},
		{"pos": Vector2(2500, 208), "text": "HOLD WALL + JUMP . SWAP SIDES"},
		{"pos": Vector2(3060, 208), "text": "SPRING!"},
	],
	"deco": [
		{"pos": Vector2(200, 60), "s": 40.0}, {"pos": Vector2(700, 40), "s": 70.0},
		{"pos": Vector2(1200, 80), "s": 30.0}, {"pos": Vector2(1600, 50), "s": 90.0},
		{"pos": Vector2(2100, 60), "s": 50.0}, {"pos": Vector2(2600, 40), "s": 80.0},
		{"pos": Vector2(3100, 50), "s": 60.0}, {"pos": Vector2(3550, 60), "s": 46.0},
	],
}

const RELEASED_RELAYS := 3

static func get_level(index: int) -> Dictionary:
	if index == 1:
		return listening_field()
	if index == 2:
		return the_stand()
	var tutorial := DATA.duplicate(true)
	tutorial.name = "THE FLATS LINE"
	tutorial["objective"] = "REACH THE TRANSMITTER"
	tutorial["fixtures"] = []
	return tutorial

static func blank_level(title: String, width: int, biome: int) -> Dictionary:
	return {"name": title, "width": width, "height": 270,
		"spawn": Vector2(48, 223), "kill_y": 310.0,
		"goal": Rect2(width - 80, 150, 26, 80), "biome": biome,
		"platforms": [], "crumbles": [], "springs": [], "movers": [],
		"spikes": [], "gems": [], "enemies": [], "checkpoints": [],
		"signs": [], "deco": [], "fixtures": [],
		"zones": [{"x0": 0, "x1": width / 3, "name": "RELAY", "sub": "CARRY THE SPARK"},
			{"x0": width / 3, "x1": width * 2 / 3, "name": "RELAY", "sub": "CARRY THE SPARK"},
			{"x0": width * 2 / 3, "x1": width, "name": "RELAY", "sub": "CARRY THE SPARK"}]}

static func platform(l: Dictionary, r: Rect2, kind: String = "block") -> void:
	l.platforms.append({"r": r, "type": kind})

static func sign_at(l: Dictionary, x: float, y: float, words: String) -> void:
	l.signs.append({"pos": Vector2(x, y), "text": words})

static func fixture(l: Dictionary, kind: String, x: float, y: float, id: String = "", dest: Vector2 = Vector2.ZERO) -> void:
	l.fixtures.append({"kind": kind, "pos": Vector2(x, y), "id": id, "destination": dest})

static func listening_field() -> Dictionary:
	var l := blank_level("THE LISTENING FIELD", 3840, 0)
	l["objective"] = "WAKE THREE EARS"
	l["required_ears"] = 3
	l.spawn = Vector2(48, 223)
	l.goal = Rect2(414, 150, 26, 80)
	# Three maintenance conduits lead from the visible hub into short spokes.
	platform(l, Rect2(0, 230, 480, 40), "ground")
	platform(l, Rect2(476, -80, 24, 310))
	l.checkpoints.append({"pos": Vector2(64, 230)})
	sign_at(l, 68, 170, "WAKE THREE EARS")
	sign_at(l, 128, 199, "DOWN ENTERS")
	for i in 3:
		var start := 600.0 + i * 900.0
		var hub := 150.0 + i * 90.0
		fixture(l, "conduit", hub, 230, ["RISE", "CROSS", "SEARCH"][i], Vector2(start + 45, 223))
		fixture(l, "conduit", start + 45, 230, "HUB", Vector2(hub, 223))
		fixture(l, "conduit", start + 660, 230, "HUB", Vector2(hub, 223))
		platform(l, Rect2(start, 230, 720, 40), "ground")
		# Separate rooms cannot be bypassed by jumping between spokes.
		platform(l, Rect2(start - 24, -80, 24, 350))
		platform(l, Rect2(start + 720, -80, 24, 350))
		l.checkpoints.append({"pos": Vector2(start + 84, 230)})
		for x in [150, 220, 350, 470, 600]:
			var gem_y := 192.0
			if i == 0 and x == 350: gem_y = 128.0
			if i == 0 and x == 470: gem_y = 92.0
			if i == 1 and x == 350: gem_y = 152.0
			l.gems.append(Vector2(start + x, gem_y))
		fixture(l, "memory", start + 150, 179)
		if i == 0:
			sign_at(l, start + 100, 208, "HIT FROM BELOW")
			# 36px steps allow an unmodified Spark to reach the high EAR.
			platform(l, Rect2(start + 260, 194, 68, 36))
			platform(l, Rect2(start + 340, 158, 68, 72))
			platform(l, Rect2(start + 420, 122, 110, 108))
			fixture(l, "ear", start + 465, 122, "NORTH")
			l.gems.append(Vector2(start + 450, 91))
		elif i == 1:
			sign_at(l, start + 110, 208, "KEEP YOUR RHYTHM")
			for x in [240, 320, 400]:
				l.crumbles.append({"r": Rect2(start + x, 184, 60, 12)})
			l.spikes.append({"r": Rect2(start + 320, 218, 40, 12)})
			fixture(l, "ear", start + 570, 230, "EAST")
			l.enemies.append({"r": Rect2(start + 475, 212, 14, 18), "min_x": start + 450, "max_x": start + 530, "speed": 45.0})
		else:
			sign_at(l, start + 100, 208, "MEMORY HAS WEIGHT")
			for x in [270, 290, 310]:
				fixture(l, "brick", start + x, 180)
			fixture(l, "ear", start + 590, 230, "SOUTH")
			# Optional archive has a matching conduit back; no glyph can strand you.
			fixture(l, "conduit", start + 420, 230, "ARCHIVE", Vector2(3430, 223))
	platform(l, Rect2(3370, 230, 400, 40), "ground")
	fixture(l, "conduit", 3430, 230, "RETURN", Vector2(2820, 223))
	sign_at(l, 3470, 160, "STILL LISTENING")
	for x in [3500, 3530, 3560]:
		fixture(l, "memory", x, 179)
	# An empty chair and an unused receiver: no text explaining the loss.
	platform(l, Rect2(3640, 214, 18, 16))
	return l

static func the_stand() -> Dictionary:
	var l := blank_level("THE STAND", 3000, 1)
	l["objective"] = "CROSS THE FALLEN DISH"
	l["rain_pressure"] = true
	for r in [Rect2(0,230,380,40), Rect2(660,230,440,40), Rect2(1360,230,400,40),
			Rect2(2050,230,390,40), Rect2(2650,230,350,40)]:
		platform(l, r, "ground")
	for x in [390, 480, 570, 1110, 1200, 1290, 1770, 1860, 1950, 2450, 2540]:
		l.crumbles.append({"r": Rect2(x, 230, 80, 12)})
	for x in [80, 700, 1400, 2100, 2700]:
		l.checkpoints.append({"pos": Vector2(x, 230)})
	for x in [280, 780, 1520, 2220]:
		fixture(l, "memory", x, 179)
	for x in [880, 900, 920]:
		fixture(l, "brick", x, 180)
	# The collapsed rim: ascend its broken braces; the higher route is optional.
	platform(l, Rect2(1450, 194, 60, 36))
	platform(l, Rect2(1530, 158, 60, 72))
	platform(l, Rect2(1610, 122, 100, 12))
	l.springs.append({"r": Rect2(1640, 212, 24, 18), "power": 500.0})
	for x in [720, 1430, 2120, 2730]:
		l.enemies.append({"r": Rect2(x + 30, 212, 14, 18), "min_x": float(x), "max_x": float(x + 130), "speed": 55.0})
	for x in [1010, 2310]:
		l.spikes.append({"r": Rect2(x, 218, 40, 12)})
	for x in [170, 310, 430, 610, 760, 940, 1050, 1160, 1320, 1470, 1690, 1810, 1990, 2190, 2380, 2500, 2610, 2810]:
		l.gems.append(Vector2(x, 182))
	l.gems.append(Vector2(1660, 88))
	sign_at(l, 100, 195, "RAIN EATS STONE")
	sign_at(l, 700, 190, "BEACONS CALM RAIN")
	sign_at(l, 840, 148, "BREAK THE MEMORY")
	sign_at(l, 1450, 96, "THE FALLEN DISH")
	sign_at(l, 2730, 195, "CARRY IT ON")
	return l
