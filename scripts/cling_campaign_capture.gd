extends "res://scripts/exploration_capture.gd"
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/cling_campaign_capture.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    for id in ["wire_shaft","wire_shelter","stand_bridge","wire_carriage","array","drowned_dock","array_inspection","array_cable"]: scene.enter_room(id)
    scene.profile.set_flags({"cable_archive":true,"wire_repaired":true,"stand_restored":true,"array_restored":true})
    scene.player.reset_at(Vector2(210,217))
    for i in 3: await physics_frame
    root.get_node("RunState").state = "pause"
    await capture(scene,"cling-campaign-warning")
    scene.map_open = true
    await capture(scene,"cling-campaign-map")
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/cling_campaign_capture.json"+suffix)
    quit()
