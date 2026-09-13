extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/drowned_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("basin")
    root.get_node("RunState").state = "pause"
    scene.paused = false
    await capture(scene, "drowned-high")
    scene.activate("bleed")
    scene.activate("bleed")
    scene.drowned.water_y = 246
    await capture(scene, "drowned-low")
    scene.activate("impeller")
    scene.enter_room("pump")
    scene.activate("pump_socket")
    await capture(scene, "drowned-pump")
    scene.enter_room("float")
    scene.activate("float_valve")
    scene.activate("float_valve")
    scene.drowned.water_y = 137
    scene.drowned.carrier.position.y = 127
    await capture(scene, "drowned-float")
    scene.map_open = true
    await capture(scene, "drowned-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/drowned_capture.json"+suffix)
    print("DROWNED CAPTURE: complete")
    quit()
