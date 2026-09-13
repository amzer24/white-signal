extends SceneTree
class MenuHost extends Node2D:
    var can_resume := true
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var host := MenuHost.new()
    root.add_child(host)
    var menu = load("res://scripts/menu_ui.gd").new()
    var path := "res://test-user/menu_resume_test.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    menu.exploration_path = path
    host.add_child(menu)
    assert(menu.home_items()[0][0] == "START EXPLORATION")
    var profile = load("res://scripts/exploration_save.gd").new()
    profile.path = path
    assert(profile.enter_room("drowned_gallery"))
    menu.refresh_exploration()
    assert(menu.home_items()[0][0] == "RESUME EXPLORATION")
    assert(menu.home_items()[0][1].contains("GALLERY"))
    assert(menu.home_items()[1][0] == "NEW EXPLORATION")
    assert(menu.home_items()[2][0] == "RESUME CLASSIC")
    assert(menu.home_items()[3][0] == "NEW CLASSIC RUN")
    if not DisplayServer.get_name() == "headless":
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://test-user/menu-resume.png")
    var original := FileAccess.get_file_as_bytes(path)
    menu.refresh_exploration()
    assert(FileAccess.get_file_as_bytes(path) == original)
    assert(DirAccess.copy_absolute(path,path+".bak") == OK)
    var file := FileAccess.open(path,FileAccess.WRITE)
    file.store_string("broken")
    file.close()
    menu.refresh_exploration()
    assert(menu.exploration_detail.begins_with("BACKUP AVAILABLE"))
    DirAccess.remove_absolute(path+".bak")
    menu.refresh_exploration()
    assert(menu.exploration_detail == "SAVE UNREADABLE . ORIGINAL RETAINED")
    assert(FileAccess.get_file_as_string(path) == "broken")
    host.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("MENU RESUME: fresh, saved, classic, backup and unreadable states passed; preview never writes save")
    quit()
