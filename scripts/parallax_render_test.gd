extends SceneTree

var failures := 0
func check(label: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func _initialize() -> void:
    run.call_deferred()

func frame_at(world: Node, view: Node, layer: int, offset: float) -> Image:
    world.cam.position = Vector2(240+offset/float(view.layer_layout[layer].speed),135)
    world.cam.force_update_scroll()
    view._process(0.0)
    for i in view.layers.size(): view.layers[i].visible = i == layer
    await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func run() -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(960,540))
    var world = load("res://scenes/main.tscn").instantiate()
    root.add_child(world)
    current_scene = world
    var rs = root.get_node("RunState")
    rs.start_lab()
    rs.state = "pause"
    rs.lab_mode = 0
    rs.lab_generated = true
    world.set_process(false)
    world.set_physics_process(false)
    for path in ["BackgroundLayer/Background","HUDLayer/HUD","EntityRenderLayer","FXLayer"]:
        world.get_node(path).hide()
    world.level_root.hide()
    var view = world.get_node("AfterlightLayer/View")
    view.set_process(false)
    view.get_node("Memories").hide()
    for i in view.layers.size():
        var period: float = view.layer_layout[i].size.x
        var first := await frame_at(world,view,i,0)
        var plus := await frame_at(world,view,i,period*2)
        var minus := await frame_at(world,view,i,-period*2)
        check("layer %d repeats identically after two camera wraps each direction"%i,first.get_data()==plus.get_data() and first.get_data()==minus.get_data())
        var before := await frame_at(world,view,i,period-1)
        var after := await frame_at(world,view,i,period)
        var continuous := true
        for y in range(0,540,2):
            for x in range(0,958,2):
                if after.get_pixel(x,y)!=before.get_pixel(x+2,y): continuous=false
        check("layer %d wrap advances one logical pixel without a phase jump"%i,continuous)
        var stopped := await frame_at(world,view,i,period)
        check("layer %d stopped camera is pixel stable"%i,after.get_data()==stopped.get_data())
        # Exercise continuous camera travel and reversals through full periods.
        for direction in [1,-1]:
            for step in range(0,int(period*2)+1,24):
                await frame_at(world,view,i,float(step*direction))
            for step in range(-16,17):
                await frame_at(world,view,i,period+float(step*direction))
        var seam := await frame_at(world,view,i,period-240)
        seam.save_png("res://test-user/parallax-wrap-%d.png"%i)
    print("PARALLAX RENDER: %d failure(s)"%failures)
    quit(1 if failures else 0)
