extends "res://scripts/drowned_expanded_routes_test.gd"
func check(ok: bool,label: String) -> void:
    if not ok:
        failed += 1
        print("FAIL ",label)
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/inspection_campaign.json"
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+s)
    root.add_child(scene)
    scene.profile.set_flag("dash")
    scene.enter_room("array")
    await frames(5)
    await land(75,183)
    await land(100,183,false)
    await land(170,149)
    await land(185,149,false)
    await use()
    check(scene.room_id == "array_inspection","Array stairs enter optional bay")
    await land(130,183)
    await land(155,183,false)
    await land(210,149)
    await land(295,149,false)
    await land(375,183)
    await land(420,183,false)
    var path: String = scene.profile.path
    scene.profile.path = path+"/blocked.json"
    await use()
    check(not scene.profile.has_flag("inspection_archive"),"failed archive save grants nothing")
    scene.profile.path = path
    await use()
    check(scene.profile.has_flag("inspection_archive") and is_instance_valid(scene.noise_actor),"archive can be saved without killing NOISE")
    scene._controller_lost()
    await frames(3)
    var at: Vector2 = scene.noise_actor.position
    await frames(15)
    check(scene.noise_actor.position == at,"controller pause freezes patrol")
    var e := InputEventKey.new()
    e.keycode = KEY_ESCAPE
    e.pressed = true
    scene._unhandled_input(e)
    await land(330,217,false)
    var dashed := false
    for i in 240:
        if not is_instance_valid(scene.noise_actor): break
        steer(scene.noise_actor.position.x)
        if not dashed and absf(scene.player.position.x-scene.noise_actor.position.x)<39:
            Input.action_press("dash")
            dashed = true
        await physics_frame
    Input.action_release("dash")
    Input.action_release("move_left")
    Input.action_release("move_right")
    check(not is_instance_valid(scene.noise_actor) and scene.noise_cleared.has("array_inspection"),"dash records defeat for current life")
    await land(110,217,false)
    await land(27,217,false)
    await use()
    check(scene.room_id == "array","bay has safe unconditional return")
    await land(185,149,false)
    await use()
    check(scene.room_id == "array_inspection" and not is_instance_valid(scene.noise_actor),"same-life revisit keeps NOISE defeated")
    scene.respawn()
    check(is_instance_valid(scene.noise_actor) and scene.player.position.x < 80,"death re-forms patrol away from safe entry")
    check(scene.profile.has_flag("inspection_archive"),"death retains archive")
    check(scene.profile.load_profile() and scene.profile.has_flag("inspection_archive"),"archive reloads")
    print("INSPECTION CAMPAIGN: %d failures" % failed)
    scene.queue_free()
    await process_frame
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/inspection_campaign.json"+s)
    quit(1 if failed else 0)
