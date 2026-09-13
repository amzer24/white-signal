extends "res://scripts/inspection_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/map_help_capture.json"
    root.add_child(scene)
    scene.map_open = true
    scene.map_help = true
    root.get_node("RunState").state = "pause"
    await capture(scene,"map-help")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/map_help_capture.json"+suffix)
    quit()
