extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/wire_shaft_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("wire_shelter")
    scene.enter_room("wire_shaft")
    await capture(scene,"wire-shaft-campaign-before")
    scene.player.reset_at(Vector2(400,59))
    scene.activate("shaft_release")
    for i in 30: await physics_frame
    await capture(scene,"wire-shaft-campaign-released")
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    await capture(scene,"wire-shaft-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/wire_shaft_capture.json"+suffix)
    quit()
