extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/inspection_capture.json"
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+s)
    root.add_child(scene)
    scene.enter_room("array")
    await capture(scene,"inspection-array-entry")
    scene.enter_room("array_inspection")
    await capture(scene,"inspection-campaign")
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    await capture(scene,"inspection-map")
    scene.queue_free()
    await process_frame
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/inspection_capture.json"+s)
    quit()
