extends RefCounted
## Per-biome platform materials from PixelLab sidescroller Wang tilesets.
## Every tileset PNG uses the same tileset15 4x4 layout; the index is
## NW*8 + NE*4 + SW*2 + SE*1 with "upper" (= AIR) corners set, so a fully
## solid tile is wang_0 and the empty tile is wang_15. Tiles are placed on a
## grid offset by half a tile so corners land on the collision rect edge, then
## clipped to the rect — collision and picture never disagree.

const TILE := 16
const HALF := 8
# wang index -> sheet position (constant across all generated tilesets)
const SHEET := [Vector2(32,16),Vector2(48,16),Vector2(32,32),Vector2(16,32),Vector2(32,0),Vector2(48,32),Vector2(0,16),Vector2(48,48),
    Vector2(16,16),Vector2(32,48),Vector2(16,0),Vector2(0,32),Vector2(48,0),Vector2(0,0),Vector2(16,48),Vector2(0,48)]
const ROOT := "res://assets/exploration/biomes/"
const BIOMES := {
    "flats": ["flats","conduit","arrival"],
    "field": ["hub","workshop","gallery","amplifier","return","lookout","causeway","cellar","sump","fourth"],
    "drowned": ["basin","pump","float","siphon","drowned_street","drowned_gallery","drowned_dock","drowned_cycle"],
    "stand": ["shelter","conductor","stand_rim","stand_charge","stand_trial","stand_sluice","stand_bridge"],
    "wire": ["wire_shelter","wire_carriage","wire_shaft"],
    "array": ["array","array_inspection","array_cable","array_shutter","approach"],
    "source": ["gate","source_return","source_walk","aftermath"],
}
# Tint per biome keeps the four-grey identity: nothing brighter than GRAY in the play layer.
const TINT := {
    "flats": Color(0.72,0.70,0.66), "field": Color(0.78,0.78,0.78), "drowned": Color(0.65,0.72,0.68),
    "stand": Color(0.66,0.68,0.74), "wire": Color(0.74,0.74,0.74), "array": Color(0.70,0.72,0.72), "source": Color(0.62,0.62,0.60),
}
var textures: Dictionary = {}

func _init() -> void:
    for biome in BIOMES:
        var path: String = ROOT + str(biome) + "-tiles.png"
        if biome == "drowned": path = "res://assets/exploration/wet-concrete.png"
        if ResourceLoader.exists(path): textures[biome] = load(path)

static func biome_of(room_id: String) -> String:
    for biome in BIOMES:
        if room_id in BIOMES[biome]: return biome
    return "field"

func has(biome: String) -> bool:
    return textures.has(biome)

## Draw `rect` filled with the biome's material. `mass` rects (same biome) are
## treated as connected so ledges attached to walls don't grow a seam.
func draw(canvas: CanvasItem, rect: Rect2, biome: String, tint_scale := 1.0, neighbours: Array = []) -> void:
    var tex: Texture2D = textures.get(biome)
    if tex == null: return
    # anything past the room edge counts as solid so floors don't grow rounded ends at x=0 / x=480
    neighbours = neighbours.duplicate()
    neighbours.append_array([Rect2(-64,-64,64,400),Rect2(480,-64,64,400),Rect2(-64,270,608,64)])
    var tint: Color = TINT.get(biome, Color(0.75,0.75,0.75)) * tint_scale
    tint.a = 1.0
    var x0 := int(rect.position.x)
    var y0 := int(rect.position.y)
    var x1 := int(rect.end.x)
    var y1 := int(rect.end.y)
    var cols := ceili(rect.size.x / TILE) + 1
    var rows := ceili(rect.size.y / TILE) + 1
    for j in rows:
        for i in cols:
            var tx := x0 + i * TILE - HALF
            var ty := y0 + j * TILE - HALF
            # corner samples: the centre of each neighbouring cell
            var nw := _solid(Vector2(tx + 4, ty + 4), rect, neighbours)
            var ne := _solid(Vector2(tx + 12, ty + 4), rect, neighbours)
            var sw := _solid(Vector2(tx + 4, ty + 12), rect, neighbours)
            var se := _solid(Vector2(tx + 12, ty + 12), rect, neighbours)
            var idx := (8 if nw else 0) + (4 if ne else 0) + (2 if sw else 0) + (1 if se else 0)
            if idx == 0: continue
            # clip the tile to the rect
            var cx0 := maxi(tx, x0)
            var cy0 := maxi(ty, y0)
            var cx1 := mini(tx + TILE, x1)
            var cy1 := mini(ty + TILE, y1)
            if cx1 <= cx0 or cy1 <= cy0: continue
            var src: Vector2 = SHEET[15 - idx] + Vector2(cx0 - tx, cy0 - ty)
            canvas.draw_texture_rect_region(tex, Rect2(cx0, cy0, cx1 - cx0, cy1 - cy0), Rect2(src, Vector2(cx1 - cx0, cy1 - cy0)), tint)

static func _solid(p: Vector2, rect: Rect2, neighbours: Array) -> bool:
    if rect.has_point(p): return true
    for other in neighbours:
        if other.has_point(p): return true
    return false
