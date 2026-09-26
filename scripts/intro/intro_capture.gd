extends SceneTree
## Screenshots of the story intro at the key moment of each card, then the
## hand-off into Last Relay. Writes PNGs to test-user/intro/.
##   godot --path . --script res://scripts/intro/intro_capture.gd

const SPOTS := [[0, 3.0, "01-the-line"], [1, 3.05, "02-relay"], [2, 4.0, "03-noise"], [3, 1.3, "04-cut"],
	[3, 4.6, "04b-lights-out"], [4, 4.0, "05-quiet"], [5, 3.0, "06-spark"], [6, 4.0, "07-rings"],
	[7, 1.0, "08-flare"], [7, 4.0, "08b-awake"], [8, 4.8, "09-last-relay"], [9, 3.0, "10-window"]]

var intro


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-user/intro/%s.png" % name)
	print("CAPTURE ", name)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/intro"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(960, 540))
	intro = load("res://scenes/intro.tscn").instantiate()
	root.add_child(intro)
	await frames(3)
	for spot in SPOTS:
		intro._enter_card(spot[0])
		intro.ct = spot[1]
		intro.fired.clear()
		for k in intro.fired:
			pass
		await frames(1)
		intro.ct = spot[1]
		intro._update_shader()
		intro.queue_redraw()
		await frames(1)
		await shot(spot[2])
	print("INTRO CAPTURE DONE")
	quit()
