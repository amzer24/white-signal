extends "res://scripts/drowned_expanded_routes_test.gd"
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/wire_shaft_campaign.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    await frames(5)
    scene.enter_room("wire_shelter")
    await frames(3)
    await land(120,217,false)
    await use()
    if scene.room_id != "wire_shaft": failed += 1
    await land(228,217,false)
    Input.action_press("jump")
    var direction := 1
    var cooldown := 0
    var kick_count := 0
    var escaped := false
    for i in 600:
        cooldown -= 1
        if scene.player.position.y < 48: escaped = true
        if escaped: steer(310)
        else:
            Input.action_release("move_left")
            Input.action_release("move_right")
            Input.action_press("move_right" if direction > 0 else "move_left")
            if scene.player.is_on_wall() and cooldown <= 0:
                Input.action_release("jump")
                await physics_frame
                Input.action_press("jump")
                direction *= -1
                cooldown = 10
                kick_count += 1
        await physics_frame
        if escaped and scene.player.is_on_floor() and scene.player.position.x > 290: break
    Input.action_release("jump")
    Input.action_release("move_left")
    Input.action_release("move_right")
    print("CLIMB position=",scene.player.position," kicks=",kick_count," escaped=",escaped)
    if not escaped or absf(scene.player.position.y-59)>5: failed += 1
    await land(400,59,false)
    var save_path: String = scene.profile.path
    scene.profile.path = save_path+"/blocked.json"
    await use()
    if scene.profile.has_flag("wire_shaft_archive") or scene.room.platforms.size() != 4: failed += 1
    scene.profile.path = save_path
    await use()
    if not scene.profile.has_flag("wire_shaft_archive"): failed += 1
    scene.respawn()
    await frames(3)
    if not scene.profile.has_flag("wire_shaft_released"): failed += 1
    await land(70,217,false)
    await use()
    await land(125,217,false)
    await use()
    await frames(30)
    scene.paused = true
    root.get_node("RunState").state = "pause"
    var stopped: float = scene.network.shaft.y
    await frames(30)
    if scene.network.shaft.y != stopped: failed += 1
    scene.paused = false
    root.get_node("RunState").state = "play"
    await frames(230)
    print("LIFT rider=",scene.player.position," surface=",scene.network.shaft.y)
    if absf(scene.player.position.y-59)>5: failed += 1
    await land(300,59,false)
    await land(400,59,false)
    await use()
    if scene.room.platforms.size() != 5: failed += 1
    await land(125,59,false)
    await use()
    await frames(240)
    if absf(scene.player.position.y-217)>5: failed += 1
    await land(40,217,false)
    print("REVERSE RETURN position=",scene.player.position)
    await land(27,217,false)
    await use()
    if scene.room_id != "wire_shelter": failed += 1
    scene.enter_room("wire_shaft")
    if scene.room.platforms.size() != 5: failed += 1
    if not scene.profile.load_profile() or not scene.profile.has_flag("wire_shaft_archive"): failed += 1
    var restored = load("res://scenes/exploration.tscn").instantiate()
    restored.save_path = scene.save_path
    scene.queue_free()
    await process_frame
    scene = restored
    root.add_child(scene)
    await frames(3)
    if scene.room_id != "wire_shaft" or scene.room.platforms.size() != 5 or scene.network.shaft.y != 224: failed += 1
    print("WIRE SHAFT CAMPAIGN: %d missed observations" % failed)
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/wire_shaft_campaign.json"+suffix)
    quit(1 if failed else 0)
