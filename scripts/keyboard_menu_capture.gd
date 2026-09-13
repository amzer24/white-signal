extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var main = load("res://scenes/main.tscn").instantiate()
    root.add_child(main)
    var menu = main.get_node("HUDLayer/HUD").menu_ui
    menu.page = "keyboard"
    menu.selected = 2
    await capture(menu,"keyboard-page")
    var controls = root.get_node("GameInput").keyboard
    controls.begin_capture("jump")
    var event := InputEventKey.new()
    event.physical_keycode = KEY_A
    event.pressed = true
    controls.capture(event)
    await capture(menu,"keyboard-conflict")
    controls.capturing = ""
    menu.page = "settings"
    await capture(menu,"keyboard-settings")
    quit()
