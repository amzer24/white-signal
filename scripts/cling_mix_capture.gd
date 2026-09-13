extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
    var settings = root.get_node("AppSettings")
    settings.music_volume = 0.65
    settings.sfx_volume = 0.8
    settings.apply_audio()
    var recorder := AudioEffectRecord.new()
    recorder.format = AudioStreamWAV.FORMAT_16_BITS
    var effect_index := AudioServer.get_bus_effect_count(0)
    AudioServer.add_bus_effect(0,recorder)
    var world = load("res://scenes/exploration.tscn").instantiate()
    var fixture := "res://test-user/cling-mix-%d.json" % OS.get_process_id()
    world.save_path = fixture
    root.add_child(world)
    world.enter_room("array_cable")
    world.player.set_physics_process(false)
    world.player.position = Vector2(world.noise_actor.position.x+40,217)
    recorder.set_recording_active(true)
    print("AUDIO DRIVER ",AudioServer.get_driver_name()," DEVICE ",AudioServer.output_device)
    for bus in AudioServer.bus_count:
        print("BUS ",AudioServer.get_bus_name(bus)," mute=",AudioServer.is_bus_mute(bus)," db=",AudioServer.get_bus_volume_db(bus)," send=",AudioServer.get_bus_send(bus))
    await create_timer(1.0).timeout
    var music = root.get_node("Music")
    print("PLAYBACK state=",root.get_node("RunState").state," playing=",music.player.playing," paused=",music.player.stream_paused," position=",music.player.get_playback_position()," enemy=",world.noise_actor.phase)
    print("MASTER PEAK ",AudioServer.get_bus_peak_volume_left_db(0,0))
    await create_timer(4.0).timeout
    recorder.set_recording_active(false)
    var recording := recorder.get_recording()
    var samples := recording.data
    var peak := 0
    for i in int(samples.size()/2.0):
        peak = maxi(peak,absi(samples.decode_s16(i*2)))
    print("CLING MASTER MIX seconds=",recording.get_length()," peak=",peak," clipped=",peak>=32767)
    if peak > 0 and AudioServer.get_bus_channels(0) == 1:
        print("WAV RESULT ",recording.save_to_wav("res://test-user/cling-master-mix.wav"))
    else: push_error("INVALID MIX CAPTURE . REQUIRE NONZERO STEREO SIGNAL")
    AudioServer.remove_bus_effect(0,effect_index)
    world.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture+suffix)
    quit()
