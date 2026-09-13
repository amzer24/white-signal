extends "res://scripts/exploration_routes_test.gd"
func check(ok: bool,label: String) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failed += 1
func run() -> void:
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/motor_audio_test.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.enter_room("wire_shaft")
    await frames(5)
    var shaft = scene.network.shaft
    var motor = shaft.motor
    check(not motor.playing,"idle motor silent")
    scene.activate("shaft_release")
    await frames(3)
    motor = shaft.motor
    scene.activate("shaft_ride")
    await frames(30)
    await process_frame
    check(motor.playing and motor.moving and motor.bus == "SFX","moving lift uses effects bus")
    scene.map_open = true
    root.get_node("RunState").state = "pause"
    await process_frame
    await process_frame
    check(motor.stream_paused,"map pauses motor")
    var position: float = motor.get_playback_position()
    await frames(15)
    check(absf(motor.get_playback_position()-position)<0.05,"paused audio position holds")
    scene.map_open = false
    root.get_node("RunState").state = "play"
    await process_frame
    await process_frame
    check(not motor.stream_paused,"closing map resumes motor")
    var settings = root.get_node("AppSettings")
    var previous: float = settings.sfx_volume
    settings.set_volume("effects",0,false)
    check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"effects mute covers motor")
    settings.set_volume("effects",previous,false)
    await frames(260)
    await process_frame
    check(not motor.playing and motor.arrivals == 1,"arrival cue once then motor silent")
    scene.activate("shaft_ride")
    await frames(10)
    scene.respawn()
    await frames(10)
    check(not motor.playing and motor.arrivals == 1,"death stops motor without false arrival")
    scene.enter_room("wire_shelter")
    await frames(3)
    check(not is_instance_valid(motor),"room exit frees motor player")
    print("MOTOR AUDIO: %d failures"%failed)
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/motor_audio_test.json"+suffix)
    quit(1 if failed else 0)
