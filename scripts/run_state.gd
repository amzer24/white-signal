extends Node
## RunState autoload — run/deck/state + tuned modifiers (ported JS TUNE + CARDS).

signal state_changed(s: String)
signal respawned
signal banner(text: String, sub: String)

const SAVE_PATH := "user://ws_best.json"

const BASE := {
	"max_run": 135.0, "accel": 1150.0, "air_accel": 780.0, "friction": 1500.0,
	"gravity": 920.0, "jump_vel": 325.0, "short_hop": 0.45,
	"coyote": 0.10, "buffer": 0.12, "max_fall": 390.0, "fall_mult": 1.0,
	"air_jumps": 0, "dash": false, "magnet_r": 13.0, "shield_max": 0,
	"stomp_plus": false, "glass": false,
}

const CARDS := {
	"dash": {"g": ">>", "n": "DASH", "cost": 2, "cursed": false},
	"jump2": {"g": "J2", "n": "2xJUMP", "cost": 2, "cursed": false},
	"feather": {"g": "~", "n": "FEATHER", "cost": 1, "cursed": false},
	"swift": {"g": ">", "n": "SWIFT", "cost": 1, "cursed": false},
	"spring": {"g": "^^", "n": "SPRING", "cost": 1, "cursed": false},
	"magnet": {"g": "O", "n": "MAGNET", "cost": 1, "cursed": false},
	"aegis": {"g": "A", "n": "AEGIS", "cost": 1, "cursed": false},
	"stomp": {"g": "v", "n": "STOMP+", "cost": 1, "cursed": false},
	"heavy": {"g": "H", "n": "HEAVY", "cost": 1, "cursed": true},
	"glass": {"g": "G", "n": "GLASS", "cost": 1, "cursed": true},
}
const SHORT := {
	"dash": "DSH", "jump2": "JMP", "feather": "FTH", "swift": "SWF",
	"spring": "SPR", "magnet": "MAG", "aegis": "AEG", "stomp": "STM",
	"heavy": "HVY", "glass": "GLS",
}

var state := "menu"
var time := 0.0
var deaths := 0
var gems := 0
var last_surge := 0
var drafts_seen := 0
var deck: Array = []
var notches_max := 3
var cursed_max := 2
var draft_opts: Array = []
var cur_zone := 0
var checkpoint := Vector2(36, 187)
var mods := {}
var best := {}
var new_best := false
var zones: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mods = BASE.duplicate()
	zones = LevelData.DATA.zones
	load_best()

func _physics_process(delta: float) -> void:
	if state == "play":
		time += delta

func zone_of(x: float) -> int:
	for i in zones.size():
		if x < float(zones[i].x1):
			return i
	return zones.size() - 1

func update_zone(px: float) -> void:
	var zi := zone_of(px)
	if zi != cur_zone:
		cur_zone = zi
		banner.emit(String(zones[zi].name), String(zones[zi].sub))
		if zi == 2 and notches_max < 4:
			notches_max = 4

func start_run() -> void:
	reset_run()
	respawned.emit()
	state = "play"
	state_changed.emit(state)

func reset_run() -> void:
	deck = []
	gems = 0
	deaths = 0
	time = 0.0
	last_surge = 0
	drafts_seen = 0
	notches_max = 3
	cur_zone = 0
	draft_opts = []
	new_best = false
	checkpoint = Vector2(36, 187)
	apply_deck()

func collect_gem() -> void:
	gems += 1
	var s: int = gems / 5
	if s > last_surge:
		last_surge = s
		open_draft()

func open_draft() -> void:
	var pool: Array = []
	for id in CARDS.keys():
		if not deck.has(id):
			pool.append(id)
	pool.shuffle()
	draft_opts = pool.slice(0, 3)
	if drafts_seen == 0 and not deck.has("dash") and not draft_opts.has("dash"):
		draft_opts[2] = "dash"  # marquee guarantee (GDD §6)
	drafts_seen += 1
	state = "draft"
	state_changed.emit(state)

func used_notches() -> int:
	var u := 0
	for id in deck:
		if not CARDS[id].cursed:
			u += int(CARDS[id].cost)
	return u

func used_cursed() -> int:
	var u := 0
	for id in deck:
		if CARDS[id].cursed:
			u += int(CARDS[id].cost)
	return u

func pick_card(i: int) -> void:
	if state != "draft" or i >= draft_opts.size():
		return
	var id: String = draft_opts[i]
	var c: Dictionary = CARDS[id]
	if c.cursed:
		if used_cursed() + int(c.cost) > cursed_max:
			return
	elif used_notches() + int(c.cost) > notches_max:
		return
	deck.append(id)
	apply_deck()
	close_draft()

func skip_draft() -> void:
	if state == "draft":
		close_draft()

func close_draft() -> void:
	draft_opts = []
	if state == "draft":
		state = "play"
		state_changed.emit(state)

func toggle_pause() -> void:
	if state == "play":
		state = "pause"
		state_changed.emit(state)
	elif state == "pause":
		state = "play"
		state_changed.emit(state)

func manual_respawn() -> void:
	if state == "play" or state == "pause":
		respawned.emit()

func register_death() -> void:
	deaths += 1
	respawned.emit()

func apply_deck() -> void:
	mods = BASE.duplicate()
	for id in deck:
		match id:
			"dash": mods.dash = true
			"jump2": mods.air_jumps = int(mods.air_jumps) + 1
			"feather": mods.fall_mult = 0.7
			"swift":
				mods.max_run = float(mods.max_run) * 1.25
				mods.accel = float(mods.accel) * 1.2
				mods.air_accel = float(mods.air_accel) * 1.15
			"spring": mods.jump_vel = float(mods.jump_vel) * 1.2
			"magnet": mods.magnet_r = 46.0
			"aegis": mods.shield_max = 1
			"stomp": mods.stomp_plus = true
			"heavy":
				mods.jump_vel = float(mods.jump_vel) * 1.25
				mods.gravity = float(mods.gravity) * 1.35
				mods.max_fall = float(mods.max_fall) * 1.3
			"glass":
				mods.max_run = float(mods.max_run) * 1.5
				mods.accel = float(mods.accel) * 1.3
				mods.air_accel = float(mods.air_accel) * 1.25
				mods.air_jumps = int(mods.air_jumps) + 1
				mods.glass = true

func win() -> void:
	if state != "play":
		return
	new_best = save_best(time, deaths, gems)
	state = "win"
	state_changed.emit(state)

func load_best() -> void:
	best = {}
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				best = parsed

func save_best(t: float, d: int, g: int) -> bool:
	if not best.is_empty() and not (t < float(best.get("t", INF))):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"t": t, "d": d, "g": g}))
	best = {"t": t, "d": d, "g": g}
	return true