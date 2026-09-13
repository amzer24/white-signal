extends RefCounted
## Feeder fixtures are scenery. The shelter's independent window is drawn separately.
const FIXTURES := {
    "stand_rim": [Vector2(54,162),Vector2(424,162)],
    "shelter": [Vector2(418,164)],
    "stand_charge": [Vector2(40,176),Vector2(444,176)],
    "conductor": [Vector2(42,180),Vector2(444,180)],
    "stand_bridge": [Vector2(100,170),Vector2(380,170)],
    "stand_sluice": [Vector2(45,174),Vector2(428,174)],
    "stand_trial": [Vector2(42,175),Vector2(430,175)],
}

static func draw(world) -> void:
    if not FIXTURES.has(world.room_id): return
    var powered: bool = world.profile.has_flag("stand_restored")
    var wire := Color("3d4241") if powered else Color("242b30")
    for at in FIXTURES[world.room_id]:
        # Recessed cable stays behind platforms; it never resembles a landing edge.
        world.draw_line(Vector2(at.x,39),at+Vector2(0,-16),wire,1)
        world.draw_rect(Rect2(at+Vector2(-8,-17),Vector2(16,31)),Color("101419"))
        world.draw_rect(Rect2(at+Vector2(-7,-16),Vector2(14,29)),Color("353b3e"),false,1)
        if powered:
            world.coherence_light.draw(world,at,0.7,Color(0.72,0.65,0.45,0.25))
        for offset in [-9,-1,7]:
            world.draw_rect(Rect2(at+Vector2(-4,offset),Vector2(8,3)),Color("b8ac85") if powered else Color("292f32"))
        world.draw_rect(Rect2(at+Vector2(-2,-15),Vector2(4,2)),Color("636866"))
