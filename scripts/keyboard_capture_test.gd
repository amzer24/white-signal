extends SceneTree
func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = true
    return event
func _initialize() -> void:
    var settings = load("res://scripts/keyboard_bindings.gd").new()
    settings.path = "res://test-user/capture-%d.cfg" % OS.get_process_id()
    settings.begin_capture("jump")
    settings.capture(key(KEY_A))
    assert(settings.capturing == "jump" and settings.bindings.is_empty())
    settings.capture(key(KEY_ESCAPE))
    assert(settings.capturing.is_empty())
    settings.begin_capture("jump")
    var chord := key(KEY_J)
    chord.ctrl_pressed = true
    settings.capture(chord)
    assert(settings.bindings.is_empty())
    settings.capture(key(KEY_J))
    assert(settings.bindings.jump == KEY_J and settings.capturing.is_empty())
    settings.begin_capture("dash")
    var shift := key(KEY_SHIFT)
    shift.shift_pressed = true
    settings.capture(shift)
    assert(not settings.bindings.has("dash"))
    var shifted := key(KEY_K)
    shifted.shift_pressed = true
    settings.capture(shifted)
    shift.pressed = false
    shift.shift_pressed = false
    settings.capture(shift)
    assert(not settings.bindings.has("dash") and settings.capturing == "dash")
    shift.pressed = true
    shift.shift_pressed = true
    settings.capture(shift)
    shift.pressed = false
    shift.shift_pressed = false
    settings.capture(shift)
    assert(settings.bindings.dash == KEY_SHIFT)
    settings.begin_capture("jump")
    var cancel := InputEventJoypadButton.new()
    cancel.button_index = JOY_BUTTON_B
    cancel.pressed = true
    settings.capture(cancel)
    assert(settings.capturing.is_empty())
    settings.path = "res://test-user/nonexistent-parent/capture.cfg"
    settings.begin_capture("jump")
    settings.capture(key(KEY_U))
    assert(settings.capturing == "jump" and settings.bindings.jump == KEY_J)
    assert(settings.error == "BINDINGS NOT SAVED")
    DirAccess.remove_absolute("res://test-user/capture-%d.cfg" % OS.get_process_id())
    print("KEYBOARD CAPTURE: conflict, cancel, chords, Shift and failed-save preservation passed")
    quit()
