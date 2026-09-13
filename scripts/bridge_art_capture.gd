extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/bridge-art-%d.json" % OS.get_process_id()
    root.add_child(world)
    world.enter_room("stand_bridge")
    assert(world.Guidance.goal(world).begins_with("BRIDGE UNPOWERED"))
    world.player.set_physics_process(false)
    world.stand.weather_time = 3
    await capture(world,"bridge-unpowered")
    assert(world.profile.set_flag("stand_restored"))
    assert(world.Guidance.goal(world).begins_with("THE BRIDGE HOLDS"))
    world.enter_room("stand_bridge")
    world.player.set_physics_process(false)
    world.stand.weather_time = 3
    await capture(world,"bridge-restored")
    root.get_node("AppSettings").reduced_flashes = true
    await capture(world,"bridge-reduced")
    var path: String = world.save_path
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
