extends "res://scripts/exploration_capture.gd"
func run() -> void:
    assert(change_scene_to_file("res://scenes/main.tscn") == OK)
    await scene_changed
    var hud: Node
    for node in current_scene.find_children("*", "Node2D", true, false):
        if node.get_script() == load("res://scripts/hud.gd"): hud = node
    assert(hud != null)
    hud.can_resume = true # fullest title menu
    root.get_node("RunState").state = "menu"
    var menu = hud.menu_ui
    var mode := OS.get_environment("WS_QUIT_MODE")
    if mode == "controller":
        var up := InputEventJoypadButton.new()
        up.button_index = JOY_BUTTON_DPAD_UP
        up.pressed = true
        menu.handle_input(up)
        root.get_node("GameInput").controller_active = true
    else:
        var up := InputEventKey.new()
        up.keycode = KEY_UP
        up.pressed = true
        menu.handle_input(up)
    assert(menu.home_items()[menu.selected][2] == "quit")
    await capture(menu,"quit-menu-"+mode)
    var event: InputEvent
    if mode == "controller":
        event = InputEventJoypadButton.new()
        event.button_index = JOY_BUTTON_A
    elif mode == "mouse":
        event = InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.position = menu.row_rect(menu.selected).get_center()
    else:
        event = InputEventKey.new()
        event.keycode = KEY_ENTER
    event.pressed = true
    print("QUIT MENU: activating ",mode)
    hud._unhandled_input(event)
    await create_timer(2).timeout
    push_error("Quit action did not close the game")
    quit(1)
