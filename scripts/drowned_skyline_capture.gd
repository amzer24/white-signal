extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/drowned-skyline-%d.json" % OS.get_process_id()
    root.add_child(world)
    world.enter_room("drowned_street")
    world.set_physics_process(false)
    world.player.set_physics_process(false)
    for x in [8,472,8]:
        world.player.position.x = x
        await capture(world,"drowned-skyline-"+str(x))
    world.profile.set_flag("drowned_restored")
    await capture(world,"drowned-skyline-restored")
    var path: String = world.save_path
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
