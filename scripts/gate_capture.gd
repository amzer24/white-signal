extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/gate_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("approach")
    await capture(scene,"approach-missing-feeders")
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored"]: scene.profile.set_flag(flag)
    scene.enter_room("gate")
    scene.activate("gate_latch")
    scene.activate("gate_isolate")
    scene.activate("gate_test")
    scene.gate.tick(2.1)
    await capture(scene,"gate-ready")
    scene.activate("gate_commit")
    scene.enter_room("aftermath")
    await capture(scene,"signal-aftermath")
    scene.map_open = true
    await capture(scene,"source-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/gate_capture.json"+suffix)
    print("GATE CAPTURE: complete")
    quit()
