extends SceneTree
var scene: Node
var failed := 0

func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
    for i in n: await physics_frame
func steer(x: float) -> void:
    Input.action_release("move_left")
    Input.action_release("move_right")
    if absf(scene.player.position.x-x) > 3:
        Input.action_press("move_right" if scene.player.position.x < x else "move_left")
func land(x: float, y: float, jump := true) -> void:
    Input.action_release("jump")
    await frames(2)
    if jump: Input.action_press("jump")
    var reached := false
    for i in 100:
        steer(x)
        await physics_frame
        if i > 15 and scene.player.is_on_floor() and absf(scene.player.position.x-x) < 8 and absf(scene.player.position.y-y) < 5:
            reached = true
            break
    Input.action_release("jump")
    Input.action_release("move_left")
    Input.action_release("move_right")
    if not reached:
        failed += 1
        print("FAIL landing ",Vector2(x,y)," from actual ",scene.player.position)
    await frames(3)
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/exploration_routes.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("hub")
    await frames(5)
    await land(125,217,false)
    await land(82,185)
    await land(101,185,false)
    await land(146,151)
    await land(122,151,false)
    await land(80,119)
    scene.enter_room("gallery")
    await frames(5)
    await land(170,217,false)
    scene.activate("selector")
    Input.action_press("jump")
    for i in 65:
        steer(225)
        await physics_frame
    Input.action_release("jump")
    Input.action_release("move_right")
    Input.action_release("move_left")
    await frames(160)
    if scene.player.position.y > 120:
        failed += 1
        print("FAIL lift ride ",scene.player.position)
    await land(299,113)
    await land(324,113,false)
    scene.activate("catch")
    scene.activate("selector")
    scene.enter_room("amplifier")
    await frames(5)
    await land(90,183)
    await land(167,149)
    await land(199,149,false)
    scene.activate("dash")
    scene.enter_room("lookout")
    await frames(5)
    await land(113,183)
    await land(158,183,false)
    await land(221,147)
    scene.activate("survey")
    if not scene.profile.has_flag("survey"): failed += 1
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/exploration_routes.json"+suffix)
    print("EXPLORATION ROUTES: %d failures" % failed)
    quit(1 if failed else 0)
