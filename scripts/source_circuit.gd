extends RefCounted
## Staged finale controller. Pending diagnostics never become saved progress.
const Layout = preload("res://scripts/source_district_rooms.gd")
const FEEDERS := ["field_restored", "stand_restored", "drowned_restored", "array_restored"]
const SETTLE_SECONDS := 1.5
var profile: RefCounted
var remaining := 0.0

func _init(saved_profile: RefCounted) -> void:
    profile = saved_profile

func ready() -> bool:
    for flag in FEEDERS:
        if not profile.has_flag(flag): return false
    return true

func cancel() -> void:
    remaining = 0.0

func use(room: String, action: String) -> String:
    var expected := {"gate_latch":"gate", "gate_isolate":"source_return", "gate_commit":"source_walk"}
    if not expected.has(action) or expected[action] != room: return "unhandled"
    if not ready(): return "feeders_missing"
    var state := Layout.progress(profile.data.flags)
    match action:
        "gate_latch":
            if state.latched: return "already_latched"
            return "latched" if profile.set_flag("gate_latched") else "save_failed"
        "gate_isolate":
            if not state.latched: return "latch_required"
            if state.tested: return "already_verified"
            if remaining > 0: return "verifying"
            remaining = SETTLE_SECONDS
            return "verifying"
        "gate_commit":
            if not state.tested: return "verification_required"
            if state.restored: return "already_restored"
            return "restored" if profile.set_flag("signal_restored") else "save_failed"
    return "unhandled"

func tick(delta: float, room: String, paused: bool) -> String:
    if room != "source_return":
        cancel()
        return ""
    if paused or remaining <= 0: return ""
    if not ready():
        cancel()
        return "feeders_missing"
    remaining = maxf(0.0, remaining - maxf(delta, 0.0))
    if remaining > 0: return ""
    # One transaction: a failed write cannot deploy the verified bridge.
    return "verified" if profile.set_flags({"gate_isolated":true, "gate_tested":true}) else "save_failed"
