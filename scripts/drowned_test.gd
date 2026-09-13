extends SceneTree
var failed := 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failed += 1
        print("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    if not FileAccess.file_exists("res://scripts/drowned_mechanism.gd"):
        print("FAIL: Drowned mechanism is missing")
        quit(1)
        return
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/drowned_contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    await process_frame
    scene.enter_room("basin")
    check(scene.room_id == "basin", "Drowned accepts an existing exploration profile")
    check(scene.drowned.water_y == 160, "first basin entry is flooded")
    scene.enter_room("pump")
    scene.activate("pump_socket")
    check(not scene.profile.has_flag("pump_repaired"), "missing impeller cannot repair pump")
    check(not scene.can_use_exit("float"), "unpowered float chamber is gated")
    scene.enter_room("basin")
    scene.activate("impeller")
    check(not scene.profile.has_flag("impeller"), "flooded impeller cannot be collected")
    scene.activate("bleed")
    check(scene.drowned.target_y == 198, "manual bleed reaches marked middle without impeller")
    scene.activate("bleed")
    check(scene.drowned.target_y == 246, "manual bleed reaches low without impeller")
    scene.drowned.water_y = 246
    scene.enter_room("drowned_street")
    scene.activate("impeller")
    check(scene.profile.has_flag("impeller"), "dry street yields impeller")
    scene.respawn()
    check(scene.drowned.water_y == 246 and scene.profile.has_flag("impeller"), "death resets safely and retains recovered part")
    scene.drowned.water_y = 160
    scene.drowned.target_y = 160
    scene.player.position = Vector2(250,180)
    scene.drowned.tick(0)
    check(scene.player.position == scene.room.spawn and scene.drowned.water_y == 246, "static water returns player to safe dry spawn")
    scene.enter_room("pump")
    scene.activate("pump_socket")
    check(scene.profile.has_flag("pump_repaired"), "impeller repairs pump")
    scene.enter_room("drowned_gallery")
    scene.activate("air_jump")
    scene.enter_room("float")
    scene.activate("float_valve")
    check(scene.drowned.target_y == 180, "repaired pump powers float middle setting")
    scene.activate("float_valve")
    check(scene.drowned.target_y == 152, "second setting raises float to high")
    scene.player.position = Vector2(209,145)
    scene.drowned.water_y = 152
    scene.drowned.tick(0)
    check(scene.player.position == Vector2(209,145), "high water leaves control landing safe")
    scene.activate("float_latch")
    check(scene.profile.has_flag("drowned_restored"), "return latch completes Drowned feeder")
    scene.activate("air_jump")
    scene.respawn()
    check(root.get_node("RunState").mods.air_jumps == 1, "Air Jump survives death")
    scene.enter_room("pump")
    check(scene.can_use_exit("float"), "latched return opens short pump loop")
    check(scene.profile.load_profile(), "Drowned profile reloads")
    check(scene.profile.has_flag("pump_repaired") and scene.profile.has_flag("drowned_restored"), "repair survives reload")
    scene.enter_room("basin")
    check(scene.drowned.water_y == 246, "repaired service street remains dry")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/drowned_contract.json"+suffix)
    print("DROWNED: %d failures" % failed)
    quit(1 if failed else 0)
