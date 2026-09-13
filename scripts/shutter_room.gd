extends RefCounted
const ID = "array_shutter"
const FLAG = "shutter_archive"
var upper := true

func reset() -> void:
    upper = true

func archive_lit(flags: Dictionary) -> bool:
    return not upper or flags.get(FLAG,false)

func return_lit(flags: Dictionary) -> bool:
    return upper or flags.get(FLAG,false)

static func room() -> Dictionary:
    return {"title":"ARRAY . SHUTTER CHAMBER","goal":"ROUTE ONE LIGHT . PROJECTOR BELOW . RETURN ABOVE","spawn":Vector2(40,217),
        "platforms":[Rect2(0,224,480,46),Rect2(70,190,65,8),Rect2(130,156,65,8),Rect2(190,122,65,8),Rect2(250,88,195,8)],
        "exits":[["array_inspection",Vector2(27,217),"INSPECTION RETURN"],["array",Vector2(420,81),"POWERED CORE RETURN"]],
        "actions":[["shutter_selector",Vector2(210,217),"ROUTE LIGHT"],["shutter_archive",Vector2(420,217),"PROJECT / RETAIN LOCAL COPY"]]}

func use(world: Node2D, id: String) -> bool:
    if world.room_id != ID: return false
    if id == "shutter_selector":
        upper = not upper
        world._notify("LOCAL COPY HOLDS BOTH BRANCHES" if world.profile.has_flag(FLAG) else "RETURN ABOVE LIT" if upper else "PROJECTOR BELOW LIT . RETURN TO THE LOWER FLOOR")
        return true
    if id != "shutter_archive": return false
    if not archive_lit(world.profile.data.flags):
        world._notify("PROJECTOR DARK . ROUTE LIGHT AT THE CENTRAL LEVER")
    elif world._commit(FLAG):
        world.memory_time = 8
        world._notify("THEY KEPT A LOCAL COPY . BOTH BRANCHES HOLD . CORE SHORTCUT OPEN")
    return true

func draw(world: Node2D) -> void:
    if world.room_id != ID: return
    var flags: Dictionary = world.profile.data.flags
    world.draw_rect(Rect2(0,29,480,195),Color("0c1115"))
    world.draw_line(Vector2(210,198),Vector2(210,167) if upper else Vector2(233,180),DrawUtil.WHITE,2)
    world.draw_rect(Rect2(201,198,18,26),DrawUtil.GRAY)
    for branch in [0,1]:
        var lit: bool = return_lit(flags) if branch == 0 else archive_lit(flags)
        var endpoint := Vector2(420,65) if branch == 0 else Vector2(420,189)
        var tone: Color = DrawUtil.GRAY if lit else Color("293139")
        world.draw_polyline(PackedVector2Array([Vector2(210,198),Vector2(235,198),Vector2(235,endpoint.y),endpoint]),tone,2)
        world.coherence_light.draw(world,endpoint,0.85 if lit else 0.0,Color(0.58,0.69,0.75,0.22))
    world.draw_rect(Rect2(404,190,32,34),DrawUtil.GRAY,false,2)
    world.draw_rect(Rect2(411,197,18,10),DrawUtil.WHITE if archive_lit(flags) else DrawUtil.DARK)
    world.text_at(Vector2(298,177),"LOCAL COPY" if flags.get(FLAG,false) else "PROJECTOR",DrawUtil.GRAY)
    world.text_at(Vector2(295,47),"RETURN LIT" if return_lit(flags) else "RETURN DARK",DrawUtil.GRAY)
    if flags.get(FLAG,false):
        world.draw_line(Vector2(426,190),Vector2(451,190),DrawUtil.GRAY,2)
        world.draw_line(Vector2(451,190),Vector2(451,65),DrawUtil.GRAY,2)
    if world.memory_time > 0:
        for x in [306,340]:
            world.draw_rect(Rect2(x,183,6,7),DrawUtil.GRAY)
            world.draw_rect(Rect2(x-2,192,10,27),DrawUtil.GRAY)
        world.draw_line(Vector2(312,200),Vector2(404,200),DrawUtil.WHITE,1)
