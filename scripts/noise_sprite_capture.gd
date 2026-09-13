extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/noise_sprite_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("array_inspection")
    await capture(scene,"noise-sprite-walking")
    print("SOURCE REGION ",scene.noise_actor.sprite_region)
    for i in 200:
        await physics_frame
        if scene.noise_actor.turn_time > 0: break
    root.get_node("RunState").state = "pause"
    print("TURN TIME ",scene.noise_actor.turn_time)
    await capture(scene,"noise-sprite-turn")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/noise_sprite_capture.json"+suffix)
    quit()
