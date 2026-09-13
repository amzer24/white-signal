extends Node
## RunState autoload — run/deck/state + tuned modifiers (ported JS TUNE + CARDS).

signal state_changed(s: String)
signal memory_triggered(at: Vector2)
signal relay_changed
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

var lab_active := false
var lab_mode := 1 # 0 ordinary, 1 authored dark, 2 readability assist
var lab_generated := true
var lab_gentle := false
var lit_beacons: Array[Vector2] = []
var relay_index := 0
var level: Dictionary = LevelData.get_level(0)
var objectives: Array = []
var relay_time := 0.0
var collected_this_relay := 0
var boundary_path := "user://ws_campaign_v1.json"

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
var hitstop := 0.0  # JS hitstop: freezes sim for a few frames on kills

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if not InputMap.has_action("interact"):
        InputMap.add_action("interact")
        for code in [KEY_DOWN, KEY_S]:
            var key := InputEventKey.new()
            key.physical_keycode = code
            InputMap.action_add_event("interact", key)
    mods = BASE.duplicate()
    zones = level.zones
    load_best()

func _physics_process(delta: float) -> void:
    if state == "play":
        if hitstop > 0.0:
            hitstop -= delta
        else:
            time += delta
            relay_time += delta

## true when the sim should advance this frame (play state and not in hitstop)
func sim_active() -> bool:
    return state == "play" and hitstop <= 0.0

func zone_of(x: float) -> int:
    for i in zones.size():
        if x < float(zones[i].x1):
            return i
    return zones.size() - 1

const ZONE_HYST := 24.0  # px past a boundary before the zone flips (wall-kicks straddle Z1/Z2)

func update_zone(px: float) -> void:
    var zi := zone_of(px)
    if zi == cur_zone:
        return
    if zi > cur_zone and px < float(zones[zi].x0) + ZONE_HYST:
        return
    if zi < cur_zone and px > float(zones[cur_zone].x0) - ZONE_HYST:
        return
    cur_zone = zi
    banner.emit(String(zones[zi].name), String(zones[zi].sub))
    Sfx.beep(520.0, 0.08)
    if relay_index == 0 and zi == 2 and notches_max < 4:
        notches_max = 4
        Sfx.two(780.0, 1040.0, 100)

func start_run() -> void:
    lab_active = false
    state = "loading"
    reset_run()
    _enter_relay(0)

func _enter_relay(index: int) -> void:
    relay_index = index
    level = preload("res://scripts/afterlight_data.gd").build() if lab_active else LevelData.get_level(index)
    zones = level.zones
    objectives = []
    lit_beacons.clear()
    relay_time = 0.0
    collected_this_relay = 0
    cur_zone = 0
    hitstop = 0.0
    checkpoint = Vector2(level.spawn) + Vector2(0, 7)
    notches_max = 4 if index >= 1 else 3
    draft_opts = []
    state = "loading"
    relay_changed.emit()
    save_boundary()
    state = "play"
    state_changed.emit(state)
    banner.emit(level.name, level.objective)

func advance_relay() -> void:
    if state == "relay_clear" and relay_index + 1 < LevelData.RELEASED_RELAYS:
        _enter_relay(relay_index + 1)

func exit_ready() -> bool:
    return objectives.size() >= int(level.get("required_memories", level.get("required_ears", 0)))

func objective_text() -> String:
    if lab_active:
        return "CARRY THEM ON" if exit_ready() else "MEMORIES %d/3" % objectives.size()
    if level.has("required_ears"):
        return "RETURN TO TRANSMITTER" if exit_ready() else "WAKE EARS %d/3" % objectives.size()
    return String(level.objective)

func save_boundary() -> void:
    if lab_active: return
    var f := FileAccess.open(boundary_path, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"version": 1, "relay": relay_index,
            "deck": deck, "gems": gems, "deaths": deaths, "time": time,
            "surges": last_surge, "drafts": drafts_seen}))
    else:
        push_warning("Campaign boundary could not be saved: " + error_string(FileAccess.get_open_error()))

func load_boundary() -> Dictionary:
    if not FileAccess.file_exists(boundary_path):
        return {}
    var f := FileAccess.open(boundary_path, FileAccess.READ)
    if not f: return {}
    var data = JSON.parse_string(f.get_as_text())
    if not data is Dictionary or data.get("version") != 1: return {}
    for key in ["relay", "gems", "deaths", "time", "surges", "drafts"]:
        if not (data.get(key) is float or data.get(key) is int): return {}
        if not is_finite(float(data[key])) or float(data[key]) < 0: return {}
    if int(data.relay) >= LevelData.RELEASED_RELAYS: return {}
    if not data.get("deck") is Array: return {}
    var seen: Array = []
    var normal := 0
    var cursed := 0
    for id in data.deck:
        if not id is String or not CARDS.has(id) or seen.has(id): return {}
        seen.append(id)
        if CARDS[id].cursed: cursed += int(CARDS[id].cost)
        else: normal += int(CARDS[id].cost)
    if normal > (4 if int(data.relay) > 0 else 3) or cursed > 2: return {}
    if int(data.surges) != int(data.gems) / 5: return {}
    return data

func resume_run() -> void:
    var data := load_boundary()
    if data.is_empty(): return
    lab_active = false
    deck = data.deck.duplicate()
    gems = int(data.gems)
    deaths = int(data.deaths)
    time = float(data.time)
    last_surge = int(data.surges)
    drafts_seen = int(data.drafts)
    new_best = false
    apply_deck()
    _enter_relay(int(data.relay))

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
    checkpoint = Vector2(36, 194)
    apply_deck()

func collect_gem() -> void:
    gems += 1
    collected_this_relay += 1
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
    Sfx.two(660.0, 990.0, 100)
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
    if state != "draft" or i < 0 or i >= draft_opts.size():
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
    # draft pick arpeggio (GDD §9)
    Sfx.beep(660.0, 0.06)
    get_tree().create_timer(0.07).timeout.connect(Sfx.beep.bind(830.0, 0.06, 0.06, "square"))
    get_tree().create_timer(0.14).timeout.connect(Sfx.beep.bind(990.0, 0.1, 0.06, "square"))
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
        state = "play"  # JS respawn() always resumes play
        state_changed.emit(state)

func register_death() -> void:
    if state != "play": return
    relay_time = 0.0
    deaths += 1
    Sfx.beep(110.0, 0.2, 0.08, "sawtooth")
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
    if state != "play" or not exit_ready():
        return
    if lab_active:
        state = "lab_complete"
        state_changed.emit(state)
        return
    Sfx.two(523.0, 784.0, 120)
    state = "relay_clear" if relay_index + 1 < LevelData.RELEASED_RELAYS else "build_complete"
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
func start_lab() -> void:
    lab_active = true
    state = "loading"
    reset_run()
    _enter_relay(0)

func leave_lab() -> void:
    if not lab_active: return
    lab_active = false
    state = "loading"
    reset_run()
    relay_index = 0
    level = LevelData.get_level(0)
    zones = level.zones
    objectives.clear()
    lit_beacons.clear()
    relay_changed.emit()
    state = "menu"
    state_changed.emit(state)

func remember(at: Vector2, id: String) -> void:
    if not lab_active or state != "play": return
    if not objectives.has(id): objectives.append(id)
    memory_triggered.emit(at)
