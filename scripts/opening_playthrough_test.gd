extends "res://scripts/exploration_routes_test.gd"

var fixture_path := ""

func use_control() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_E
    event.pressed = true
    Input.parse_input_event(event)
    await frames(2)
    event = InputEventKey.new()
    event.keycode = KEY_E
    event.pressed = false
    Input.parse_input_event(event)
    await frames(3)

func require_room(id: String) -> bool:
    if scene.room_id == id: return true
    failed += 1
    print("FAIL expected room ",id," actual ",scene.room_id," at ",scene.player.position)
    return false

func run() -> void:
    fixture_path = "res://test-user/%s-%d.json" % [get_script().resource_path.get_file().get_basename(),OS.get_process_id()]
    print("ISOLATED PROFILE ",fixture_path)
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = fixture_path
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    await frames(5)
    if not require_room("flats"): finish(); return
    await land(100,217,false)
    await land(145,193)
    await land(211,217,false)
    Input.action_press("jump")
    await frames(30)
    Input.action_release("jump")
    await frames(20)
    if not scene.profile.has_flag("intro_memory"):
        failed += 1
        print("FAIL physical memory strike")
    await land(270,217,false)
    await land(330,201)
    await land(400,193)
    await land(442,217,false)
    await use_control()
    if not require_room("conduit"): finish(); return
    await land(100,217,false)
    await land(160,183)
    await land(211,217,false)
    await use_control()
    await land(397,183)
    await land(445,217,false)
    await use_control()
    if not require_room("arrival"): finish(); return
    await land(100,217,false)
    await land(145,183)
    await land(240,217,false)
    await use_control()
    await land(325,193)
    await land(420,183)
    await land(456,217,false)
    await use_control()
    if require_room("hub"):
        for flag in ["intro_memory","conduit_open","first_beacon"]:
            if not scene.profile.has_flag(flag):
                failed += 1
                print("FAIL opening discovery missing: ",flag)
        if not scene.profile.load_profile() or scene.profile.data.room != "hub":
            failed += 1
            print("FAIL opening progress reload")
    if scene.room_id == "hub": await west_route()
    finish()

func west_route() -> void:
    await land(125,217,false)
    await land(82,185)
    await land(101,185,false)
    await land(146,151)
    await land(122,151,false)
    await land(80,119)
    await use_control()
    if not require_room("workshop"): return
    await land(175,217,false)
    await land(350,217,false)
    await land(440,217,false)
    await use_control()
    if not require_room("gallery"): return
    await land(168,217,false)
    await use_control()
    Input.action_press("jump")
    for i in 65:
        steer(225)
        await physics_frame
    Input.action_release("jump")
    Input.action_release("move_right")
    Input.action_release("move_left")
    await frames(160)
    await land(299,113)
    await land(328,113,false)
    await use_control()
    await land(225,113)
    await land(185,150,false)
    await land(130,183,false)
    await land(168,217,false)
    await use_control()
    if not scene.profile.has_flag("west_ear"):
        failed += 1
        print("FAIL west ear reroute through nearby input")
        return
    await land(130,183)
    await land(192,150)
    await land(225,113)
    await land(266,118,false)
    await land(330,113)
    await land(421,113,false)
    await use_control()
    if not require_room("amplifier"): return
    await land(90,183)
    await land(167,149)
    await land(199,149,false)
    await use_control()
    if not scene.profile.has_flag("dash"):
        failed += 1
        print("FAIL dash acquisition through nearby input")
        return
    await land(229,149,false)
    Input.action_press("jump")
    for i in 130:
        if i == 15: Input.action_release("jump")
        if i == 20: Input.action_press("dash")
        if i == 29: Input.action_release("dash")
        steer(390)
        await physics_frame
        if i>25 and scene.player.is_on_floor() and scene.player.position.x>340 and absf(scene.player.position.y-149)<5: break
    for action in ["jump","dash","move_left","move_right"]: Input.action_release(action)
    if scene.player.position.x<340 or absf(scene.player.position.y-149)>5:
        failed += 1
        print("FAIL first Dash crossing")
        return
    await land(410,149,false)
    await use_control()
    if not scene.profile.has_flag("amplifier_released"):
        failed += 1
        print("FAIL amplifier return release")
        return
    await land(449,149,false)
    await use_control()
    if not require_room("return"): return
    await land(115,217,false)
    await land(175,184)
    await land(204,184,false)
    await land(283,174)
    await land(303,174,false)
    await use_control()
    await land(432,217,false)
    await use_control()
    if not require_room("hub"): return
    await land(430,217,false)
    await use_control()
    if not require_room("lookout"): return
    await land(113,183)
    await land(158,183,false)
    await land(221,147)
    await use_control()
    if not scene.profile.has_flag("return_open") or scene.map_state("pump") != "surveyed":
        failed += 1
        print("FAIL shortcut and survey discovery loop")
        return
    await drowned_route()

