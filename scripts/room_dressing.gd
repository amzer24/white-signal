extends RefCounted
## Non-collision architecture for exploration rooms: ceilings, pillars and
## ledge struts drawn in the biome material behind the play layer so interior
## rooms read as rooms instead of a floor under a picture. Nothing here is
## solid — routes, journeys and saves are untouched.

const CEIL_Y := 29.0
const PILLAR_W := 12.0

# room -> {"ceiling": thickness, "pillars": [x...], "struts": true/false}
const ROOMS := {
    # Listening Field halls
    "hub": {"ceiling": 12, "pillars": [205, 452], "struts": true},
    "workshop": {"ceiling": 12, "pillars": [160, 300], "struts": true},
    "gallery": {"ceiling": 12, "pillars": [120, 460], "struts": false},
    "amplifier": {"ceiling": 12, "pillars": [270], "struts": true},
    "return": {"ceiling": 12, "pillars": [230, 400], "struts": true},
    "lookout": {"ceiling": 12, "pillars": [60, 285], "struts": true},
    "causeway": {"ceiling": 12, "pillars": [], "struts": true},
    "cellar": {"ceiling": 12, "pillars": [130, 400], "struts": true},
    "sump": {"ceiling": 12, "pillars": [60, 420], "struts": false},
    "fourth": {"ceiling": 12, "pillars": [60, 400], "struts": true},
    # Array interiors
    "array": {"ceiling": 12, "pillars": [60, 224], "struts": true},
    "array_inspection": {"ceiling": 12, "pillars": [60, 330], "struts": true},
    "array_cable": {"ceiling": 12, "pillars": [50, 400], "struts": true},
    "approach": {"ceiling": 12, "pillars": [130, 236, 342], "struts": true},
    # Source core (its bus lines start at y=39, so the ceiling stays thin)
    "gate": {"ceiling": 8, "pillars": [140, 320], "struts": false},
    "source_return": {"ceiling": 8, "pillars": [], "struts": false},
    "source_walk": {"ceiling": 8, "pillars": [60], "struts": false},
}

static func has(room_id: String) -> bool:
    return ROOMS.has(room_id)

## Draw behind platforms. `material` is the world's BiomeMaterial.
static func draw(world: Node2D, room_id: String, material, biome: String) -> void:
    if not ROOMS.has(room_id): return
    var spec: Dictionary = ROOMS[room_id]
    var floor_y := 224.0
    for rect in world.room.platforms:
        if rect.size.x >= 400: floor_y = minf(floor_y, rect.position.y)
    var masses: Array = []
    var thick: float = spec.ceiling
    if thick > 0: masses.append(Rect2(0, CEIL_Y, 480, thick))
    for x in spec.pillars:
        masses.append(Rect2(float(x), CEIL_Y + thick, PILLAR_W, floor_y - CEIL_Y - thick))
    for m in masses:
        world.draw_rect(m, DrawUtil.DARK)
        material.draw(world, m, biome, 0.55, masses)
        # a one-pixel darker seam keeps mass visually behind the platform lips
        world.draw_rect(Rect2(m.position.x, m.end.y - 1, m.size.x, 1), Color(0.05, 0.05, 0.05))
    if spec.struts:
        for rect in world.room.platforms:
            if rect.size.x >= 400 or rect.size.y > 12: continue
            for sx in [rect.position.x + 6.0, rect.end.x - 8.0]:
                if rect.end.y >= floor_y: continue
                world.draw_rect(Rect2(sx, rect.end.y, 2, floor_y - rect.end.y), Color(0.11, 0.11, 0.11))
                world.draw_rect(Rect2(sx - 1, rect.end.y, 4, 2), Color(0.16, 0.16, 0.16))
