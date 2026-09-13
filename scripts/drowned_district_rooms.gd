extends RefCounted
## Seven-room Drowned district, adapted from the physical route blockout.
const IDS := ["basin","pump","drowned_street","drowned_gallery","float","drowned_dock","drowned_cycle"]
static func rooms() -> Dictionary:
    var f := Rect2(0,224,480,46)
    var draft := {
        "rim":{"name":"HIGH WATER RIM","spawn":Vector2(35,115),"platforms":[f,Rect2(0,122,120,8),Rect2(174,122,70,8),Rect2(290,122,50,8),Rect2(386,122,94,8),Rect2(160,156,70,8),Rect2(215,190,70,8)],"exits":[["pump",Vector2(445,115),"DRY UPPER WALK"],["street",Vector2(260,217),"EXPOSED STREET"]],"controls":[["bleed",Vector2(80,115),"BLEED MAIN BASIN"]]},
        "pump":{"name":"DRY PUMP HOUSE","spawn":Vector2(38,217),"platforms":[f,Rect2(100,190,75,8),Rect2(200,156,100,8)],"exits":[["rim",Vector2(27,217),"DRY RIM"],["float",Vector2(444,217),"UPPER RETURN HATCH"]],"controls":[["repair",Vector2(244,149),"FIT IMPELLER"]]},
        "street":{"name":"SERVICE STREET","spawn":Vector2(38,115),"platforms":[f,Rect2(0,122,94,8),Rect2(120,156,80,8),Rect2(228,190,74,8)],"exits":[["rim",Vector2(30,115),"FIXED DRY STAIR"],["gallery",Vector2(445,217),"SURVEY GALLERY"],["cycle",Vector2(333,217),"OPTIONAL BASIN"]],"controls":[["part",Vector2(265,217),"RECOVER IMPELLER"]]},
        "gallery":{"name":"SURVEY GALLERY","spawn":Vector2(38,217),"platforms":[f,Rect2(100,190,70,8),Rect2(235,120,245,8)],"exits":[["street",Vector2(27,217),"STREET RETURN"],["float",Vector2(435,113),"FLOAT CONTROL WALK"],["dock",Vector2(435,217),"INNER FREIGHT HATCH"]],"controls":[["air",Vector2(75,217),"LEARN AIR JUMP"]]},
        "float":{"name":"GUIDED FLOAT","spawn":Vector2(35,217),"platforms":[f,Rect2(88,190,78,8),Rect2(177,156,70,8),Rect2(350,68,130,8)],"exits":[["gallery",Vector2(27,217),"DRY GALLERY RETURN"],["pump",Vector2(438,61),"SHORT PUMP RETURN"]],"controls":[["raise_float",Vector2(207,149),"CYCLE FLOAT HEIGHT"],["latch",Vector2(380,61),"LATCH UPPER CONDUIT"]]},
        "dock":{"name":"FREIGHT DOCK","spawn":Vector2(430,217),"platforms":[f,Rect2(105,190,75,8),Rect2(220,156,100,8)],"exits":[["gallery",Vector2(27,217),"INNER CONDUIT"],["array",Vector2(445,217),"ARRAY RETREAT"]],"controls":[]},
        "cycle":{"name":"OPTIONAL CYCLING BASIN","spawn":Vector2(35,115),"platforms":[f,Rect2(0,122,110,8),Rect2(140,156,70,8),Rect2(250,190,75,8)],"exits":[["street",Vector2(27,115),"DRY RETURN"]],"controls":[["tide",Vector2(80,115),"CYCLE LOCAL TIDE"],["archive",Vector2(370,217),"RECOVER ARCHIVE"]]},
        "array":{"name":"ARRAY BOUNDARY","spawn":Vector2(40,217),"platforms":[f],"exits":[["dock",Vector2(27,217),"DROWNED DOCK"]],"controls":[]}
    }
    var names := {"rim":"basin","pump":"pump","street":"drowned_street","gallery":"drowned_gallery","float":"float","dock":"drowned_dock","cycle":"drowned_cycle"}
    var actions := {"bleed":"bleed","part":"impeller","air":"air_jump","repair":"pump_socket","raise_float":"float_valve","latch":"float_latch","tide":"cycle_valve","archive":"cycle_archive"}
    var goals := {
        "rim":"LOWER THE WATER . FOLLOW THE EXPOSED STAIR",
        "pump":"FIT THE IMPELLER . POWER THE FLOAT CONTROL WALK",
        "street":"RECOVER THE IMPELLER . EXPLORE THE SURVEY GALLERY",
        "gallery":"LEARN AIR JUMP . REACH THE UPPER CONTROL WALK",
        "float":"RAISE THE FLOAT . AIR JUMP TO THE UPPER LATCH",
        "dock":"FOLLOW THE FREIGHT CONDUIT TO THE ARRAY",
        "cycle":"OPTIONAL . DRAIN THE SEPARATE BASIN . FIND THE ARCHIVE"}
    var result := {}
    for key in names:
        var old: Dictionary = draft[key]
        var exits: Array = old.exits.duplicate(true)
        for door in exits:
            door[0] = names.get(door[0],door[0])
        var controls: Array = old.controls.duplicate(true)
        for control in controls: control[0] = actions[control[0]]
        result[names[key]] = {"title":"DROWNED . "+String(old.name),"goal":goals[key],"spawn":old.spawn,"platforms":old.platforms.duplicate(),"exits":exits,"actions":controls}
    result.basin.exits.append(["lookout",Vector2(27,115),"LOOKOUT RETURN"])
    result.pump.exits.append(["stand_sluice",Vector2(345,217),"STAND SLUICE"])
    result.pump.exits.append(["siphon",Vector2(284,149),"SIPHON SERVICE BAY"])
    return result