func air_land(x: float,y: float) -> void:
    Input.action_press("jump")
    for i in 105:
        if i == 15: Input.action_release("jump")
        if i == 19: Input.action_press("jump")
        steer(x)
        await physics_frame
        if i > 25 and scene.player.is_on_floor() and absf(scene.player.position.x-x)<8 and absf(scene.player.position.y-y)<5: break
    Input.action_release("jump")
    Input.action_release("move_left")
    Input.action_release("move_right")
    if absf(scene.player.position.y-y)>5:
        failed += 1
        print("MISSED AIR LANDING ",scene.player.position)
    await frames(4)
func land(x: float, y: float, jump := true) -> void:
    Input.action_release("jump")
    await frames(2)
    if jump: Input.action_press("jump")
    var reached := false
    for i in 180:
        steer(x)
        await physics_frame
        if i > 15 and scene.player.is_on_floor() and absf(scene.player.position.x-x) < 8 and absf(scene.player.position.y-y) < 5:
            reached = true
            break
    Input.action_release("jump")
    Input.action_release("move_left")
    Input.action_release("move_right")
    if not reached:
        failed += 1
        print("FAIL landing ",Vector2(x,y)," from actual ",scene.player.position)
    await frames(3)
func drowned_route() -> void:
    await land(288,217,false)
    await land(352,178)
    await land(415,178,false)
    await use_control()
    if not require_room("basin"): return
    await frames(5)
    await land(80,115,false)
    await use_control()
    await use_control()
    await frames(180)
    await land(140,217,false)
    await land(260,217,false)
    await use_control()
    print("DESCENT: ",scene.room_id," water=",scene.drowned.water_y)
    await land(210,217,false)
    await land(340,217,false)
    await land(265,217,false)
    await use_control()
    await land(445,217,false)
    await use_control()
    await land(75,217,false)
    await use_control()
    await land(140,183)
    await land(165,183,false)
    await air_land(270,113)
    await land(420,113,false)
    print("GALLERY: air=",scene.profile.has_flag("air_jump")," landing=",scene.player.position)
    await land(220,217,false)
    await land(27,217,false)
    await use_control()
    await land(250,217,false)
    await land(260,183)
    await land(240,183,false)
    await land(180,149)
    await land(145,149,false)
    await land(80,115)
    await land(30,115,false)
    await use_control()
    await land(250,183)
    await land(195,149)
    await land(200,115)
    await land(238,115,false)
    await land(315,115)
    await land(336,115,false)
    await land(425,115)
    await land(445,115,false)
    await use_control()
    await land(135,183)
    await land(160,183,false)
    await land(240,149)
    await use_control()
    print("DRY RETURN: room=",scene.room_id," part=",scene.profile.has_flag("impeller")," air=",scene.profile.has_flag("air_jump")," repaired=",scene.profile.has_flag("pump_repaired"))
    await land(160,183,false)
    await land(27,217,false)
    await use_control()
    await land(360,217,false)
    await land(260,217,false)
    await use_control()
    await land(210,217,false)
    await land(445,217,false)
    await use_control()
    await land(140,183)
    await land(165,183,false)
    await air_land(270,113)
    await land(435,113,false)
    await use_control()
    await land(130,183)
    await land(153,183,false)
    await land(207,149)
    await use_control()
    await use_control()
    await frames(135)
    await land(238,149,false)
    await land(290,131)
    await air_land(380,61)
    await use_control()
    await land(438,61,false)
    await use_control()
    print("UPPER RETURN: room=",scene.room_id," latch=",scene.profile.has_flag("drowned_restored")," water=",scene.drowned.water_y)
    if scene.room_id != "pump" or not scene.profile.has_flag("drowned_restored"): failed += 1
    await stand_route()

