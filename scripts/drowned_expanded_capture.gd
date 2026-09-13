extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/drowned_expanded_capture.json"
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+s)
    root.add_child(scene)
    for id in ["basin","pump","drowned_street","drowned_gallery","float","drowned_dock","drowned_cycle"]:
        scene.enter_room(id)
        await capture(scene,"drowned-expanded-"+id)
    scene.enter_room("drowned_gallery")
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    await capture(scene,"drowned-expanded-map")
    scene.queue_free()
    await process_frame
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/drowned_expanded_capture.json"+s)
    quit()
