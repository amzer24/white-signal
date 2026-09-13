extends Node

signal controller_lost
var controller_active := false
var active_device := -1
var keyboard = preload("res://scripts/keyboard_bindings.gd").new()
func action_label(action: String) -> String:
    if controller_active:
        return {"jump":"A","dash":"RB","interact":"X","move_left":"LEFT","move_right":"RIGHT"}.get(action,action)
    return keyboard.key_label(action).split("/")[0]

func use_event(event: InputEvent) -> bool:
    if event is InputEventJoypadButton: return event.pressed and event.button_index == JOY_BUTTON_X
    return event.is_action_pressed("interact")

func _ready() -> void:
    if OS.has_environment("WS_KEYBOARD_PATH"): keyboard.path = OS.get_environment("WS_KEYBOARD_PATH")
    keyboard.load_bindings()
    keyboard.apply()
    Input.joy_connection_changed.connect(_connection_changed)
    for pair in [["jump",JOY_BUTTON_A],["dash",JOY_BUTTON_RIGHT_SHOULDER],["interact",JOY_BUTTON_X],["move_left",JOY_BUTTON_DPAD_LEFT],["move_right",JOY_BUTTON_DPAD_RIGHT]]:
        var event := InputEventJoypadButton.new()
        event.button_index = pair[1]
        InputMap.action_add_event(pair[0],event)
    for side in [-1,1]:
        var event := InputEventJoypadMotion.new()
        event.axis = JOY_AXIS_LEFT_X
        event.axis_value = side
        InputMap.action_add_event("move_left" if side < 0 else "move_right",event)

func _input(event: InputEvent) -> void:
    if (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.3):
        controller_active = true
        active_device = event.device
    elif event is InputEventKey or event is InputEventMouseButton:
        controller_active = false

func _connection_changed(device: int, connected: bool) -> void:
    if connected or device != active_device: return
    for action in ["move_left","move_right","jump","dash","interact"]:
        Input.action_release(action)
    active_device = -1
    controller_active = false
    controller_lost.emit()

# Translate locally, without injecting duplicate keyboard events into Input.
func menu_event(event: InputEvent) -> InputEvent:
    if not event is InputEventJoypadButton: return event
    var bindings := {JOY_BUTTON_A:KEY_ENTER,JOY_BUTTON_B:KEY_ESCAPE,JOY_BUTTON_DPAD_UP:KEY_UP,JOY_BUTTON_DPAD_DOWN:KEY_DOWN,JOY_BUTTON_DPAD_LEFT:KEY_LEFT,JOY_BUTTON_DPAD_RIGHT:KEY_RIGHT}
    if not bindings.has(event.button_index): return event
    var key := InputEventKey.new()
    key.keycode = bindings[event.button_index]
    key.pressed = event.pressed
    return key

func exploration_event(event: InputEvent, paused: bool, map_open: bool) -> InputEvent:
    if not event is InputEventJoypadButton: return event
    var bindings := {JOY_BUTTON_Y:KEY_M,JOY_BUTTON_START:KEY_ESCAPE}
    if map_open:
        bindings[JOY_BUTTON_LEFT_SHOULDER] = KEY_TAB
        bindings[JOY_BUTTON_X] = KEY_H
        bindings[JOY_BUTTON_B] = KEY_ESCAPE
    elif paused:
        bindings[JOY_BUTTON_A] = KEY_O
        bindings[JOY_BUTTON_B] = KEY_ESCAPE
        bindings[JOY_BUTTON_X] = KEY_F
        bindings[JOY_BUTTON_BACK] = KEY_Q
    else:
        bindings[JOY_BUTTON_X] = KEY_E
    if not bindings.has(event.button_index): return event
    var key := InputEventKey.new()
    key.keycode = bindings[event.button_index]
    key.pressed = event.pressed
    return key

func classic_event(event: InputEvent, state: String) -> InputEvent:
    if not event is InputEventJoypadButton: return event
    var bindings := {JOY_BUTTON_START:KEY_ESCAPE}
    if state == "pause":
        bindings[JOY_BUTTON_B] = KEY_ESCAPE
        bindings[JOY_BUTTON_X] = KEY_O
    elif state == "draft":
        bindings = {JOY_BUTTON_A:KEY_1,JOY_BUTTON_X:KEY_2,JOY_BUTTON_Y:KEY_3,JOY_BUTTON_B:KEY_ESCAPE}
    elif state in ["relay_clear","build_complete","win","lab_complete"]:
        bindings[JOY_BUTTON_A] = KEY_ENTER
    if not bindings.has(event.button_index): return event
    var key := InputEventKey.new()
    key.keycode = bindings[event.button_index]
    key.pressed = event.pressed
    return key
