extends SceneTree
func _initialize() -> void:
    var source = load("res://scripts/stand_district_rooms.gd")
    var rooms: Dictionary = source.rooms()
    var failures := 0
    for id in source.IDS:
        if not rooms.has(id): failures += 1
        for route in rooms[id].exits:
            if route[0] in source.IDS:
                var reverse := false
                for other in rooms[route[0]].exits:
                    if other[0] == id: reverse = true
                if not reverse:
                    failures += 1
                    print("Missing reverse: ",id," to ",route[0])
    print("STAND DISTRICT DATA: ",rooms.size()," rooms, ",failures," failures")
    quit(1 if failures else 0)
