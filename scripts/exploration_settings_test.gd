extends SceneTree
func _initialize() -> void: run.call_deferred()
func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/explore-settings-%d.json" % OS.get_process_id()
    root.add_child(world)
    await process_frame
    await process_frame
    var music = root.get_node("Music")
    var playback = music.player.get_stream_playback()
    world._unhandled_input(key(KEY_ESCAPE))
    world._unhandled_input(key(KEY_O))
    assert(world.paused and world.settings_menu.page == "settings")
    var at: Vector2 = world.player.position
    for i in 10: await physics_frame
    assert(world.player.position == at)
    assert(music.player.stream_paused)
    world._unhandled_input(key(KEY_M))
    assert(not world.map_open and world.settings_menu.page == "settings")
    world.settings_menu.selected = 5
    world._unhandled_input(key(KEY_ENTER))
    assert(world.settings_menu.page == "keyboard")
    world._unhandled_input(key(KEY_ESCAPE))
    assert(world.settings_menu.page == "settings" and world.paused)
    world._unhandled_input(key(KEY_ESCAPE))
    assert(world.settings_menu.page == "home" and world.paused)
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_A
    pad.pressed = true
    world._unhandled_input(pad)
    assert(world.settings_menu.page == "settings")
    world._unhandled_input(key(KEY_ESCAPE))
    world._unhandled_input(key(KEY_ESCAPE))
    assert(not world.paused)
    await process_frame
    await process_frame
    assert(not music.player.stream_paused and music.player.get_stream_playback() == playback)
    world.enter_room("hub")
    world._unhandled_input(key(KEY_ESCAPE))
    world._unhandled_input(key(KEY_O))
    assert(is_instance_valid(world.settings_menu) and world.settings_menu.page == "settings")
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(world.save_path+suffix)
    print("EXPLORATION SETTINGS: keyboard/pad access, nested back and paused physics passed")
    quit()
