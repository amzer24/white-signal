extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/pending-map-%d.json" % OS.get_process_id()
    world.save_path = path
    root.add_child(world)
    for id in ["wire_shaft","wire_shelter","wire_carriage","array","array_inspection","array_cable","array_shutter","stand_bridge","drowned_dock"]:
        world.profile.enter_room(id)
    world.profile.set_flags({"brake_spare":true,"diagnostic_seen":true})
    world.enter_room("array")
    world.map_open = true
    await capture(world,"pending-network-map")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
