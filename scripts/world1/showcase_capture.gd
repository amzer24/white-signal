extends SceneTree
## Renders the World 1 and World 2 showcase to PNGs in test-user/world1-art/.
## "E:/Godot games/Godot_v4.7.2-stable_win64.exe" --path . --resolution 960x540 --script res://scripts/world1/showcase_capture.gd
## Optional: -- only=<name-prefix> to capture a subset.

const OUT := "res://test-user/world1-art/"

## [file name, page, clock, level index (-1 = none), scroll, shader]
const SHOTS := [
	["g0-terrain", 0, 1.35, -1, 0.0, true],
	["g1-traps", 1, 1.0, -1, 0.0, true],
	["g2-actors", 2, 1.3, -1, 0.0, true],
	["g3-landmark", 3, 3.3, -1, 0.0, true],
	["g4-switchyard", 4, 1.85, -1, 0.0, true],
	["g4-switchyard-b", 4, 2.05, -1, 0.0, true],
	["g5-relay", 5, 1.8, -1, 0.0, true],
	["g5-relay-b", 5, 8.2, -1, 0.0, true],
	["g6-backdrop", 6, 20.0, -1, 0.0, true],
	["g4-switchyard-noshader", 4, 1.85, -1, 0.0, false],
	["g7-atmosphere-dark", 7, 1.2, -1, 0.0, true],
	["g7-atmosphere-ignite", 7, 2.45, -1, 0.0, true],
	["g7-atmosphere-medium", 7, 3.4, -1, 0.0, true],
	["g7-atmosphere-large", 7, 7.3, -1, 0.0, true],
	["g7-atmosphere-noshader", 7, 3.4, -1, 0.0, false],
	["v0-village", 8, 1.0, -1, 0.0, true],
	["v0-village-b", 8, 8.6, -1, 0.0, true],
	["v0-village-noshader", 8, 1.0, -1, 0.0, false],
	["v1-village-sheets", 9, 1.3, -1, 0.0, true],
	["v1-village-sheets-noshader", 9, 1.3, -1, 0.0, false],
	["j1-a", 10, 0.66, -1, 0.0, true],
	["j1-b", 10, 0.93, -1, 0.0, true],
	["j1-c", 10, 1.08, -1, 0.0, true],
	["j1-d", 10, 1.6, -1, 0.0, true],
	["j2-a", 11, 0.9, -1, 0.0, true],
	["j2-b", 11, 1.12, -1, 0.0, true],
	["j2-c", 11, 1.48, -1, 0.0, true],
	["j2-d", 11, 3.25, -1, 0.0, true],
	["j3-a", 12, 0.66, -1, 0.0, true],
	["j3-b", 12, 1.02, -1, 0.0, true],
	["j3-c", 12, 1.35, -1, 0.0, true],
	["j3-d", 12, 1.6, -1, 0.0, true],
	["l1-a", 13, 1.0, 0, 0.0, true],
	["l1-b", 13, 1.0, 0, 640.0, true],
	["l1-c", 13, 1.2, 0, 1440.0, true],
	["l1-d", 13, 1.2, 0, 2880.0, true],
	["l2-a", 13, 1.0, 1, 900.0, true],
	["l2-b", 13, 1.0, 1, 1460.0, true],
	["l2-c", 13, 1.0, 1, 1920.0, true],
	["l3-a", 13, 0.85, 2, 400.0, true],
	["l3-b", 13, 1.1, 2, 1900.0, true],
	["l3-c", 13, 1.1, 2, 2900.0, true],
	["l4-a", 13, 1.0, 3, 0.0, true],
	["l4-b", 13, 1.0, 3, 2400.0, true],
	["l4-c", 13, 1.0, 3, 2880.0, true],
	["l1-a-noshader", 13, 1.0, 0, 0.0, false],
	["j1-b-noshader", 10, 0.93, -1, 0.0, false],
]

func _initialize() -> void:
	run.call_deferred()

func frames(n := 3) -> void:
	for _i in n:
		await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	var scene: Node = load("res://scenes/world1_showcase.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.set("auto_clock", false)
	for shot in SHOTS:
		var shot_name: String = shot[0]
		if only != "" and not shot_name.begins_with(only):
			continue
		scene.call("set_shader", shot[5])
		if int(shot[3]) >= 0:
			scene.call("set_level", int(shot[3]), float(shot[4]))
		scene.call("show_page", int(shot[1]))
		scene.call("set_clock", float(shot[2]))
		await frames()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + shot_name + ".png")
		print("CAPTURE " + shot_name)
	if only == "" or only == "live":
		# live sweep: every page with the clock running, driven by the real keys
		scene.set("auto_clock", true)
		scene.call("show_page", 0)
		for key in [KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT,
				KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_RIGHT, KEY_DOWN, KEY_DOWN, KEY_UP, KEY_S, KEY_T, KEY_P, KEY_P, KEY_F, KEY_F, KEY_SPACE, KEY_1]:
			var ev := InputEventKey.new()
			ev.keycode = key
			ev.pressed = true
			Input.parse_input_event(ev)
			await frames(12)
			if key == KEY_DOWN:
				print("LIVE SWEEP on page %d, level %d" % [int(scene.get("page")), int(scene.get("level_idx"))])
		print("LIVE SWEEP done, page %d" % int(scene.get("page")))
	scene.queue_free()
	await frames()
	quit()
