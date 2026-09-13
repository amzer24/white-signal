extends RefCounted
const RECEIVER = preload("res://assets/exploration/source-receiver.png")
const FEEDERS = preload("res://scripts/source_circuit.gd").FEEDERS
const RECEIVER_ORIGIN = Vector2(24,68)
## Background machinery only. The room registry owns all walkable geometry.
static func draw(world: Node2D, state: Dictionary, remaining: float) -> void:
    var verified: bool = state.tested
    var amount := 1.0 if verified else clampf(1.0-remaining/1.5,0.0,1.0) if remaining > 0 else 0.0
    # A buried common bus and four separate overhead carriers share a visual grammar.
    for x in range(24,480,48):
        world.draw_rect(Rect2(x,62,32,145),Color(0.07,0.075,0.08),false,1)
        world.draw_rect(Rect2(x+4,67,4,4),Color(0.11,0.12,0.13))
    if world.room_id == "gate":
        world.draw_texture(RECEIVER,RECEIVER_ORIGIN,Color(0.34,0.36,0.34))
        world.draw_rect(Rect2(RECEIVER_ORIGIN+Vector2(59,38),Vector2(11,51)),Color("101414"))
        for i in 4:
            var lit: bool = world.profile.has_flag(FEEDERS[i])
            world.draw_rect(Rect2(RECEIVER_ORIGIN+Vector2(62,41+i*12),Vector2(5,5)),Color("7d826d") if lit else Color("171b1b"))
    world.draw_rect(Rect2(0,207,480,9),Color(0.085,0.09,0.095))
    for x in range(0,480,16): world.draw_line(Vector2(x,210),Vector2(x+7,214),Color(0.12,0.125,0.13),1)
    if world.room_id != "source_return": return
    var dim := Color(0.18,0.19,0.20)
    var active := Color(0.65,0.69,0.61)
    # Separate conductors converge on the lift motor, not on the isolated common bus.
    for i in 4:
        var y := 111.0 + i*5
        world.draw_line(Vector2(210,y),Vector2(370,y),dim,1)
        var reach := clampf(amount*4-i,0,1)
        if reach > 0: world.draw_line(Vector2(210,y),Vector2(210+160*reach,y),active,1)
        world.draw_rect(Rect2(366,y-2,5,4),active if reach == 1 else dim)
    world.draw_line(Vector2(210,149),Vector2(210,183),dim,2)
    world.draw_line(Vector2(210,195),Vector2(210,207),dim,2)
    # The knife switch visibly opens the shared return during verification.
    world.draw_line(Vector2(210,195),Vector2(220 if amount > 0 else 210,183),active,2)
    world.draw_rect(Rect2(353,134,20,17),dim,false,1)
    world.draw_circle(Vector2(363,142),4,active if verified else dim)
    world.coherence_light.draw(world,Vector2(363,140),amount,Color(0.66,0.74,0.60,0.30))
    # Seven deck sections rise from a recessed cradle. They are deliberately dark
    # while moving; the normal bright platform appears only after the saved commit.
    if not verified:
        for i in 7:
            var local := clampf(amount*1.4-i*0.065,0,1)
            var y := roundf(202-46*local)
            var x := 245.0+i*15
            world.draw_line(Vector2(x+7,211),Vector2(x+7,y+4),dim,1)
            world.draw_rect(Rect2(x,y,14,4),Color(0.19,0.20,0.21))
    else:
        for i in 7:
            world.draw_line(Vector2(252+i*15,164),Vector2(252+i*15,211),dim,1)

