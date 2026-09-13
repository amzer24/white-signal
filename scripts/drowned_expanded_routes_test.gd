extends "res://scripts/exploration_routes_test.gd"
## Integrated Drowned route: actual movement and interactions, isolated profile.
func use() -> void:
    var e := InputEventKey.new()
    e.keycode = KEY_E
    e.pressed = true
    Input.parse_input_event(e)
    await frames(3)
    e = InputEventKey.new()
    e.keycode = KEY_E
    e.pressed = false
    Input.parse_input_event(e)
    await frames(3)
func air_land(x: float,y: float) -> void:
    Input.action_press("jump")
    for i in 105:
        if i == 15: Input.action_release("jump")
        if i == 19: Input.action_press("jump")
        steer(x)
        await physics_frame
        if i > 25 and scene.player.is_on_floor() and absf(scene.player.position.x-x)<8 and absf(scene.player.position.y-y)<5: break
    Input.action_release("jump")
    Input.action_release("move_left")
    Input.action_release("move_right")
    if absf(scene.player.position.y-y)>5:
        failed += 1
        print("MISSED AIR LANDING ",scene.player.position)
    await frames(4)
func land(x: float, y: float, jump := true) -> void:
    Input.action_release("jump")
    await frames(2)
    if jump: Input.action_press("jump")
    var reached := false
    for i in 180:
        steer(x)
        await physics_frame
        if i > 15 and scene.player.is_on_floor() and absf(scene.player.position.x-x) < 8 and absf(scene.player.position.y-y) < 5:
            reached = true
            break
    Input.action_release("jump")
    Input.action_release("move_left")
    Input.action_release("move_right")
    if not reached:
        failed += 1
        print("FAIL landing ",Vector2(x,y)," from actual ",scene.player.position)
    await frames(3)
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/drowned_expanded_route.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("basin")
    await frames(5)
    await land(80,115,false)
    await use()
    await use()
    await frames(180)
    await land(140,217,false)
    await land(260,217,false)
    await use()
    print("DESCENT: ",scene.room_id," water=",scene.drowned.water_y)
    await land(210,217,false)
    await land(340,217,false)
    await land(265,217,false)
    await use()
    await land(445,217,false)
    await use()
    await land(75,217,false)
    await use()
    await land(140,183)
    await land(165,183,false)
    await air_land(270,113)
    await land(420,113,false)
    print("GALLERY: air=",scene.profile.has_flag("air_jump")," landing=",scene.player.position)
    await land(220,217,false)
    await land(27,217,false)
    await use()
    await land(250,217,false)
    await land(260,183)
    await land(240,183,false)
    await land(180,149)
    await land(145,149,false)
    await land(80,115)
    await land(30,115,false)
    await use()
    await land(250,183)
    await land(195,149)
    await land(200,115)
    await land(238,115,false)
    await land(315,115)
    await land(336,115,false)
    await land(425,115)
    await land(445,115,false)
    await use()
    await land(135,183)
    await land(160,183,false)
    await land(240,149)
    await use()
    print("DRY RETURN: room=",scene.room_id," part=",scene.profile.has_flag("impeller")," air=",scene.profile.has_flag("air_jump")," repaired=",scene.profile.has_flag("pump_repaired"))
    await land(160,183,false)
    await land(27,217,false)
    await use()
    await land(360,217,false)
    await land(260,217,false)
    await use()
    await land(210,217,false)
    await land(445,217,false)
    await use()
    await land(140,183)
    await land(165,183,false)
    await air_land(270,113)
    await land(435,113,false)
    await use()
    await land(130,183)
    await land(153,183,false)
    await land(207,149)
    await use()
    await use()
    await frames(135)
    await land(238,149,false)
    await land(290,131)
    await air_land(380,61)
    await use()
    await land(438,61,false)
    await use()
    print("UPPER RETURN: room=",scene.room_id," latch=",scene.profile.has_flag("drowned_restored")," water=",scene.drowned.water_y)
    if scene.room_id != "pump" or not scene.profile.has_flag("drowned_restored"): failed += 1
    print("DROWNED INTEGRATED ROUTE: %d missed landings" % failed)
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/drowned_expanded_route.json"+suffix)
    quit(1 if failed else 0)

