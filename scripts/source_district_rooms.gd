extends RefCounted
## Connected Source finale; progress derives geometry without mutating saved flags.
const IDS := ["gate","source_return","source_walk"]
const RETURN_STEPS := [Rect2(255,190,60,8),Rect2(290,156,60,8),Rect2(320,122,60,8)]
const LOCAL_BRIDGE := Rect2(245,156,105,8)
static func progress(flags: Dictionary) -> Dictionary:
    # Completed old saves can keep their direct route home, without rewriting flags.
    var restored := bool(flags.get("signal_restored",false))
    var tested := restored or bool(flags.get("gate_tested",false))
    var isolated := tested or bool(flags.get("gate_isolated",false))
    return {"latched":isolated or bool(flags.get("gate_latched",false)),"isolated":isolated,"tested":tested,"restored":restored}
static func rooms(flags: Dictionary = {}) -> Dictionary:
    var floor_rect := Rect2(0,224,480,46)
    var state := progress(flags)
    var result := {
        "gate":{"title":"SOURCE . DISTRIBUTION GANTRY","goal":"SECURE THE LOCAL BUS . FOUR FEEDS ARRIVED","spawn":Vector2(40,217),"platforms":[floor_rect,Rect2(80,190,75,8),Rect2(170,156,75,8),Rect2(365,80,115,8)],"exits":[["approach",Vector2(27,217),"APPROACH RETURN"],["source_return",Vector2(445,73),"COMMON RETURN CHAMBER"]],"actions":[["gate_latch",Vector2(395,73),"SECURE LOCAL BUS"]]},
        "source_return":{"title":"SOURCE . COMMON RETURN","goal":"ISOLATE THE SHARED FAULT . WATCH THE LOCAL PATH","spawn":Vector2(40,217),"platforms":[floor_rect,Rect2(90,190,70,8),Rect2(175,156,70,8),Rect2(350,156,130,8)],"exits":[["gate",Vector2(27,217),"GANTRY RETURN"],["source_walk",Vector2(445,149),"INDEPENDENT PATH"]],"actions":[["gate_isolate",Vector2(210,149),"ISOLATE / VERIFY LOCAL PATH"]]},
        "source_walk":{"title":"SOURCE . COMMISSIONING WALK","goal":"FOLLOW FOUR INDEPENDENT FEEDS . COMMIT RESTORATION","spawn":Vector2(40,217),"platforms":[floor_rect,Rect2(90,190,65,8),Rect2(175,156,65,8),Rect2(260,122,65,8),Rect2(365,156,115,8)],"exits":[["source_return",Vector2(27,217),"CIRCUIT RETURN"],["aftermath",Vector2(445,149),"ANSWERING NETWORK"]],"actions":[["gate_commit",Vector2(400,149),"COMMIT RESTORATION"]]}
    }
    if state.latched: result.gate.platforms.append_array(RETURN_STEPS)
    if state.tested: result.source_return.platforms.append(LOCAL_BRIDGE)
    if state.restored: result.gate.exits.append(["aftermath",Vector2(445,217),"RESTORED NETWORK RETURN"])
    return result
