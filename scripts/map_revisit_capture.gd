extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/map-revisit-capture-%d.json" % OS.get_process_id()
    root.add_child(world)
    world.enter_room("amplifier")
    world.map_open = true
    root.get_node("RunState").state = "pause"
    await capture(world,"map-revisit-gated")
    world.profile.set_flag("air_jump")
    await capture(world,"map-revisit-reachable")
    var path: String = world.save_path
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
