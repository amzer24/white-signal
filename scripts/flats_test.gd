extends "res://scripts/exploration_routes_test.gd"
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/flats_contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    if scene.room_id != "flats":
        print("FAIL: new exploration does not begin in Flats")
        quit(1)
        return
    await frames(5)
    await land(211,217,false)
    Input.action_press("jump")
    await frames(30)
    Input.action_release("jump")
    await frames(20)
    if not scene.profile.has_flag("intro_memory"): failed += 1
    scene.enter_room("conduit","flats")
    await frames(5)
    if scene.can_use_exit("arrival"): failed += 1
    await land(211,217,false)
    scene.activate("conduit_switch")
    if not scene.can_use_exit("arrival"): failed += 1
    if absf(scene.player.position.x-355) > 1: failed += 1
    scene.activate("conduit_return")
    if absf(scene.player.position.x-211) > 1: failed += 1
    scene.activate("conduit_switch")
    scene.enter_room("arrival","conduit")
    await frames(5)
    await land(240,217,false)
    scene.activate("first_beacon")
    scene.respawn()
    if scene.player.position != Vector2(240,215): failed += 1
    scene.enter_room("hub","arrival")
    if scene.room_id != "hub": failed += 1
    scene.respawn()
    scene.profile.load_profile()
    if not scene.profile.has_flag("first_beacon") or scene.profile.data.room != "hub": failed += 1
    scene.queue_free()
    await process_frame
    # Existing v1 hub profiles must remain valid and keep their current room.
    var old_profile = load("res://scripts/exploration_save.gd").new()
    old_profile.path = "res://test-user/flats_contract.json"
    var file := FileAccess.open(old_profile.path,FileAccess.WRITE)
    file.store_string('{"version":1,"room":"hub","visited":["hub"],"flags":{"dash":true}}')
    file.close()
    if not old_profile.load_profile() or old_profile.data.room != "hub" or not old_profile.has_flag("dash"): failed += 1
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/flats_contract.json"+suffix)
    print("FLATS: %d failures" % failed)
    quit(1 if failed else 0)
