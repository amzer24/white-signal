extends RefCounted
## PixelLab sprites for the interaction points that used to be a box with a
## "+" in it, and for room exits. Sprites stand on the floor under the action's
## anchor (the old box bottom = at.y + 9; the old door bottom = at.y + 7).

const ROOT := "res://assets/exploration/props/"
const NAMES := ["lever","breaker","valve","socket","impeller","brake","archive","protocol","beacon","crank","callpost","door_open","door_shut","memory","operator","lever_arm","breaker_on"]

# action id -> sprite. Anything not listed falls back to a lever.
const KIND := {
    "conduit_switch":"lever", "selector":"lever", "catch":"lever", "return_latch":"lever", "float_latch":"lever",
    "siphon_catch":"lever", "approach_latch":"lever", "amplifier_release":"lever", "shaft_release":"lever",
    "shutter_selector":"lever", "storm_divert":"lever", "storm_charge":"lever",
    "ear_transmit":"breaker", "field_transmit":"breaker", "array_test":"breaker", "array_isolate":"breaker",
    "array_bypass":"breaker", "gate_latch":"breaker", "gate_isolate":"breaker", "gate_commit":"breaker",
    "bleed":"valve", "float_valve":"valve", "siphon_valve":"valve", "cycle_valve":"valve", "siphon_wheel":"valve",
    "pump_socket":"socket", "brake_socket":"socket",
    "impeller":"impeller", "brake_spare":"brake",
    "survey":"archive", "fourth_memory":"archive", "siphon_archive":"archive", "cycle_archive":"archive",
    "shelter_memory":"archive", "stand_archive":"archive", "inspection_archive":"archive", "cable_archive":"archive",
    "shutter_archive":"archive",
    "dash":"protocol", "air_jump":"protocol",
    "first_beacon":"beacon",
    "dish_0":"crank", "dish_1":"crank", "dish_2":"crank",
    "carriage_recall":"callpost", "carriage_send":"callpost", "carriage_summon_right":"callpost",
    "shaft_recall":"callpost", "shaft_upper":"callpost", "shaft_ride":"callpost",
}
# pickups vanish once their flag is set; sockets show the fitted part once repaired
const PICKUP_FLAG := {"impeller":"impeller", "brake_spare":"brake_spare", "dash":"dash", "air_jump":"air_jump"}
const SOCKET_PART := {"pump_socket":["pump_repaired","impeller"], "brake_socket":["wire_repaired","brake"]}

# levers whose on/off state is a saved flag; anything else keeps a session toggle
const LEVER_FLAG := {"conduit_switch":"conduit_open", "catch":"catch", "return_latch":"return_open", "float_latch":"float_latch",
    "amplifier_release":"amplifier_released", "shaft_release":"wire_shaft_released", "approach_latch":"approach_return"}
const ARM_PIVOT := Vector2(15, 28)   # pivot hole in lever_arm.png
const ARM_ANGLE := deg_to_rad(38.0)
const BREAKER_FLAG := {"ear_transmit":"east_ear", "field_transmit":"field_restored", "array_test":"diagnostic_seen",
    "array_isolate":"array_isolated", "array_bypass":"array_restored", "gate_commit":"signal_restored"}
var breaker_on: Dictionary = {}
var use_anim: Dictionary = {}     # id -> t of last use (breaker flicker, valve spin, crank turn, callpost lamp)
var door_anim: Dictionary = {}    # "room/target" -> t the door opened
var door_was_open: Dictionary = {}
var lever_on: Dictionary = {}
var lever_anim: Dictionary = {}   # id -> {"start": t, "from": angle}
var lever_shown: Dictionary = {}  # id -> last drawn angle
var tex: Dictionary = {}
var used: Dictionary = {}   # opaque bounds per sprite, for floor anchoring

func _init() -> void:
    for n in NAMES:
        var path: String = ROOT + n + ".png"
        if not ResourceLoader.exists(path): continue
        var t: Texture2D = load(path)
        tex[n] = t
        used[n] = t.get_image().get_used_rect()

func has(n: String) -> bool:
    return tex.has(n)

## Draw sprite `n` so its opaque bottom-centre sits at `foot`.
func blit(canvas: CanvasItem, n: String, foot: Vector2, tint := Color.WHITE, scale := 1.0) -> bool:
    if not tex.has(n): return false
    var r: Rect2 = used[n]
    var pos := Vector2(roundf(foot.x - (r.position.x + r.size.x * 0.5) * scale), roundf(foot.y - (r.position.y + r.size.y) * scale))
    var t: Texture2D = tex[n]
    canvas.draw_texture_rect(t, Rect2(pos, t.get_size() * scale), false, tint)
    return true

