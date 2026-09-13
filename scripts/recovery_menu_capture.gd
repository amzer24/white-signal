extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var main = load("res://scenes/main.tscn").instantiate()
    root.add_child(main)
    var menu = main.get_node("HUDLayer/HUD").menu_ui
    menu.page = "recovery_confirm"
    menu.selected = 0
    await capture(menu,"recovery-confirmation")
    menu.page = "recovery_done"
    menu.recovery_message = "FRESH JOURNEY READY . ORIGINALS RETAINED"
    await capture(menu,"recovery-result")
    main.queue_free()
    await process_frame
    quit()
