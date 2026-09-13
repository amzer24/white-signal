extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/causeway_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("causeway")
    await capture(scene,"causeway-initial")
    for i in 3:
        for step in scene.alignment.target[i]: scene.activate("dish_%d" % i)
    scene.activate("ear_transmit")
    await capture(scene,"causeway-restored")
    scene.map_open = true
    await capture(scene,"causeway-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/causeway_capture.json"+suffix)
    print("CAUSEWAY CAPTURE: complete")
    quit()
