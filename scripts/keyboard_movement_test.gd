extends SceneTree
var failures := 0
func check(label: String, ok: bool) -> void:
    if not ok: failures += 1
    print(("PASS " if ok else "FAIL ")+label)
func key(code: int, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    Input.parse_input_event(event)
func frames(count: int) -> void:
    for i in count: await physics_frame
func _initialize() -> void: run.call_deferred()
func run() -> void:
    var controls = root.get_node("GameInput").keyboard
    controls.path = "res://test-user/movement-%d.cfg" % OS.get_process_id()
    assert(controls.save({"move_left":KEY_J,"move_right":KEY_L,"jump":KEY_I,"dash":KEY_K}))
    controls.apply()
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/movement-%d.json" % OS.get_process_id()
    root.add_child(world)
    world.enter_room("workshop")
    world.player.reset_at(Vector2(240,215))
    await frames(5)
    var start_x: float = world.player.position.x
    key(KEY_D,true)
    await frames(12)
    key(KEY_D,false)
    check("old D does not move",absf(world.player.position.x-start_x)<1)
    key(KEY_L,true)
    await frames(12)
    key(KEY_L,false)
    check("L moves right",world.player.position.x>start_x+10)
    key(KEY_J,true)
    await frames(24)
    key(KEY_J,false)
    check("J moves left",world.player.velocity.x<0)
    await frames(10)
    key(KEY_I,true)
    await frames(3)
    check("I jumps",world.player.velocity.y < -100)
    key(KEY_I,false)
    root.get_node("RunState").mods.dash = true
    world.player.dash_ready = true
    key(KEY_K,true)
    await frames(3)
    check("K dashes",world.player.dash_t>0 and absf(world.player.velocity.x)>300)
    key(KEY_K,false)
    root.get_node("RunState").state = "pause"
    var stopped_time: float = world.player.visual_time
    await frames(10)
    check("pause freezes visual clock",world.player.visual_time == stopped_time)
    root.get_node("RunState").state = "play"
    await frames(3)
    check("resume advances visual clock",world.player.visual_time > stopped_time)
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(world.save_path+suffix)
    DirAccess.remove_absolute(controls.path)
    print("KEYBOARD MOVEMENT: ",failures," failures")
    quit(failures)
