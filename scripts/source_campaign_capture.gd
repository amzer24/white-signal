extends "res://scripts/inspection_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/source-capture-%d.json" % OS.get_process_id()
    var path: String = scene.save_path
    root.add_child(scene)
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored","dash","air_jump"]:
        scene.profile.set_flag(flag)
    scene.enter_room("gate")
    await capture(scene,"source-campaign-gantry")
    scene.activate("gate_latch")
    scene.enter_room("source_return")
    await capture(scene,"source-campaign-return-idle")
    scene.activate("gate_isolate")
    scene.gate.tick(0.75)
    scene.set_physics_process(false)
    await capture(scene,"source-campaign-return-deploying")
    scene.set_physics_process(true)
    scene.gate.tick(1.6)
    await capture(scene,"source-campaign-return")
    scene.enter_room("source_walk")
    for id in ["array","approach","gate","source_return","source_walk","aftermath","shelter","hub"]:
        if not id in scene.profile.data.visited: scene.profile.data.visited.append(id)
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    await capture(scene,"source-campaign-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
