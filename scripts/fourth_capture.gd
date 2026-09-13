extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/fourth_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("amplifier")
    await capture(scene,"fourth-visible-ledge")
    scene.enter_room("fourth")
    scene.activate("fourth_memory")
    await capture(scene,"fourth-memory-before")
    scene.memory_time = 4
    await capture(scene,"fourth-memory-isolated")
    root.get_node("AppSettings").reduced_flashes = true
    scene.memory_time = 4
    await capture(scene,"fourth-memory-reduced")
    scene.map_open = true
    await capture(scene,"fourth-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/fourth_capture.json"+suffix)
    print("FOURTH CAPTURE: complete")
    quit()
