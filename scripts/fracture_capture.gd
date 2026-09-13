extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/fracture-capture-%d.json" % OS.get_process_id()
    root.add_child(world)
    world.enter_room("stand_trial")
    world.player.set_physics_process(false)
    await capture(world,"fracture-refuge-layout")
    world.player.position = Vector2(240,217)
    world.stand.crumble[1].gone = true
    await capture(world,"fracture-refuge-recovery")
    var path: String = world.save_path
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
