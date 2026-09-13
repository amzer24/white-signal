extends RefCounted
## Read-only guidance derived from saved discoveries; never grants progression.
static func drowned_lead(profile) -> String:
    if profile.has_flag("drowned_restored"):
        return "DROWNED FEED HOLDS . EXPLORE THE SERVICE ROUTES"
    if profile.has_flag("pump_repaired"):
        return "PUMP LIVE . FOLLOW GALLERY TO FLOAT RETURN"
    if profile.has_flag("impeller"):
        return "IMPELLER RECOVERED . FIT AT THE PUMP HOUSE"
    return "IMPELLER IN THE OLD STREET"

static func goal(world) -> String:
    var p = world.profile
    match world.room_id:
        "flats":
            if p.has_flag("intro_memory"): return "MEMORY ANSWERED . FOLLOW THE MAINTENANCE CONDUIT"
            var movement := "STICK" if GameInput.controller_active else GameInput.action_label("move_left")+"/"+GameInput.action_label("move_right")
            return movement+" MOVE . "+GameInput.action_label("jump")+" JUMP . STRIKE MEMORY BELOW"
        "conduit":
            return GameInput.action_label("interact")+" USE AT THE MARKED CONDUIT . FOLLOW ITS RETURN"
        "amplifier":
            if not p.has_flag("dash"): return "CLIMB TO THE RELAY . RECOVER THE DASH PROTOCOL"
            if preload("res://scripts/amplifier_room.gd").released(p.data.flags):
                return "RETURN STEPS HOLD . FOLLOW THE COUNTERWEIGHT WALK"
            var dash_key := GameInput.action_label("dash")
            return "JUMP THEN %s . LAND ACROSS . LOWER RETURN STEPS" % dash_key
        "lookout":
            if p.has_flag("survey"): return drowned_lead(p)
        "basin":
            if p.has_flag("pump_repaired"): return "STREET HOLDS DRY . FOLLOW THE UPPER RETURN"
            if p.has_flag("impeller"): return "IMPELLER RECOVERED . FIND THE DRY PUMP HOUSE"
            if world.drowned.water_y >= 241: return "STREET EXPOSED . RECOVER THE IMPELLER"
            return "BLEED FROM THE DRY RIM . WATCH THE WATER MARKS"
        "pump":
            if p.has_flag("drowned_restored"): return "FEED HOLDS . FREIGHT AND SIPHON ROUTES OPEN"
            if p.has_flag("pump_repaired"): return "PUMP LIVE . REVISIT THE GALLERY . OPEN UPPER RETURN"
            if p.has_flag("impeller"): return "FIT THE RECOVERED IMPELLER IN THE PUMP"
            return "IMPELLER MISSING . SEARCH THE OLD STREET"
        "float":
            if p.has_flag("air_jump") and p.has_flag("drowned_restored"): return "RETURN OPEN . AIR JUMP REACHES OLD HIGH ROUTES"
            if not p.has_flag("air_jump"): return "AIR JUMP IN THE GALLERY . DRY RETURN BELOW"
            if p.has_flag("pump_repaired"): return "RIDE THE FLOAT . LATCH THE UPPER RETURN"
            return "NO POWER . REPAIR THE DRY PUMP FIRST"
        "drowned_street":
            if not p.has_flag("impeller"): return "RECOVER THE IMPELLER . FOLLOW THE SURVEY MARKS"
            if not p.has_flag("air_jump"): return "IMPELLER HELD . EXPLORE THE SURVEY GALLERY"
            if not p.has_flag("pump_repaired"): return "DRY STAIR TO RIM . FIT IMPELLER AT PUMP"
            return "GALLERY ABOVE . FLOAT CONTROL WALK POWERED"
        "drowned_gallery":
            if not p.has_flag("air_jump"): return "LEARN AIR JUMP . PRACTISE OVER THE SAFE FLOOR"
            if not p.has_flag("pump_repaired"): return "AIR JUMP LEARNED . RETURN IMPELLER TO PUMP"
            return "AIR JUMP TO UPPER WALK . FLOAT CONTROLS AHEAD"
        "drowned_dock":
            if not p.has_flag("drowned_restored"): return "INNER HATCH CLOSED . ARRAY RETREAT STAYS OPEN"
        "drowned_cycle":
            if p.has_flag("cycle_archive"): return "ARCHIVE RETAINED . DRY STAIR RETURNS TO STREET"
        "wire_shaft":
            if p.has_flag("wire_shaft_released"): return "RETURN HOLDS . RECALL THEN BOARD THE SERVICE LIFT"
        "wire_shelter":
            if p.has_flag("wire_repaired"): return "CARRIAGE LIVE . FOLLOW THE WIRE TO THE ARRAY"
            if p.has_flag("brake_spare"): return "BRAKE RECOVERED . FIT AT THE CARRIAGE DOCK"
        "wire_carriage":
            if p.has_flag("wire_repaired"): return "BOARD THE CARRIAGE . BOTH SHORES CAN RECALL"
            if p.has_flag("brake_spare"): return "FIT THE BRAKE BEFORE BOARDING"
            return "BRAKE MISSING . SEARCH THE INSPECTION SHELTER"
        "array_cable":
            if p.has_flag("cable_archive"): return "SERVICE RETURN OPEN . THE DROP LANE STAYS MARKED"
        "array_inspection":
            if p.has_flag("inspection_archive"): return "ARCHIVE REMEMBERED . UPPER WALK RETURNS SAFELY"
        "array":
            if p.has_flag("array_restored"): return "LOCAL FEED HOLDS . SOURCE APPROACH OPEN"
            if world.network.diagnostic_time > 0: return "TEST RUNNING . WATCH WHICH BRANCH STAYS LIT"
            if p.has_flag("array_isolated"): return "FAULT ISOLATED . ROUTE THE HEALTHY FEED"
            if p.has_flag("diagnostic_seen"): return "COMMON RETURN FAULT . ISOLATE THE BRANCH"
            return "RUN THE DIAGNOSTIC . WATCH THE TWO BRANCHES"
        "stand_charge":
            if p.has_flag("stand_restored"): return "BRIDGE HOLDS . THE UPPER ROUTE STAYS OPEN"
            if world.stand.charge == 1: return "CHARGE HELD . FOLLOW THE CABLE TO RESERVOIR WALK"
            if world.stand.phase == "charging": return "CURRENT FILLING . IT WILL HOLD WITHOUT A TIMER"
        "stand_bridge":
            if not p.has_flag("stand_restored"): return "BRIDGE UNPOWERED . DIVERT CHARGE AT RESERVOIR"
            return "THE BRIDGE HOLDS . FOLLOW THE WIRE"
        "stand_trial":
            if p.has_flag("stand_archive"): return "ARCHIVE RECOVERED . THE LOWER WALK HOLDS"
        "shelter":
            if p.has_flag("stand_restored"): return "LOWER BRIDGE RETURN OPEN . SLUICE BELOW"
        "conductor":
            if p.has_flag("stand_restored"): return "BRIDGE HOLDS . THE SHELTER KEEPS ITS OWN FEED"
            if world.stand.phase in ["warning","discharge"]: return "MOTOR CYCLING . STAY IN THE MARKED SHELTER"
            if world.stand.phase == "ready": return "CHARGE HELD . DIVERT TO THE BRIDGE MOTOR"
            return "RESERVOIR EMPTY . STORE CURRENT IN THE CHARGE BAY"
        "gate":
            if p.has_flag("signal_restored"): return "THE NETWORK ANSWERS . FOLLOW THE LIGHTS HOME"
            if world.gate.progress().latched: return "BUS HELD . RETURN STAIRS LEAD TO THE UPPER DOOR"
            return "CLIMB THE GANTRY . AIR JUMP THEN DASH TO THE BUS"
        "source_return":
            if world.gate.progress().tested: return "FOUR FEEDS HOLD . CROSS THE INDEPENDENT BRIDGE"
            if world.gate.test_time > 0: return "WATCH THE LOCAL LINE . FOUR FEEDS MUST HOLD"
            return "CLIMB TO THE SWITCH . ISOLATE THE COMMON RETURN"
        "source_walk":
            if p.has_flag("signal_restored"): return "THE NETWORK ANSWERS . FOLLOW THE LIGHTS HOME"
            return "FOLLOW THE FOUR FEEDS . COMMISSION THE NETWORK"
    return world.room.goal
