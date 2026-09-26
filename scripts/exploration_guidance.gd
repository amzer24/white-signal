extends RefCounted
## Read-only guidance derived from saved discoveries; never grants progression.
## Every line answers one question for the player: "what do I do next?"

# Plain-language fallback goal per room, used when no state rule below applies.
const PLAIN := {
    "flats": "WALK RIGHT . HIT THE GLOWING BLOCK FROM BELOW",
    "conduit": "PULL THE LEVER . THEN FOLLOW THE OPEN DOOR",
    "arrival": "WALK RIGHT INTO THE LISTENING FIELD",
    "hub": "THIS IS THE CROSSROADS . TRY EACH DOOR . THE MAP SHOWS WHAT IS LEFT",
    "workshop": "HIT THE BLOCK FROM BELOW . THEN WALK BACK OUT",
    "gallery": "PULL THE LEVER TO POWER THE LIFT . THEN LATCH IT",
    "amplifier": "CLIMB UP . GRAB THE GLOWING DASH PROTOCOL",
    "return": "PULL THE LEVER . IT OPENS A SHORTCUT BACK TO THE HUB",
    "lookout": "READ THE ARCHIVE ON THE RIGHT . IT SHOWS THE WAY DOWN",
    "causeway": "TURN EACH CRANK UNTIL THE DISH LINES UP WITH ITS MARK",
    "cellar": "HIT THE CRACKED BLOCK FROM BELOW",
    "sump": "FLIP THE BREAKER ONCE WEST . EAST . SOUTH ARE DONE",
    "fourth": "OPTIONAL . READ THE ARCHIVE . NOTHING TO FIX HERE",
    "basin": "PULL THE VALVE TO DRAIN THE WATER . THEN GO DOWN THE STAIR",
    "pump": "PUT THE IMPELLER IN THE SOCKET . THAT POWERS THE FLOAT ROOM",
    "float": "TURN THE VALVE TO RAISE THE FLOAT . RIDE IT UP . PULL THE LATCH",
    "drowned_street": "FIND THE IMPELLER ON THE FLOOR . THEN LOOK FOR THE GALLERY",
    "drowned_gallery": "GRAB THE AIR JUMP . PRESS JUMP AGAIN IN THE AIR",
    "drowned_dock": "FOLLOW THE TUNNEL RIGHT TOWARDS THE ARRAY",
    "drowned_cycle": "OPTIONAL . DRAIN THIS BASIN . READ THE ARCHIVE",
    "siphon": "RAISE THE FLOAT . PIN IT . DRAIN . THEN OPEN THE LOWER DOOR",
    "stand_rim": "WALK RIGHT ALONG THE BROKEN RIM",
    "shelter": "CLIMB TO THE TOP DOOR . THIS ROOM IS SAFE",
    "stand_charge": "FLIP THE SWITCH TO STORE CHARGE . THEN GO RIGHT",
    "conductor": "FLIP THE SWITCH TO SEND CHARGE TO THE BRIDGE MOTOR",
    "stand_bridge": "WALK ACROSS THE BRIDGE . FOLLOW THE WIRE",
    "stand_sluice": "OPTIONAL . READ THE PIPE ARCHIVE",
    "stand_trial": "OPTIONAL . CROSS THE FALLING RIBS TO THE ARCHIVE",
    "wire_shelter": "FIND THE BRAKE PART . TAKE IT TO THE CARRIAGE",
    "wire_carriage": "FIT THE BRAKE IN THE SOCKET . THEN CALL AND BOARD THE CARRIAGE",
    "wire_shaft": "OPTIONAL . KICK BETWEEN THE WALLS TO CLIMB",
    "array": "FLIP TEST . SEE WHICH SIDE STAYS LIT . ISOLATE THE DEAD SIDE . FLIP BYPASS",
    "array_inspection": "OPTIONAL . DASH PAST THE PATROL OR TAKE THE HIGH ROUTE",
    "array_cable": "OPTIONAL . WATCH THE DROP MARK . USE THE HIGH WALK",
    "array_shutter": "OPTIONAL . PICK ONE SHUTTER . READ THE PROJECTOR BELOW",
    "approach": "ALL FOUR DISTRICTS MUST BE FIXED . THEN PULL THE LATCH",
    "gate": "CLIMB THE TOWER . AIR JUMP THEN DASH TO THE BREAKER AT THE TOP",
    "source_return": "CLIMB TO THE SWITCH . FLIP ISOLATE . WATCH THE LIGHTS",
    "source_walk": "WALK RIGHT . FLIP THE LAST BREAKER",
    "aftermath": "YOU DID IT . THE SIGNAL IS HOME . WALK AND LISTEN",
}

