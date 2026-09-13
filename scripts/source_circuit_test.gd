extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
    print(("PASS " if ok else "FAIL ") + label)
    if not ok: failures += 1
func _initialize() -> void:
    var saved = load("res://scripts/exploration_save.gd").new()
    var path := "res://test-user/source-circuit-%d.json" % OS.get_process_id()
    saved.path = path
    var circuit = load("res://scripts/source_circuit.gd").new(saved)
    check(circuit.use("gate", "gate_latch") == "feeders_missing", "four feeders required")
    for flag in circuit.FEEDERS: saved.data.flags[flag] = true
    check(circuit.use("source_return", "gate_latch") == "unhandled", "actions belong to physical rooms")
    check(circuit.use("source_walk", "gate_commit") == "verification_required", "cannot restore before verification")
    check(circuit.use("gate", "gate_latch") == "latched", "bus saved")
    circuit.use("source_return", "gate_isolate")
    circuit.tick(10.0, "source_return", true)
    check(circuit.remaining == 1.5, "map and pause freeze diagnostic")
    circuit.tick(0.5, "source_return", false)
    circuit.tick(10.0, "gate", false)
    check(circuit.remaining == 0 and not saved.has_flag("gate_tested"), "exit cancels pending diagnostic")
    circuit.use("source_return", "gate_isolate")
    circuit.cancel()
    check(not saved.has_flag("gate_isolated") and saved.has_flag("gate_latched"), "death cancels transient work and retains bus")
    saved.path = "res://test-user/missing-source-directory/profile.json"
    circuit.use("source_return", "gate_isolate")
    check(circuit.tick(2.0, "source_return", false) == "save_failed", "failed diagnostic write reported")
    check(not saved.has_flag("gate_isolated") and not saved.has_flag("gate_tested"), "failed write leaves neither completion flag")
    saved.path = path
    circuit.use("source_return", "gate_isolate")
    check(circuit.tick(2.0, "source_return", false) == "verified", "retry commits both flags")
    var reloaded = load("res://scripts/exploration_save.gd").new()
    reloaded.path = path
    check(reloaded.load_profile() and reloaded.has_flag("gate_isolated") and reloaded.has_flag("gate_tested"), "disk reload preserves verified circuit")
    check(circuit.use("source_walk", "gate_commit") == "restored", "commissioning commits restoration")
    saved.data.flags.erase("gate_latched")
    saved.data.flags.erase("gate_isolated")
    saved.data.flags.erase("gate_tested")
    var before: Dictionary = saved.data.duplicate(true)
    check(circuit.use("gate", "gate_latch") == "already_latched", "old completed save derives prerequisites")
    check(saved.data == before, "reading old completion does not rewrite flags")
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path + suffix)
    print("SOURCE CIRCUIT: %d failures" % failures)
    quit(1 if failures else 0)
