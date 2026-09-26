extends SceneTree
## Screenshots of the Arc: the swing, a hit on a spiked walker, a cracked wall
## breaking, and the HUD icon. Writes PNGs to test-user/w1-arc/.
##   godot --path . --resolution 960x540 --script res://scripts/world1/w1_arc_capture.gd

var game


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-user/w1-arc/%s.png" % name)
	print("CAPTURE ", name)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user/w1-arc"))
	game = load("res://scenes/world1_play.tscn").instantiate()
	game.progress_path = "res://test-user/w1-arc/capture-progress.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress_path))
	root.add_child(game)
	game.load_level("2-1", Vector2i(-1, -1), false)
	await frames(20)
	await shot("00-cracked-shed")
	game.S.face = 1
	Input.action_press("attack")
	await frames(1)
	Input.action_release("attack")
	await frames(3)
	await shot("01-arc-swing")
	await frames(6)
	await shot("02-wall-breaking")
	game.load_level("2-2", Vector2i(-1, -1), false)
	await frames(10)
	for n in game.L.walkers.size():
		if str(game.L.walkers[n].kind) == "spiky":
			var wp: Vector2 = game.S.walker_pos(n)
			game.S.x = wp.x - 22.0
			game.S.y = wp.y - 7.5
			game.S.face = 1
			game.S.invuln = 5.0
			game.cam_x = game._cam_target(true)
			break
	Input.action_press("attack")
	await frames(1)
	Input.action_release("attack")
	await frames(4)
	game.S.invuln = 0.0
	await shot("03-arc-hits-spiky")
	print("ARC CAPTURE DONE")
	quit()
