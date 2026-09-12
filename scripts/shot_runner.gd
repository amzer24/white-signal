extends Node
## Screenshot runner — boots, starts a run, captures frames at key spots.
## WS_SHOT=1 godot --rendering-driver opengl3 (or under xvfb)

var shots := [
    {"x": 300.0, "y": 223.0, "name": "z0_vista"},
    {"x": 1300.0, "y": 223.0, "name": "ruins"},
    {"x": 2480.0, "y": 223.0, "name": "shaft"},
]

func _ready() -> void:
    _run.call_deferred()

func _run() -> void:
    for i in 10:
        await get_tree().physics_frame
    var world := get_parent()
    var player: CharacterBody2D = world.get_node("Player")
    RunState.start_run()
    player.invuln = 999.0
    for s in shots:
        player.global_position = Vector2(s.x, s.y)
        player.velocity = Vector2.ZERO
        for i in 40:
            await get_tree().physics_frame
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("/tmp/ws_shots_%s.png" % s.name)
        print("SHOT %s saved" % s.name)
    RunState.state = "menu"
    await RenderingServer.frame_post_draw
    var img2 := get_viewport().get_texture().get_image()
    img2.save_png("/tmp/ws_shots_menu.png")
    print("SHOT menu saved")
    get_tree().quit(0)