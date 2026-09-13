extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        print("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    if not FileAccess.file_exists("res://scripts/gate_mechanism.gd"):
        print("FAIL: Gate mechanism missing")
        quit(1)
        return
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/gate_contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("approach")
    check(not scene.can_use_exit("gate"),"incomplete network blocks Gate")
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored"]:
        scene.profile.set_flag(flag)
    check(scene.can_use_exit("gate"),"four feeder projects open Gate")
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored"]:
        scene.profile.data.flags.erase(flag)
        check(not scene.can_use_exit("gate"),"each feeder is individually mandatory: "+flag)
        scene.profile.set_flag(flag)
    scene.activate("approach_latch")
    check(scene.profile.has_flag("approach_return"),"service return opens persistently")
    scene.enter_room("gate")
    scene.activate("gate_commit")
    check(not scene.profile.has_flag("signal_restored"),"commit cannot skip commissioning")
    scene.activate("gate_latch")
    check(scene.can_use_exit("source_return"),"secured bus opens return chamber")
    scene.enter_room("source_return")
    scene.activate("gate_isolate")
    check(not scene.profile.has_flag("gate_tested"),"test waits for diagnostic")
    scene.gate.tick(2.1)
    check(scene.can_use_exit("source_walk"),"verified bridge opens commissioning")
    scene.enter_room("source_walk")
    var working_path: String = scene.profile.path
    scene.profile.path = "res://test-user/nonexistent-gate-folder/profile.json"
    scene.activate("gate_commit")
    check(not scene.profile.has_flag("signal_restored"),"failed save cannot report restoration")
    scene.profile.path = working_path
    scene.activate("gate_commit")
    check(scene.profile.has_flag("signal_restored"),"valid commissioning restores Signal")
    check(scene.can_use_exit("aftermath"),"aftermath opens")
    check(not scene.profile.has_flag("fourth_archive"),"optional archive is not an ending quota")
    scene.profile.set_flag("dash")
    scene.profile.set_flag("air_jump")
    scene.enter_room("aftermath")
    scene.respawn()
    scene.profile.load_profile()
    check(scene.profile.has_flag("signal_restored") and scene.profile.has_flag("dash") and scene.profile.has_flag("air_jump"),"ending preserves world and abilities on reload")
    scene.enter_room("hub")
    check(scene.room_id == "hub", "completed world remains revisitable")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/gate_contract.json"+suffix)
    print("GATE: %d failures" % failures)
    quit(1 if failures else 0)
