extends SceneTree
class FailedWriter extends "res://scripts/exploration_save.gd":
    func save_profile() -> bool:
        last_error = "SIMULATED WRITE FAILURE"
        return false
func write(path: String, contents: String) -> void:
    var file := FileAccess.open(path,FileAccess.WRITE)
    assert(file != null)
    file.store_string(contents)
    file.close()
func _initialize() -> void:
    var recovery = load("res://scripts/save_recovery.gd")
    var profile = FailedWriter.new()
    profile.path = "res://test-user/recovery-failure-%d.json" % OS.get_process_id()
    var originals := {"":"bad current",".bak":"bad backup",".tmp":"pending bytes"}
    for suffix in originals: write(profile.path+suffix,originals[suffix])
    var before: Dictionary = profile.data.duplicate(true)
    var result: Dictionary = recovery.restart_unreadable(profile)
    assert(not result.ok and result.has("archive"))
    assert(profile.data == before)
    for suffix in originals:
        assert(FileAccess.get_file_as_string(profile.path+suffix) == originals[suffix])
        assert(FileAccess.get_file_as_string(result.archive+"/"+profile.path.get_file()+suffix) == originals[suffix])
    print("PASS failed replacement restores active originals and retains verified copies")
    var valid := {"version":1,"room":"hub","visited":["flats","hub"],"flags":{"dash":true}}
    write(profile.path+".bak",JSON.stringify(valid))
    var backup_bytes := FileAccess.get_file_as_bytes(profile.path+".bak")
    var refused: Dictionary = recovery.restart_unreadable(profile)
    assert(not refused.ok and not refused.has("archive"))
    assert(FileAccess.get_file_as_bytes(profile.path+".bak") == backup_bytes)
    assert(FileAccess.get_file_as_string(profile.path) == "bad current")
    print("PASS valid backup blocks restart without altering current or backup")
    for suffix in originals:
        DirAccess.remove_absolute(profile.path+suffix)
        DirAccess.remove_absolute(result.archive+"/"+profile.path.get_file()+suffix)
    DirAccess.remove_absolute(result.archive)
    assert(not recovery.restart_unreadable(profile).ok)
    print("SAVE RECOVERY FAILURE: replacement rollback, valid backup and absent-save protection passed")
    quit()
