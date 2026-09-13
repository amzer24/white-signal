extends "res://scripts/exploration_routes_test.gd"
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/fracture-route-%d.json" % OS.get_process_id()
    root.add_child(scene)
    scene.enter_room("stand_trial")
    await frames(4)
    await land(72,217,false)
    await land(150,185)
    await land(166,185,false)
    await land(240,155)
    # Deliberately let the high rib fall: the lower shelter should catch us.
    await frames(95)
    if not scene.player.is_on_floor() or absf(scene.player.position.y-217)>4 or absf(scene.player.position.x-240)>8:
        failed += 1
        print("FAIL lower shelter recovery: ",scene.player.position)
    if scene.profile.has_flag("stand_archive"):
        failed += 1
        print("FAIL refuge must not grant archive")
    if failed:
        print("FRACTURE ROUTES: %d failures" % failed)
        quit(1)
        return
    await land(264,217,false)
    await land(344,185)
    await land(434,217)
    var event := InputEventKey.new()
    event.keycode = KEY_E
    event.pressed = true
    Input.parse_input_event(event)
    await frames(3)
    if not scene.profile.has_flag("stand_archive"): failed += 1
    await land(275,217,false)
    await land(130,217,false)
    await land(27,217,false)
    event = InputEventKey.new()
    event.keycode = KEY_E
    event.pressed = true
    Input.parse_input_event(event)
    await frames(3)
    if scene.room_id != "conductor": failed += 1
    var path: String = scene.save_path
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("FRACTURE ROUTES: %d failures" % failed)
    quit(1 if failed else 0)
