extends Node
## Integration test runner — lives INSIDE the game tree (autoloads registered).
## Enabled via WS_TEST=1 env: WS_TEST=1 godot --headless
## Drives the real game loop and asserts outcomes, then quits with exit code.

var failures := 0

func check(name: String, ok: bool, detail: String) -> void:
    if ok:
        print("PASS  %s (%s)" % [name, detail])
    else:
        failures += 1
        print("FAIL  %s (%s)" % [name, detail])

func wait_frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame

func _ready() -> void:
    _run.call_deferred()

func _run() -> void:
    await wait_frames(8)
    var world := get_parent()
    var player: CharacterBody2D

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user"))
    RunState.boundary_path = "res://test-user/regression-save.json"
    RunState.start_run()
    await wait_frames(10)
    player = world.player
    check("run_started", RunState.state == "play", RunState.state)

    # smart traversal: walk right, full-hop only when a gap is ahead,
    # tap-hop across crumble bridges; invuln on (this tests GEOMETRY)
    player.invuln = 999.0
    Input.action_press("move_right")
    var crossed := false
    var entered := false
    var jump_hold := 0
    for i in 4000:
        if RunState.state == "draft":
            RunState.skip_draft()  # surge mid-walk (gems collected): skip is free
        if jump_hold > 0:
            jump_hold -= 1
            if jump_hold == 0:
                Input.action_release("jump")
        if player.is_on_floor():
            var feet: float = player.global_position.y + 7.0
            var probe: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
                Vector2(player.global_position.x + 24.0, feet + 2.0),
                Vector2(player.global_position.x + 24.0, feet + 50.0))
            var gap: bool = player.get_world_2d().direct_space_state.intersect_ray(probe).is_empty()
            var in_crumble: bool = (player.global_position.x > 1480.0 and player.global_position.x < 1745.0) \
                or (player.global_position.x > 2720.0 and player.global_position.x < 2950.0)
            if gap:
                Input.action_press("jump")
                jump_hold = 20  # full-height hop; short-hop cut must not clip the arc
            elif in_crumble and i % 30 == 0:
                Input.action_press("jump")
                jump_hold = 14
        if player.global_position.x > 1210.0:
            crossed = true
        if player.global_position.x > 2470.0:
            entered = true
            break
        # ferry + crumble bridge are timed-skill content — seed past them
        # (both already crossed in earlier legs; this isolates the Z1→Z2 gate)
        if player.global_position.x > 1300.0 and player.global_position.x < 1470.0:
            player.global_position = Vector2(1750.0, 216.0)
            player.velocity = Vector2.ZERO
        await get_tree().physics_frame
    Input.action_release("move_right")
    Input.action_release("jump")
    check("z0_to_z1", crossed, "x=%.0f" % player.global_position.x)
    check("z1_to_z2_shaft", entered, "x=%.0f" % player.global_position.x)

    # --- enemy lifecycle: dash-kill, death re-forms all ---
    if RunState.state == "draft":
        RunState.skip_draft()
    var e_before := get_tree().get_nodes_in_group("enemy").size()
    # acquire DASH: loop the pool (drafts_seen>0 now, no marquee guarantee)
    var got_dash := false
    for attempt in 15:
        if RunState.state == "draft":
            RunState.skip_draft()
        RunState.open_draft()
        var di: int = RunState.draft_opts.find("dash")
        if di >= 0:
            RunState.pick_card(di)
            got_dash = true
            break
        RunState.skip_draft()
    check("dash_acquired", got_dash and bool(RunState.mods.dash), "")
    await wait_frames(10)
    var target: Node = null
    for e in get_tree().get_nodes_in_group("enemy"):
        if is_instance_valid(e) and e.position.x > 2050.0 and e.position.x < 2400.0:
            target = e
            break
    if target != null:
        target.position.x = 2120.0  # deterministic intercept point
        target.dir = 1.0
        player.global_position = Vector2(2080.0, 216.0)
        player.velocity = Vector2.ZERO
        player.invuln = 0.0
        Input.action_press("move_right")
        await get_tree().physics_frame
        player.t_dash()
        for i in 30:
            await get_tree().physics_frame
        Input.action_release("move_right")
        var killed: bool = not is_instance_valid(target) or target.dead
        check("dash_kill", killed, "")
        RunState.register_death()
        await wait_frames(10)
        check("death_reforms_all", get_tree().get_nodes_in_group("enemy").size() == e_before,
            "%d vs %d" % [get_tree().get_nodes_in_group("enemy").size(), e_before])
    else:
        check("dash_kill", false, "no target enemy found")

    # --- draft mods apply (glass) — loop the pool until offered ---
    var got_glass := false
    for attempt in 15:
        RunState.open_draft()
        var gi: int = RunState.draft_opts.find("glass")
        if gi >= 0:
            RunState.pick_card(gi)
            got_glass = true
            break
        RunState.skip_draft()
    check("glass_mods", got_glass and float(RunState.mods.max_run) > 200.0,
        "max_run=%.0f" % float(RunState.mods.max_run))

    # --- win + best save ---
    RunState.win()
    check("tutorial_relay_clear", RunState.state == "relay_clear", RunState.state)

    print("---")
    print("PORT-VALIDATION: %d failure(s)" % failures)
    get_tree().quit(1 if failures > 0 else 0)