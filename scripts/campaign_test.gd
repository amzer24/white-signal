extends SceneTree

var failures := 0
func check(label: String, ok: bool) -> void:
    print(('PASS ' if ok else 'FAIL ') + label)
    if not ok: failures += 1
func frames(n: int = 4) -> void:
    for i in n: await physics_frame
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-user"))
    var scene = load('res://scenes/main.tscn').instantiate()
    root.add_child(scene)
    current_scene = scene
    await frames(8)
    var run_state = root.get_node('RunState')
    run_state.boundary_path = "res://test-user/campaign.json"
    run_state.start_run()
    await frames()
    run_state.deck = ['dash', 'aegis']
    run_state.apply_deck()
    run_state.gems = 7
    run_state.last_surge = 1
    run_state.win()
    check('tutorial exits to next relay instead of final victory', run_state.state == 'relay_clear')
    check('campaign transition exists', run_state.has_method('advance_relay'))
    if not run_state.has_method('advance_relay'):
        quit(1)
        return
    run_state.advance_relay()
    await frames(8)
    for index in [1,2]:
        var data: Dictionary = LevelData.get_level(index)
        var clear := true
        for gem in data.gems:
            for surface in data.platforms + data.crumbles:
                if Rect2(surface.r).has_point(gem): clear = false
        check('R%d pickups are outside solid geometry' % index, clear)
    check('R1 has three ears', scene.fixtures.filter(func(f): return f.kind == 'ear').size() == 3)
    check('transition preserves build and shard remainder', run_state.deck == ['dash', 'aegis'] and run_state.gems == 7)
    check('R1 entered at its spawn', scene.player.position.distance_to(run_state.level.spawn) < 50)
    run_state.win()
    check('R1 exit refuses incomplete objective', run_state.state == 'play')
    var ears = scene.fixtures.filter(func(f): return f.kind == 'ear')
    for ear in ears:
        scene.player.position = ear.position + Vector2(0, -7)
        await frames(2)
    check('all three ears wake', run_state.objectives.size() == 3)
    run_state.register_death()
    await frames()
    check('death preserves restored dishes', run_state.objectives.size() == 3)
    var block = scene.fixtures.filter(func(f): return f.kind == 'memory')[0]
    var before = run_state.gems
    block.strike()
    block.strike()
    check('memory block pays once', run_state.gems == before + 1)
    var solid = scene.fixtures.filter(func(f): return f.kind == 'memory' and not f.spent)[0]
    if run_state.state == 'draft': run_state.skip_draft()
    scene.player.reset_at(solid.position + Vector2(0, 44))
    scene.player.velocity = Vector2(0, -260)
    Input.action_press('jump')
    await frames(24)
    Input.action_release('jump')
    check('real ceiling collision strikes memory block', solid.spent)
    before = run_state.gems - 1

    if run_state.state == 'draft': run_state.skip_draft()
    run_state.register_death()
    await frames()
    block.strike()
    check('death cannot farm block', run_state.gems == before + 1)
    var pipe = scene.fixtures.filter(func(f): return f.kind == 'conduit')[0]
    scene.player.reset_at(pipe.position + Vector2(0, -7))
    await frames(3)
    check('conduit never activates by proximity', scene.player.position.distance_to(pipe.position) < 20)
    Input.action_press('interact')
    await frames(2)
    Input.action_release('interact')
    check('down enters conduit', scene.player.position.distance_to(pipe.destination) < 15)
    await frames(30)
    Input.action_press('interact')
    await frames(2)
    Input.action_release('interact')
    check('paired conduit returns safely', scene.player.position.distance_to(pipe.position) < 20)
    run_state.win()
    check('all ears allow relay clear', run_state.state == 'relay_clear')
    run_state.advance_relay()
    await frames(8)
    check('R2 loads distinct geometry', run_state.relay_index == 2 and run_state.level.name == 'THE STAND')
    check('boundary snapshot exists', not run_state.load_boundary().is_empty())
    run_state.deck = []
    run_state.resume_run()
    await frames(8)
    check('resume restores relay and deck', run_state.relay_index == 2 and run_state.deck == ['dash', 'aegis'])
    run_state.win()
    check('unfinished campaign is honestly labelled', run_state.state == 'build_complete')
    run_state.start_run()
    await frames(8)
    check('new run returns to tutorial with fresh deck', run_state.relay_index == 0 and run_state.deck.is_empty())
    check('new run rebuilds every shard', scene.gems.size() == run_state.level.gems.size())

    var file := FileAccess.open(run_state.boundary_path, FileAccess.WRITE)
    file.store_string('{"version":1,"relay":999}')
    file.close()
    check('corrupt boundary is ignored', run_state.load_boundary().is_empty())
    scene.queue_free()
    await frames(4)
    print('CAMPAIGN: %d failure(s)' % failures)
    quit(1 if failures else 0)
