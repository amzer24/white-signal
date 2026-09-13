extends RefCounted
static var tutorial_layout: Dictionary = {}

static func get_room(id: String, flags: Dictionary = {}) -> Dictionary:
    if id in ["flats","conduit","arrival"]:
        if tutorial_layout.is_empty():
            tutorial_layout = JSON.parse_string(FileAccess.get_file_as_string("res://data/flats_rooms.json"))
        for item in tutorial_layout.rooms:
            if item.id != id: continue
            var result: Dictionary = item.duplicate(true)
            result.spawn = Vector2(item.spawn[0],item.spawn[1])
            result.platforms = []
            for rect in item.platforms: result.platforms.append(Rect2(rect[0],rect[1],rect[2],rect[3]))
            for entries in [result.exits,result.actions]:
                for entry in entries: entry[1] = Vector2(entry[1][0],entry[1][1])
            if id == "conduit":
                result.platforms.append(Rect2(255,80,28,144))
                result.actions.append(["conduit_return",Vector2(355,215),"RETURN THROUGH CONDUIT"])
            result.title = {"flats":"FLATS . THE FIRST CARRIER","conduit":"FLATS . MAINTENANCE CONDUIT","arrival":"FLATS . FIRST RECEIVER"}[id]
            result.goal = {"flats":"A/D MOVE . SPACE JUMP . STRIKE THE MEMORY FROM BELOW","conduit":"E OR DOWN AT THE MARKED CONDUIT","arrival":"RESTORE THE BEACON . FOLLOW THE FIELD RECEIVERS"}[id]
            return result
    var floor_rect := Rect2(0,224,480,46)
    var rooms := {
        "hub": {"title":"TRIANGULATION HUB", "goal":"FOLLOW THE ANSWERING WINDOW", "spawn":Vector2(235,215),
            "platforms":[floor_rect,Rect2(42,192,64,8),Rect2(119,158,64,8),Rect2(36,126,72,10),Rect2(310,191,74,8)],
            "exits":[["workshop",Vector2(69,119),"WORKSHOP"],["lookout",Vector2(430,215),"LOWER SERVICE"],["return",Vector2(346,184),"RETURN LIFT"],["causeway",Vector2(234,215),"EAST CAUSEWAY"]], "actions":[]},
        "workshop": {"title":"WEST WORKSHOP", "goal":"STRIKE THE MEMORY . FOLLOW ITS CIRCUIT", "spawn":Vector2(42,215),
            "platforms":[floor_rect,Rect2(60,185,44,8),Rect2(107,150,38,8),Rect2(52,113,48,8)],
            "exits":[["hub",Vector2(30,215),"HUB"],["gallery",Vector2(440,215),"BALLAST GALLERY"]], "actions":[["memory",Vector2(211,158),"MEMORY BLOCK"]]},
        "gallery": {"title":"BALLAST GALLERY", "goal":"POWER LIFT . LATCH CATCH . REROUTE", "spawn":Vector2(42,215),
            "platforms":[floor_rect,Rect2(279,120,163,12)],
            "exits":[["workshop",Vector2(28,215),"WORKSHOP"],["amplifier",Vector2(421,113),"AMPLIFIER"]],
            "actions":[["selector",Vector2(168,215),"POWER SELECTOR"],["catch",Vector2(328,113),"SAFETY CATCH"]]},
        "amplifier": {"title":"UPPER AMPLIFIER", "goal":"RECOVER THE DASH PROTOCOL", "spawn":Vector2(36,215),
            "platforms":[floor_rect,Rect2(66,190,62,8),Rect2(145,156,105,10),Rect2(292,187,76,8)],
            "exits":[["gallery",Vector2(27,215),"GALLERY"],["return",Vector2(442,215),"COUNTERWEIGHT"]], "actions":[["dash",Vector2(199,148),"DASH PROTOCOL"]]},
        "return": {"title":"COUNTERWEIGHT RETURN", "goal":"OPEN A ROUTE YOU WILL REMEMBER", "spawn":Vector2(41,215),
            "platforms":[floor_rect,Rect2(143,191,69,8),Rect2(255,181,92,9)],
            "exits":[["amplifier",Vector2(27,215),"AMPLIFIER"],["hub",Vector2(432,215),"HUB LIFT"],["shelter",Vector2(169,184),"STAND SHELTER"],["conductor",Vector2(336,174),"STORM BRIDGE RETURN"],["causeway",Vector2(95,215),"EAST CAUSEWAY"]], "actions":[["return_latch",Vector2(303,174),"RETURN CATCH"]]},
        "lookout": {"title":"DRAIN LOOKOUT", "goal":"READ THE STREET BENEATH THE STATIC", "spawn":Vector2(39,215),
            "platforms":[floor_rect,Rect2(94,190,76,8),Rect2(192,154,72,8),Rect2(322,185,110,8)],
            "exits":[["hub",Vector2(26,215),"HUB"],["basin",Vector2(415,178),"DROWNED SERVICE"]], "actions":[["survey",Vector2(227,147),"SERVICE SURVEY"]]},
        "basin": {"title":"DROWNED . SERVICE BASIN", "goal":"BLEED THE BASIN . FIND THE MISSING IMPELLER", "spawn":Vector2(42,137),
            "platforms":[Rect2(0,244,480,26),Rect2(0,144,112,10),Rect2(96,178,43,8),Rect2(142,211,42,8),Rect2(357,211,42,8),Rect2(390,178,40,8),Rect2(430,144,50,10)],
            "exits":[["lookout",Vector2(28,137),"LOOKOUT"],["pump",Vector2(450,137),"DRY PUMP HOUSE"],["float",Vector2(403,171),"UPPER RETURN"]],
            "actions":[["bleed",Vector2(80,137),"MANUAL BLEED"],["impeller",Vector2(246,237),"RECOVER IMPELLER"]]},
        "pump": {"title":"DROWNED . DRY PUMP HOUSE", "goal":"FIT THE IMPELLER . POWER THE FLOAT CHAMBER", "spawn":Vector2(37,215),
            "platforms":[floor_rect,Rect2(96,188,70,8),Rect2(191,155,106,10)],
            "exits":[["basin",Vector2(26,215),"SERVICE BASIN"],["float",Vector2(449,215),"FLOAT CHAMBER"],["shelter",Vector2(345,215),"STAND SLUICE"]],
            "actions":[["pump_socket",Vector2(244,148),"FIT PUMP IMPELLER"]]},
        "float": {"title":"DROWNED . FLOAT CHAMBER", "goal":"RAISE FLOAT . LATCH RETURN . RECOVER AIR JUMP", "spawn":Vector2(40,237),
            "platforms":[Rect2(0,244,480,26),Rect2(73,209,58,8),Rect2(136,180,52,8),Rect2(179,152,54,8),Rect2(345,113,120,10)],
            "exits":[["pump",Vector2(28,237),"PUMP HOUSE"],["basin",Vector2(441,106),"BASIN RETURN"]],
            "actions":[["float_valve",Vector2(209,145),"FLOAT LOW / MID / HIGH"],["float_latch",Vector2(368,106),"LATCH UPPER RETURN"],["air_jump",Vector2(408,106),"AIR JUMP PROTOCOL"]]},
        "shelter": {"title":"THE STAND . OBSERVATION SHELTER", "goal":"FOLLOW THE STORED CURRENT . KEEP THE SHELTER LIVE", "spawn":Vector2(40,215),
            "platforms":[floor_rect,Rect2(95,190,68,8),Rect2(181,158,105,10)],
            "exits":[["return",Vector2(28,215),"LISTENING FIELD"],["pump",Vector2(231,151),"DROWNED SLUICE"],["conductor",Vector2(444,215),"CONDUCTOR BAY"]],
            "actions":[["shelter_memory",Vector2(128,183),"REPLAY SHELTER MEMORY"]]},
        "conductor": {"title":"THE STAND . STORED STORM", "goal":"CHARGE RESERVOIR . DIVERT TO MOTOR . BRIDGE HOLDS", "spawn":Vector2(40,215),
            "platforms":[Rect2(0,224,211,46),Rect2(341,224,139,46)],
            "exits":[["shelter",Vector2(28,215),"SHELTER"],["return",Vector2(445,215),"FIELD SERVICE RETURN"]],
            "actions":[["storm_charge",Vector2(105,215),"CHARGE RESERVOIR"],["storm_divert",Vector2(170,215),"DIVERT TO MOTOR"]]},
        "causeway": {"title":"LISTENING FIELD . EAST CAUSEWAY", "goal":"MATCH THE DISHES TO THEIR ETCHED SIGHT LINES", "spawn":Vector2(42,215),
            "platforms":[floor_rect,Rect2(85,190,72,8),Rect2(183,156,75,10),Rect2(291,190,65,8)],
            "exits":[["hub",Vector2(27,215),"TRIANGULATION HUB"],["return",Vector2(447,215),"COUNTERWEIGHT RETURN"]],
            "actions":[["dish_0",Vector2(120,183),"TURN WEST REFLECTOR"],["dish_1",Vector2(216,149),"TURN SKY REFLECTOR"],["dish_2",Vector2(323,183),"TURN EAST REFLECTOR"],["ear_transmit",Vector2(388,215),"TEST AND LATCH EAST EAR"]]},
    }
    rooms.cellar = {"title":"LISTENING FIELD . SOUTH INTAKE", "goal":"STRIKE THE CRACKED INTAKE FROM BELOW", "spawn":Vector2(40,215),
        "platforms":[floor_rect,Rect2(65,190,68,8),Rect2(297,185,87,8)],
        "exits":[["hub",Vector2(27,215),"HUB SERVICE STAIR"],["lookout",Vector2(444,215),"DRAIN LOOKOUT"]],"actions":[]}
    rooms.sump = {"title":"LISTENING FIELD . TRANSMITTER SUMP", "goal":"VERIFY WEST . EAST . SOUTH . COMMISSION THE FIELD", "spawn":Vector2(40,215),
        "platforms":[floor_rect],"exits":[["lookout",Vector2(27,215),"DRAIN LOOKOUT"],["causeway",Vector2(444,215),"CAUSEWAY SERVICE RETURN"]],
        "actions":[["field_transmit",Vector2(244,215),"VERIFY AND COMMISSION FIELD"]]}
    rooms.hub.exits.append(["cellar",Vector2(153,151),"SOUTH INTAKE"])
    rooms.lookout.exits.append(["cellar",Vector2(126,183),"INTAKE RETURN"])
    rooms.lookout.exits.append(["sump",Vector2(337,178),"TRANSMITTER SUMP"])
    rooms.causeway.exits.append(["sump",Vector2(73,215),"TRANSMITTER RETURN"])
    rooms.hub.exits.append(["arrival",Vector2(27,215),"FLATS RETURN"])
    rooms.amplifier.platforms.append(Rect2(350,105,100,10))
    rooms.amplifier.exits.append(["fourth",Vector2(384,98),"FOURTH DISH . AIR JUMP"])
    rooms.fourth = {"title":"LISTENING FIELD . FOURTH DISH", "goal":"AN INTACT DISH . A DELIBERATE CUT", "spawn":Vector2(40,215),
        "platforms":[floor_rect,Rect2(112,190,66,8),Rect2(203,157,99,10)],
        "exits":[["amplifier",Vector2(27,215),"UPPER AMPLIFIER"]],"actions":[["fourth_memory",Vector2(252,150),"REPLAY ISOLATION ARCHIVE"]]}
    rooms.wire_shelter = {"title":"THE WIRE . INSPECTION SHELTER","goal":"RECOVER THE BRAKE . REPAIR THE CARRIAGE","spawn":Vector2(40,215),
        "platforms":[floor_rect,Rect2(86,190,74,8),Rect2(185,157,110,10)],
        "exits":[["shelter",Vector2(27,215),"STAND RETURN"],["wire_carriage",Vector2(445,215),"CARRIAGE DOCK"]],"actions":[["brake_spare",Vector2(235,150),"RECOVER BRAKE ASSEMBLY"]]}
    rooms.wire_shelter.exits.append(["wire_shaft",Vector2(120,217),"OPTIONAL MAINTENANCE SHAFT"])
    rooms.wire_shaft = {"title":"THE WIRE . MAINTENANCE SHAFT","goal":"ENTER UNDER LEFT WALL . ALTERNATE WALL KICKS","spawn":Vector2(40,217),
        "platforms":[floor_rect,Rect2(184,100,16,90),Rect2(260,66,16,158),Rect2(276,66,204,8)],
        "exits":[["wire_shelter",Vector2(27,217),"INSPECTION RETURN"]],
        "actions":[["shaft_release",Vector2(400,59),"RELEASE RETURN / READ ARCHIVE"],["shaft_recall",Vector2(70,217),"RECALL LIFT DOWN"],["shaft_upper",Vector2(310,59),"RECALL LIFT UP"],["shaft_ride",Vector2(125,217),"SEND LIFT"]]}
    rooms.wire_carriage = {"title":"THE WIRE . SUSPENDED CROSSING","goal":"FIT BRAKE . BOARD CARRIAGE . BOTH SHORES CAN RECALL","spawn":Vector2(40,215),
        "platforms":[Rect2(0,224,199,46),Rect2(330,224,150,46)],
        "exits":[["wire_shelter",Vector2(27,215),"INSPECTION SHELTER"],["array",Vector2(447,215),"ARRAY CORE"]],
        "actions":[["brake_socket",Vector2(69,215),"FIT BRAKE ASSEMBLY"],["carriage_recall",Vector2(107,215),"RECALL LEFT"],["carriage_send",Vector2(150,199),"RIDE TO OTHER SHORE"],["carriage_summon_right",Vector2(393,215),"RECALL RIGHT"]]}
    rooms.array = {"title":"THE ARRAY . COMMON RETURN","goal":"TEST THE CIRCUIT . ISOLATE FAULT . ROUTE HEALTHY FEED","spawn":Vector2(40,215),
        "platforms":[floor_rect],"exits":[["pump",Vector2(27,215),"DROWNED FREIGHT"],["wire_carriage",Vector2(447,215),"WIRE RETURN"]],
        "actions":[["array_test",Vector2(109,215),"RUN / REPLAY DIAGNOSTIC"],["array_isolate",Vector2(244,215),"ISOLATE COMMON RETURN"],["array_bypass",Vector2(374,215),"BYPASS AND COMMISSION"]]}
    rooms.shelter.exits.append(["wire_shelter",Vector2(374,215),"WIRE INSPECTION"])
    rooms.pump.exits.append(["array",Vector2(126,181),"FREIGHT TO ARRAY"])
    rooms.array.exits.append(["wire_shelter",Vector2(174,215),"INSPECTION SERVICE STAIR"])
    rooms.wire_shelter.exits.append(["array",Vector2(335,215),"ARRAY SERVICE STAIR"])
    rooms.approach = {"title":"THE APPROACH . LOCAL FEEDERS","goal":"VERIFY THE FOUR PROJECTS . OPEN THE SERVICE RETURN","spawn":Vector2(40,215),
        "platforms":[floor_rect,Rect2(108,190,68,8)],"exits":[["array",Vector2(27,215),"ARRAY RETURN"],["gate",Vector2(447,215),"SOURCE GATE"],["shelter",Vector2(346,215),"STAND SERVICE RETURN"]],
        "actions":[["approach_latch",Vector2(144,183),"OPEN SERVICE RETURN"]]}
    rooms.gate = {"title":"THE GATE . CARRY THE SIGNAL","goal":"LATCH LOCAL FEEDS . ISOLATE . TEST . COMMIT","spawn":Vector2(40,215),
        "platforms":[floor_rect],"exits":[["approach",Vector2(27,215),"APPROACH RETURN"],["aftermath",Vector2(447,215),"ANSWERING NETWORK"]],
        "actions":[["gate_latch",Vector2(103,215),"LATCH LOCAL FEEDERS"],["gate_isolate",Vector2(184,215),"ISOLATE COMMON RETURN"],["gate_test",Vector2(269,215),"RUN FINAL DIAGNOSTIC"],["gate_commit",Vector2(357,215),"COMMIT RESTORATION"]]}
    rooms.aftermath = {"title":"WHITE SIGNAL . THE NETWORK ANSWERS","goal":"THE SIGNAL HOLDS . YOUR WORLD REMAINS","spawn":Vector2(40,215),
        "platforms":[floor_rect],"exits":[["gate",Vector2(27,215),"GATE RETURN"],["hub",Vector2(443,215),"RETURN TO LISTENING FIELD"]],"actions":[]}
    rooms.array.exits.append(["approach",Vector2(306,215),"SOURCE APPROACH"])
    rooms.shelter.exits.append(["approach",Vector2(324,215),"SOURCE SERVICE RETURN"])
    rooms.hub.exits.append(["aftermath",Vector2(386,215),"ANSWERING NETWORK"])
    rooms.siphon = {"title":"DROWNED . SIPHON STACK","goal":"RAISE FLOAT . PIN . DRAIN . SERVICE THE LOWER RETURN","spawn":Vector2(240,215),
        "platforms":[Rect2(200,224,80,46),Rect2(200,174,80,8),Rect2(65,106,95,8),Rect2(320,106,95,8),Rect2(390,220,40,8),Rect2(385,180,35,8)],
        "exits":[["pump",Vector2(240,215),"DRY PUMP HOUSE"],["lookout",Vector2(330,99),"LOOKOUT SERVICE RETURN"]],
        "actions":[["siphon_valve",Vector2(240,167),"TRANSFER WATER"],["siphon_archive",Vector2(110,99),"MAINTENANCE ARCHIVE"],["siphon_catch",Vector2(370,99),"PIN RIGHT FLOAT"],["siphon_wheel",Vector2(406,213),"SERVICE RETURN WHEEL"]]}
    rooms.pump.exits.append(["siphon",Vector2(284,148),"SIPHON SERVICE BAY"])
    rooms.lookout.exits.append(["siphon",Vector2(245,147),"SIPHON RETURN"])
    rooms.merge(preload("res://scripts/stand_district_rooms.gd").rooms(),true)
    rooms["return"].exits = rooms["return"].exits.filter(func(route): return route[0] != "conductor")
    for route in rooms["return"].exits:
        if route[0] == "shelter": route[0] = "stand_rim"
    for route in rooms.pump.exits:
        if route[0] == "shelter": route[0] = "stand_sluice"
    for route in rooms.wire_shelter.exits:
        if route[0] == "shelter": route[0] = "stand_bridge"
    rooms.merge(preload("res://scripts/drowned_district_rooms.gd").rooms(),true)
    for route in rooms.array.exits:
        if route[0] == "pump": route[0] = "drowned_dock"
    rooms.array.platforms.append_array([Rect2(40,190,70,8),Rect2(130,156,90,8)])
    rooms.array.exits.append(["array_inspection",Vector2(185,149),"OPTIONAL INSPECTION BAY"])
    rooms.array_inspection = {"title":"ARRAY . INSPECTION BAY","goal":"WATCH THE PATROL . DASH . STOMP . OR TAKE THE UPPER WALK","spawn":Vector2(40,217),
        "platforms":[Rect2(0,224,480,46),Rect2(100,190,65,8),Rect2(175,156,140,8),Rect2(350,190,100,8)],
        "exits":[["array",Vector2(27,217),"ARRAY RETURN"]],"actions":[["inspection_archive",Vector2(420,183),"REPLAY INSPECTION ARCHIVE"]]}
    rooms.array_inspection.exits.append(["array_cable",Vector2(355,183),"CABLE GALLERY"])
    rooms.wire_shelter.platforms.append(Rect2(330,157,75,10))
    rooms.wire_shelter.exits.append(["array_cable",Vector2(355,150),"ARCHIVE SERVICE RETURN"])
    rooms.array_cable = {"title":"ARRAY . CABLE GALLERY","goal":"WATCH THE DROP MARK . UPPER WALK PASSES ABOVE","spawn":Vector2(40,217),
        "platforms":[floor_rect,Rect2(70,190,60,8),Rect2(110,156,65,8),Rect2(150,122,65,8),Rect2(195,88,160,8)],
        "exits":[["array_inspection",Vector2(27,217),"INSPECTION BAY RETURN"],["wire_shelter",Vector2(445,217),"UNLATCHED SHELTER RETURN"]],
        "actions":[["cable_archive",Vector2(420,217),"RECOVER LOG / OPEN SERVICE RETURN"]]}
    rooms.merge(preload("res://scripts/source_district_rooms.gd").rooms(flags),true)
    rooms.aftermath.exits.append(["source_walk",Vector2(160,217),"COMMISSIONING RETURN"])
    rooms.amplifier = preload("res://scripts/amplifier_room.gd").room(flags)
    return rooms.get(id,rooms.hub).duplicate(true)
