extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        print("FAIL: "+label)
func button(code: int) -> InputEventJoypadButton:
    var event := InputEventJoypadButton.new()
    event.button_index = code
    event.pressed = true
    return event
func _initialize() -> void: call_deferred("run")
func run() -> void:
    if not root.has_node("GameInput"):
        print("FAIL: controller input bridge missing")
        quit(1)
        return
    var bridge = root.get_node("GameInput")
    var menu = load("res://scripts/menu_ui.gd").new()
    root.add_child(menu)
    menu.page = "settings"
    menu.selected = 0
    menu.handle_input(button(JOY_BUTTON_DPAD_DOWN))
    check(menu.selected == 1,"D-pad navigates settings")
    menu.handle_input(button(JOY_BUTTON_B))
    check(menu.page == "home","B leaves settings")
    root.remove_child(menu)
    menu.queue_free()
    check(InputMap.action_has_event("jump",button(JOY_BUTTON_A)),"A is bound to jump")
    check(InputMap.action_has_event("dash",button(JOY_BUTTON_RIGHT_SHOULDER)),"RB is bound to dash")
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/controller_contract.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(world.save_path+suffix)
    root.add_child(world)
    await process_frame
    world._unhandled_input(button(JOY_BUTTON_Y))
    check(world.map_open,"Y opens map")
    var page: int = world.map_region
    world._unhandled_input(button(JOY_BUTTON_LEFT_SHOULDER))
    check(world.map_region != page,"LB changes map region")
    world._unhandled_input(button(JOY_BUTTON_B))
    check(not world.map_open,"B closes map")
    world._unhandled_input(button(JOY_BUTTON_START))
    check(world.paused,"Start pauses")
    world._unhandled_input(button(JOY_BUTTON_B))
    check(not world.paused,"B resumes")
    world.enter_room("arrival")
    world.player.position = Vector2(240,215)
    world._unhandled_input(button(JOY_BUTTON_X))
    check(world.profile.has_flag("first_beacon"),"X activates nearby mechanism")
    bridge.active_device = 7
    bridge.controller_active = true
    bridge._connection_changed(7,false)
    check(world.paused,"disconnect pauses exploration")
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/controller_contract.json"+suffix)
    print("CONTROLLER: %d failures" % failures)
    print("Physical controller IDs: ",Input.get_connected_joypads())
    quit(1 if failures else 0)
