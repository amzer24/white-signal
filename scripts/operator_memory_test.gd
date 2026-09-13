extends "res://scripts/exploration_routes_test.gd"
func check(ok: bool,label: String) -> void:
    if not ok:
        failed += 1
        print("FAIL ",label)
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/operator_memory_test.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("wire_shaft")
    var shaft = scene.network.shaft
    var path: String = scene.profile.path
    scene.profile.path = path+"/blocked.json"
    scene.activate("shaft_release")
    check(shaft.memory.time < 0,"failed save does not start memory")
    scene.profile.path = path
    scene.activate("shaft_release")
    await frames(150)
    check(shaft.memory.time > 2 and shaft.memory.rider().y < 224,"memory rider ascends")
    check(shaft.y == 224 and shaft.target == 224,"memory does not move real lift")
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    var stopped: float = shaft.memory.time
    await frames(20)
    check(shaft.memory.time == stopped,"map freezes memory")
    scene.map_open = false
    root.get_node("RunState").state = "play"
    await frames(440)
    check(shaft.memory.time < 0,"replay finishes")
    scene.activate("shaft_release")
    check(shaft.memory.time == 0,"archive replays on demand")
    scene.respawn()
    check(shaft.memory.time < 0 and scene.profile.has_flag("wire_shaft_archive"),"death ends replay and retains archive")
    scene.activate("shaft_release")
    scene.enter_room("wire_shelter")
    check(shaft.memory.time < 0,"room exit clears replay")
    print("OPERATOR MEMORY: %d failures"%failed)
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit(1 if failed else 0)
