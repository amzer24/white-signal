extends SceneTree
class MenuHost extends Node2D:
    var can_resume := true
func _initialize() -> void: run.call_deferred()
func key(menu: Node, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    menu.handle_input(event)
func capture(menu: Node, name: String) -> void:
    if DisplayServer.get_name() == "headless": return
    menu.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://test-user/"+name+".png")
func run() -> void:
    var host := MenuHost.new()
    root.add_child(host)
    var menu = load("res://scripts/menu_ui.gd").new()
    var path := "res://test-user/extras-%d.json" % OS.get_process_id()
    menu.exploration_path = path
    host.add_child(menu)
    var home_index := -1
    for i in menu.home_items().size():
        if menu.home_items()[i][2] == "extras": home_index = i
    assert(home_index >= 0)
    menu.selected = home_index
    key(menu,KEY_ENTER)
    assert(menu.page == "extras" and menu.selected == 0)
    await capture(menu,"extras-menu")
    key(menu,KEY_UP)
    assert(menu.selected == 2)
    key(menu,KEY_DOWN)
    key(menu,KEY_ENTER)
    assert(menu.page == "credits")
    key(menu,KEY_DOWN)
    assert(menu.selected == 0)
    await capture(menu,"credits-menu")
    key(menu,KEY_ESCAPE)
    assert(menu.page == "extras" and menu.selected == 0)
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.pressed = true
    click.position = menu.row_rect(0).get_center()
    menu.handle_input(click)
    assert(menu.page == "credits")
    var pad := InputEventJoypadButton.new()
    pad.button_index = JOY_BUTTON_B
    pad.pressed = true
    menu.handle_input(pad)
    assert(menu.page == "extras")
    key(menu,KEY_ESCAPE)
    assert(menu.page == "home" and menu.selected == home_index)
    assert(not FileAccess.file_exists(path))
    key(menu,KEY_ENTER)
    key(menu,KEY_DOWN)
    key(menu,KEY_ENTER)
    assert(root.get_node("RunState").lab_active)
    host.queue_free()
    await process_frame
    print("EXTRAS MENU: keyboard, mouse, pad back, focus, credits and study passed")
    quit()
