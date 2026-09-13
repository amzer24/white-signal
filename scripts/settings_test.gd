extends SceneTree

var failures := 0
func check(label: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event
func pad(code: int) -> InputEventJoypadButton:
    var event := InputEventJoypadButton.new()
    event.button_index = code
    event.pressed = true
    return event
func click(at: Vector2, pressed := true) -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.position = at
    event.pressed = pressed
    return event
func frames(n := 3) -> void:
    for i in n: await physics_frame
func _initialize() -> void: run.call_deferred()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user"))
    var settings = root.get_node("AppSettings")
    settings.save_path = "res://test-user/settings-test.cfg"
    settings.set_volume("music",0.35)
    settings.set_volume("effects",0.0)
    check("music and effects have separate buses",AudioServer.get_bus_index("Music")>0 and AudioServer.get_bus_index("SFX")>0)
    check("zero effects volume mutes only SFX",AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
    settings.music_volume = 1
    settings.sfx_volume = 1
    settings.load_preferences()
    settings.apply_audio()
    check("volume preferences reload",is_equal_approx(settings.music_volume,0.35) and settings.sfx_volume==0)
    check("invalid volume types use defaults",settings.safe_volume("broken",0.65)==0.65 and settings.safe_volume(NAN,0.8)==0.8)
    var world = load("res://scenes/main.tscn").instantiate()
    root.add_child(world)
    current_scene = world
    var rs = root.get_node("RunState")
    var music = root.get_node("Music")
    rs.boundary_path = "res://test-user/settings-campaign.json"
    await frames()
    var hud = world.get_node("HUDLayer/HUD")
    var menu = hud.menu_ui
    settings.reduced_flashes = true
    hud._on_state("draft")
    check("reduced flash suppresses full-screen surge",hud._surge_flash == 0)
    settings.reduced_flashes = false
    hud._on_state("draft")
    check("standard effects retain surge feedback",hud._surge_flash > 0)
    settings.reduced_flashes = true
    check("title is silent",not music.player.playing)
    menu.handle_input(click(Vector2(20,20)))
    check("background clicks do not start a run",rs.state=="menu")
    menu.handle_input(key(KEY_O))
    check("settings opens from title",menu.page=="settings" and rs.state=="menu")
    menu.selected = 4
    menu.handle_input(key(KEY_ENTER))
    check("camera shake row remains in settings",menu.page == "settings")
    settings.camera_shake = false
    settings.save_preferences()
    settings.camera_shake = true
    settings.load_preferences()
    check("camera shake preference reloads",not settings.camera_shake)
    world.fx_node.shake(10)
    await frames()
    check("disabled shake keeps camera steady",world.cam.offset == Vector2.ZERO)
    menu.open_settings()
    menu.handle_input(key(KEY_RIGHT))
    check("keyboard adjusts music",is_equal_approx(settings.music_volume,0.4))
    menu.handle_input(click(Vector2(230,96)))
    menu.handle_input(click(Vector2(230,96),false))
    check("slider click can mute music",settings.music_volume==0 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
    menu.handle_input(key(KEY_ESCAPE))
    check("settings back returns to title",menu.page=="home" and rs.state=="menu")
    # Use the visible NEW RUN row, including when an older test save exists.
    var items: Array = menu.home_items()
    for i in items.size():
        if items[i][2]=="new": menu.selected=i
    menu.handle_input(key(KEY_ENTER))
    await frames()
    check("new run starts tutorial track",rs.state=="play" and music.player.playing)
    var track: AudioStreamWAV = music.player.stream
    check("supplied track loops full 113.16 seconds",is_equal_approx(track.get_length(),113.16) and track.loop_mode==AudioStreamWAV.LOOP_FORWARD and track.loop_end==5431680)
    var playback: AudioStreamPlayback = music.player.get_stream_playback()
    rs.manual_respawn()
    await frames(80)
    check("death does not replace music playback",music.player.get_stream_playback()==playback)
    rs.toggle_pause()
    hud._unhandled_input(key(KEY_O))
    check("pause settings preserves paused run and audio",menu.page=="settings" and rs.state=="pause" and music.player.stream_paused)
    menu.handle_input(key(KEY_ESCAPE))
    check("back from pause settings stays paused",menu.page=="home" and rs.state=="pause")
    rs.toggle_pause()
    check("resume keeps same music playback",not music.player.stream_paused and music.player.get_stream_playback()==playback)
    hud._unhandled_input(pad(JOY_BUTTON_START))
    check("controller pauses classic run",rs.state == "pause")
    hud._unhandled_input(pad(JOY_BUTTON_X))
    check("controller opens pause settings",menu.page == "settings")
    menu.back()
    hud._unhandled_input(pad(JOY_BUTTON_B))
    check("controller resumes classic run",rs.state == "play")
    var bridge = root.get_node("GameInput")
    bridge.active_device = 12
    bridge.controller_active = true
    Input.action_press("move_right")
    bridge._connection_changed(12,false)
    check("disconnect pauses classic and releases movement",rs.state == "pause" and not Input.is_action_pressed("move_right"))
    if rs.state == "pause": hud._unhandled_input(pad(JOY_BUTTON_B))
    rs.open_draft()
    hud._unhandled_input(pad(JOY_BUTTON_B))
    check("controller skips draft",rs.state == "play" and rs.draft_opts.is_empty())
    for index in 3:
        rs.deck.clear()
        rs.apply_deck()
        rs.open_draft()
        var choice: String = rs.draft_opts[index]
        hud._unhandled_input(pad([JOY_BUTTON_A,JOY_BUTTON_X,JOY_BUTTON_Y][index]))
        check("controller picks draft slot %d" % (index+1),rs.state == "play" and rs.deck.has(choice))
    rs._enter_relay(1)
    var saved := FileAccess.get_file_as_string(rs.boundary_path)
    check("tutorial song stops in R1",not music.player.playing)
    rs.start_lab()
    check("tutorial song stays off in Afterlight",not music.player.playing)
    rs.leave_lab()
    menu.open_settings()
    menu.handle_input(key(KEY_RIGHT))
    check("settings leaves campaign save unchanged",FileAccess.get_file_as_string(rs.boundary_path)==saved and rs.load_boundary().relay==1)
    menu.back()
    settings.set_volume("effects",0.8)
    root.get_node("Sfx").beep(440,0.05)
    var sfx = root.get_node("Sfx")
    check("synthesized effects use SFX bus",sfx.get_child(sfx.get_child_count()-1).bus=="SFX")
    await frames(20)
    print("SETTINGS/AUDIO: %d failure(s)"%failures)
    quit(1 if failures else 0)
