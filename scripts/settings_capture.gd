extends SceneTree

var failures := 0
func check(label: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func _initialize() -> void: run.call_deferred()
func shot(name: String) -> void:
    for i in 3: await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.impeccable/review/"+name+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.impeccable/review"))
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(960,540))
    # Mute at the master only: capture the actual Music bus without playing aloud.
    AudioServer.set_bus_mute(0,true)
    var capture := AudioEffectCapture.new()
    capture.buffer_length = 2.0
    var bus := AudioServer.get_bus_index("Music")
    AudioServer.add_bus_effect(bus,capture)
    var world = load("res://scenes/main.tscn").instantiate()
    root.add_child(world)
    current_scene = world
    var rs = root.get_node("RunState")
    var settings = root.get_node("AppSettings")
    settings.save_path = "res://test-user/settings-capture.cfg"
    settings.set_volume("music",0.65,false)
    settings.set_volume("effects",0.8,false)
    rs.boundary_path = "res://test-user/settings-capture-save.json"
    var hud = world.get_node("HUDLayer/HUD")
    var menu = hud.menu_ui
    hud.can_resume = false
    await shot("menu-960")
    hud.can_resume = true
    await shot("menu-continue-960")
    menu.open_settings()
    await shot("settings-960")
    DisplayServer.window_set_size(Vector2i(1280,720))
    await shot("settings-1280")
    menu.back()
    menu.page = "controls"
    await shot("controls-1280")
    menu.page = "home"
    await shot("menu-1280")
    capture.clear_buffer()
    rs.start_run()
    await create_timer(0.8).timeout
    var audio = root.get_node("Music").player
    var samples := capture.get_buffer(capture.get_frames_available())
    var peak := 0.0
    for sample in samples: peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
    check("tutorial produces real audio samples",samples.size()>0 and peak>0.0001)
    print("AUDIO frames=",samples.size()," peak=",peak)
    audio.seek(audio.stream.get_length()-0.10)
    await create_timer(0.45).timeout
    check("track crosses endpoint and loops",audio.playing and audio.get_playback_position()<1.0)
    rs.toggle_pause()
    var paused_at: float = audio.get_playback_position()
    await create_timer(0.2).timeout
    check("pause holds actual playback position",absf(audio.get_playback_position()-paused_at)<0.02)
    menu.open_settings()
    DisplayServer.window_set_size(Vector2i(960,540))
    await shot("pause-settings-960")
    menu.back()
    await shot("pause-960")
    rs.toggle_pause()
    await create_timer(0.2).timeout
    check("resume continues rather than rewinds",audio.get_playback_position()>paused_at)
    rs._enter_relay(1)
    check("entering R1 stops audio playback",not audio.playing)
    settings.toggle_fullscreen()
    await process_frame
    check("fullscreen setting changes the actual window",DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN)
    settings.toggle_fullscreen()
    await process_frame
    check("fullscreen can return to windowed",DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_WINDOWED and not settings.fullscreen)
    print("SETTINGS RENDER/AUDIO: %d failure(s)"%failures)
    quit(1 if failures else 0)
