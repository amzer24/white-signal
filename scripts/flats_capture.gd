extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/flats_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    await capture(scene,"flats-opening")
    scene.enter_room("conduit")
    await capture(scene,"flats-conduit")
    scene.activate("conduit_switch")
    scene.enter_room("arrival")
    scene.activate("first_beacon")
    await capture(scene,"flats-beacon")
    scene.map_open = true
    await capture(scene,"flats-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/flats_capture.json"+suffix)
    print("FLATS CAPTURE: complete")
    quit()
