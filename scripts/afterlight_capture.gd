extends SceneTree

var metrics: Array = []
func _initialize() -> void:
    run.call_deferred()
func frames(count: int = 4) -> void:
    for i in count: await physics_frame
func shot(name: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/"+name+".png")
    print("CAPTURE "+name)
func measure(rs: Node, name: String) -> void:
    var samples: Array[float] = []
    var last := Time.get_ticks_usec()
    for i in 150:
        await process_frame
        var now := Time.get_ticks_usec()
        if i >= 30: samples.append((now-last)/1000.0)
        last = now
    samples.sort()
    metrics.append({"mode":name,"frame_median_ms":samples[samples.size()/2],
        "frame_p95_ms":samples[int(samples.size()*0.95)],
        "draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
        "generated":rs.lab_generated,"resolution":str(root.size)})
func run() -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(960,540))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user"))
    var world = load("res://scenes/main.tscn").instantiate()
    root.add_child(world)
    current_scene = world
    var rs = root.get_node("RunState")
    rs.boundary_path = "res://test-user/afterlight-capture-save.json"
    await frames(6)
    await shot("afterlight-title")
    rs.start_lab()
    await frames(8)
    world.player.reset_at(Vector2(350,223))
    world.snap_camera()
    await frames(175)
    rs.state = "pause"
    # Pause sim without displaying its overlay: capture only play view at fixed camera.
    var hud = world.get_node("HUDLayer/HUD")
    hud.banner_t = 0
    for i in 3:
        rs.lab_mode = i
        rs.state = "play"
        await frames(1)
        await shot(["afterlight-normal","afterlight-dark","afterlight-assist"][i])
        await measure(rs,["ordinary","dark","assist"][i])
    rs.lab_mode = 1
    rs.remember(Vector2(270,179),"THE OPERATOR")
    await frames(42)
    await shot("afterlight-memory")
    var view = world.get_node("AfterlightLayer/View")
    for i in view.layers.size():
        var tex: Texture2D = view.layers[i].texture
        var image := tex.get_image()
        print("ASSET ",view.layer_layout[i].asset," ",image.get_size()," alpha=",image.detect_alpha())
    rs.lab_generated = false
    await frames(3)
    await shot("afterlight-procedural")
    await measure(rs,"procedural-control")
    rs.lab_generated = true
    rs.lab_mode = 2
    world.player.reset_at(Vector2(1610,151))
    world.snap_camera()
    await frames(175)
    hud.banner_t = 0
    rs.remember(Vector2(1600,107),"THE LAST SHIFT")
    await frames(42)
    await shot("afterlight-last-shift")
    var f := FileAccess.open("res://test-user/afterlight-metrics.json",FileAccess.WRITE)
    f.store_string(JSON.stringify({"device":RenderingServer.get_video_adapter_name(),"samples":metrics},"  "))
    f.close()
    print("CAPTURE COMPLETE")
    quit()
