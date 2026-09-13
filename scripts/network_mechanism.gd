extends RefCounted
const Motion = preload("res://scripts/carriage_motion.gd")
var world: Node2D
var motion = Motion.new()
var carrier: AnimatableBody2D
var diagnostic_time := 0.0
var shaft: RefCounted
func _init(owner_world: Node2D) -> void:
    world = owner_world
    shaft = preload("res://scripts/wire_shaft_mechanism.gd").new(world)
func enter() -> void:
    shaft.reset()
    motion.reset()
    diagnostic_time = 0
func build() -> void:
    shaft.build()
    carrier = null
    if world.room_id != "wire_carriage": return
    carrier = AnimatableBody2D.new()
    carrier.sync_to_physics = false
    carrier.position = Vector2(motion.position,210)
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(64,8)
    collision.shape = shape
    carrier.add_child(collision)
    world.solids.add_child(carrier)
func use(id: String) -> bool:
    if shaft.use(id): return true
    match id:
        "brake_spare":
            if world.room_id != "wire_shelter": return false
            if world._commit("brake_spare"): world._notify("BRAKE ASSEMBLY RECOVERED . FIT AT THE DOCK")
        "brake_socket":
            if world.room_id != "wire_carriage": return false
            if not world.profile.has_flag("brake_spare"): world._notify("SPARE IN THE INSPECTION SHELTER . CARRIAGE NOT REQUIRED")
            elif world._commit("wire_repaired"): world._notify("BRAKE FITTED . CARRIAGE AND BOTH RECALLS LIVE")
        "carriage_send", "carriage_recall", "carriage_summon_right":
            if world.room_id != "wire_carriage": return false
            if not world.profile.has_flag("wire_repaired"):
                world._notify("FIT THE BRAKE BEFORE MOVING")
            elif id == "carriage_recall" or (id == "carriage_send" and motion.position > 250): motion.recall()
            else: motion.send_right()
        "array_test":
            if world.room_id != "array": return false
            diagnostic_time = 2
            world._notify("DIAGNOSTIC . WATCH THE COMMON RETURN")
        "array_isolate":
            if world.room_id != "array": return false
            if not world.profile.has_flag("diagnostic_seen"): world._notify("RUN THE VISIBLE DIAGNOSTIC FIRST")
            elif world._commit("array_isolated"): world._notify("FAULT HELD . HEALTHY BRANCH STILL LIT")
        "array_bypass":
            if world.room_id != "array": return false
            if not world.profile.has_flag("array_isolated"): world._notify("ISOLATE THE FAULT BEFORE ROUTING AROUND IT")
            elif world._commit("array_restored"): world._notify("ARRAY COMMISSIONED . LOCAL FEEDS HOLD INDEPENDENTLY")
        _: return false
    return true
func tick(delta: float) -> void:
    shaft.tick(delta)
    if world.room_id == "wire_carriage":
        motion.tick(delta)
        if is_instance_valid(carrier): carrier.position.x = motion.position
        for action in world.room.actions:
            if action[0] == "carriage_send": action[1] = Vector2(motion.position,199)
    if world.room_id == "array" and diagnostic_time > 0:
        diagnostic_time = maxf(0,diagnostic_time-delta)
        if diagnostic_time == 0:
            if world._commit("diagnostic_seen"): world._notify("COMMON RETURN FAULT . ONE BRANCH CAN BE ISOLATED")
