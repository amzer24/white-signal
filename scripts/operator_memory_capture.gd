extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/operator_memory_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("wire_shaft")
    scene.activate("shaft_release")
    scene.player.reset_at(Vector2(445,59))
    for i in 180: await physics_frame
    await capture(scene,"operator-memory-lift")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/operator_memory_capture.json"+suffix)
    quit()
