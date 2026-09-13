extends SceneTree
func _initialize() -> void:
    var profile = load("res://scripts/exploration_save.gd").new()
    profile.path = OS.get_environment("WS_LOCKED_PROFILE")
    assert(not profile.path.is_empty())
    var result: Dictionary = load("res://scripts/save_recovery.gd").restart_unreadable(profile)
    assert(not result.ok)
    assert(FileAccess.get_file_as_string(profile.path) == "locked damaged original")
    assert(not profile.has_flag("dash"))
    if result.has("archive"):
        var original: String = result.archive+"/"+profile.path.get_file()
        if FileAccess.file_exists(original):
            assert(FileAccess.get_file_as_string(original) == "locked damaged original")
            DirAccess.remove_absolute(original)
        DirAccess.remove_absolute(result.archive)
    print("LOCKED RECOVERY: ",result.message," . ORIGINAL UNCHANGED")
    quit()
