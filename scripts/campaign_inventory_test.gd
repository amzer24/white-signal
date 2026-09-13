extends SceneTree
func _initialize() -> void:
    var registry = load("res://scripts/exploration_save.gd")
    var layouts = load("res://scripts/exploration_rooms.gd")
    var inventory: Array = []
    var ids: Array = registry.ROOMS
    var broken: Array = []
    for id in ids:
        var room: Dictionary = layouts.get_room(id)
        var exits: Array = []
        for route in room.exits:
            exits.append({"room":route[0],"label":route[2],"x":route[1].x,"y":route[1].y})
            if not route[0] in ids: broken.append(id+" -> "+route[0])
        var actions: Array = []
        for action in room.actions: actions.append({"id":action[0],"label":action[2]})
        inventory.append({"id":id,"title":room.title,"goal":room.goal,"platform_count":room.platforms.size(),"exits":exits,"actions":actions})
    var reachable: Array = ["flats"]
    var changed := true
    while changed:
        changed = false
        for item in inventory:
            if not item.id in reachable: continue
            for route in item.exits:
                if not route.room in reachable:
                    reachable.append(route.room)
                    changed = true
    var orphaned: Array = []
    for id in ids:
        if not id in reachable: orphaned.append(id)
    var report := {"room_count":inventory.size(),"broken_targets":broken,"structurally_unreachable":orphaned,"scope":"Structural graph only. Does not establish reachability under gates, physics or ability ordering.","rooms":inventory}
    var file := FileAccess.open("res://test-user/campaign-inventory.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    print("CAMPAIGN INVENTORY ",inventory.size()," rooms; broken=",broken," unreachable=",orphaned)
    quit(1 if broken.size()+orphaned.size()>0 else 0)
