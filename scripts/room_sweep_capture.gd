extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(scene: Node, filename: String) -> void:
    scene.queue_redraw(); await process_frame; await process_frame; await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/sweep/" + filename + ".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/sweep"))
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/sweep_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path + suffix)
    root.add_child(scene)
    scene.intro_open = false
    root.get_node("RunState").state = "play"
    await process_frame
    var ids: Array = OS.get_environment("WS_ROOMS").split(",") if OS.has_environment("WS_ROOMS") else ["flats","hub","basin","stand_rim","wire_shelter","array","gate","aftermath","source_return"]
    for id in ids:
        scene.enter_room(id)
        if OS.has_environment("WS_BANNER"): scene.banner_time = 2.0
        else: scene.banner_time = 0.0
        await capture(scene, id)
    scene.queue_free(); await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/sweep_capture.json" + suffix)
    print("SWEEP: complete"); quit()
