extends "res://scripts/drowned_expanded_routes_test.gd"
func check(ok: bool,label: String) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failed += 1
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/cling_campaign.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("array_inspection")
    await frames(5)
    check(scene.map_state("array_cable") == "hint","gallery hinted before entry")
    await land(130,183)
    await land(155,183,false)
    await land(210,149)
    await land(295,149,false)
    await land(375,183)
    await land(355,183,false)
    await use()
    check(scene.room_id == "array_cable","inspection upper route enters gallery")
    scene.map_open = true
    check(not scene.noise_actor.visible,"map hides enemy render layer")
    scene.map_open = false
    check(scene.noise_actor.visible,"closing map restores enemy")
    check(not scene.can_use_exit("wire_shelter"),"return remains closed before archive")
    await land(100,183)
    await land(145,149)
    await land(190,115)
    await land(230,81)
    await land(340,81,false)
    await land(420,217,false)
    check(scene.noise_actor.phase == "hang","base-jump upper bypass does not trigger CLING")
    var path: String = scene.profile.path
    scene.profile.path = path+"/blocked.json"
    await use()
    check(not scene.profile.has_flag("cable_archive") and not scene.can_use_exit("wire_shelter"),"failed save opens nothing")
    scene.profile.path = path
    await use()
    check(scene.profile.has_flag("cable_archive") and scene.can_use_exit("wire_shelter"),"archive unlocks saved return")
    await land(445,217,false)
    await use()
    check(scene.room_id == "wire_shelter","gallery connects to shelter upper landing")
    await land(355,150,false)
    await use()
    check(scene.room_id == "array_cable" and scene.player.position.x>400,"reverse entrance is outside drop lane")
    await land(295,217,false)
    check(scene.noise_actor.phase == "warning","reverse approach has same warning")
    await land(315,217,false)
    await frames(260)
    check(scene.noise_actor.phase == "hang","drop cycle returns to ceiling")
    scene.noise_actor.kill() # Defeat-state fixture; physical attacks covered by prototype observations.
    await frames(3)
    scene.enter_room("wire_shelter")
    scene.enter_room("array_cable")
    check(not is_instance_valid(scene.noise_actor),"defeat holds for current life")
    scene.respawn()
    check(is_instance_valid(scene.noise_actor) and scene.noise_actor.position.y == 112,"death re-forms CLING at ceiling")
    check(scene.profile.has_flag("cable_archive"),"death retains archive and return")
    scene.queue_free()
    await process_frame
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = path
    root.add_child(scene)
    await frames(3)
    check(scene.room_id == "array_cable" and scene.can_use_exit("wire_shelter"),"fresh scene restores room and return")
    print("CLING CAMPAIGN: %d failures"%failed)
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit(1 if failed else 0)
