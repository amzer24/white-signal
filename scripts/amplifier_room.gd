extends RefCounted
static var pedestal: Texture2D
const STEPS := [Rect2(263,190,60,8),Rect2(310,156,55,8)]
static func legacy(flags: Dictionary) -> bool:
    return flags.get("dash",false) and not flags.get("amplifier_training",false)
static func released(flags: Dictionary) -> bool:
    return legacy(flags) or flags.get("amplifier_released",false)
static func room(flags: Dictionary) -> Dictionary:
    var data := {"title":"UPPER AMPLIFIER","goal":"RECOVER DASH . JUMP THEN DASH TO THE RECEIVING LEDGE","spawn":Vector2(40,217),
        "platforms":[Rect2(0,224,480,46),Rect2(80,190,65,8),Rect2(155,156,80,8),Rect2(345,156,135,8)],
        "exits":[["gallery",Vector2(27,217),"GALLERY RETURN"],["return",Vector2(449,149),"COUNTERWEIGHT WALK"]],
        "actions":[["dash",Vector2(192,149),"RECOVER DASH PROTOCOL"],["amplifier_release",Vector2(410,149),"LOWER RETURN STEPS"]]}
    if released(flags): data.platforms.append_array(STEPS)
    data.platforms.append(Rect2(350,65,100,8))
    data.exits.append(["fourth",Vector2(384,58),"FOURTH DISH . AIR JUMP"])
    if legacy(flags): data.exits[1][1] = Vector2(442,217)
    return data

static func draw(world: Node2D) -> void:
    if pedestal == null and ResourceLoader.exists("res://assets/exploration/amplifier-pedestal.png"):
        pedestal = load("res://assets/exploration/amplifier-pedestal.png")
    if pedestal != null:
        world.draw_rect(Rect2(176,124,32,32),Color(0.025,0.025,0.025,0.9))
        world.draw_texture(pedestal,Vector2(176,124))
    # Etched floor arrows identify the launch edge without drawing a false bridge.
    for x in [211,220]:
        world.draw_polyline(PackedVector2Array([Vector2(x,143),Vector2(x+4,146),Vector2(x,149)]),DrawUtil.GRAY,1)
    world.draw_rect(Rect2(350,131,8,18),DrawUtil.GRAY,false,1)
    var complete := released(world.profile.data.flags)
    world.draw_line(Vector2(410,138),Vector2(410,178),DrawUtil.GRAY,1)
    world.draw_line(Vector2(292,178),Vector2(410,178),DrawUtil.GRAY if complete else DrawUtil.DARK,1)
    world.coherence_light.draw(world,Vector2(350,140),1.0 if complete else 0.35,Color(0.65,0.72,0.59,0.24))
