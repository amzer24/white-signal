extends SceneTree
func _initialize() -> void: call_deferred("run")
func press(scene, code) -> void:
    var e := InputEventKey.new()
    e.keycode = code
    e.pressed = true
    scene._unhandled_input(e)
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/map_help_test.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    press(scene,KEY_M)
    press(scene,KEY_H)
    assert(scene.map_open and scene.map_help)
    assert(root.get_node("RunState").state == "pause")
    press(scene,KEY_ESCAPE)
    assert(scene.map_open and not scene.map_help)
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_X
    pad.pressed = true
    scene._unhandled_input(pad)
    assert(scene.map_help)
    press(scene,KEY_TAB)
    assert(scene.map_open and not scene.map_help)
    press(scene,KEY_H)
    press(scene,KEY_M)
    assert(not scene.map_open and not scene.map_help)
    assert(root.get_node("RunState").state == "play")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/map_help_test.json"+suffix)
    print("MAP HELP: keyboard, controller, back, paging and resume passed")
    quit()
