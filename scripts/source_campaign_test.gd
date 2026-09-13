extends "res://scripts/opening_playthrough_test.gd"
func run() -> void:
    fixture_path = "res://test-user/source-campaign-%d.json" % OS.get_process_id()
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = fixture_path
    root.add_child(scene)
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored","dash","air_jump"]:
        scene.profile.set_flag(flag)
    scene.enter_room("gate")
    await frames(5)
    await finale_controls()
    require_room("aftermath")
    if not scene.profile.has_flag("signal_restored"): failed += 1
    scene.enter_room("gate")
    if scene.room.platforms.size() != 7: failed += 1
    scene.enter_room("source_return")
    if scene.room.platforms.size() != 5: failed += 1
    scene.respawn()
    if not scene.can_use_exit("source_walk"): failed += 1
    print("SOURCE CAMPAIGN: %d failures" % failed)
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture_path+suffix)
    quit(1 if failed else 0)
