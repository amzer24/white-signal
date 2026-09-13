extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/field_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("cellar")
    await capture(scene,"field-intake")
    scene.activate("intake_strike")
    scene.enter_room("sump")
    await capture(scene,"field-incomplete")
    scene.profile.set_flag("west_ear")
    scene.profile.set_flag("east_ear")
    scene.activate("field_transmit")
    await capture(scene,"field-commissioned")
    scene.map_open = true
    await capture(scene,"field-service-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/field_capture.json"+suffix)
    print("FIELD CAPTURE: complete")
    quit()
