extends SceneTree
var failed := 0
func check(ok: bool, label: String) -> void:
    if not ok:
        failed += 1
        print("FAIL: " + label)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    if not FileAccess.file_exists("res://scenes/exploration.tscn"):
        print("FAIL: exploration scene is missing")
        quit(1)
        return
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/exploration_world_contract.json"
    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute(scene.save_path + suffix)
    root.add_child(scene)
    await process_frame
    check(scene.room_id == "flats", "new exploration begins in Flats")
    scene.enter_room("hub")
    check(scene.map_state("hub") == "visited", "map reveals current room")
    check(scene.map_state("workshop") == "hint", "map hints adjacent lead")
    check(scene.map_state("gallery") == "hidden", "map conceals undiscovered interior")
    var map_key := InputEventKey.new()
    map_key.keycode = KEY_M
    map_key.pressed = true
    scene._unhandled_input(map_key)
    check(scene.map_open and root.get_node("RunState").state == "pause", "M opens map and pauses play")
    map_key.keycode = KEY_ESCAPE
    scene._unhandled_input(map_key)
    check(not scene.map_open and root.get_node("RunState").state == "play", "Escape closes map and resumes")
    scene._unhandled_input(map_key)
    map_key.keycode = KEY_M
    scene._unhandled_input(map_key)
    scene._unhandled_input(map_key)
    check(scene.paused and root.get_node("RunState").state == "pause", "closing map preserves existing pause")
    map_key.keycode = KEY_ESCAPE
    scene._unhandled_input(map_key)
    check(not scene.can_use_exit("return"), "hub return is initially locked")
    scene.enter_room("gallery")
    await physics_frame
    check(not scene.can_use_exit("amplifier"), "receiver gates amplifier")
    scene.activate("selector")
    check(scene.lift_power, "selector powers lift")
    scene.activate("catch")
    check(scene.profile.has_flag("catch"), "catch persists")
    scene.activate("selector")
    check(scene.profile.has_flag("west_ear"), "rerouting after catch restores ear")
    check(scene.can_use_exit("amplifier"), "completed ear opens amplifier")
    scene.enter_room("amplifier")
    scene.activate("dash")
    check(scene.profile.has_flag("dash"), "Dash permanently discovered")
    scene.respawn()
    check(root.get_node("RunState").mods.dash, "death retains traversal ability")
    scene.enter_room("return")
    scene.activate("return_latch")
    scene.enter_room("hub")
    check(scene.can_use_exit("return"), "completed return opens from hub")
    check(scene.profile.has_flag("west_ear"), "room travel retains repair")
    check(scene.map_state("amplifier") == "visited", "map remembers visited amplifier")
    scene.enter_room("lookout")
    check(scene.map_state("pump") == "hidden", "unsurveyed Drowned interior stays hidden")
    scene.activate("survey")
    check(scene.map_state("pump") == "surveyed" and scene.map_state("float") == "surveyed", "survey reveals rough Drowned layout")
    check(not "pump" in scene.profile.data.visited, "survey does not mark rooms explored")
    check(scene.map_state("gate") == "hidden", "local survey does not reveal distant source")
    scene.respawn()
    check(scene.profile.has_flag("survey"), "survey survives death")
    check(scene.profile.load_profile(), "map profile reloads")
    check(scene.map_state("pump") == "surveyed", "surveyed layout survives reload")
    check(scene.map_state("amplifier") == "visited" and scene.profile.has_flag("survey"), "map and survey survive reload")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute("res://test-user/exploration_world_contract.json" + suffix)
    print("EXPLORATION WORLD: %d failures" % failed)
    quit(1 if failed else 0)
