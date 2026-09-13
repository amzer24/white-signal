extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
    var input = root.get_node("GameInput")
    var profile = load("res://scripts/exploration_save.gd").new()
    var context := {"profile":profile,"room_id":"flats"}
    var guidance = load("res://scripts/exploration_guidance.gd")
    input.keyboard.bindings = {"move_left":KEY_J,"move_right":KEY_L,"jump":KEY_I,"interact":KEY_U}
    input.controller_active = false
    assert(guidance.goal(context).begins_with("J/L MOVE . I JUMP"))
    context.room_id = "conduit"
    assert(guidance.goal(context).begins_with("U USE"))
    input.controller_active = true
    assert(guidance.goal(context).begins_with("X USE"))
    context.room_id = "flats"
    assert(guidance.goal(context).begins_with("STICK MOVE . A JUMP"))
    profile.data.flags.intro_memory = true
    assert(guidance.goal(context).begins_with("MEMORY ANSWERED"))
    print("TUTORIAL CONTROLS: custom keyboard, controller and discovery guidance passed")
    quit()
