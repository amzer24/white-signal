extends SceneTree

func _initialize() -> void:
    run.call_deferred()

func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event

func run() -> void:
    for mode in ["keyboard", "mouse", "controller"]:
        assert(change_scene_to_file("res://scenes/main.tscn") == OK)
        await scene_changed
        await process_frame
        var hud = current_scene.find_child("*", true, false)
        for node in current_scene.find_children("*", "Node2D", true, false):
            if node.get_script() == load("res://scripts/hud.gd"):
                hud = node
                break
        assert(hud.get_script() == load("res://scripts/hud.gd"))
        root.get_node("RunState").state = "menu"
        hud.menu_ui.selected = 0
        var viewport := hud.get_viewport()
        var event: InputEvent = key(KEY_ENTER)
        if mode == "mouse":
            var click := InputEventMouseButton.new()
            click.button_index = MOUSE_BUTTON_LEFT
            click.pressed = true
            click.position = hud.menu_ui.row_rect(0).get_center()
            event = click
        elif mode == "controller":
            var button := InputEventJoypadButton.new()
            button.button_index = JOY_BUTTON_A
            button.pressed = true
            event = button
        hud._unhandled_input(event)
        # change_scene detaches the old scene synchronously; its viewport is gone.
        assert(not hud.is_inside_tree())
        assert(viewport.is_input_handled())
        await scene_changed
        assert(current_scene.scene_file_path == "res://scenes/exploration.tscn")
        current_scene._unhandled_input(key(KEY_ESCAPE))
        current_scene._unhandled_input(key(KEY_Q))
        await scene_changed
        assert(current_scene.scene_file_path == "res://scenes/main.tscn")
        print("MENU TRANSITION: ", mode, " exploration and return passed")
    quit()
