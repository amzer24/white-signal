extends "res://scripts/exploration_routes_test.gd"
func use_control() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_E
    event.pressed = true
    Input.parse_input_event(event)
    await frames(2)
    event = InputEventKey.new()
    event.keycode = KEY_E
    Input.parse_input_event(event)
    await frames(3)

func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/siphon-contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("pump")
    if scene.can_use_exit("siphon"): failed += 1
    scene.profile.set_flag("pump_repaired")
    await frames(5)
    await land(82,217,false)
    await land(140,181)
    await land(161,181,false)
    await land(218,148)
    await land(284,148,false)
    await use_control()
    if scene.room_id != "siphon":
        print("FAIL pump entrance did not reach Siphon")
        quit(1)
        return
    await frames(5)
    await land(240,167)
    await land(207,167,false)
    await land(145,141)
    await land(110,99)
    await use_control()
    print("Archive reached: ",scene.profile.has_flag("siphon_archive"))
    await land(212,167)
    await land(240,167,false)
    await use_control()
    await frames(190)
    await land(273,167,false)
    await land(340,141)
    await land(370,99)
    await use_control()
    print("Float pinned: ",scene.siphon.caught," shortcut still closed: ",not scene.profile.has_flag("siphon_return"))
    await land(270,167)
    await land(240,167,false)
    await use_control()
    await frames(190)
    print("Right basin drained: ",scene.siphon.levels[1]," held float: ",scene.siphon.floats[1].position.y)
    await land(273,167,false)
    await land(340,141)
    await land(370,99)
    await land(427,213,false)
    await land(406,213,false)
    await use_control()
    print("Return latched: ",scene.profile.has_flag("siphon_return"))
    scene.respawn()
    await frames(5)
    await land(240,167)
    await land(293,136)
    await land(322,99)
    await land(370,99)
    print("Route landing failures: ",failed)
    print("After recovery: archive=",scene.profile.has_flag("siphon_archive")," stair=",scene.profile.has_flag("siphon_return"))
    if not scene.profile.has_flag("siphon_archive") or not scene.profile.has_flag("siphon_return"): failed += 1
    if not scene.can_use_exit("lookout"): failed += 1
    await land(330,99,false)
    await use_control()
    if scene.room_id != "lookout":
        print("FAIL Siphon shortcut exit")
        failed += 1
    else:
        await land(245,147,false)
        await use_control()
        if scene.room_id != "siphon":
            failed += 1
            print("FAIL lookout reverse shortcut")
    if not scene.profile.load_profile(): failed += 1
    scene.enter_room("siphon")
    if not scene.can_use_exit("lookout") or scene.siphon.caught: failed += 1
    scene.respawn()
    await frames(5)
    await use_control()
    if scene.room_id != "pump":
        failed += 1
        print("FAIL dry dock return to pump")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/siphon-contract.json"+suffix)
    print("SIPHON CAMPAIGN: %d failures" % failed)
    quit(1 if failed else 0)
