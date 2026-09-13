extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/network_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("wire_shelter")
    scene.activate("brake_spare")
    scene.enter_room("wire_carriage")
    scene.activate("brake_socket")
    await capture(scene,"wire-carriage")
    scene.enter_room("array")
    scene.activate("array_test")
    scene.network.tick(2.1)
    await capture(scene,"array-fault")
    scene.activate("array_isolate")
    scene.activate("array_bypass")
    await capture(scene,"array-bypass")
    scene.map_open = true
    await capture(scene,"network-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/network_capture.json"+suffix)
    print("NETWORK CAPTURE: complete")
    quit()
