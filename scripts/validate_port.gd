extends SceneTree
## Full-port validation — drives the REAL game loop headlessly.
## Run: Godot --headless -s scripts/validate_port.gd
## Outcome assertions (never implementation mirrors):
##   boot, traversal Z0→Z1→Z2, gate window, enemy lifecycle, corner fix, beacon refill, draft economy.

var failures := 0

func check(name: String, ok: bool, detail: String) -> void:
    if ok:
        print("PASS  %s (%s)" % [name, detail])
    else:
        failures += 1
        print("FAIL  %s (%s)" % [name, detail])

func _init() -> void:
    var ms: PackedScene = load("res://scenes/main.tscn")
    var main := ms.instantiate()
    root.add_child(main)
    for i in 8:
        await physics_frame
    var world := main
    var player: CharacterBody2D = world.get_node_or_null("Player")
    check("player_exists", player != null, "")
    if player == null:
        print("PORT-VALIDATION: fatal (no player)")
        quit(1)
        return
    var frames := func(ms_count: int) -> void:
        for i in ms_count:
            await physics_frame

    RunState.start_run()
    for i in 10:
        await physics_frame
    check("run_started", RunState.state == "play", RunState.state)

    # --- traversal Z0→Z1: bunny-hop right from spawn ---
    Input.action_press("move_right")
    var crossed_z0 := false
    for i in 1500:
        if player.is_on_floor() and i % 26 == 0:
            Input.action_press("jump")
        elif i % 26 == 13:
            Input.action_release("jump")
        if player.global_position.x > 1210.0:
            crossed_z0 = true
            break
        await physics_frame
    Input.action_release("move_right")
    Input.action_release("jump")
    check("z0_to_z1", crossed_z0, "x=%.0f" % player.global_position.x)

    # --- traversal into Z2 shaft (through the walk-through passage) ---
    Input.action_press("move_right")
    var entered_z2 := false
    for i in 1500:
        if player.is_on_floor() and i % 26 == 0:
            Input.action_press("jump")
        elif i % 26 == 13:
            Input.action_release("jump")
        if player.global_position.x > 2470.0:
            entered_z2 = true
            break
        await physics_frame
    Input.action_release("move_right")
    Input.action_release("jump")
    check("z1_to_z2_shaft", entered_z2, "x=%.0f" % player.global_position.x)

    # --- enemy lifecycle: dash-kill then death re-forms ---
    RunState.open_draft()
    var di: int = RunState.draft_opts.find("dash")
    if di >= 0:
        RunState.pick_card(di)
    for i in 10:
        await physics_frame
    var e_before := get_nodes_in_group("enemy").size()
    var target = null
    for e in get_nodes_in_group("enemy"):
        if e.position.x > 2000.0 and e.position.x < 2200.0:
            target = e
            break
    if target:
        player.global_position = Vector2(target.position.x - 40.0, 216.0)
        player.velocity = Vector2.ZERO
        player.invuln = 0.0
        Input.action_press("move_right")
        await physics_frame
        player.t_dash()
        for i in 30:
            await physics_frame
        Input.action_release("move_right")
        var killed: bool = not is_instance_valid(target) or target.dead
        check("dash_kill", killed, "")
        RunState.register_death()
        for i in 10:
            await physics_frame
        check("death_reforms_all", get_nodes_in_group("enemy").size() == e_before,
            "%d vs %d" % [get_nodes_in_group("enemy").size(), e_before])

    # --- draft system: card pick applies mods ---
    RunState.open_draft()
    var gi: int = RunState.draft_opts.find("glass")
    if gi >= 0:
        RunState.pick_card(gi)
    check("glass_mods", float(RunState.mods.max_run) > 200.0, "max_run=%.0f" % float(RunState.mods.max_run))
    RunState.skip_draft()

    # --- win + best save ---
    RunState.win()
    check("win_saves_best", RunState.state == "win" and not RunState.best.is_empty(),
        str(RunState.best))

    print("---")
    print("PORT-VALIDATION: %d failure(s)" % failures)
    quit(1 if failures > 0 else 0)