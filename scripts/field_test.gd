extends "res://scripts/exploration_routes_test.gd"
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/field_contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("cellar")
    if scene.room_id != "cellar":
        print("FAIL: south intake room missing")
        quit(1)
        return
    await frames(5)
    await land(211,217,false)
    Input.action_press("jump")
    await frames(30)
    Input.action_release("jump")
    await frames(20)
    if not scene.profile.has_flag("south_ear"):
        failed += 1
        print("FAIL real ceiling strike did not clear intake")
    scene.enter_room("sump")
    scene.activate("field_transmit")
    if scene.profile.has_flag("field_restored"): failed += 1
    scene.profile.set_flag("west_ear")
    scene.profile.set_flag("east_ear")
    scene.activate("field_transmit")
    if not scene.profile.has_flag("field_restored"): failed += 1
    scene.respawn()
    scene.profile.load_profile()
    scene.enter_room("cellar")
    if not scene.profile.has_flag("south_ear") or not scene.profile.has_flag("field_restored"): failed += 1
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/field_contract.json"+suffix)
    print("FIELD: %d failures" % failed)
    quit(1 if failed else 0)