func stand_route() -> void:
    await land(345,217,false)
    await use_control()
    if not require_room("stand_sluice"): return
    await land(345,217,false)
    await land(286,183,true)
    await land(251,183,false)
    await land(180,149,true)
    await land(141,149,false)
    await land(73,115,true)
    await land(32,115,false)
    await use_control()
    if not require_room("shelter"): return
    await stand_core()

func stand_core() -> void:
    await land(78,217,false)
    await land(140,183,true)
    await land(160,183,false)
    await land(235,149,true)
    await land(266,149,false)
    await land(345,115,true)
    await land(365,115,false)
    await use_control()
    if not require_room("stand_charge"): return
    await land(76,217,false)
    await land(140,183,true)
    await land(164,183,false)
    await land(240,149,true)
    await use_control()
    await frames(200)
    await land(280,149,false)
    await land(353,149,true)
    await land(436,149,false)
    await use_control()
    if not require_room("conductor"): return
    await land(72,217,false)
    await land(128,183,true)
    await land(154,183,false)
    await land(225,151,true)
    await land(256,151,false)
    await land(347,151,true)
    await land(365,151,false)
    await use_control()
    await frames(120)
    if not scene.profile.has_flag("stand_restored"):
        failed += 1
        print("FAIL Stand restoration via input")
        return
    await land(439,151,false)
    await use_control()
    if not require_room("stand_bridge"): return
    await land(366,217,false)
    await use_control()
    if not require_room("wire_shelter"): return
    await land(73,217,false)
    await land(122,183)
    await land(155,183,false)
    await land(231,150)
    await use_control()
    await land(320,217,false)
    await land(445,217,false)
    await use_control()
    if not require_room("wire_carriage"): return
    await land(69,217,false)
    await use_control()
    await land(145,199)
    await use_control()
    await frames(260)
    await land(395,217,false)
    await land(447,217,false)
    await use_control()
    if not require_room("array"): return
    await land(250,217,false)
    await land(109,217,false)
    await use_control()
    await frames(130)
    await land(244,217,false)
    await use_control()
    await land(374,217,false)
    await use_control()
    if not scene.profile.has_flag("wire_repaired") or not scene.profile.has_flag("array_restored"):
        failed += 1
        print("FAIL Wire and Array input journey")
        return
    await field_return_route()

