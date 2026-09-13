extends SceneTree

var failed := 0
func check(value: bool, message: String) -> void:
    if not value:
        failed += 1
        print("FAIL: " + message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    if not FileAccess.file_exists("res://scripts/exploration_save.gd"):
        print("FAIL: exploration save module does not exist")
        quit(1)
        return
    var script = load("res://scripts/exploration_save.gd")
    if script == null:
        print("FAIL: exploration save module cannot load")
        quit(1)
        return
    var profile = script.new()
    profile.path = "res://test-user/exploration_contract.json"
    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute(profile.path + suffix)
    profile.fresh()
    check(profile.data.room == "flats", "fresh profile starts at Flats")
    check(not profile.has_flag("dash"), "Dash is not initially acquired")
    check(profile.set_flag("dash"), "Dash transaction saves")
    check(profile.set_flag("return_open"), "return shortcut transaction saves")
    check(profile.enter_room("return"), "valid room transition saves")
    var reloaded = script.new()
    reloaded.path = profile.path
    check(reloaded.load_profile(), "profile reloads")
    check(reloaded.has_flag("dash") and reloaded.has_flag("return_open"), "discoveries survive reload")
    check(reloaded.data.room == "return", "saved room survives reload")
    check("return" in reloaded.data.visited and "flats" in reloaded.data.visited, "map discoveries survive reload")
    check(not reloaded.enter_room("missing-room"), "unknown room rejected")
    # The previous valid copy must recover a malformed latest write.
    check(reloaded.save_profile(), "create a recoverable backup")
    var file := FileAccess.open(profile.path, FileAccess.WRITE)
    file.store_string("{broken")
    file.close()
    var recovery = script.new()
    recovery.path = profile.path
    check(recovery.load_profile(), "malformed current save recovers backup")
    check(recovery.has_flag("dash"), "recovered backup retains Dash")
    for suffix in ["", ".tmp", ".bak"]:
        DirAccess.remove_absolute(profile.path + suffix)
    print("EXPLORATION SAVE: %d failures" % failed)
    quit(1 if failed else 0)
