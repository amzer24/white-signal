extends "res://scripts/exploration_routes_test.gd"
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/network_routes.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("wire_shelter")
    await frames(5)
    await land(73,217,false)
    await land(122,183)
    await land(155,183,false)
    await land(231,150)
    scene.activate("brake_spare")
    scene.enter_room("wire_carriage")
    await frames(5)
    await land(69,217,false)
    scene.activate("brake_socket")
    await land(145,199)
    scene.activate("carriage_send")
    await frames(260)
    if absf(scene.player.position.x-345) > 15 or scene.player.position.y > 204:
        failed += 1
        print("FAIL right carriage ride ",scene.player.position)
    await land(395,217,false)
    scene.activate("carriage_summon_right")
    await land(350,199)
    scene.activate("carriage_send")
    await frames(260)
    if absf(scene.player.position.x-150) > 15:
        failed += 1
        print("FAIL left carriage ride ",scene.player.position)
    scene.enter_room("array","wire_carriage")
    await frames(5)
    await land(250,217,false)
    await land(109,217,false)
    scene.activate("array_test")
    await frames(130)
    await land(244,217,false)
    scene.activate("array_isolate")
    await land(374,217,false)
    scene.activate("array_bypass")
    if not scene.profile.has_flag("array_restored"): failed += 1
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/network_routes.json"+suffix)
    print("NETWORK ROUTES: %d failures" % failed)
    quit(1 if failed else 0)
