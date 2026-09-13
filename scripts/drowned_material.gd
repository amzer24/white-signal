extends RefCounted

# PixelLab wang_0: all four corners are solid concrete (metadata bounding box).
const TILE_ORIGIN = Vector2(32,16)
var texture: Texture2D

func _init() -> void:
    if ResourceLoader.exists("res://assets/exploration/wet-concrete.png"):
        texture = load("res://assets/exploration/wet-concrete.png")

func draw(canvas: CanvasItem, rect: Rect2) -> void:
    if texture == null: return
    for y in range(0,ceili(rect.size.y),16):
        for x in range(0,ceili(rect.size.x),16):
            var size := Vector2(minf(16,rect.size.x-x),minf(16,rect.size.y-y))
            canvas.draw_texture_rect_region(texture,Rect2(rect.position+Vector2(x,y),size),Rect2(TILE_ORIGIN,size),Color(0.65,0.72,0.68))
