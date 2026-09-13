extends SceneTree
func _initialize() -> void:
    var settings = load("res://scripts/keyboard_bindings.gd").new()
    settings.path = "res://test-user/keyboard-%d.cfg" % OS.get_process_id()
    assert(not settings.save({"jump":KEY_J,"dash":KEY_J}))
    assert(not settings.save({"jump":KEY_ESCAPE}))
    assert(not settings.save({"jump":KEY_A}))
    assert(not settings.save({"dash":KEY_UP}))
    assert(not settings.save({"jump":KEY_E}))
    assert(settings.valid({"jump":KEY_A,"move_left":KEY_J}))
    assert(settings.save({"jump":KEY_J,"dash":KEY_K}))
    assert(settings.save({"jump":KEY_U,"dash":KEY_K}))
    var loaded = load("res://scripts/keyboard_bindings.gd").new()
    loaded.path = settings.path
    assert(loaded.load_bindings() and loaded.bindings.jump == KEY_U)
    var original: Array = InputMap.action_get_events("jump")
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_A
    InputMap.action_add_event("jump",pad)
    loaded.apply()
    assert(InputMap.action_has_event("jump",pad))
    var keyboard_count := 0
    for event in InputMap.action_get_events("jump"):
        if event is InputEventKey:
            keyboard_count += 1
            assert(event.physical_keycode == KEY_U)
    assert(keyboard_count == 1)
    assert(loaded.restore_defaults())
    assert(InputMap.action_has_event("jump",pad))
    for action in loaded.ACTIONS:
        var actual: Array = []
        for event in InputMap.action_get_events(action):
            if event is InputEventKey: actual.append(event)
        var defaults: Array = loaded.default_events(action)
        assert(actual.size() == defaults.size())
        for event in defaults: assert(InputMap.action_has_event(action,event))
    assert(loaded.load_bindings() and loaded.bindings.is_empty())
    InputMap.action_erase_events("jump")
    for event in original: InputMap.action_add_event("jump",event)
    for suffix in ["", ".tmp"]: DirAccess.remove_absolute(settings.path+suffix)
    print("KEYBOARD BINDINGS: conflicts, reserved controls, disk update/reload and controller preservation passed")
    quit()
