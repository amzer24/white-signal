extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/stand_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("conductor")
    root.get_node("RunState").state = "pause"
    scene.activate("storm_charge")
    scene.stand.tick(3.1)
    await capture(scene, "stand-ready")
    scene.activate("storm_divert")
    await capture(scene, "stand-warning")
    scene.stand.tick(1.6)
    await capture(scene, "stand-discharge")
    scene.stand.tick(0.4)
    await capture(scene, "stand-latched")
    scene.map_open = true
    await capture(scene, "stand-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/stand_capture.json"+suffix)
    print("STAND CAPTURE: complete")
    quit()