# Autoload fetched by name so this script also compiles when preloaded before autoloads exist (test scripts).
static func _gi() -> Node:
    return Engine.get_main_loop().root.get_node("GameInput")

static func drowned_lead(profile) -> String:
    if profile.has_flag("drowned_restored"):
        return "DROWNED IS FIXED . GO BACK TO THE HUB FOR THE NEXT DISTRICT"
    if profile.has_flag("pump_repaired"):
        return "PUMP LIVE . NOW GO TO THE FLOAT CHAMBER AND RIDE THE FLOAT UP"
    if profile.has_flag("impeller"):
        return "IMPELLER RECOVERED . TAKE IT TO THE PUMP HOUSE SOCKET"
    return "THE IMPELLER IS LYING IN THE OLD STREET . GO GET IT"

static func goal(world) -> String:
    var p = world.profile
    var use_key: String = _gi().action_label("interact")
    match world.room_id:
        "flats":
            if p.has_flag("intro_memory"): return "MEMORY ANSWERED . NOW WALK RIGHT THROUGH THE DOOR"
            var movement: String = "STICK" if _gi().controller_active else _gi().action_label("move_left")+"/"+_gi().action_label("move_right")
            return movement+" MOVE . "+_gi().action_label("jump")+" JUMP . HIT THE GLOWING BLOCK FROM BELOW"
        "conduit":
            return use_key+" USE THE LEVER . THEN WALK THROUGH THE OPEN DOOR"
        "arrival":
            return "WALK RIGHT . THE FIELD IS AHEAD"
        "amplifier":
            if not p.has_flag("dash"): return "CLIMB UP . GRAB THE GLOWING DASH PROTOCOL"
            if preload("res://scripts/amplifier_room.gd").released(p.data.flags):
                return "STEPS ARE DOWN . TAKE THE RIGHT DOOR BACK TOWARDS THE HUB"
            var dash_key: String = _gi().action_label("dash")
            return "JUMP THEN PRESS %s TO DASH ACROSS THE GAP . PULL THE LEVER THERE" % dash_key
        "lookout":
            if p.has_flag("survey"): return drowned_lead(p)
        "basin":
            if p.has_flag("pump_repaired"): return "STREET IS DRY . TAKE THE UPPER DOOR BACK"
            if p.has_flag("impeller"): return "IMPELLER RECOVERED . GO TO THE PUMP HOUSE AND FIT IT"
            if world.drowned.water_y >= 241: return "WATER IS DOWN . GO DOWN THE STAIR AND FIND THE IMPELLER"
            return use_key+" USE THE VALVE ON THE RIM . WATCH THE WATER DROP"
        "pump":
            if p.has_flag("drowned_restored"): return "DROWNED IS FIXED . HEAD BACK TO THE HUB"
            if p.has_flag("pump_repaired"): return "PUMP LIVE . NOW GO TO THE FLOAT CHAMBER AND RIDE THE FLOAT"
            if p.has_flag("impeller"): return use_key+" USE THE SOCKET TO FIT THE IMPELLER"
            return "IMPELLER MISSING . IT IS IN THE OLD STREET . GO GET IT"
        "float":
            if p.has_flag("air_jump") and p.has_flag("drowned_restored"): return "DROWNED IS FIXED . HEAD BACK TO THE HUB"
            if not p.has_flag("air_jump"): return "YOU NEED AIR JUMP . IT IS IN THE GALLERY . COME BACK AFTER"
            if p.has_flag("pump_repaired"): return "TURN THE VALVE . RIDE THE FLOAT UP . AIR JUMP TO THE LATCH"
            return "NO POWER HERE . FIT THE IMPELLER IN THE PUMP HOUSE FIRST"
        "drowned_street":
            if not p.has_flag("impeller"): return "PICK UP THE IMPELLER . IT IS LYING IN THIS STREET"
            if not p.has_flag("air_jump"): return "GOT THE IMPELLER . NOW FIND THE GALLERY FOR AIR JUMP"
            if not p.has_flag("pump_repaired"): return "GO UP THE STAIR AND FIT THE IMPELLER AT THE PUMP"
            return "PUMP IS LIVE . HEAD UP TO THE FLOAT CHAMBER"
        "drowned_gallery":
            if not p.has_flag("air_jump"): return "GRAB THE GLOWING PROTOCOL . THEN PRESS JUMP AGAIN MID AIR"
            if not p.has_flag("pump_repaired"): return "AIR JUMP LEARNED . NOW FIT THE IMPELLER AT THE PUMP"
            return "AIR JUMP UP TO THE TOP WALK . FLOAT CHAMBER IS AHEAD"
        "drowned_dock":
            if not p.has_flag("drowned_restored"): return "THIS HATCH IS SHUT . FINISH THE FLOAT CHAMBER FIRST"
        "drowned_cycle":
            if p.has_flag("cycle_archive"): return "ARCHIVE READ . GO BACK DOWN TO THE STREET"
        "wire_shaft":
            if p.has_flag("wire_shaft_released"): return "SHORTCUT OPEN . CALL THE LIFT AND RIDE IT"
        "wire_shelter":
            if p.has_flag("wire_repaired"): return "CARRIAGE WORKS . FOLLOW THE WIRE TO THE ARRAY"
            if p.has_flag("brake_spare"): return "GOT THE BRAKE . TAKE IT TO THE CARRIAGE SOCKET"
        "wire_carriage":
            if p.has_flag("wire_repaired"): return "CALL THE CARRIAGE AT THE POST . STAND ON IT . SEND IT"
            if p.has_flag("brake_spare"): return use_key+" USE THE SOCKET TO FIT THE BRAKE"
            return "BRAKE MISSING . IT IS IN THE SHELTER TO THE LEFT"
        "array_cable":
            if p.has_flag("cable_archive"): return "ARCHIVE READ . TAKE THE HIGH WALK BACK"
        "array_inspection":
            if p.has_flag("inspection_archive"): return "ARCHIVE READ . TAKE THE HIGH WALK BACK"
        "array":
            if p.has_flag("array_restored"): return "ARRAY IS FIXED . SOURCE APPROACH OPEN . HEAD RIGHT"
            if world.network.diagnostic_time > 0: return "TEST RUNNING . WATCH WHICH SIDE STAYS LIT"
            if p.has_flag("array_isolated"): return "DEAD SIDE CUT OFF . NOW FLIP THE BYPASS BREAKER"
            if p.has_flag("diagnostic_seen"): return "ONE SIDE IS DEAD . FLIP ISOLATE ON THAT SIDE"
            return "FLIP THE TEST BREAKER . WATCH THE TWO SIDES"
        "stand_charge":
            if p.has_flag("stand_restored"): return "STAND IS FIXED . HEAD BACK TO THE HUB"
            if world.stand.charge == 1: return "CHARGE STORED . GO RIGHT TO THE RESERVOIR WALK"
            if world.stand.phase == "charging": return "CHARGING . WAIT FOR IT TO FILL . NO RUSH"
        "stand_bridge":
            if not p.has_flag("stand_restored"): return "BRIDGE UNPOWERED . GO UP AND SEND CHARGE FROM THE RESERVOIR WALK"
            return "THE BRIDGE HOLDS . WALK ACROSS AND FOLLOW THE WIRE"
        "stand_trial":
            if p.has_flag("stand_archive"): return "ARCHIVE READ . GO BACK LEFT"
        "shelter":
            if p.has_flag("stand_restored"): return "STAND IS FIXED . TAKE THE BRIDGE DOOR ON THE RIGHT"
        "conductor":
            if p.has_flag("stand_restored"): return "BRIDGE POWERED . GO RIGHT ACROSS IT"
            if world.stand.phase in ["warning","discharge"]: return "MOTOR FIRING . STAND STILL IN THE MARKED SHELTER"
            if world.stand.phase == "ready": return use_key+" USE THE SWITCH TO SEND CHARGE TO THE BRIDGE"
            return "NO CHARGE YET . GO BACK LEFT AND STORE SOME IN THE CONDUCTOR BAY"
        "gate":
            if p.has_flag("signal_restored"): return "THE SIGNAL IS HOME . FOLLOW THE LIGHTS RIGHT"
            if world.gate.progress().latched: return "BUS HELD . TAKE THE STAIRS TO THE UPPER DOOR"
            return "CLIMB THE TOWER . AIR JUMP THEN DASH TO THE BREAKER AT THE TOP"
        "source_return":
            if world.gate.progress().tested: return "ALL FOUR FEEDS LIT . CROSS THE BRIDGE ON THE RIGHT"
            if world.gate.test_time > 0: return "TESTING . WATCH THE FOUR LIGHTS . THEY MUST ALL STAY ON"
            return "CLIMB TO THE SWITCH . FLIP ISOLATE . THEN FLIP TEST"
        "source_walk":
            if p.has_flag("signal_restored"): return "THE SIGNAL IS HOME . FOLLOW THE LIGHTS RIGHT"
            return "WALK RIGHT . FLIP THE LAST BREAKER . BRING THE SIGNAL HOME"
    if PLAIN.has(world.room_id): return PLAIN[world.room_id]
    return world.room.goal
