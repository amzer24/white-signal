extends SceneTree
## Dev tool: use every control in a few rooms and capture mid-animation frames.
func _initialize() -> void: run.call_deferred()
func cap(scene, name: String) -> void:
    scene.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/sweep/anim-" + name + ".png")
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/anim_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path + suffix)
    root.add_child(scene)
    scene.intro_open = false
    root.get_node("RunState").state = "play"
    await process_frame
    for step in [["conduit","conduit_switch"],["causeway","dish_0"],["causeway","ear_transmit"],["basin","bleed"],["wire_carriage","carriage_recall"],["pump","pump_socket"]]:
        scene.enter_room(step[0]); scene.banner_time = 0.0
        await process_frame
        scene.activate(step[1])
        for i in 6: await process_frame
        await cap(scene, step[0] + "-" + step[1])
    var path: String = scene.save_path
    scene.queue_free(); await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path + suffix)
    print("ANIM CAPTURE: done"); quit()
