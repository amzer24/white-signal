extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
    if not value:
        failures += 1
        print("FAIL ",label)
func _initialize() -> void: call_deferred("run")
func frames(n := 4) -> void:
    for i in n: await process_frame
func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event
func run() -> void:
    var music = root.get_node("Music")
    var state = root.get_node("RunState")
    var settings = root.get_node("AppSettings")
    var world = load("res://scenes/exploration.tscn").instantiate()
    world.save_path = "res://test-user/music_lifecycle.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(world.save_path+suffix)
    root.add_child(world)
    await frames()
    check(music.exploration_active and music.track_id == "exploration","exploration selects its score")
    check(music.player.playing and music.player.stream.loop,"exploration starts looping audio")
    check(absf(music.player.stream.get_length()-64.919708) < .002,"import retains loop length")
    var original = music.player.stream
    music.player.seek(12)
    await frames()
    world.enter_room("conduit")
    world.respawn()
    await frames()
    check(music.player.stream == original and music.player.get_playback_position() > 11,"room and death preserve playback")
    world._unhandled_input(key(KEY_M))
    await frames()
    check(music.player.stream_paused,"map pauses music")
    var position: float = music.player.get_playback_position()
    await frames(12)
    check(absf(music.player.get_playback_position()-position) < .08,"paused cursor holds")
    world._unhandled_input(key(KEY_ESCAPE))
    await frames()
    check(not music.player.stream_paused and music.player.get_playback_position() > 11,"map close resumes same position")
    world._controller_lost()
    await frames()
    check(music.player.stream_paused,"controller disconnect pauses music")
    world._unhandled_input(key(KEY_ESCAPE))
    await frames()
    music.player.seek(music.player.stream.get_length()-.08)
    await frames(30)
    check(music.player.playing and music.player.get_playback_position() < 2,"imported stream wraps without stopping")
    var volume: float = settings.music_volume
    settings.set_volume("music",0,false)
    check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"music slider still mutes score")
    settings.set_volume("music",volume,false)
    state.state = "menu"
    world.queue_free()
    await frames()
    check(not music.exploration_active and not music.player.playing,"leaving exploration stops score")
    state.lab_active = false
    state.relay_index = 0
    state.state = "play"
    state.state_changed.emit("play")
    check(music.track_id == "tutorial" and music.player.stream is AudioStreamWAV,"Classic restores tutorial WAV")
    check(music.player.volume_db == 0 and music.player.playing,"Classic restores original gain and playback")
    state.relay_index = 1
    state.state_changed.emit("play")
    check(not music.player.playing,"later Classic relay has no tutorial bleed")
    state.state = "menu"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/music_lifecycle.json"+suffix)
    print("MUSIC LIFECYCLE: %d failures" % failures)
    quit(1 if failures else 0)
