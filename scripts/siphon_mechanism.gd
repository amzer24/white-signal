extends RefCounted
var world: Node2D
var high_left := true
var levels := [152.0,222.0]
var caught := false
var floats: Array[AnimatableBody2D] = []
const STAIRS := [Rect2(275,143,48,8),Rect2(306,116,40,8)]
func _init(owner_world: Node2D) -> void: world = owner_world
func enter() -> void:
    high_left = true
    levels = [152.0,222.0]
    caught = false
    for i in floats.size():
        if is_instance_valid(floats[i]): floats[i].position.y = levels[i]
func build() -> void:
    floats.clear()
    if world.room_id != "siphon": return
    for x in [140,340]:
        var body := AnimatableBody2D.new()
        body.position = Vector2(x,levels[floats.size()])
        body.sync_to_physics = false
        var collider := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(70,8)
        collider.shape = shape
        collider.one_way_collision = true
        body.add_child(collider)
        world.solids.add_child(body)
        floats.append(body)
    if world.profile.has_flag("siphon_return"):
        for rect in STAIRS: world._solid(rect)
func use(id: String) -> bool:
    if world.room_id != "siphon": return false
    match id:
        "siphon_valve":
            high_left = not high_left
            world._notify("ONE SUPPLY . WATER TRADES SIDES . THE PIN HOLDS")
            Sfx.mechanism("valve")
        "siphon_archive":
            if world._commit("siphon_archive"):
                world._notify("THEY DRAINED THE SERVICE BAY . THE CIVILIAN RETURN STAYED OPEN")
                Sfx.mechanism("part")
        "siphon_catch":
            if not caught and floats[1].position.y > 153:
                world._notify("CATCH EMPTY . RAISE THE RIGHT FLOAT")
                Sfx.mechanism("reject")
            else:
                caught = true
                world._notify("FLOAT PINNED . DRAIN THE BAY . SERVICE WHEEL BELOW")
                Sfx.mechanism("repair")
        "siphon_wheel":
            if not caught and not world.profile.has_flag("siphon_return"):
                world._notify("SERVICE INTERLOCK . PIN FLOAT BEFORE WORKING BELOW")
                Sfx.mechanism("reject")
            elif levels[1] < 220:
                world._notify("WHEEL SUBMERGED . DRAIN THE RIGHT BASIN")
            elif not world.profile.has_flag("siphon_return") and world._commit("siphon_return"):
                for rect in STAIRS: world._solid(rect)
                world._notify("RETURN STAIR HOLDS . LOOKOUT SERVICE ROUTE OPEN")
                Sfx.mechanism("repair")
            elif world.profile.has_flag("siphon_return"):
                world._notify("SERVICE RETURN HOLDS")
        _: return false
    return true
func tick(delta: float) -> void:
    if world.room_id != "siphon": return
    for i in 2:
        levels[i] = move_toward(levels[i],152.0 if (i == 0) == high_left else 222.0,24*delta)
        floats[i].position.y = 152 if i == 1 and caught else levels[i]
        var left := 75+i*220
        if world.player.position.x > left and world.player.position.x < left+115 and world.player.position.y+7 > levels[i]+7:
            world.respawn()
            world._notify("STATIC WATER . DRY DOCK . REPAIRS HOLD")
            Sfx.mechanism("hazard")
            break
func draw_world() -> void:
    if world.room_id != "siphon": return
    world.draw_rect(Rect2(0,29,480,217),Color("101c18"))
    # A service cutaway: structural rails and a shared pipe explain the mechanism.
    for x in [75,190,295,410]:
        world.draw_line(Vector2(x,118),Vector2(x,245),Color("34483e"),3)
        for y in [126,172,236]: world.draw_rect(Rect2(x-2,y,4,3),Color("718073"))
    world.draw_polyline(PackedVector2Array([Vector2(140,234),Vector2(140,240),Vector2(240,240),Vector2(240,178)]),Color("53695b"),5)
    world.draw_polyline(PackedVector2Array([Vector2(240,240),Vector2(340,240),Vector2(340,234)]),Color("53695b"),5)
    for x in [140,340]:
        world.draw_line(Vector2(x,122),Vector2(x,230),Color("435b4b"),2)
    world.draw_line(Vector2(370,107),Vector2(370,147),DrawUtil.GRAY,2)
    world.draw_line(Vector2(370,147),Vector2(351 if caught else 365,147),DrawUtil.WHITE,3)
    if caught:
        world.draw_rect(Rect2(346,146,8,8),DrawUtil.WHITE,false,1)
    for i in 2:
        var x := 75+i*220
        world.draw_rect(Rect2(x,levels[i]+7,115,260-levels[i]-7),Color("284a40"))
        world.draw_line(Vector2(x,levels[i]+7),Vector2(x+115,levels[i]+7),Color("779785"),1)
        for mark in [159,229]: world.draw_line(Vector2(x-6,mark),Vector2(x+5,mark),DrawUtil.GRAY,1)
        world._draw_platform(Rect2(floats[i].position-Vector2(35,4),Vector2(70,8)))
        world.draw_line(Vector2(x+65,240),Vector2(240,240),Color("658574"),3)
    if world.profile.has_flag("siphon_return"):
        for rect in STAIRS: world._draw_platform(rect)
    world.draw_circle(Vector2(240,154),7,DrawUtil.WHITE,false,2)
    world.text_at(Vector2(68,76),"ARCHIVE",DrawUtil.GRAY)
    world.text_at(Vector2(353,59),"PINNED" if caught else "FLOAT CATCH",DrawUtil.GRAY)
    world.draw_circle(Vector2(406,207),6,DrawUtil.WHITE,false,1)
    if not caught and not world.profile.has_flag("siphon_return"):
        world.draw_rect(Rect2(397,198,18,18),DrawUtil.GRAY,false,1)
        world.draw_line(Vector2(398,199),Vector2(414,215),DrawUtil.GRAY,2)
