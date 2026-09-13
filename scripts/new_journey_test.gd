extends SceneTree
class MenuHost extends Node2D:
    var can_resume := true
class FailedWriter extends "res://scripts/exploration_save.gd":
    func save_profile() -> bool: return false
func _initialize() -> void: run.call_deferred()
func key(code: int) -> InputEventKey:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    return event
func remove_archive(path: String) -> void:
    for name in DirAccess.get_files_at(path): DirAccess.remove_absolute(path+"/"+name)
    DirAccess.remove_absolute(path)
func run() -> void:
    var profile = load("res://scripts/exploration_save.gd").new()
    profile.path = "res://test-user/new-journey-%d.json" % OS.get_process_id()
    assert(profile.enter_room("hub"))
    assert(profile.set_flag("dash"))
    var original := FileAccess.get_file_as_bytes(profile.path)
    var old_backup := FileAccess.get_file_as_bytes(profile.path+".bak")
    var host := MenuHost.new()
    root.add_child(host)
    var menu = load("res://scripts/menu_ui.gd").new()
    menu.exploration_path = profile.path
    host.add_child(menu)
    root.get_node("RunState").state = "menu"
    assert(menu.home_items().size() == 8)
    assert(menu.home_items()[1][2] == "restart_explore")
    menu.selected = 1
    if DisplayServer.get_name() != "headless":
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://test-user/new-journey-title.png")
    menu.handle_input(key(KEY_ENTER))
    assert(menu.page == "new_journey" and menu.selected == 0)
    menu.handle_input(key(KEY_ESCAPE))
    assert(menu.page == "home" and menu.selected == 1)
    assert(FileAccess.get_file_as_bytes(profile.path) == original)
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_A
    pad.pressed = true
    menu.handle_input(pad)
    assert(menu.page == "new_journey")
    pad = InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_B
    pad.pressed = true
    menu.handle_input(pad)
    assert(menu.page == "home" and FileAccess.get_file_as_bytes(profile.path) == original)
    menu.handle_input(key(KEY_ENTER))
    if DisplayServer.get_name() != "headless":
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://test-user/new-journey-confirm.png")
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.pressed = true
    click.position = menu.row_rect(1).get_center()
    menu.handle_input(click)
    assert(menu.page == "recovery_done")
    assert(FileAccess.get_file_as_bytes(menu.recovery_archive+"/"+profile.path.get_file()) == original)
    assert(FileAccess.get_file_as_bytes(menu.recovery_archive+"/"+profile.path.get_file()+".bak") == old_backup)
    assert(profile.load_profile() and profile.data.room == "flats" and profile.data.flags.is_empty())
    remove_archive(menu.recovery_archive)
    assert(profile.set_flag("dash"))
    original = FileAccess.get_file_as_bytes(profile.path)
    var broken := FailedWriter.new()
    broken.path = profile.path
    var result: Dictionary = load("res://scripts/save_recovery.gd").restart_readable(broken)
    assert(not result.ok and FileAccess.get_file_as_bytes(profile.path) == original)
    assert(broken.has_flag("dash"))
    remove_archive(result.archive)
    host.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(profile.path+suffix)
    print("NEW JOURNEY: cancel, retained current/backup, fresh start and failed-write rollback passed")
    quit()