## Called when the player uses a lever: swings the arm to the new state, or nudges it if nothing changed.
func flip(id: String, world, t: float) -> void:
    use_anim[id] = t
    var n: String = KIND.get(id, "lever")
    if n == "lever":
        if not LEVER_FLAG.has(id): lever_on[id] = not lever_on.get(id, false)
        lever_anim[id] = {"start": t, "from": lever_shown.get(id, -ARM_ANGLE)}
    elif n == "breaker" and not BREAKER_FLAG.has(id):
        breaker_on[id] = not breaker_on.get(id, false)

## Top-left of sprite `n` when its opaque bottom-centre sits at `foot`.
func origin(n: String, foot: Vector2, scale := 1.0) -> Vector2:
    var r: Rect2 = used[n]
    return Vector2(roundf(foot.x - (r.position.x + r.size.x * 0.5) * scale), roundf(foot.y - (r.position.y + r.size.y) * scale))

func lever_is_on(id: String, world) -> bool:
    if LEVER_FLAG.has(id): return world.profile.has_flag(LEVER_FLAG[id])
    return lever_on.get(id, false)

## Floor lever: coded pedestal in the four greys plus the PixelLab arm rotated about its pivot.
func draw_lever(canvas: CanvasItem, world, id: String, foot: Vector2, t: float, tint: Color) -> void:
    var target := ARM_ANGLE if lever_is_on(id, world) else -ARM_ANGLE
    var angle := target
    if lever_anim.has(id):
        var a: Dictionary = lever_anim[id]
        var k: float = clampf((t - a.start) / 0.28, 0.0, 1.0)
        var eased := 1.0 - pow(1.0 - k, 3)
        angle = lerpf(a.from, target, eased)
        if is_equal_approx(a.from, target): angle += sin(k * PI) * deg_to_rad(9.0) * (1.0 - k)  # would not budge
        if k >= 1.0: lever_anim.erase(id)
    lever_shown[id] = angle
    # pedestal: plate, quadrant and pivot bolt
    var px := foot.x
    canvas.draw_rect(Rect2(px - 11, foot.y - 5, 22, 5), DrawUtil.DARK)
    canvas.draw_rect(Rect2(px - 11, foot.y - 5, 22, 1), DrawUtil.GRAY)
    canvas.draw_rect(Rect2(px - 7, foot.y - 9, 14, 4), DrawUtil.DARK)
    canvas.draw_arc(Vector2(px, foot.y - 9), 6.0, PI, TAU, 10, DrawUtil.GRAY, 1)
    for tick in [-ARM_ANGLE, ARM_ANGLE]:
        var d := Vector2.UP.rotated(tick)
        canvas.draw_line(Vector2(px, foot.y - 9) + d * 5.0, Vector2(px, foot.y - 9) + d * 8.0, DrawUtil.GRAY, 1)
    if tex.has("lever_arm"):
        canvas.draw_set_transform(Vector2(px, foot.y - 9), angle, Vector2.ONE)
        canvas.draw_texture(tex["lever_arm"], -ARM_PIVOT, tint)
        canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    else:
        canvas.draw_line(Vector2(px, foot.y - 9), Vector2(px, foot.y - 9) + Vector2.UP.rotated(angle) * 24.0, tint, 2)
    canvas.draw_circle(Vector2(px, foot.y - 9), 1.5, DrawUtil.WHITE)

