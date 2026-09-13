extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/pump_art_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("pump")
    scene.player.position = Vector2(244,148)
    await capture(scene,"pump-empty")
    scene.profile.set_flag("impeller")
    scene.activate("pump_socket")
    scene.elapsed = 2
    await capture(scene,"pump-repaired")
    scene.enter_room("float")
    scene.activate("float_valve")
    await capture(scene,"pump-float-connection")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/pump_art_capture.json"+suffix)
    print("PUMP ART CAPTURE: complete")
    quit()
