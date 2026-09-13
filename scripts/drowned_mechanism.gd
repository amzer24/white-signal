extends RefCounted
## Main drainage, powered float and optional tide own separate temporary state.
const IDS = preload("res://scripts/drowned_district_rooms.gd").IDS
var world: Node2D
var water_y := 246.0
var target_y := 246.0
var main_y := 160.0
var main_target := 160.0
var cycle_y := 153.0
var cycle_target := 153.0
var cycle_setting := 2
var setting := 0
var carrier: AnimatableBody2D
var pump_texture: Texture2D
var backdrop = preload("res://scripts/drowned_backdrop.gd").new()
func _init(owner_world: Node2D) -> void:
    world = owner_world
    if world.profile.has_flag("basin_bled") or world.profile.has_flag("pump_repaired") or world.profile.has_flag("drowned_restored"):
        main_y = 246
        main_target = 246
    if ResourceLoader.exists("res://assets/exploration/drowned-pump.png"):
        pump_texture = load("res://assets/exploration/drowned-pump.png")
func enter() -> void:
    setting = 0
    water_y = 246
    target_y = 246
    if world.room_id == "basin":
        if world.profile.has_flag("basin_bled") or world.profile.has_flag("pump_repaired") or world.profile.has_flag("drowned_restored"):
            main_y = 246
            main_target = 246
        water_y = main_y
        target_y = main_target
    elif world.room_id == "float":
        water_y = 212
        target_y = 212
    elif world.room_id == "drowned_cycle":
        water_y = cycle_y
        target_y = cycle_target
func reset_safe() -> void:
    main_y = 246
    main_target = 246
    cycle_y = 153
    cycle_target = 153
    cycle_setting = 2
    setting = 0
    water_y = 246
    target_y = 246
    if is_instance_valid(carrier): carrier.position.y = 202
func build() -> void:
    carrier = null
    if world.room_id != "float": return
    carrier = AnimatableBody2D.new()
    carrier.sync_to_physics = false
    carrier.position = Vector2(290,water_y-10)
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(58,8)
    collision.shape = shape
    collision.one_way_collision = true
    carrier.add_child(collision)
    world.solids.add_child(carrier)
func use(id: String) -> bool:
    match id:
        "bleed":
            if world.room_id != "basin": return false
            if main_target >= 241:
                world._notify("SERVICE STREET HOLDS DRY")
            elif main_target < 198:
                main_target = 198
                target_y = main_target
                Sfx.mechanism("valve")
                world._notify("MIDDLE MARK . KEEP TO THE DRY STAIR")
            elif world._commit("basin_bled"):
                main_target = 246
                target_y = main_target
                Sfx.mechanism("valve")
                world._notify("DRAINING TO LOW . FOLLOW THE EXPOSED STREET")
        "impeller":
            if world.room_id != "drowned_street": return false
            if world._commit("impeller"):
                Sfx.mechanism("part")
                world._notify("IMPELLER RECOVERED . RETURN TO DRY PUMP")
        "pump_socket":
            if world.room_id != "pump": return false
            if not world.profile.has_flag("impeller"):
                Sfx.mechanism("reject")
                world._notify("MISSING IMPELLER . SEARCH THE OLD STREET")
            elif world._commit("pump_repaired"):
                Sfx.mechanism("repair")
                world._notify("PUMP LIVE . FOLLOW THE SURVEY GALLERY TO THE FLOAT")
        "air_jump":
            if world.room_id != "drowned_gallery": return false
            if world._commit("air_jump"):
                Sfx.mechanism("protocol")
                world._sync_abilities()
                world.player.air_jumps = 1
                world._notify("AIR JUMP LEARNED . RELEASE AND JUMP AGAIN IN AIR")
        "float_valve":
            if world.room_id != "float": return false
            if not world.profile.has_flag("pump_repaired"):
                Sfx.mechanism("reject")
                world._notify("NO POWER . RETURN THROUGH THE GALLERY")
            else:
                setting = (setting+1)%3
                target_y = [212.0,180.0,152.0][setting]
                Sfx.mechanism("valve")
                world._notify(["FLOAT LOW","FLOAT MIDDLE","FLOAT HIGH . AIR JUMP TO UPPER LANDING"][setting])
        "float_latch":
            if world.room_id != "float": return false
            if world.profile.has_flag("drowned_restored"):
                world._notify("UPPER RETURN ALREADY HOLDS")
            elif not world.profile.has_flag("pump_repaired") or not world.profile.has_flag("air_jump") or setting != 2 or water_y > 153:
                Sfx.mechanism("reject")
                world._notify("REPAIR PUMP . RAISE FLOAT . LEARN AIR JUMP")
            elif world.profile.set_flags({"float_latch":true,"drowned_restored":true}):
                main_y = 246
                main_target = 246
                Sfx.mechanism("repair")
                world._notify("CONDUIT LATCHED . PUMP SHORTCUT AND FREIGHT OPEN")
            else: world._notify("SAVE FAILED . TRY THE LATCH AGAIN")
        "cycle_valve":
            if world.room_id != "drowned_cycle": return false
            cycle_setting = (cycle_setting+1)%3
            cycle_target = [246.0,190.0,153.0][cycle_setting]
            target_y = cycle_target
            Sfx.mechanism("valve")
            world._notify("OPTIONAL TIDE . MAIN STREET UNCHANGED")
        "cycle_archive":
            if world.room_id != "drowned_cycle": return false
            if water_y < 241:
                world._notify("ARCHIVE SUBMERGED . DRAIN FROM DRY CONTROL")
            elif world._commit("cycle_archive"):
                Sfx.mechanism("part")
                world._notify("DIVERSION RECORD . FREIGHT SURVIVED THE HOMES BELOW")
        _:
            return false
    return true
