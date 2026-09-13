extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        print("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    if not FileAccess.file_exists("res://scripts/stand_mechanism.gd"):
        print("FAIL: Stand mechanism is missing")
        quit(1)
        return
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/stand_contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(world.save_path+suffix)
    root.add_child(world)
    await process_frame
    world.enter_room("return")
    check(not world.can_use_exit("stand_rim"), "Field arrival requires Dash before restoration")
    world.profile.set_flag("dash")
    check(world.can_use_exit("stand_rim"), "Field arrival opens with permanent Dash")
    world.enter_room("pump")
    check(not world.can_use_exit("stand_sluice"), "Drowned arrival requires its restored feeder")
    world.profile.set_flag("drowned_restored")
    check(world.can_use_exit("stand_sluice"), "Drowned arrival opens independently")
    world.enter_room("conductor")
    check(not world.can_use_exit("stand_bridge"), "bridge exit is initially closed")
    world.activate("storm_divert")
    check(world.stand.phase == "idle", "empty reservoir cannot drive motor")
    world.enter_room("stand_charge")
    world.activate("storm_charge")
    world.stand.tick(3.1)
    check(world.stand.charge == 1, "reservoir fills from sheltered selector")
    world.stand.tick(30)
    check(world.stand.charge == 1, "charge holds without timing pressure")
    world.respawn()
    check(world.stand.phase == "idle" and world.stand.charge == 0, "unfinished charge safely resets on death")
    world.enter_room("stand_charge")
    world.activate("storm_charge")
    world.stand.tick(3.1)
    world.enter_room("conductor")
    world.activate("storm_divert")
    check(world.stand.phase == "warning", "diversion gives advance warning")
    world.stand.tick(1.4)
    check(not world.profile.has_flag("stand_restored"), "warning is not premature completion")
    world.stand.tick(0.2)
    check(world.stand.phase == "discharge", "deterministic cue precedes discharge")
    world.stand.tick(0.4)
    check(world.profile.has_flag("stand_restored"), "motor commits permanent bridge latch")
    check(world.can_use_exit("stand_bridge"), "latched bridge opens Field return")
    world.respawn()
    check(world.profile.has_flag("stand_restored"), "death retains bridge")
    check(world.profile.load_profile() and world.profile.has_flag("stand_restored"), "bridge survives reload")
    var preferences = root.get_node("AppSettings")
    preferences.save_path = "res://test-user/stand_preferences.cfg"
    preferences.reduced_flashes = true
    preferences.toggle_flashes()
    preferences.reduced_flashes = true
    preferences.load_preferences()
    check(not preferences.reduced_flashes, "reduced-flash preference survives reload")
    DirAccess.remove_absolute(preferences.save_path)
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/stand_contract.json"+suffix)
    print("STAND: %d failures" % failures)
    quit(1 if failures else 0)
