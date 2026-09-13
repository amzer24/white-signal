extends SceneTree
func _initialize() -> void: call_deferred("run")
func key(menu: Node, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    menu.handle_input(event)
func pad(menu: Node, code: int) -> void:
    var event := InputEventJoypadButton.new()
    event.button_index = code
    event.pressed = true
    menu.handle_input(event)
func run() -> void:
    var main = load("res://scenes/main.tscn").instantiate()
    root.add_child(main)
    var menu = main.get_node("HUDLayer/HUD").menu_ui
    var path := "res://test-user/recovery-menu-%d.json" % OS.get_process_id()
    var file := FileAccess.open(path,FileAccess.WRITE)
    file.store_string("original damaged bytes")
    file.close()
    menu.exploration_path = path
    menu.refresh_exploration()
    key(menu,KEY_ENTER)
    assert(menu.page == "recovery" and menu.selected == 0)
    key(menu,KEY_ENTER)
    assert(menu.page == "home" and FileAccess.get_file_as_string(path) == "original damaged bytes")
    key(menu,KEY_ENTER)
    key(menu,KEY_DOWN)
    key(menu,KEY_ENTER)
    assert(menu.page == "recovery_confirm" and menu.selected == 0)
    pad(menu,JOY_BUTTON_B)
    assert(menu.page == "home" and FileAccess.get_file_as_string(path) == "original damaged bytes")
    pad(menu,JOY_BUTTON_A)
    pad(menu,JOY_BUTTON_DPAD_DOWN)
    pad(menu,JOY_BUTTON_A)
    pad(menu,JOY_BUTTON_DPAD_DOWN)
    pad(menu,JOY_BUTTON_A)
    assert(menu.page == "recovery_done" and menu.selected == 0 and not menu.exploration_unreadable)
    assert(DirAccess.dir_exists_absolute(menu.recovery_archive))
    pad(menu,JOY_BUTTON_A)
    assert(menu.page == "home")
    var profile = load("res://scripts/exploration_save.gd").new()
    profile.path = path
    assert(profile.load_profile() and profile.data.room == "flats")
    var folder := DirAccess.open("res://test-user")
    for name in folder.get_directories():
        if name.begins_with(path.get_file()+".retained-"):
            var original := "res://test-user/"+name+"/"+path.get_file()
            assert(FileAccess.get_file_as_string(original) == "original damaged bytes")
            DirAccess.remove_absolute(original)
            DirAccess.remove_absolute("res://test-user/"+name)
    DirAccess.remove_absolute(path)
    main.queue_free()
    await process_frame
    print("RECOVERY MENU: keyboard cancel, controller cancel, deliberate confirmation and retained original passed")
    quit()
