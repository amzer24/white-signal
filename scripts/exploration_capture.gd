extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func capture(scene: Node, filename: String) -> void:
    scene.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/" + filename + ".png")

func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/exploration_capture.json"
    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute(scene.save_path + suffix)
    root.add_child(scene)
    await process_frame
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    await capture(scene, "map-first-visit")
    for id in ["workshop", "gallery", "amplifier", "return", "lookout"]:
        scene.enter_room(id)
    scene.activate("survey")
    scene.profile.set_flag("return_open")
    await capture(scene, "map-surveyed")
    scene.map_open = false
    scene.enter_room("hub")
    await capture(scene, "exploration-hub")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute("res://test-user/exploration_capture.json" + suffix)
    print("EXPLORATION CAPTURE: complete")
    quit()
