extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/stand-power-%d.json" % OS.get_process_id()
    root.add_child(world)
    world.paused = true
    root.get_node("AppSettings").reduced_flashes = true
    for powered in [false,true]:
        if powered: assert(world.profile.set_flag("stand_restored"))
        for id in ["shelter","stand_bridge","conductor"]:
            world.enter_room(id)
            world.player.set_physics_process(false)
            world.stand.weather_time = 3
            world.paused = false # hide pause overlay, keep the fixture frame stationary
            await capture(world,"stand-power-"+id+("-on" if powered else "-off"))
    var path: String = world.save_path
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
