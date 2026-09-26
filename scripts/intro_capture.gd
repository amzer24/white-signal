extends SceneTree
## Dev tool: capture the first-run intro overlay and the title menu to test-user/.
## godot --rendering-driver opengl3 --path . --script res://scripts/intro_capture.gd
func _initialize() -> void: run.call_deferred()
func run() -> void:
    var save := "res://test-user/intro-capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(save+suffix)
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = save
    root.add_child(world)
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/intro-overlay.png")
    var key := InputEventKey.new()
    key.keycode = KEY_SPACE
    key.pressed = true
    Input.parse_input_event(key)
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/intro-dismissed.png")
    world.activate("intro_memory")
    world.player.position = Vector2(150,217)
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/intro-memory.png")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(save+suffix)
    print("INTRO CAPTURE: done")
    quit()
