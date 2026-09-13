extends RefCounted
## Explicit user-selected restart only; never called during ordinary loading.
static func restart_unreadable(profile: RefCounted) -> Dictionary:
    if not profile._read(profile.path).is_empty() or not profile._read(profile.path+".bak").is_empty():
        return {"ok":false,"message":"READABLE SAVE EXISTS . RESUME IT"}
    var originals: Dictionary = {}
    for suffix in ["", ".bak", ".tmp"]:
        var source: String = profile.path+suffix
        if FileAccess.file_exists(source): originals[source] = FileAccess.get_file_as_bytes(source)
    if originals.is_empty(): return {"ok":false,"message":"NO DAMAGED SAVE FOUND"}
    var archive: String = profile.path+".retained-"+str(Time.get_unix_time_from_system()).replace(".","-")+"-"+str(Time.get_ticks_usec())
    if DirAccess.make_dir_absolute(archive) != OK:
        return {"ok":false,"message":"COULD NOT RETAIN ORIGINAL . NOTHING CHANGED"}
    for source in originals:
        var copy: String = archive+"/"+source.get_file()
        if DirAccess.copy_absolute(source,copy) != OK or FileAccess.get_file_as_bytes(copy) != originals[source]:
            return {"ok":false,"message":"COPY FAILED . ORIGINALS UNCHANGED","archive":archive}
    # Only remove active files after every retained copy was verified byte-for-byte.
    for source in originals:
        if DirAccess.remove_absolute(source) != OK:
            _restore(originals)
            return {"ok":false,"message":"RESTART FAILED . COPIES RETAINED","archive":archive}
    var previous: Dictionary = profile.data.duplicate(true)
    profile.fresh()
    if not profile.save_profile():
        _restore(originals)
        profile.data = previous
        return {"ok":false,"message":"NEW SAVE FAILED . COPIES RETAINED","archive":archive}
    return {"ok":true,"message":"FRESH JOURNEY READY . ORIGINALS RETAINED","archive":archive}

static func _restore(originals: Dictionary) -> void:
    for source in originals:
        var file := FileAccess.open(source,FileAccess.WRITE)
        if file != null:
            file.store_buffer(originals[source])
            file.close()
