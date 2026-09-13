extends "res://scripts/exploration_routes_test.gd"
class FailedSave extends "res://scripts/exploration_save.gd":
    func save_profile() -> bool: return false

func use_key() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_E
    event.pressed = true
    Input.parse_input_event(event)
    await frames(2)
    event.pressed = false
    Input.parse_input_event(event)
    await frames(3)
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/shutter-%d.json" % OS.get_process_id()
    scene.save_path = path
    root.add_child(scene)
    scene.enter_room("array_shutter")
    await frames(5)
    assert(scene.can_use_exit("array"))
    await land(210,217,false)
    await land(420,217,false)
    await use_key()
    assert(not scene.profile.has_flag("shutter_archive"))
    await land(210,217,false)
    await use_key()
    assert(not scene.can_use_exit("array"))
    await land(420,217,false)
    await use_key()
    assert(scene.profile.has_flag("shutter_archive"))
    assert(scene.can_use_exit("array"))
    await land(210,217,false)
    await land(90,217,false)
    await land(95,183)
    await land(160,149)
    await land(220,115)
    await land(280,81)
    await land(420,81,false)
    await use_key()
    assert(scene.room_id == "array")
    assert(scene.can_use_exit("array_shutter"))
    assert(scene.profile.load_profile())
    scene.enter_room("array_shutter")
    assert(scene.shutter.archive_lit(scene.profile.data.flags))
    assert(scene.shutter.return_lit(scene.profile.data.flags))
    scene.shutter.upper = false
    scene.respawn()
    assert(scene.shutter.upper)
    assert(scene.profile.has_flag("shutter_archive"))
    var original = scene.profile
    var rejected = FailedSave.new()
    rejected.data = original.data.duplicate(true)
    rejected.data.flags.erase("shutter_archive")
    scene.profile = rejected
    scene.shutter.upper = false
    scene.activate("shutter_archive")
    assert(not scene.profile.has_flag("shutter_archive"))
    assert(not scene.can_use_exit("array"))
    scene.profile = original
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("SHUTTER ROUTE: %d failures" % failed)
    quit(1 if failed else 0)
