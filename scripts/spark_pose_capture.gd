extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    var fixture := "res://test-user/spark-pose-%d.json" % OS.get_process_id()
    world.save_path = fixture
    root.add_child(world)
    world.enter_room("workshop")
    var player = world.player
    player.set_physics_process(false)
    world.set_process(false)
    player.position = Vector2(240,190)
    player.invuln = 0
    player.sx_anim = 0.72
    player.sy_anim = 1.32
    player.velocity = Vector2(90,-200)
    await capture(world,"spark-airborne")
    player.sliding_anim = true
    player.wall_dir = 1
    player.sx_anim = 1
    player.sy_anim = 1
    await capture(world,"spark-wall")
    player.sliding_anim = false
    player.dash_t = 0.1
    player.sx_anim = 1.35
    player.sy_anim = 0.65
    await capture(world,"spark-dash")
    player.dash_t = 0
    player.invuln = 1
    player.sx_anim = 1
    player.sy_anim = 1
    root.get_node("AppSettings").reduced_flashes = true
    await capture(world,"spark-protected-reduced")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture+suffix)
    print("SPARK POSES: captured")
    quit()
