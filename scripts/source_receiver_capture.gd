extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/receiver-art-%d.json" % OS.get_process_id()
    world.save_path = path
    root.add_child(world)
    world.enter_room("gate")
    await capture(world,"source-receiver-unlit")
    assert(world.profile.set_flag("field_restored"))
    assert(world.profile.set_flag("drowned_restored"))
    await capture(world,"source-receiver-partial")
    assert(world.profile.set_flag("stand_restored"))
    assert(world.profile.set_flag("array_restored"))
    world.activate("gate_latch")
    assert(world.profile.has_flag("gate_latched"))
    var before := FileAccess.get_file_as_bytes(path)
    await capture(world,"source-receiver-held")
    assert(FileAccess.get_file_as_bytes(path) == before)
    assert(world.profile.load_profile())
    world.enter_room("gate")
    await capture(world,"source-receiver-reloaded")
    world.queue_free()
    await process_frame
    for i in 20:
        OS.delay_msec(10)
        await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("SOURCE RECEIVER: partial/full flags, latch, reload and read-only draw passed")
    quit()
