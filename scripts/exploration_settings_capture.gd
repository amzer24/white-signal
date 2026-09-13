extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    var fixture := "res://test-user/settings-render-%d.json" % OS.get_process_id()
    world.save_path = fixture
    root.add_child(world)
    world.paused = true
    root.get_node("RunState").state = "pause"
    await capture(world,"exploration-pause-settings")
    world.settings_menu.open_settings()
    await capture(world,"exploration-settings-overlay")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture+suffix)
    quit()
