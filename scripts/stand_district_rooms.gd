extends RefCounted
## Expanded Stand data. Existing shelter/conductor IDs retain safe save entries.
## Stand mechanism owns transient charge, crumble and permanent bridge geometry.
const IDS := ["stand_rim","shelter","stand_charge","conductor","stand_bridge","stand_sluice","stand_trial"]
static func rooms() -> Dictionary:
    var floor_rect := Rect2(0,224,480,46)
    var district := {
        "stand_rim":{"title":"BROKEN RIM", "spawn":Vector2(35,217),"platforms":[floor_rect,Rect2(110,192,80,8)],"exits":[["shelter",Vector2(445,217),"SHELTER COURT"]],"actions":[]},
        "shelter":{"title":"SHELTER COURT", "spawn":Vector2(40,217),"platforms":[floor_rect,Rect2(105,190,75,8),Rect2(200,156,80,8),Rect2(302,122,110,8)],"exits":[["stand_rim",Vector2(27,217),"BROKEN RIM"],["stand_charge",Vector2(365,115),"UPPER CONDUCTOR"],["stand_bridge",Vector2(447,217),"LOWER BRIDGE RETURN"],["stand_sluice",Vector2(240,217),"SLUICE DESCENT"]],"actions":[]},
        "stand_charge":{"title":"CONDUCTOR BAY", "spawn":Vector2(40,217),"platforms":[floor_rect,Rect2(98,190,80,8),Rect2(197,156,95,8),Rect2(332,156,130,8)],"exits":[["shelter",Vector2(27,217),"COURT DESCENT"],["conductor",Vector2(436,149),"RESERVOIR WALK"]],"actions":[["storm_charge",Vector2(240,149),"STORE CHARGE"]]},
        "conductor":{"title":"RESERVOIR WALK", "spawn":Vector2(35,217),"platforms":[floor_rect,Rect2(91,190,77,8),Rect2(185,158,85,8),Rect2(327,158,136,8)],"exits":[["stand_charge",Vector2(27,217),"CONDUCTOR RETURN"],["stand_bridge",Vector2(439,151),"LATCHED BRIDGE"],["stand_trial",Vector2(225,151),"OPTIONAL FRACTURE TRIAL"]],"actions":[["storm_divert",Vector2(365,151),"DIVERT TO MOTOR"]]},
        "stand_trial":{"title":"FRACTURE TRIAL", "spawn":Vector2(40,217),"platforms":[Rect2(0,224,95,46),Rect2(390,224,90,46),Rect2(207,224,66,8)],"exits":[["conductor",Vector2(27,217),"RESERVOIR RETURN"]],"actions":[["stand_archive",Vector2(434,217),"OPERATOR ARCHIVE"]]},
        "stand_sluice":{"title":"SLUICE SHELTER", "spawn":Vector2(42,115),"platforms":[floor_rect,Rect2(0,122,100,8),Rect2(130,156,82,8),Rect2(243,190,83,8)],"exits":[["shelter",Vector2(32,115),"COURT ASCENT"]],"actions":[["stand_sluice_memory",Vector2(420,217),"INSPECT DROWNED CONNECTION"]]},
        "stand_bridge":{"title":"LATCHED BRIDGE", "spawn":Vector2(430,217),"platforms":[Rect2(0,224,150,46),Rect2(330,224,150,46)],"exits":[["shelter",Vector2(27,217),"SHELTER RETURN"],["conductor",Vector2(447,217),"UPPER WALK RETURN"]],"actions":[]}
    }
    var goals := {
        "stand_rim":"FOLLOW THE BROKEN RIM TO THE SHELTER",
        "shelter":"FIND THE UPPER CABLE . THE COURT IS SAFE",
        "stand_charge":"STORE THE CURRENT . FOLLOW IT TO THE MOTOR",
        "conductor":"DIVERT HELD CHARGE . OPEN THE LOWER RETURN",
        "stand_bridge":"THE BRIDGE HOLDS . FOLLOW THE WIRE",
        "stand_sluice":"FOLLOW THE PIPE TO DROWNED",
        "stand_trial":"CRACKED RIBS FALL . LOWER SHELTER HOLDS"
    }
    for id in district:
        district[id].title = "THE STAND . "+district[id].title
        district[id].goal = goals[id]
    district.stand_rim.exits.append(["return",Vector2(27,217),"LISTENING FIELD"])
    district.stand_sluice.actions = []
    district.stand_sluice.exits.append(["pump",Vector2(420,217),"DROWNED PUMP HOUSE"])
    district.stand_bridge.exits.append(["wire_shelter",Vector2(366,217),"WIRE INSPECTION"])
    district.shelter.actions.append(["shelter_memory",Vector2(144,183),"REPLAY SHELTER MEMORY"])
    district.shelter.exits.append(["approach",Vector2(76,217),"SOURCE SERVICE RETURN"])
    return district
