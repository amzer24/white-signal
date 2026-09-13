extends RefCounted
const IDS = preload("res://scripts/stand_district_rooms.gd").IDS
var previous_room := ""
var crumble: Array = []
var world: Node2D
var phase := "idle"
var charge := 0.0
var timer := 0.0
var weather_time := 0.0
var rim_texture: Texture2D
var reservoir_texture: Texture2D
var bridge: StaticBody2D

func _init(owner_world: Node2D) -> void:
    world = owner_world
    var path := "res://assets/exploration/storm-reservoir.png"
    if ResourceLoader.exists(path): reservoir_texture = load(path)
    var rim_path := "res://assets/exploration/broken-rim.png"
    if ResourceLoader.exists(rim_path): rim_texture = load(rim_path)
func enter() -> void:
    if not previous_room in IDS or not world.room_id in IDS: reset()
    if phase in ["warning","discharge"] and world.room_id != "conductor":
        phase = "ready"
        timer = 0
    previous_room = world.room_id
func reset() -> void:
    phase = "latched" if world.profile.has_flag("stand_restored") else "idle"
    charge = 0
    timer = 0
    for tile in crumble:
        tile.timer = -1.0
        tile.gone = false
        if is_instance_valid(tile.body): tile.body.get_child(0).set_deferred("disabled",false)
func build() -> void:
    bridge = null
    crumble.clear()
    if world.room_id == "stand_bridge" and world.profile.has_flag("stand_restored"):
        bridge = world._solid(Rect2(150,224,180,8))
    if world.room_id == "stand_trial":
        if world.profile.has_flag("stand_archive"):
            bridge = world._solid(Rect2(95,224,295,8))
        else:
            for rect in [Rect2(121,192,58,8),Rect2(224,162,58,8),Rect2(324,192,48,8)]:
                var body = world._solid(rect)
                body.get_child(0).one_way_collision = true
                crumble.append({"rect":rect,"body":body,"timer":-1.0,"gone":false})
func use(id: String) -> bool:
    if id == "shelter_memory" and world.room_id == "shelter":
        if world._commit("shelter_memory"):
            world.memory_time = 7
            world._notify("THEY CUT THE COMMON RETURN . THE SHELTER STAYED LIT")
        return true
    if id == "stand_archive" and world.room_id == "stand_trial":
        if world._commit("stand_archive"):
            world._build_geometry()
            world._notify("DISH RIBS BECAME SHELTERS . ARCHIVE RETURN OPEN")
        return true
    if not ((world.room_id == "stand_charge" and id == "storm_charge") or (world.room_id == "conductor" and id == "storm_divert")): return false
    if world.profile.has_flag("stand_restored"):
        world._notify("STAND FEEDER HOLDS . BRIDGE LATCHED")
        return true
    if phase in ["warning","discharge"]:
        world._notify("MOTOR CYCLING . STAY IN THE MARKED SHELTER")
    elif id == "storm_charge":
        phase = "charging"
        world._notify("RESERVOIR SELECTED . STORED CHARGE WILL HOLD")
    elif charge < 1:
        world._notify("RESERVOIR EMPTY . SELECT CHARGE FIRST")
    else:
        phase = "warning"
        timer = 1.5
        world._notify("DISCHARGE IN MARKED CHANNEL . SHELTER IS SAFE")
    return true
func tick(delta: float) -> void:
    if not world.room_id in IDS: return
    var old_storm := floori((weather_time-0.65)/9.0)
    weather_time += delta
    if floori((weather_time-0.65)/9.0) > old_storm: Sfx.thunder()
    for tile in crumble:
        if tile.gone: continue
        var rect: Rect2 = tile.rect
        if tile.timer < 0 and world.player.is_on_floor() and absf(world.player.position.y+7-rect.position.y) < 3 and world.player.position.x > rect.position.x-5 and world.player.position.x < rect.end.x+5: tile.timer = 0.9
        if tile.timer >= 0:
            tile.timer -= delta
            if tile.timer <= 0:
                tile.gone = true
                tile.body.get_child(0).set_deferred("disabled",true)
    if phase == "charging":
        charge = minf(1,charge+delta/3)
        if charge == 1:
            phase = "ready"
            world._notify("CHARGE HELD . DIVERT WHEN READY")
            Sfx.beep(110,0.12,0.035,"sawtooth")
    elif phase == "warning":
        timer -= delta
        if timer <= 0:
            phase = "discharge"
            timer = 0.35
            Sfx.beep(55,0.22,0.04,"sawtooth")
    elif phase == "discharge":
        timer -= delta
        if world.room_id == "conductor" and absf(world.player.position.x-299) < 11:
            world.respawn()
            world._notify("CONDUCTOR CHANNEL . CHARGE RESET . SHELTER SAFE")
            return
        if timer <= 0:
            if world._commit("stand_restored"):
                phase = "latched"
                world._build_geometry()
                world._notify("STAND FEEDER RESTORED . BRIDGE HOLDS")
            else:
                phase = "ready" # preserve charge so a failed save can be retried