func tick(delta: float) -> void:
    if not world.room_id in ["basin","float","drowned_cycle"]: return
    water_y = move_toward(water_y,target_y,30.0*delta)
    if world.room_id == "basin": main_y = water_y
    elif world.room_id == "drowned_cycle": cycle_y = water_y
    if is_instance_valid(carrier): carrier.position.y = water_y-10
    var span: Vector2 = {"basin":Vector2(235,365),"float":Vector2(261,319),"drowned_cycle":Vector2(220,480)}[world.room_id]
    var p: Vector2 = world.player.position
    if p.x > span.x and p.x < span.y and p.y+5 > water_y and water_y < 241:
        Sfx.mechanism("hazard")
        world.respawn()
        world._notify("STATIC WATER . DRY RIM . DISCOVERIES RETAINED")
func draw_world() -> void:
    if not world.room_id in IDS: return
    world.draw_rect(Rect2(0,29,480,215),Color(0.07,0.11,0.10,0.35))
    var has_skyline: bool = backdrop.draw(world)
    for i in 5:
        var x := 20+i*96
        var top := (150 if has_skyline else 68)+(i%3)*17
        world.draw_rect(Rect2(x,top,68,244-top),Color(0.09,0.12,0.11))
        world.draw_line(Vector2(x-3,top),Vector2(x+71,top),Color(0.20,0.23,0.21),2)
        for row in 3:
            for column in 2:
                var lit: bool = world.profile.has_flag("drowned_restored") and row == 0
                world.draw_rect(Rect2(x+12+column*28,top+14+row*28,12,17),Color(0.38,0.42,0.37) if lit else Color(0.045,0.055,0.05))
    if world.room_id == "pump":
        var repaired: bool = world.profile.has_flag("pump_repaired")
        var pipe_color := Color(0.24,0.29,0.26)
        world.draw_polyline(PackedVector2Array([Vector2(30,202),Vector2(174,202),Vector2(174,116),Vector2(217,116)]),pipe_color,3)
        world.draw_polyline(PackedVector2Array([Vector2(272,116),Vector2(323,116),Vector2(323,190),Vector2(437,190),Vector2(437,201)]),pipe_color,3)
        if pump_texture != null:
            world.draw_texture(pump_texture,Vector2(196,79),Color(0.8,0.8,0.8))
        else:
            world.draw_rect(Rect2(200,85,87,66),Color(0.10,0.14,0.12))
            world.draw_circle(Vector2(244,116),19,DrawUtil.GRAY)
            world.draw_circle(Vector2(244,116),13,DrawUtil.BG)
        if repaired:
            for i in 4:
                var direction := Vector2.RIGHT.rotated(i*PI/2+world.elapsed*0.7)
                world.draw_line(Vector2(244,116),Vector2(244,116)+direction*12,DrawUtil.WHITE,3)
            world.draw_circle(Vector2(244,116),3,DrawUtil.GRAY)
        world.draw_rect(Rect2(319,130,8,10),DrawUtil.BG)
        world.draw_rect(Rect2(321,132,4,6),DrawUtil.WHITE if repaired else DrawUtil.DARK)
        world.text_at(Vector2(188,66),"FLOAT SUPPLY . LIVE" if repaired else "CIVILIAN SUPPLY . ISOLATED",DrawUtil.GRAY)
        return
    if world.room_id == "drowned_street":
        world.draw_polyline(PackedVector2Array([Vector2(12,182),Vector2(160,182),Vector2(160,203),Vector2(465,203)]),Color(0.27,0.32,0.28),4)
        world.text_at(Vector2(198,76),"DIVERSION CROSSES THE DOORWAYS",DrawUtil.GRAY)
        if not world.profile.has_flag("impeller"):
            world.draw_circle(Vector2(265,211),6,DrawUtil.WHITE)
            world.draw_circle(Vector2(265,211),3,DrawUtil.BG)
    elif world.room_id == "drowned_gallery":
        world.text_at(Vector2(199,76),"SURVEY MARKS BELOW THE OLD WATERLINE",DrawUtil.GRAY)
        world.draw_line(Vector2(210,160),Vector2(226,160),DrawUtil.GRAY,1)
        world.draw_line(Vector2(210,120),Vector2(226,120),DrawUtil.GRAY,1)
    elif world.room_id == "drowned_dock":
        world.text_at(Vector2(162,90),"FREIGHT HARDWARE SURVIVED",DrawUtil.GRAY)
    if not world.room_id in ["basin","float","drowned_cycle"]: return
    var span: Vector2 = {"basin":Vector2(235,365),"float":Vector2(261,319),"drowned_cycle":Vector2(220,480)}[world.room_id]
    world.draw_rect(Rect2(span.x,water_y,span.y-span.x,maxf(0,244-water_y)),Color(0.12,0.19,0.17))
    for x in range(int(span.x),int(span.y),8):
        var y := roundf(water_y)+float((int(world.elapsed*3)+x/8)%2)
        world.draw_line(Vector2(x,y),Vector2(minf(x+5,span.y),y),DrawUtil.WHITE,1)
    if world.room_id == "basin":
        for mark in [[160,"HIGH"],[198,"MID"],[241,"LOW"]]:
            world.draw_line(Vector2(368,mark[0]),Vector2(376,mark[0]),DrawUtil.GRAY,1)
            world.text_at(Vector2(381,mark[0]-4),mark[1],DrawUtil.GRAY)
    if is_instance_valid(carrier):
        world._draw_platform(Rect2(carrier.position-Vector2(29,4),Vector2(58,8)))
        world.draw_line(Vector2(290,95),Vector2(290,224),DrawUtil.GRAY,1)
