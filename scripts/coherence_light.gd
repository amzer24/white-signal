extends RefCounted
## Cached decorative light field, drawn behind gameplay silhouettes.
var texture: ImageTexture
func _init() -> void:
    var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in 64:
        for x in 64:
            var distance := Vector2(x+0.5-32,y+0.5-32).length()/32.0
            var falloff := maxf(0.0,1.0-distance)
            # Sixteen stable steps; nearest sampling produces a two-pixel grid.
            var alpha := floorf(falloff*falloff*16.0)/16.0
            image.set_pixel(x,y,Color(1,1,1,alpha))
    texture = ImageTexture.create_from_image(image)
func draw(canvas: Node2D, center: Vector2, power: float, tint: Color) -> void:
    if power <= 0: return
    var color := tint
    color.a *= clampf(power,0,1)
    canvas.draw_texture_rect(texture,Rect2(center.round()-Vector2(64,64),Vector2(128,128)),false,color)
