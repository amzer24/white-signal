extends SceneTree
var failed := false
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
    for i in n: await physics_frame
func run() -> void:
    var scene = load('res://scenes/main.tscn').instantiate()
    root.add_child(scene)
    current_scene = scene
    var rs = root.get_node('RunState')
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path('res://test-user'))
    rs.boundary_path = 'res://test-user/routes-save.json'
    rs.start_run()
    rs._enter_relay(1)
    var p = scene.player
    p.reset_at(Vector2(645,223))
    await frames(4)
    Input.action_press('move_right')
    var hold := 0
    var reached := false
    for i in 900:
        if rs.state == 'draft': rs.skip_draft()
        if hold > 0:
            hold -= 1
            if hold == 0:
                Input.action_release('jump')
                await physics_frame
                continue
        if p.is_on_floor() and p.is_on_wall() and hold == 0:
            Input.action_press('jump')
            hold = 24
        if p.position.x >= 1060:
            Input.action_release('move_right')
            p.velocity.x = 0
            await frames(55)
            reached = rs.objectives.has('NORTH')
            break
        await physics_frame
    Input.action_release('move_right')
    Input.action_release('jump')
    print(('PASS ' if reached else 'FAIL ') + 'R1 high dish reachable without glyphs')
    failed = not reached
    rs._enter_relay(2)
    p = scene.player
    p.invuln = 999.0 # geometry validation, combat covered in original suite
    Input.action_press('move_right')
    hold = 0
    var last_deaths := 0
    var farthest := 0.0
    for i in 2400:
        farthest = maxf(farthest, p.position.x)
        if rs.deaths != last_deaths:
            print("DEATH after reaching ", farthest)
            last_deaths = rs.deaths
            p.invuln = 999.0
        if rs.state == 'draft': rs.skip_draft()
        if hold > 0:
            hold -= 1
            if hold == 0:
                Input.action_release('jump')
                await physics_frame
                continue
        if p.is_on_floor() and hold == 0:
            # Hop at an approaching ledge, wall or visible spike.
            var feet: float = p.position.y + 7
            var query := PhysicsRayQueryParameters2D.create(Vector2(p.position.x+24,feet+2),Vector2(p.position.x+24,feet+30))
            var gap: bool = p.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
            var near_spike := false
            for spike in rs.level.spikes:
                if spike.r.position.x - p.position.x > 0 and spike.r.position.x - p.position.x < 45: near_spike = true
            var on_bridge := false
            for crumble in rs.level.crumbles:
                if p.position.x > crumble.r.position.x - 15 and p.position.x < crumble.r.end.x: on_bridge = true
            if gap or p.is_on_wall() or near_spike or on_bridge:
                Input.action_press('jump')
                hold = 23
        if rs.state == 'build_complete': break
        await physics_frame
    Input.action_release('move_right')
    Input.action_release('jump')
    var crossed: bool = rs.state == 'build_complete'
    print(('PASS ' if crossed else 'FAIL ') + 'R2 crossing without glyphs; x=' + str(p.position) + ' deaths=' + str(rs.deaths))
    failed = failed or not crossed
    quit(1 if failed else 0)

