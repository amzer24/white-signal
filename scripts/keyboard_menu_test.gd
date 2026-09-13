extends SceneTree
func _initialize() -> void: run.call_deferred()
func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event
func run() -> void:
    var scene = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    await process_frame
    var menu = scene.get_node("HUDLayer/HUD").menu_ui
    var controls = root.get_node("GameInput").keyboard
    controls.path = "res://test-user/menu-keyboard.cfg"
    menu.open_settings()
    menu.selected = 5
    menu.activate()
    assert(menu.page == "keyboard")
    menu.selected = 2
    menu.activate()
    menu.handle_input(key(KEY_J))
    assert(controls.bindings.jump == KEY_J)
    menu.activate()
    assert(controls.capturing == "jump")
    menu._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    assert(controls.capturing.is_empty() and controls.bindings.jump == KEY_J)
    menu.selected = 5
    menu.activate()
    assert(controls.bindings.is_empty())
    menu.handle_input(key(KEY_ESCAPE))
    assert(menu.page == "settings" and menu.selected == 5)
    DirAccess.remove_absolute(controls.path)
    print("KEYBOARD MENU: navigation, capture, defaults and return passed")
    quit()
