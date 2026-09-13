extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/aftermath-art-%d.json" % OS.get_process_id()
    world.save_path = path
    root.add_child(world)
    world.enter_room("aftermath")
    await capture(world,"answering-town-unlit")
    assert(world.profile.set_flag("signal_restored"))
    await capture(world,"answering-town-lit")
    var before := FileAccess.get_file_as_bytes(path)
    await capture(world,"answering-town-steady")
    assert(FileAccess.get_file_as_bytes(path) == before)
    assert(world.profile.load_profile())
    world.enter_room("aftermath")
    assert(world.profile.has_flag("signal_restored"))
    assert(world.gate.aftermath_art.texture != null)
    await capture(world,"answering-town-reloaded")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("AFTERMATH ART: asset, saved restoration and read-only draw passed")
    quit()
