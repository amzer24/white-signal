extends SceneTree
var failed := 0
func check(ok: bool,label: String) -> void:
    if not ok:
        failed += 1
        print("FAIL ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var w = load("res://scenes/exploration.tscn").instantiate()
    w.save_path = "res://test-user/drowned_expanded.json"
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(w.save_path+s)
    root.add_child(w)
    w.enter_room("basin")
    check(not w.can_use_exit("drowned_street"),"high water gates descent")
    w.activate("bleed")
    w.activate("bleed")
    w.drowned.tick(3.0)
    check(w.can_use_exit("drowned_street"),"low water opens street")
    w.enter_room("drowned_street")
    w.activate("impeller")
    w.enter_room("drowned_gallery")
    w.activate("air_jump")
    check(w.profile.has_flag("air_jump") and not w.profile.has_flag("pump_repaired"),"gallery grants permanent ability before float")
    w.enter_room("pump")
    w.activate("pump_socket")
    check(not w.can_use_exit("float"),"pump shortcut remains closed before latch")
    w.enter_room("float")
    w.activate("float_valve")
    w.activate("float_valve")
    w.drowned.tick(2.1)
    var path: String = w.profile.path
    w.profile.path = path+"/blocked.json"
    w.activate("float_latch")
    check(not w.profile.has_flag("float_latch") and not w.profile.has_flag("drowned_restored"),"failed save commits neither half of latch")
    w.profile.path = path
    w.activate("float_latch")
    check(w.profile.has_flag("float_latch") and w.profile.has_flag("drowned_restored"),"successful retry commits both latch flags")
    check(w.can_use_exit("pump"),"latch opens short return")
    w.enter_room("drowned_cycle")
    w.activate("cycle_valve")
    w.drowned.tick(3.2)
    w.activate("cycle_archive")
    check(w.profile.has_flag("cycle_archive"),"optional archive saved")
    w.respawn()
    check(w.room_id == "basin" and w.drowned.water_y >= 241,"Drowned recovery uses dry rim and low water")
    check(w.profile.has_flag("air_jump") and w.profile.has_flag("cycle_archive") and w.profile.has_flag("drowned_restored"),"recovery retains discoveries and repair")
    check(w.profile.load_profile(),"expanded room profile reloads")
    w.queue_free()
    await process_frame
    for s in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/drowned_expanded.json"+s)
    for old_room in ["basin","pump","float"]:
        var fixture := "res://test-user/drowned_legacy.json"
        var file := FileAccess.open(fixture,FileAccess.WRITE)
        file.store_string(JSON.stringify({"version":1,"room":old_room,"visited":["basin","pump","float"],"flags":{"impeller":true,"pump_repaired":true,"float_latch":true,"drowned_restored":true,"air_jump":true}}))
        file.close()
        var old = load("res://scenes/exploration.tscn").instantiate()
        old.save_path = fixture
        root.add_child(old)
        check(old.room_id == old_room,"legacy Drowned room resumes")
        check(old.profile.has_flag("air_jump") and old.profile.has_flag("drowned_restored"),"legacy discoveries retained")
        old.enter_room("pump")
        check(old.can_use_exit("float"),"legacy repair opens new shortcut")
        old.enter_room("drowned_dock")
        check(old.can_use_exit("drowned_gallery") and old.can_use_exit("array"),"legacy repair opens freight connection")
        old.queue_free()
        await process_frame
        for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture+suffix)
    print("DROWNED EXPANDED: %d failures" % failed)
    quit(1 if failed else 0)
