extends SceneTree
var failures := 0
const Guidance = preload("res://scripts/exploration_guidance.gd")
const SAVE := "res://test-user/guidance.json"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error(label)
func run() -> void:
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(SAVE+suffix)
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = SAVE
    root.add_child(world)
    world.enter_room("basin")
    world.activate("bleed")
    world.activate("bleed")
    world.drowned.tick(4)
    world.activate("impeller")
    check(Guidance.drowned_lead(world.profile).contains("RECOVERED"),"map must stop directing collection after recovery")
    world.enter_room("pump")
    world.activate("pump_socket")
    check(Guidance.goal(world).contains("FLOAT CHAMBER"),"repaired pump points to newly powered route")
    world.enter_room("array")
    world.activate("array_test")
    check(Guidance.goal(world).contains("TEST RUNNING"),"active diagnostic has wait guidance")
    world.network.tick(2)
    check(Guidance.goal(world).contains("ISOLATE"),"diagnostic reveals next operation")
    world.activate("array_isolate")
    world.activate("array_bypass")
    check(Guidance.goal(world).contains("SOURCE APPROACH OPEN"),"commissioned Array points onward")
    world.queue_free()
    await process_frame
    world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = SAVE
    root.add_child(world)
    check(Guidance.goal(world).contains("SOURCE APPROACH OPEN"),"reloaded goals respect saved repairs")
    check(Guidance.drowned_lead(world.profile).contains("PUMP LIVE"),"reloaded map respects pump repair")
    if DisplayServer.get_name() != "headless":
        world.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://test-user/guidance-array.png")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(SAVE+suffix)
    print("GUIDANCE: %d failures" % failures)
    quit(1 if failures else 0)
