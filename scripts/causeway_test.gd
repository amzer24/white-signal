extends "res://scripts/exploration_routes_test.gd"
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/causeway_contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("causeway")
    scene.activate("ear_transmit")
    if scene.can_use_exit("return"): failed += 1
    await frames(5)
    await land(72,217,false)
    await land(120,183)
    scene.activate("dish_0")
    scene.activate("dish_0")
    await land(154,183,false)
    await land(216,149)
    scene.activate("dish_1")
    await land(247,149,false)
    await land(323,183)
    for i in 3: scene.activate("dish_2")
    await land(388,217,false)
    scene.activate("ear_transmit")
    if not scene.profile.has_flag("east_ear") or not scene.can_use_exit("return"):
        failed += 1
        print("FAIL alignment completion")
    scene.respawn()
    if not scene.alignment.locked: failed += 1
    scene.profile.load_profile()
    scene.enter_room("causeway")
    if not scene.alignment.is_aligned() or not scene.alignment.locked: failed += 1
    scene.enter_room("return","causeway")
    await frames(5)
    if not scene.can_use_exit("causeway") or scene.player.position.y > 225: failed += 1
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/causeway_contract.json"+suffix)
    print("CAUSEWAY: %d failures" % failed)
    quit(1 if failed else 0)
