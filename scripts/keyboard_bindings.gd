extends RefCounted
## Staged keyboard preferences. Applying bindings retains non-keyboard events.
const ACTIONS := ["move_left","move_right","jump","dash","interact"]
const RESERVED := [KEY_ESCAPE,KEY_ENTER,KEY_TAB,KEY_F11,KEY_M,KEY_H,KEY_P,KEY_Q,KEY_R,KEY_F,KEY_DOWN]
var path := "user://ws_keyboard.cfg"
var bindings: Dictionary = {}
var error := ""
var capturing := ""
var shift_pending := false
func key_label(action: String) -> String:
    if bindings.has(action): return OS.get_keycode_string(bindings[action]).to_upper()
    var names := PackedStringArray()
    for event in default_events(action):
        names.append(OS.get_keycode_string(event.physical_keycode if event.physical_keycode else event.keycode).to_upper())
    return "/".join(names)
func begin_capture(action: String) -> void:
    shift_pending = false
    capturing = action if action in ACTIONS else ""
    error = ""
func capture(event: InputEvent) -> bool:
    if capturing.is_empty(): return false
    if event is InputEventJoypadButton:
        if event.pressed and event.button_index == JOY_BUTTON_B: capturing = ""
        return true
    if not event is InputEventKey or event.echo: return true
    var key: int = event.physical_keycode if event.physical_keycode else event.keycode
    if key == KEY_SHIFT:
        if event.pressed:
            shift_pending = not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed)
            return true
        if not shift_pending: return true
        shift_pending = false
    elif not event.pressed: return true
    if key == KEY_ESCAPE:
        capturing = ""
        error = ""
        return true
    if event.ctrl_pressed or event.alt_pressed or event.meta_pressed or (event.shift_pressed and key != KEY_SHIFT):
        shift_pending = false
        error = "USE ONE KEY . NO KEY COMBINATIONS"
        return true
    var candidate := bindings.duplicate()
    candidate[capturing] = key
    if save(candidate):
        apply()
        capturing = ""
    return true
func default_events(action: String) -> Array:
    var events: Array = []
    var definition: Dictionary = ProjectSettings.get_setting("input/"+action,{})
    for event in definition.get("events",[]):
        if event is InputEventKey: events.append(event.duplicate())
    if action == "interact" and events.is_empty():
        var key := InputEventKey.new()
        key.keycode = KEY_E
        events.append(key)
    return events
func valid(candidate: Dictionary) -> bool:
    for action in candidate:
        if not action in ACTIONS: return false
        var key = candidate[action]
        if not key is int or key <= 0 or key in RESERVED: return false
        if OS.get_keycode_string(key).is_empty(): return false
    var used: Dictionary = {}
    for action in ACTIONS:
        var keys: Array = []
        if candidate.has(action): keys.append(candidate[action])
        else:
            for event in default_events(action):
                keys.append(event.physical_keycode if event.physical_keycode else event.keycode)
        for key in keys:
            if used.has(key) and used[key] != action: return false
            used[key] = action
    return true
func load_bindings() -> bool:
    var config := ConfigFile.new()
    var result := config.load(path)
    if result != OK:
        error = "" if result == ERR_FILE_NOT_FOUND else "BINDINGS UNREADABLE . CURRENT KEYS RETAINED"
        return false
    var loaded = config.get_value("keyboard","bindings",{})
    if not loaded is Dictionary or not valid(loaded):
        error = "INVALID BINDINGS . CURRENT KEYS RETAINED"
        return false
    bindings = loaded
    error = ""
    return true
func save(candidate: Dictionary) -> bool:
    if not valid(candidate):
        error = "KEY CONFLICT OR RESERVED CONTROL"
        return false
    var config := ConfigFile.new()
    config.set_value("keyboard","bindings",candidate)
    if config.save(path+".tmp") != OK:
        error = "BINDINGS NOT SAVED"
        return false
    if DirAccess.rename_absolute(path+".tmp",path) != OK:
        error = "BINDINGS NOT SAVED"
        return false
    bindings = candidate.duplicate()
    error = ""
    return true
func apply() -> void:
    for action in ACTIONS:
        if not InputMap.has_action(action): InputMap.add_action(action)
        Input.action_release(action)
        for event in InputMap.action_get_events(action):
            if event is InputEventKey: InputMap.action_erase_event(action,event)
        if bindings.has(action):
            var key := InputEventKey.new()
            key.physical_keycode = bindings[action]
            InputMap.action_add_event(action,key)
        else:
            for event in default_events(action): InputMap.action_add_event(action,event)
func restore_defaults() -> bool:
    if not save({}): return false
    apply()
    return true
