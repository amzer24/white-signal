extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/coherence_light_capture.json"
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+s)
    root.add_child(scene)
    scene.enter_room("arrival")
    scene.player.position = Vector2(240,217)
    await capture(scene,"beacon-unlit")
    scene.profile.set_flag("first_beacon")
    for i in 24: await physics_frame
    print("BEACON MID FADE ",scene.beacon_light_power)
    await capture(scene,"beacon-light-half")
    for i in 30: await physics_frame
    print("BEACON FULL ",scene.beacon_light_power)
    await capture(scene,"beacon-light-pool")
    scene.enter_room("workshop")
    await capture(scene,"window-unlit")
    scene.profile.set_flag("west_ear")
    scene.window_light_power = 1
    await capture(scene,"window-light-pool")
    scene.queue_free()
    await process_frame
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/coherence_light_capture.json"+s)
    quit()
