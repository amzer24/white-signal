extends RefCounted
## Explicit transactional exploration profile; no legacy save references.
const ROOMS := ["array_shutter","source_return","source_walk","array_cable","wire_shaft","array_inspection","drowned_street","drowned_gallery","drowned_dock","drowned_cycle","stand_rim","stand_charge","stand_bridge","stand_sluice","stand_trial","siphon","hub","workshop","gallery","amplifier","return","lookout","basin","pump","float","shelter","conductor","causeway","cellar","sump","fourth","flats","conduit","arrival","wire_shelter","wire_carriage","array","approach","gate","aftermath"]
var path: String = "user://ws_exploration_v1.json"
var data: Dictionary = {}
var last_error: String = ""
var recovered_backup := false

func _init() -> void:
    fresh()

func fresh() -> void:
    data = {"version":1,"room":"flats","visited":["flats"],"flags":{}}
    last_error = ""
    recovered_backup = false

func has_flag(id: String) -> bool:
    return bool(data.flags.get(id,false))

func _valid(raw: Variant) -> bool:
    if not raw is Dictionary: return false
    if not raw.get("version") is float and not raw.get("version") is int: return false
    if raw.version != 1: return false
    if not raw.get("room") is String or not raw.room in ROOMS: return false
    if not raw.get("visited") is Array or not raw.get("flags") is Dictionary: return false
    for item in raw.visited:
        if not item is String or not item in ROOMS: return false
    for key in raw.flags:
        if not key is String or key.is_empty() or key.length() > 64: return false
        if not raw.flags[key] is bool: return false
    return raw.room in raw.visited

func _read(candidate: String) -> Dictionary:
    if not FileAccess.file_exists(candidate): return {}
    var file := FileAccess.open(candidate,FileAccess.READ)
    if file == null: return {}
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK: return {}
    var raw = parser.data
    return raw if _valid(raw) else {}

func load_profile() -> bool:
    var loaded := _read(path)
    recovered_backup = false
    if loaded.is_empty():
        loaded = _read(path+".bak")
        recovered_backup = not loaded.is_empty()
    if loaded.is_empty():
        last_error = "PROFILE UNREADABLE" if FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak") else ""
        return false
    data = loaded.duplicate(true)
    last_error = ""
    return true

func set_flag(id: String,value: bool = true) -> bool:
    return set_flags({id:value})

func set_flags(values: Dictionary) -> bool:
    for id in values:
        if not id is String or id.is_empty() or id.length() > 64 or not values[id] is bool:
            last_error = "INVALID DISCOVERY"
            return false
    var previous := data.duplicate(true)
    for id in values: data.flags[id] = values[id]
    if save_profile(): return true
    data = previous
    return false

func enter_room(id: String) -> bool:
    if not id in ROOMS:
        last_error = "UNKNOWN ROOM"
        return false
    var previous := data.duplicate(true)
    data.room = id
    if not id in data.visited: data.visited.append(id)
    if save_profile(): return true
    data = previous
    return false

func save_profile() -> bool:
    if not _valid(data):
        last_error = "INVALID PROFILE"
        return false
    # Never silently overwrite an unreadable profile without a valid recovery.
    if FileAccess.file_exists(path) and _read(path).is_empty() and not recovered_backup:
        last_error = "PROFILE UNREADABLE . RECOVERY REQUIRED"
        return false
    var tmp := path+".tmp"
    var bak := path+".bak"
    var file := FileAccess.open(tmp,FileAccess.WRITE)
    if file == null: return _failure("WRITE FAILED")
    file.store_string(JSON.stringify(data))
    file.flush()
    var write_error := file.get_error()
    file.close()
    if write_error != OK or _read(tmp).is_empty(): return _failure("WRITE INCOMPLETE")
    if FileAccess.file_exists(path):
        if recovered_backup:
            # Keep the known-good backup while discarding only the malformed current.
            if DirAccess.remove_absolute(path) != OK: return _failure("RECOVERY REPLACE FAILED")
        else:
            if FileAccess.file_exists(bak) and DirAccess.remove_absolute(bak) != OK: return _failure("BACKUP LOCKED")
            if DirAccess.rename_absolute(path,bak) != OK: return _failure("BACKUP FAILED")
    if DirAccess.rename_absolute(tmp,path) != OK:
        if FileAccess.file_exists(bak) and not FileAccess.file_exists(path):
            # Copy, retaining the backup even if restoring the current copy fails.
            DirAccess.copy_absolute(bak,path)
        return _failure("COMMIT FAILED")
    recovered_backup = false
    last_error = ""
    return true

func _failure(message: String) -> bool:
    last_error = message
    return false