func draw_world() -> void:
    if not world.room_id in IDS: return
    var reduced: bool = AppSettings.reduced_flashes
    var glow := 0.035 if reduced else maxf(0,0.08-absf(fmod(weather_time,9)-1)*0.11)
    world.draw_rect(Rect2(0,29,480,217),Color(0.10,0.12,0.17,0.35+glow))
    for i in 6:
        var x := 31+i*85
        world.draw_line(Vector2(x,70+i%2*24),Vector2(x-28,244),Color(0.15,0.17,0.20),3)
        world.draw_line(Vector2(x-16,104),Vector2(x+29,104),Color(0.20,0.22,0.25),2)
    # Remote lightning never shares the marked conductor lane or machine clock.
    if not reduced and fmod(weather_time,9) < 0.45:
        world.draw_polyline(PackedVector2Array([Vector2(389,31),Vector2(366,64),Vector2(384,62),Vector2(361,98)]),DrawUtil.GRAY,1)
    if world.room_id == "stand_rim":
        if rim_texture != null: world.draw_texture(rim_texture,Vector2(208,56),Color(0.8,0.8,0.8,1))
        else: world.draw_arc(Vector2(288,133),90,-2.8,0.6,28,DrawUtil.DARK,4)
    if world.room_id == "stand_sluice":
        world.draw_polyline(PackedVector2Array([Vector2(30,83),Vector2(110,83),Vector2(110,128),Vector2(222,128),Vector2(222,162),Vector2(348,162),Vector2(348,209),Vector2(475,209)]),Color("61767d"),5)
    if world.room_id == "shelter":
        world.draw_rect(Rect2(24,90,58,128),Color("080e12"))
        world.draw_rect(Rect2(34,105,14,22),Color("a4bac0"))
    if world.room_id == "shelter":
        world.text_at(Vector2(284,80),"COMMON RETURN: CUT",DrawUtil.GRAY)
        if world.memory_time > 0:
            for x in [321,345]:
                world.draw_rect(Rect2(x,190,6,7),DrawUtil.GRAY)
                world.draw_rect(Rect2(x-2,198,10,23),DrawUtil.GRAY)
            world.draw_line(Vector2(319,187),Vector2(354,187),DrawUtil.WHITE,2)
        return
    for tile in crumble:
        if not tile.gone:
            world._draw_platform(tile.rect)
            world.draw_line(tile.rect.position+Vector2(17,0),tile.rect.position+Vector2(24,8),DrawUtil.BG,2)
            if tile.timer >= 0: world.draw_line(tile.rect.position,tile.rect.position+Vector2(tile.rect.size.x*maxf(0,tile.timer)/0.9,0),DrawUtil.WHITE,2)
    if world.room_id in ["stand_trial","stand_bridge"] and is_instance_valid(bridge):
        world._draw_platform(Rect2(95,224,295,8) if world.room_id == "stand_trial" else Rect2(150,224,180,8))
    if world.room_id not in ["stand_charge","conductor"]: return
    var gauge_x := 225.0 if world.room_id == "stand_charge" else 350.0
    if reservoir_texture != null:
        var origin := Vector2(gauge_x-9,64)
        world.draw_texture(reservoir_texture,origin)
        var fill_height := floorf(clampf(charge,0,1)*21)
        if fill_height > 0:
            world.draw_rect(Rect2(origin+Vector2(14,37-fill_height),Vector2(19,fill_height)),DrawUtil.WHITE)
    else:
        world.draw_rect(Rect2(gauge_x,72,30,46),DrawUtil.GRAY,false,2)
        world.draw_rect(Rect2(gauge_x+4,114-charge*38,22,charge*38),DrawUtil.WHITE)
    world.text_at(Vector2(gauge_x+15,57),"HELD" if charge == 1 else "CHARGE",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
    world.draw_line(Vector2(gauge_x+15,118),Vector2(gauge_x+15,138),DrawUtil.GRAY,1)
    if world.room_id == "stand_charge": return
    world.draw_line(Vector2(365,118),Vector2(420,118),DrawUtil.GRAY,1)
    world.draw_line(Vector2(299,40),Vector2(299,205),DrawUtil.DARK,2)
    for y in range(51,212,13):
        world.draw_line(Vector2(288,y),Vector2(310,y+8),DrawUtil.GRAY,1)
    world.text_at(Vector2(240,32),"CHANNEL",DrawUtil.GRAY)
    if phase == "warning":
        world.draw_rect(Rect2(286,43,26,167),DrawUtil.WHITE,false,1)
        world.text_at(Vector2(300,83),"STAND CLEAR",DrawUtil.WHITE)
    elif phase == "discharge":
        world.draw_line(Vector2(299,43),Vector2(299,218),DrawUtil.GRAY if reduced else DrawUtil.WHITE,3)
        world.text_at(Vector2(300,83),"DISCHARGING",DrawUtil.WHITE)
    if world.room_id == "stand_bridge" and world.profile.has_flag("stand_restored"):
        world._draw_platform(Rect2(150,224,180,8))
        world.text_at(Vector2(306,176),"BRIDGE HELD",DrawUtil.WHITE)
