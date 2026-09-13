extends SceneTree

var failures := 0
func check(label: String, result: bool) -> void:
    print(("PASS " if result else "FAIL ") + label)
    if not result: failures += 1
func frames(count: int = 4) -> void:
    for i in count: await physics_frame
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user"))
    var world = load("res://scenes/main.tscn").instantiate()
    root.add_child(world)
    current_scene = world
    var rs = root.get_node("RunState")
    rs.boundary_path = "res://test-user/afterlight-save.json"
    rs.start_run()
    await frames()
    var original_save := FileAccess.get_file_as_string(rs.boundary_path)
    check("title can enter lighting study", rs.has_method("start_lab"))
    if not rs.has_method("start_lab"):
        quit(1)
        return
    rs.start_lab()
    await frames()
    check("lab uses its own layout", rs.lab_active and rs.level.name == "THE ROOM REMEMBERS")
    check("entering lab preserves campaign save", FileAccess.get_file_as_string(rs.boundary_path) == original_save)
    var view = world.get_node("AfterlightLayer/View")
    var block = world.fixtures.filter(func(f): return f.kind == "memory")[0]
    var geometry = rs.level.platforms.duplicate(true)
    block.strike()
    await frames(28)
    check("memory strike starts a visible afterimage", view.memory_left > 0 and view.reveal_strength() > 0.2)
    check("memory counts once", rs.objectives.size() == 1 and rs.gems == 1)
    view.memory_left = 0.0
    block.strike()
    check("spent block can replay memory without farming shards", view.memory_left > 0 and rs.gems == 1)
    rs.toggle_pause()
    var remaining: float = view.memory_left
    await frames(20)
    check("pause freezes afterlight", is_equal_approx(view.memory_left, remaining))
    rs.toggle_pause()
    rs.lab_mode = 0
    await frames()
    rs.lab_mode = 2
    await frames()
    check("lighting modes never change solid geometry", rs.level.platforms == geometry)
    world.player.reset_at(Vector2(740,223))
    await frames()
    check("beacon leaves a persistent lit window", rs.lit_beacons.has(Vector2(740,230)))
    rs.register_death()
    await frames()
    check("death retains memories and beacon light", rs.objectives.size() == 1 and rs.lit_beacons.has(Vector2(740,230)))
    rs.win()
    check("exit waits for all three memories", rs.state == "play")
    for item in world.fixtures:
        if item.kind == "memory": item.strike()
    rs.win()
    check("study ends without claiming campaign victory", rs.state == "lab_complete")
    rs.start_lab()
    await frames()
    check("study replay resets memories", rs.objectives.is_empty())
    rs.leave_lab()
    await frames()
    check("leaving returns to title", rs.state == "menu" and not rs.lab_active)
    check("lab never writes campaign progress", FileAccess.get_file_as_string(rs.boundary_path) == original_save)
    rs.resume_run()
    await frames()
    check("campaign resumes normally", not rs.lab_active and rs.level.name == "THE FLATS LINE" and rs.state == "play")
    print("AFTERLIGHT: %d failure(s)" % failures)
    world.queue_free()
    await frames()
    quit(1 if failures else 0)