func field_return_route() -> void:
    await land(174,217,false)
    await use_control()
    if not require_room("wire_shelter"): return
    await land(180,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("stand_bridge"): return
    await land(190,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("shelter"): return
    await land(250,217,false)
    await land(100,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("stand_rim"): return
    await land(250,217,false)
    await land(90,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("return"): return
    await land(235,217,false)
    await land(432,217,false)
    await use_control()
    if not require_room("hub"): return
    await land(234,217,false)
    await use_control()
    if not require_room("causeway"): return
    await land(72,217,false)
    await land(120,183)
    await use_control()
    await use_control()
    await land(154,183,false)
    await land(216,149)
    await use_control()
    await land(247,149,false)
    await land(323,183)
    for i in 3: await use_control()
    await land(388,217,false)
    await use_control()
    await land(220,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("hub"): return
    await land(125,217,false)
    await land(82,185)
    await land(101,185,false)
    await land(146,151)
    await use_control()
    if not require_room("cellar"): return
    await land(211,217,false)
    Input.action_press("jump")
    await frames(30)
    Input.action_release("jump")
    await frames(20)
    await land(380,217,false)
    await land(445,217,false)
    await use_control()
    if not require_room("lookout"): return
    await land(158,183,false)
    await land(221,147)
    await land(288,217,false)
    await land(337,178)
    await use_control()
    if not require_room("sump"): return
    await land(244,217,false)
    await use_control()
    if not scene.profile.has_flag("field_restored"):
        failed += 1
        print("FAIL Field commissioning via input")
        return
    await source_route()

func source_route() -> void:
    await land(444,217,false)
    await use_control()
    if not require_room("causeway"): return
    await land(270,217,false)
    await land(447,217,false)
    await use_control()
    if not require_room("return"): return
    await land(169,184)
    await use_control()
    if not require_room("stand_rim"): return
    await land(220,217,false)
    await land(390,217,false)
    await land(445,217,false)
    await use_control()
    if not require_room("shelter"): return
    await land(220,217,false)
    await land(390,217,false)
    await land(447,217,false)
    await use_control()
    if not require_room("stand_bridge"): return
    await land(210,217,false)
    await land(366,217,false)
    await use_control()
    if not require_room("wire_shelter"): return
    await land(210,217,false)
    await land(335,217,false)
    await use_control()
    if not require_room("array"): return
    await land(306,217,false)
    await use_control()
    if not require_room("approach"): return
    await land(144,183)
    await use_control()
    await land(300,217,false)
    await land(447,217,false)
    await use_control()
    if not require_room("gate"): return
    await finale_controls()
    if not require_room("aftermath"): return
    await land(230,217,false)
    await land(443,217,false)
    await use_control()
    if not require_room("hub"): return
    if not scene.profile.load_profile():
        failed += 1
        print("FAIL completed journey reload")
    scene.queue_free()
    await process_frame
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = fixture_path
    root.add_child(scene)
    await frames(5)
    if not require_room("hub"): return
    if not root.get_node("RunState").mods.dash or root.get_node("RunState").mods.air_jumps < 1:
        failed += 1
        print("FAIL scene restart did not apply saved traversal abilities")
    if not scene.can_use_exit("aftermath"):
        failed += 1
        print("FAIL scene restart lost ending revisit exit")
    for flag in ["signal_restored","field_restored","drowned_restored","stand_restored","array_restored","dash","air_jump"]:
        if not scene.profile.has_flag(flag):
            failed += 1
            print("FAIL ending lost discovery: ",flag)

func finish() -> void:
    scene.queue_free()
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(fixture_path+suffix)
    print("OPENING INPUT PLAYTHROUGH: %d failures" % failed)
    quit(1 if failed else 0)

func finale_controls() -> void:
    await land(115,183)
    await land(140,183,false)
    await land(205,149)
    await land(235,149,false)
    Input.action_press("jump")
    for i in 180:
        if i == 15: Input.action_release("jump")
        if i == 19: Input.action_press("jump")
        if i == 35: Input.action_press("dash")
        if i == 44: Input.action_release("dash")
        steer(380)
        await physics_frame
        if i>30 and scene.player.is_on_floor() and absf(scene.player.position.y-73)<5 and absf(scene.player.position.x-380)<8: break
    Input.action_release("jump")
    Input.action_release("dash")
    Input.action_release("move_left")
    Input.action_release("move_right")
    print("GANTRY CROSSING ",scene.player.position)
    if absf(scene.player.position.y-73)>5: failed += 1
    await land(395,73,false)
    await use_control()
    await land(445,73,false)
    await use_control()
    await land(125,183)
    await land(205,149)
    await use_control()
    await frames(100)
    if not scene.profile.has_flag("gate_tested"): failed += 1
    await land(435,149,false)
    await use_control()
    await land(120,183)
    await land(205,149)
    await land(290,115)
    await land(400,149)
    await use_control()
    if not scene.profile.has_flag("signal_restored"): failed += 1
    await land(445,149,false)
    await use_control()
