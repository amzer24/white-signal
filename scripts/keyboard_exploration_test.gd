extends SceneTree
func _initialize() -> void: run.call_deferred()
func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = true
    return event
func run() -> void:
    var controls = root.get_node("GameInput").keyboard
    controls.path = "res://test-user/exploration-keys-%d.cfg" % OS.get_process_id()
    assert(controls.save({"interact":KEY_U}))
    controls.apply()
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/exploration-keys-%d.json" % OS.get_process_id()
    root.add_child(world)
    await process_frame
    world.enter_room("lookout")
    world.player.position = Vector2(227,147)
    world._unhandled_input(key(KEY_E))
    assert(not world.profile.data.flags.get("survey",false))
    world._unhandled_input(key(KEY_U))
    assert(world.profile.data.flags.get("survey",false))
    world.enter_room("hub")
    world.player.position = Vector2(69,119)
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_X
    pad.pressed = true
    world._unhandled_input(pad)
    assert(world.room_id == "workshop")
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(world.save_path+suffix)
    DirAccess.remove_absolute(controls.path)
    print("KEYBOARD EXPLORATION: old E inactive, remapped U surveys, controller X traverses")
    quit()
