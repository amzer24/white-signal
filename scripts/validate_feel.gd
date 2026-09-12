extends SceneTree
## Phase 2 headless feel-validation — INTEGRATION through the real input path.
## Run: Godot --headless -s scripts/validate_feel.gd
## Asserts the ported controller reproduces the JS game's measured outcomes.

var failures := 0

func check(name: String, ok: bool, detail: String) -> void:
    if ok:
        print("PASS  %s (%s)" % [name, detail])
    else:
        failures += 1
        print("FAIL  %s (%s)" % [name, detail])

func _init() -> void:
    var scene: PackedScene = load("res://scenes/main.tscn")
    var root_node := scene.instantiate()
    root.add_child(root_node)
    var player: CharacterBody2D = root_node.get_node("Player")
    for i in 5:
        await physics_frame
    # let the player settle onto the floor
    for i in 60:
        if player.is_on_floor():
            break
        await physics_frame
    check("lands_on_floor", player.is_on_floor(), "settled y=%.1f" % player.position.y)

    # --- 1. run speed: hold move_right, expect velocity.x → 135 ---
    Input.action_press("move_right")
    for i in 30:
        await physics_frame
    var run: float = player.velocity.x
    Input.action_release("move_right")
    check("max_run", absf(run - 135.0) < 2.0, "%.1f vs 135" % run)

    # stop and settle again
    for i in 40:
        await physics_frame
        if absf(player.velocity.x) < 1.0 and player.is_on_floor():
            break

    # --- 2. jump outcome: apex time + rise, THROUGH the controller ---
    var y0: float = player.position.y
    var apex: float = y0
    var apex_t := 0.0
    Input.action_press("jump")
    var t := 0.0
    for i in 90:
        await physics_frame
        t += 1.0 / 60.0
        apex = minf(apex, player.position.y)
        if player.velocity.y >= 0.0 and apex_t == 0.0:
            apex_t = t
        if apex_t > 0.0 and player.is_on_floor():
            break
    Input.action_release("jump")
    var rise: float = player.position.y - apex
    check("apex_time", absf(apex_t - 0.35) < 0.04, "%.3fs vs 0.35" % apex_t)
    check("rise_height", absf(rise - 57.0) < 4.0, "%.1fpx vs 57" % rise)

    # --- 3. kick overspeed constant + decay behavior ---
    var kick: float = player.MAX_RUN * player.KICK_OUT
    check("kick_out", absf(kick - 155.25) < 0.1, "%.1f" % kick)

    # --- 4. round-trip math ---
    var h: float = player.JUMP_VEL * player.JUMP_VEL / (2.0 * player.GRAVITY)
    check("round_trip_h", absf(h - 57.4) < 1.0, "%.1fpx" % h)

    print("---")
    print("FEEL-VALIDATION: %d failure(s)" % failures)
    quit(1 if failures > 0 else 0)