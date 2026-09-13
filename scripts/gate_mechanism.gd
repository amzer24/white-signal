extends RefCounted
const Circuit = preload("res://scripts/source_circuit.gd")
const Layout = preload("res://scripts/source_district_rooms.gd")
const FEEDERS = Circuit.FEEDERS
var world: Node2D
var circuit: RefCounted
var aftermath_art = preload("res://scripts/aftermath_art.gd").new()
var test_time: float:
    get: return circuit.remaining
func _init(owner_world: Node2D) -> void:
    world = owner_world
    circuit = Circuit.new(world.profile)
func enter() -> void: circuit.cancel()
func progress() -> Dictionary: return Layout.progress(world.profile.data.flags)
func ready() -> bool: return circuit.ready()
func use(id: String) -> bool:
    if id == "approach_latch" and world.room_id == "approach":
        if world._commit("approach_return"): world._notify("STAND SERVICE RETURN OPEN . EVERY REPAIR IS REACHABLE")
        return true
    var result: String = circuit.use(world.room_id,id)
    if result == "unhandled": return false
    _result(result)
    return true
func _result(result: String) -> void:
    var messages := {
        "feeders_missing":"FEEDERS INCOMPLETE . CHECK THE APPROACH",
        "latch_required":"SECURE THE LOCAL BUS IN THE GANTRY",
        "verification_required":"VERIFY THE COMMON RETURN FIRST",
        "latched":"BUS HELD . RETURN STAIRS DEPLOYED",
        "already_latched":"BUS HELD . FOLLOW THE UPPER RETURN",
        "verifying":"COMMON FAULT ISOLATED . WATCH THE LOCAL BRIDGE",
        "verified":"FOUR FEEDS HOLD . INDEPENDENT WALK OPEN",
        "already_verified":"LOCAL PATH VERIFIED . CROSS THE BRIDGE",
        "restored":"WHITE SIGNAL . THE CARRIER HAS AN ANSWER",
        "already_restored":"THE NETWORK HOLDS . FOLLOW THE LIGHTS HOME",
        "save_failed":"SAVE FAILED . TRY THE CONTROL AGAIN"}
    if messages.has(result): world._notify(messages[result])
    if result == "save_failed": Sfx.beep(73,0.09,0.018,"sawtooth")
    if result in ["latched","verified","restored"]:
        world.room = world.Rooms.get_room(world.room_id,world.profile.data.flags)
        world._build_geometry()
func tick(delta: float) -> void:
    var before := test_time
    var result: String = circuit.tick(delta,world.room_id,world.paused or world.map_open)
    if before > 0 and test_time < before and result != "save_failed":
        var previous_step := int(floor((Circuit.SETTLE_SECONDS-before)/0.375))
        var current_step := int(floor((Circuit.SETTLE_SECONDS-test_time)/0.375))
        # Emit only the latest crossed step after a slow frame; never burst a queue.
        if current_step > previous_step and current_step < 4:
            Sfx.beep([110.0,130.81,165.0][current_step-1],0.045,0.012,"square")
    if result == "verified": Sfx.beep(220,0.10,0.018,"square")
    if not result.is_empty(): _result(result)
func draw_world() -> void:
    if world.room_id == "aftermath" and aftermath_art.draw(world): return
    if world.room_id in Layout.IDS:
        draw_source()
        return
    if not world.room_id in ["approach","aftermath"]: return
    var complete: bool = world.profile.has_flag("signal_restored")
    world.draw_rect(Rect2(0,29,480,217),Color(0.13,0.14,0.12,0.35 if complete else 0.17))
    for i in 4:
        var x := 77+i*106
        var lit: bool = world.profile.has_flag(FEEDERS[i])
        world.draw_rect(Rect2(x-16,81,32,56),DrawUtil.GRAY,false,2)
        world.draw_rect(Rect2(x-10,88,20,41),DrawUtil.WHITE if lit else DrawUtil.DARK)
        world.text_at(Vector2(x,149),["FIELD","STAND","DROWNED","ARRAY"][i],DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
        world.draw_line(Vector2(x,164),Vector2(240,194),DrawUtil.GRAY if lit else DrawUtil.DARK,1)
    if world.room_id == "approach":
        world.text_at(Vector2(240,53),"UNLIT FEEDERS SHOW YOUR REMAINING REPAIRS",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
    else:
        world.text_at(Vector2(240,51),"THE WINDOWS ANSWER . THE CUTS STILL PROTECT",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
        world.draw_rect(Rect2(155,172,170,15),DrawUtil.BG)
        world.text_at(Vector2(240,176),"FOLLOW THE LIGHTS HOME",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)

func draw_source() -> void:
    var state := progress()
    world.draw_rect(Rect2(0,29,480,195),Color(0.045,0.05,0.055))
    preload("res://scripts/source_art.gd").draw(world,state,test_time)
    for i in 4:
        var y := 39.0 + i * 5.0
        world.draw_line(Vector2(0,y),Vector2(470,y),DrawUtil.GRAY if ready() else DrawUtil.DARK,1)
    for rect in world.room.platforms:
        if rect.size.y > 8: continue
        world.draw_line(Vector2(rect.position.x+8,rect.end.y),Vector2(rect.position.x+8,224),DrawUtil.DARK,1)
    if world.room_id == "gate":
        world.draw_rect(Rect2(382,56,27,17),DrawUtil.GRAY,false,1)
        world.draw_rect(Rect2(388,60,15,4),DrawUtil.WHITE if state.latched else DrawUtil.DARK)
    elif world.room_id == "source_return":
        world.draw_rect(Rect2(197,129,26,20),DrawUtil.GRAY,false,1)
        world.draw_line(Vector2(210,138),Vector2(350,138),DrawUtil.WHITE if state.tested else DrawUtil.DARK,1)
        if not state.tested and test_time <= 0:
            for x in range(245,350,10): world.draw_line(Vector2(x,156),Vector2(x+4,156),DrawUtil.DARK,1)
    else:
        for i in 4:
            world.draw_rect(Rect2(374+i*13,128,7,14),DrawUtil.WHITE if state.restored else DrawUtil.GRAY)