func draw_world() -> void:
    shaft.draw_world()
    if world.room_id == "array_cable": draw_cable_gallery()
    if not world.room_id in ["wire_shelter","wire_carriage","array"]: return
    world.draw_rect(Rect2(0,29,480,217),Color(0.13,0.11,0.09,0.25))
    for i in 5:
        var x := i*110+16
        world.draw_line(Vector2(x,48),Vector2(x+20,224),DrawUtil.DARK,4)
        world.draw_line(Vector2(x,48),Vector2(x+97,62),DrawUtil.GRAY,1)
    if world.room_id == "wire_shelter":
        world.text_at(Vector2(155,82),"SHARED SPARES . KEEP THE RETURN OPEN",DrawUtil.GRAY)
        world.draw_rect(Rect2(212,116,46,28),DrawUtil.GRAY,false,2)
        if not world.profile.has_flag("brake_spare"):
            world.draw_line(Vector2(218,125),Vector2(249,135),DrawUtil.WHITE,4)
        return
    if world.room_id == "wire_carriage":
        world.draw_line(Vector2(117,79),Vector2(383,79),DrawUtil.GRAY,2)
        if is_instance_valid(carrier):
            world.draw_line(Vector2(motion.position,79),Vector2(motion.position,206),DrawUtil.GRAY,1)
            world._draw_platform(Rect2(carrier.position-Vector2(32,4),Vector2(64,8)))
        world.text_at(Vector2(201,49),"RECALLABLE CARRIAGE",DrawUtil.GRAY)
        return
    var isolated: bool = world.profile.has_flag("array_isolated")
    var seen: bool = world.profile.has_flag("diagnostic_seen")
    world.draw_line(Vector2(100,110),Vector2(220,110),DrawUtil.GRAY,2)
    world.draw_line(Vector2(244,110),Vector2(354,75),DrawUtil.DARK if isolated else DrawUtil.GRAY,2)
    world.draw_line(Vector2(100,110),Vector2(354,155),DrawUtil.WHITE,2)
    world.draw_line(Vector2(221,110),Vector2(224,86) if isolated else Vector2(243,110),DrawUtil.WHITE,3)
    world.draw_circle(Vector2(356,155),10,DrawUtil.WHITE)
    world.draw_circle(Vector2(356,75),10,DrawUtil.DARK if seen else DrawUtil.GRAY)
    world.text_at(Vector2(307,48),"FAULT HELD" if isolated else "COMMON RETURN",DrawUtil.GRAY)
    world.text_at(Vector2(310,174),"HEALTHY FEED",DrawUtil.WHITE)
    if seen:
        world.draw_polyline(PackedVector2Array([Vector2(292,78),Vector2(283,91),Vector2(297,95),Vector2(287,107)]),DrawUtil.WHITE,2)
    if diagnostic_time > 0:
        world.draw_circle(Vector2(100+(2-diagnostic_time)*61,110),3,DrawUtil.WHITE)
    if world.profile.has_flag("array_restored"):
        world.text_at(Vector2(118,64),"ARRAY HOLDS",DrawUtil.WHITE)

func draw_cable_gallery() -> void:
    world.draw_rect(Rect2(0,29,480,195),Color("111417"))
    # Stored cable reels and overhead trays explain the clinger's perch.
    for centre in [Vector2(48,116),Vector2(103,104),Vector2(389,113)]:
        for radius in [13,17,21]: world.draw_arc(centre,radius,0.1,TAU-0.2,24,Color("292e32"),1)
        world.draw_line(centre-Vector2(3,26),centre+Vector2(3,26),Color("252a2e"),2)
    for x in [14,176,365,465]:
        world.draw_line(Vector2(x,33),Vector2(x,223),Color("23292e"),3)
        for at in range(45,215,34): world.draw_rect(Rect2(x-3,at,6,2),Color("353b3e"))
    for at in [44,49,54]:
        world.draw_polyline(PackedVector2Array([Vector2(19,at),Vector2(345,at),Vector2(361,at+16),Vector2(463,at+16)]),Color("2b3034"),2)
    world.draw_rect(Rect2(230,96,40,4),DrawUtil.GRAY)
    for x in [233,265]: world.draw_rect(Rect2(x,97,2,2),DrawUtil.BG)
    var restored: bool = world.profile.has_flag("cable_archive")
    world.draw_rect(Rect2(402,187,29,37),Color("303639"))
    world.draw_rect(Rect2(406,192,21,13),DrawUtil.BG)
    for x in [410,416,422]: world.draw_rect(Rect2(x,197,2,4),DrawUtil.GRAY if restored else DrawUtil.DARK)
    world.draw_line(Vector2(427,205),Vector2(445,205),DrawUtil.GRAY if restored else DrawUtil.DARK,1)
    world.coherence_light.draw(world,Vector2(420,209),1.0 if restored else 0.2,Color(0.54,0.64,0.65,0.18))
    world.text_at(Vector2(371,176),"RETURN LOG",DrawUtil.GRAY)
