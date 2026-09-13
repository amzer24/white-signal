extends "res://scripts/exploration_routes_test.gd"
func use_control() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_E
    event.pressed = true
    scene._unhandled_input(event)
    await frames(2)
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/fourth-route-%d.json" % OS.get_process_id()
    root.add_child(scene)
    scene.profile.set_flags({"dash":true,"amplifier_training":true,"amplifier_released":true})
    scene.enter_room("amplifier")
    if scene.can_use_exit("fourth"): failed += 1
    scene.profile.set_flag("air_jump")
    scene._sync_abilities()
    await frames(5)
    await land(180,217,false)
    await land(280,217,false)
    await land(290,183)
    await land(334,149)
    await land(385,149,false)
    Input.action_press("jump")
    await frames(20)
    Input.action_release("jump")
    await frames(2)
    Input.action_press("jump")
    await frames(45)
    Input.action_release("jump")
    if absf(scene.player.position.y-58)>5:
        failed += 1
        print("FAIL upper shelf ",scene.player.position)
    await use_control()
    if scene.room_id != "fourth":
        failed += 1
        print("FAIL actual Fourth exit ",scene.room_id)
    else:
        await land(130,183)
        await land(170,183,false)
        await land(220,150)
        await land(250,150,false)
        await use_control()
        if not scene.profile.has_flag("fourth_archive"): failed += 1
        if scene.profile.has_flag("field_restored"): failed += 1
        scene.respawn()
        scene.activate("fourth_memory")
        if scene.memory_time <= 0: failed += 1
        await land(90,217,false)
        await land(130,183)
        await land(27,217,false)
        await use_control()
        if scene.room_id != "amplifier": failed += 1
        await land(460,149,false)
        if not scene.profile.load_profile() or not scene.profile.has_flag("fourth_archive"): failed += 1
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    print("FOURTH ROUTE: ",failed," failures")
    quit(failed)
