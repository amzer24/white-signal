extends SceneTree
func _initialize() -> void: run.call_deferred()
func settle() -> void:
    await process_frame
    await process_frame
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/pump-audio-%d.json" % OS.get_process_id()
    root.add_child(world)
    world.enter_room("pump")
    var motor = world.get_node("PumpMotor")
    await settle()
    assert(not motor.playing)
    assert(world.profile.set_flag("pump_repaired"))
    await settle()
    assert(motor.playing and motor.bus == "SFX")
    var playback = motor.get_stream_playback()
    world.map_open = true
    await settle()
    assert(motor.stream_paused)
    world.map_open = false
    world.paused = true
    await settle()
    assert(motor.stream_paused)
    world.paused = false
    await settle()
    assert(not motor.stream_paused and motor.get_stream_playback() == playback)
    world.enter_room("basin")
    await settle()
    assert(not motor.playing)
    world.enter_room("pump")
    await settle()
    assert(motor.playing)
    var stream = motor.stream
    var samples: PackedByteArray = stream.data
    var peak := 0
    for i in range(0,samples.size(),2): peak = maxi(peak,absi(samples.decode_s16(i)))
    assert(peak > 0 and peak < 32767)
    assert(absi(samples.decode_s16(0)-samples.decode_s16(samples.size()-2)) < 300)
    assert(stream.loop_end == stream.mix_rate)
    var path: String = world.save_path
    world.queue_free()
    await settle()
    assert(not is_instance_valid(motor))
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("PUMP MOTOR: repair, pause/resume, room exit, return, teardown and loop checks passed")
    quit()
