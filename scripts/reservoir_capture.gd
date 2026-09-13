extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/reservoir_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("stand_charge")
    root.get_node("RunState").state = "pause"
    if scene.stand.reservoir_texture == null:
        push_error("Reservoir texture missing")
        quit(1)
        return
    for amount in [0.0,0.5,1.0]:
        scene.stand.charge = amount
        await capture(scene,"reservoir-%d" % int(amount*100))
    scene.enter_room("conductor")
    scene.stand.charge = 1
    await capture(scene,"reservoir-motor")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/reservoir_capture.json"+suffix)
    print("RESERVOIR: texture loaded, four states rendered")
    quit()
