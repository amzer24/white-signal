extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/stand_expanded_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    for id in ["stand_rim","shelter","stand_charge","conductor","stand_trial","stand_sluice","stand_bridge"]:
        scene.enter_room(id)
    scene.enter_room("stand_rim")
    await capture(scene,"stand-rim-art")
    scene.enter_room("stand_charge")
    scene.activate("storm_charge")
    scene.stand.tick(3.1)
    await capture(scene,"stand-charge-integrated")
    scene.enter_room("conductor")
    await capture(scene,"stand-reservoir-integrated")
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    await capture(scene,"stand-map-integrated")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/stand_expanded_capture.json"+suffix)
    print("EXPANDED STAND CAPTURE: complete")
    quit()
