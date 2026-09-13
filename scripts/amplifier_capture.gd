extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/amplifier-capture-%d.json" % OS.get_process_id()
    scene.save_path = path
    root.add_child(scene)
    scene.profile.set_flag("west_ear")
    scene.enter_room("amplifier")
    await capture(scene,"amplifier-campaign-before")
    scene.activate("dash")
    scene.activate("amplifier_release")
    await capture(scene,"amplifier-campaign-after")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
