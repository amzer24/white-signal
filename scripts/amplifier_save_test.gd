extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/amplifier-save-%d.json" % OS.get_process_id()
    scene.save_path = path
    root.add_child(scene)
    scene.profile.set_flag("west_ear")
    scene.enter_room("amplifier")
    scene.profile.path = "res://test-user/missing-amplifier-folder/profile.json"
    scene.activate("dash")
    assert(not scene.profile.has_flag("dash") and not scene.profile.has_flag("amplifier_training"))
    scene.profile.path = path
    scene.activate("dash")
    assert(scene.profile.has_flag("dash") and scene.profile.has_flag("amplifier_training"))
    for step in preload("res://scripts/amplifier_room.gd").STEPS: assert(not scene.room.platforms.has(step))
    scene.activate("amplifier_release")
    for step in preload("res://scripts/amplifier_room.gd").STEPS: assert(scene.room.platforms.has(step))
    scene.enter_room("gallery")
    scene.enter_room("amplifier")
    for step in preload("res://scripts/amplifier_room.gd").STEPS: assert(scene.room.platforms.has(step))
    scene.profile.data.flags.erase("amplifier_training")
    scene.enter_room("amplifier")
    assert(scene.room.exits[1][1].y == 217)
    scene.activate("dash")
    assert(not scene.profile.has_flag("amplifier_training"))
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("AMPLIFIER SAVE: atomic pickup, return reconstruction, legacy route passed")
    quit()
