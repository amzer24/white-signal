extends SceneTree
var cues := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func heard(node: Node) -> void:
    if node is AudioStreamPlayer: cues += 1
func check(ok: bool, label: String) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/source-audio-%d.json" % OS.get_process_id()
    scene.save_path = path
    root.add_child(scene)
    scene.set_physics_process(false)
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored","gate_latched"]: scene.profile.set_flag(flag)
    scene.enter_room("source_return")
    root.get_node("Sfx").child_entered_tree.connect(heard)
    scene.gate.use("gate_isolate")
    scene.gate.tick(0.375)
    check(cues == 1,"first verified feed emits one cue")
    scene.map_open = true
    scene.gate.tick(5)
    check(cues == 1,"map pause emits no duplicate")
    scene.map_open = false
    scene.gate.tick(0.375)
    scene.gate.tick(0.375)
    scene.gate.tick(0.375)
    check(cues == 4,"three progress cues and one successful lock cue")
    scene.gate.tick(10)
    scene.gate.use("gate_isolate")
    scene.gate.enter()
    check(cues == 4,"completed reuse and reset do not replay")
    scene.profile.data.flags.erase("gate_tested")
    scene.profile.data.flags.erase("gate_isolated")
    scene.profile.path = "res://test-user/missing-audio-profile/profile.json"
    scene.gate.use("gate_isolate")
    scene.gate.tick(2)
    check(cues == 5 and not scene.profile.has_flag("gate_tested"),"failed write emits rejection only, no success burst")
    scene.profile.path = path
    scene.gate.use("gate_isolate")
    scene.gate.tick(2)
    check(cues == 6 and scene.profile.has_flag("gate_tested"),"immediate retry is audible; slow frame emits one completion")
    root.get_node("Sfx").child_entered_tree.disconnect(heard)
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    print("SOURCE AUDIO: %d failures" % failures)
    quit(1 if failures else 0)
