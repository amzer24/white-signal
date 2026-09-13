extends SceneTree
var failures := 0
func check(ok: bool,label: String) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func _initialize() -> void:
    var source = load("res://scripts/source_district_rooms.gd")
    var registry = load("res://scripts/exploration_save.gd").new()
    var legacy_ids: Array = registry.ROOMS
    var fixtures := [{},{"gate_latched":true},{"gate_isolated":true},{"gate_tested":true},{"signal_restored":true}]
    for flags in fixtures:
        var previous: Dictionary = flags.duplicate(true)
        var old_profile := {"version":1,"room":"gate","visited":["flats","gate"],"flags":flags}
        check(registry._valid(old_profile),"old Gate fixture remains schema-valid")
        var rooms: Dictionary = source.rooms(flags)
        check(flags == previous,"adapter does not mutate saved flags")
        check(rooms.size() == 3,"three finale rooms")
        for id in rooms:
            for route in rooms[id].exits:
                check(route[0] in rooms or route[0] in legacy_ids,"known exit "+id+" -> "+route[0])
        var state: Dictionary = source.progress(flags)
        check(rooms.gate.platforms.size() == (7 if state.latched else 4),"prior work restores return stairs")
        check(rooms.source_return.platforms.size() == (5 if state.tested else 4),"verified local bridge restored")
        if state.restored:
            var direct := false
            for route in rooms.gate.exits:
                if route[0] == "aftermath" and route[1].y == 217: direct = true
            check(direct,"completed save retains floor-level route home")
    print("SOURCE ADAPTER: %d failures"%failures)
    quit(1 if failures else 0)

