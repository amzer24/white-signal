extends SceneTree
var cues := 0
func _initialize() -> void: run.call_deferred()
func heard(node: Node) -> void:
    if node is AudioStreamPlayer: cues += 1
func run() -> void:
    var world = load("res://scenes/exploration.tscn").instantiate()
    var fixture := "res://test-user/cling-audio-%d.json" % OS.get_process_id()
    world.save_path = fixture
    root.add_child(world)
    world.enter_room("array_cable")
    var enemy = world.noise_actor
    enemy.set_physics_process(false)
    world.player.set_physics_process(false)
    world.player.position = Vector2(enemy.position.x+40,217)
    root.get_node("Sfx").child_entered_tree.connect(heard)
    enemy._physics_process(0.01)
    assert(enemy.phase == "warning" and cues == 1)
    root.get_node("RunState").state = "pause"
    enemy._physics_process(10)
    assert(enemy.phase == "warning" and cues == 1)
    root.get_node("RunState").state = "play"
    enemy._physics_process(0.7)
    assert(enemy.phase == "drop" and cues == 1)
    enemy._physics_process(1)
    assert(enemy.phase == "landed" and cues == 2)
    enemy._physics_process(0.2)
    assert(cues == 2)
    enemy._physics_process(1)
    enemy._physics_process(2)
    assert(enemy.phase == "hang" and cues == 2)
    enemy._physics_process(0.01)
    assert(enemy.phase == "warning" and cues == 3)
    root.get_node("Sfx").child_entered_tree.disconnect(heard)
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture+suffix)
    print("CLING AUDIO: warning, impact, pause and repeated cycle passed")
    quit()