func draw_action(canvas: CanvasItem, world, action: Array, t: float) -> bool:
    var id: String = action[0]
    var at: Vector2 = action[1]
    # memory blocks are drawn by the room itself (draw_block); never put a lever on top of one
    if id in ["intro_memory", "memory"]: return true
    var n: String = KIND.get(id, "lever")
    if n == "lever":
        draw_lever(canvas, world, id, at + Vector2(0, 9), t, Color(0.85, 0.85, 0.85))
        return true
    if not tex.has(n): return false
    if PICKUP_FLAG.has(id) and world.profile.has_flag(PICKUP_FLAG[id]): return true
    var foot := at + Vector2(0, 9)
    var tint := Color(0.82, 0.82, 0.82)
    var since: float = t - float(use_anim.get(id, -10.0))
    if PICKUP_FLAG.has(id) and n != "protocol":
        # loose parts hover a touch so they read as something you can take
        foot.y -= 1.0 + sin(t * 3.0) * 1.5
    if n == "breaker" and tex.has("breaker_on"):
        var on: bool = world.profile.has_flag(BREAKER_FLAG[id]) if BREAKER_FLAG.has(id) else breaker_on.get(id, false)
        if since < 0.45 and not AppSettings.reduced_flashes: on = int(since * 14.0) % 2 == 0
        n = "breaker_on" if on else "breaker"
    if n == "crank":
        _draw_crank(canvas, foot, tint, since)
        return true
    if n == "protocol":
        # the protocols are the only things in the world allowed to glow
        var pulse := 0.75 + 0.25 * sin(t * 4.0)
        foot.y -= 2.0 + sin(t * 2.0) * 1.5
        tint = Color(pulse, pulse, pulse)
        canvas.draw_circle(at, 14.0, Color(1, 1, 1, 0.05 + 0.04 * pulse))
    elif n == "beacon" and world.profile.has_flag("first_beacon"):
        tint = Color(1.0, 1.0, 1.0)
    blit(canvas, n, foot, tint, _fit(n, foot))
    if n == "valve" and since < 0.7:
        # spokes spin over the wheel for a moment after a turn
        var c := origin("valve", foot) + Vector2(10, 14)
        var spin := since / 0.7
        var ang := (1.0 - pow(1.0 - spin, 2)) * TAU
        for k in 4:
            var d := Vector2.RIGHT.rotated(ang + k * PI / 2.0)
            canvas.draw_line(c + d * 2.0, c + d * 7.0, DrawUtil.WHITE, 1)
    if n == "callpost" and since < 1.2:
        var c := origin("callpost", foot) + Vector2(19, 4)
        if int(since * 8.0) % 2 == 0 or AppSettings.reduced_flashes: canvas.draw_circle(c, 2.0, DrawUtil.WHITE)
    if SOCKET_PART.has(id) and world.profile.has_flag(SOCKET_PART[id][0]):
        blit(canvas, SOCKET_PART[id][1], at + Vector2(0, 6), Color(0.9, 0.9, 0.9), 0.5)
    return true

## Crank: the wheel stays put, the handle (right half of the sprite) orbits the axle for one turn after use.
func _draw_crank(canvas: CanvasItem, foot: Vector2, tint: Color, since: float) -> void:
    if not tex.has("crank"): return
    var o := origin("crank", foot)
    var tx: Texture2D = tex["crank"]
    canvas.draw_texture_rect_region(tx, Rect2(o, Vector2(16, 32)), Rect2(0, 0, 16, 32), tint)
    var ang := 0.0
    if since < 0.8: ang = (1.0 - pow(1.0 - since / 0.8, 2)) * TAU
    var axle := o + Vector2(15, 16)
    canvas.draw_set_transform(axle, ang, Vector2.ONE)
    canvas.draw_texture_rect_region(tx, Rect2(Vector2(-1, -4), Vector2(18, 8)), Rect2(14, 12, 18, 8), tint)
    canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_exit(canvas: CanvasItem, at: Vector2, open: bool, key := "", t := 0.0) -> bool:
    var n := "door_open" if open else "door_shut"
    if not tex.has(n): return false
    var foot := at + Vector2(0, 7)
    var scale := _fit(n, foot)
    if key != "":
        if open and door_was_open.has(key) and not door_was_open[key]: door_anim[key] = t
        door_was_open[key] = open
    var slide: float = t - float(door_anim.get(key, -10.0)) if key != "" else 10.0
    blit(canvas, n, foot, Color(0.85, 0.85, 0.85) if open else Color(0.45, 0.45, 0.45), scale)
    if open and slide < 0.5 and tex.has("door_shut"):
        # the shut door slides up out of the frame
        var k := 1.0 - pow(1.0 - slide / 0.5, 3)
        var r: Rect2 = used["door_shut"]
        var o := origin("door_shut", foot, scale)
        var lift := r.size.y * scale * k
        var h := r.size.y * scale - lift
        if h > 0.0:
            canvas.draw_texture_rect_region(tex["door_shut"], Rect2(o.x + r.position.x * scale, o.y + r.position.y * scale, r.size.x * scale, h), Rect2(r.position.x, r.position.y + lift / scale, r.size.x, h / scale), Color(0.45, 0.45, 0.45))
    return true

## Shrink a sprite so it never runs up under the 29px HUD bar (doors and levers on top ledges).
func _fit(n: String, foot: Vector2) -> float:
    var r: Rect2 = used[n]
    var room_above := foot.y - 31.0
    return clampf(room_above / r.size.y, 0.5, 1.0)

## Memory block: the sprite is square, the collision is 24x16, so it overhangs 4px top and bottom.
func draw_block(canvas: CanvasItem, rect: Rect2, charged: bool) -> bool:
    if not tex.has("memory"): return false
    var r: Rect2 = used["memory"]
    var t: Texture2D = tex["memory"]
    var size := Vector2(24, 24)
    var pos := rect.get_center() - size * 0.5
    canvas.draw_texture_rect_region(t, Rect2(pos, size), r, Color(0.95, 0.95, 0.95) if charged else Color(0.5, 0.5, 0.5))
    return true
