extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
    if not value:
        failures += 1
        print("FAIL ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/stand_expanded.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(world.save_path+suffix)
    root.add_child(world)
    check(world.stand_map_exits().is_empty(),"fresh map does not reveal Stand exits")
    world.enter_room("stand_rim")
    check(world.stand_map_exits() == "RIM: ?","discovered departure hints without destination spoiler")
    world.enter_room("return")
    check(world.stand_map_exits() == "RIM: FIELD","visited destination names district connection")
    world.enter_room("stand_charge")
    world.activate("storm_charge")
    world.stand.tick(3.1)
    world.enter_room("conductor","stand_charge")
    check(world.stand.charge == 1,"charge held across rooms")
    world.activate("storm_divert")
    world.stand.tick(1.6)
    var working_path: String = world.profile.path
    world.profile.path = working_path+"/blocked.json" # parent is an existing file
    world.stand.tick(0.4)
    check(not world.profile.has_flag("stand_restored"),"failed save does not grant feeder")
    check(not world.can_use_exit("stand_bridge"),"failed save keeps bridge exit closed")
    check(world.stand.phase == "ready" and world.stand.charge == 1,"failed save preserves retry charge")
    world.profile.path = working_path
    world.activate("storm_divert")
    world.stand.tick(1.6)
    world.stand.tick(0.4)
    check(world.profile.has_flag("stand_restored"),"motor saved latch")
    check(world.can_use_exit("stand_bridge"),"new bridge exit open")
    world.enter_room("stand_bridge","conductor")
    check(is_instance_valid(world.stand.bridge),"bridge collision built")
    world.enter_room("stand_trial")
    check(world.stand.crumble.size() == 3,"trial platforms built")
    world.profile.path = working_path+"/blocked.json"
    world.activate("stand_archive")
    check(not world.profile.has_flag("stand_archive") and not is_instance_valid(world.stand.bridge),"failed archive save keeps bypass absent")
    world.profile.path = working_path
    world.activate("stand_archive")
    check(world.profile.has_flag("stand_archive") and is_instance_valid(world.stand.bridge),"archive commits bypass")
    world.respawn()
    check(world.stand.charge == 0 and world.profile.has_flag("stand_archive"),"death clears temporary state only")
    check(world.profile.load_profile(),"new room IDs reload")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/stand_expanded.json"+suffix)
    for old_room in ["shelter","conductor"]:
        var fixture := "res://test-user/stand_legacy_fixture.json"
        var file := FileAccess.open(fixture,FileAccess.WRITE)
        file.store_string(JSON.stringify({"version":1,"room":old_room,"visited":["shelter","conductor"],"flags":{"stand_restored":true,"dash":true}}))
        file.close()
        var resumed = load("res://scenes/exploration.tscn").instantiate()
        resumed.save_path = fixture
        root.add_child(resumed)
        check(resumed.room_id == old_room,"old room ID resumes safely")
        check(resumed.profile.has_flag("stand_restored"),"old completed repair retained")
        resumed.enter_room("stand_bridge")
        check(is_instance_valid(resumed.stand.bridge),"old latch builds expanded bridge")
        check(resumed.can_use_exit("wire_shelter"),"old Dash and latch retain Wire access")
        resumed.queue_free()
        await process_frame
        for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture+suffix)
    print("EXPANDED STAND: %d failures" % failures)
    quit(1 if failures else 0)
