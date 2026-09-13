extends SceneTree
var failures := 0
var path := "res://test-user/source-reconstruction-%d.json" % OS.get_process_id()
func check(ok: bool, label: String) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func _initialize() -> void: call_deferred("run")
func cleanup() -> void:
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
func run() -> void:
    for stage in ["gate_latched","gate_isolated","gate_tested","signal_restored"]:
        cleanup()
        var saved = load("res://scripts/exploration_save.gd").new()
        saved.path = path
        saved.data = {"version":1,"room":"gate","visited":["flats","gate"],"flags":{stage:true}}
        check(saved.save_profile(),"write legacy fixture "+stage)
        var scene = load("res://scenes/exploration.tscn").instantiate()
        scene.save_path = path
        root.add_child(scene)
        check(scene.room_id == "gate" and scene.room.platforms.size() == 7,"legacy stage restores return stairs "+stage)
        check(scene.profile.data.flags == {stage:true},"legacy prerequisites do not rewrite flags "+stage)
        if stage == "signal_restored":
            var direct := false
            for route in scene.room.exits:
                if route[0] == "aftermath" and route[1].y == 217: direct = true
            check(direct and scene.can_use_exit("aftermath"),"completed old save retains floor exit")
        scene.enter_room("source_return")
        check(scene.room.platforms.size() == (5 if stage in ["gate_tested","signal_restored"] else 4),"bridge reconstructed from saved stage "+stage)
        scene.queue_free()
        await process_frame
    cleanup()
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = path
    root.add_child(scene)
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored","gate_latched"]: scene.profile.set_flag(flag)
    scene.enter_room("source_return")
    scene.activate("gate_isolate")
    scene.map_open = true
    scene.gate.tick(5)
    check(scene.gate.test_time == 1.5,"scene map freezes verification")
    scene.map_open = false
    scene.respawn()
    check(scene.gate.test_time == 0 and scene.room.platforms.size() == 4,"scene death cancels without bridge")
    scene.activate("gate_isolate")
    scene.enter_room("gate")
    check(scene.gate.test_time == 0,"scene exit cancels verification")
    scene.enter_room("source_return")
    scene.profile.path = "res://test-user/nonexistent-source-save/profile.json"
    scene.activate("gate_isolate")
    scene.gate.tick(2)
    check(scene.room.platforms.size() == 4 and not scene.can_use_exit("source_walk"),"failed diagnostic keeps collision bridge and exit closed")
    scene.profile.path = path
    scene.activate("gate_isolate")
    scene.gate.tick(2)
    check(scene.room.platforms.size() == 5 and scene.can_use_exit("source_walk"),"retry deploys bridge and opens exit")
    scene.queue_free()
    await process_frame
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = path
    root.add_child(scene)
    check(scene.room_id == "source_return" and scene.room.platforms.size() == 5,"new room and bridge survive scene reload")
    scene.queue_free()
    await process_frame
    cleanup()
    print("SOURCE RECONSTRUCTION: %d failures" % failures)
    quit(1 if failures else 0)
