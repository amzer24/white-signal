extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/shutter-capture-%d.json" % OS.get_process_id()
    world.save_path = path
    root.add_child(world)
    world.enter_room("array_shutter")
    await capture(world,"shutter-upper")
    world.activate("shutter_selector")
    await capture(world,"shutter-lower")
    world.activate("shutter_archive")
    await capture(world,"shutter-copy")
    world.map_open = true
    await capture(world,"shutter-map")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
