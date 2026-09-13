extends SceneTree

var failures := 0
func check(label: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func frames(n: int = 4) -> void:
    for i in n: await physics_frame
func _initialize() -> void: run.call_deferred()
func walk_to(world: Node, rs: Node, target_x: float) -> bool:
    var player = world.player
    var held := 0
    Input.action_press("move_right")
    for i in 1800:
        if player.position.x >= target_x:
            Input.action_release("move_right")
            Input.action_release("jump")
            player.velocity.x = 0
            await frames(48)
            return true
        if held > 0:
            held -= 1
            if held == 0:
                Input.action_release("jump")
                await physics_frame
                continue
        if player.is_on_floor() and held == 0:
            var feet: float = player.position.y+7
            var query := PhysicsRayQueryParameters2D.create(Vector2(player.position.x+24,feet+2),Vector2(player.position.x+24,feet+35))
            var gap: bool = player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
            if gap or player.is_on_wall():
                Input.action_press("jump")
                held = 24
        await physics_frame
    Input.action_release("move_right")
    Input.action_release("jump")
    print("ROUTE stalled at ",player.position," state=",rs.state)
    return false
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user"))
    var world = load("res://scenes/main.tscn").instantiate()
    root.add_child(world)
    current_scene = world
    var rs = root.get_node("RunState")
    rs.boundary_path = "res://test-user/afterlight-route-save.json"
    for mode in [1,2]:
        rs.start_lab()
        rs.lab_mode = mode
        await frames()
        for x in [270.0,1030.0,1600.0]:
            check("mode %d reaches memory %.0f without glyphs" % [mode,x],await walk_to(world,rs,x))
            Input.action_press("jump")
            await frames(30)
            Input.action_release("jump")
            await frames(30)
        check("all memories collected through real jump collisions",rs.objectives.size()==3)
        await walk_to(world,rs,2220)
        Input.action_press("move_right")
        await frames(35)
        Input.action_release("move_right")
        check("dark/assist route completes with zero deaths",rs.state=="lab_complete" and rs.deaths==0)
    print("AFTERLIGHT ROUTES: %d failure(s)" % failures)
    quit(1 if failures else 0)
