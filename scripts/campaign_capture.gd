extends SceneTree
func _initialize() -> void:
    run.call_deferred()
func frames(n: int = 5) -> void:
    for i in n: await physics_frame
func capture(scene: Node, name: String) -> void:
    await frames(5)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png('res://test-user/' + name + '.png')
    print('CAPTURE ' + name)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user"))
    var scene = load('res://scenes/main.tscn').instantiate()
    root.add_child(scene)
    current_scene = scene
    var run_state = root.get_node('RunState')
    run_state.boundary_path = 'res://test-user/capture-save.json'
    await frames()
    run_state.start_run()
    await frames()
    run_state.win()
    await capture(scene, 'relay-clear')
    run_state.advance_relay()
    await frames(180)
    await capture(scene, 'listening-hub')
    scene.player.reset_at(Vector2(780,223))
    scene.snap_camera()
    await frames(30)
    await capture(scene, 'memory-spoke')
    run_state.objectives = ['NORTH','EAST','SOUTH']
    run_state.win()
    run_state.advance_relay()
    await frames(180)
    scene.player.reset_at(Vector2(1530,151))
    scene.snap_camera()
    await frames(340)
    await capture(scene, 'the-stand')
    scene.queue_free()
    await frames()
    quit()
