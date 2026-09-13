extends RefCounted
var texture: Texture2D
func _init() -> void:
    var path := "res://assets/exploration/drowned-skyline.png"
    if ResourceLoader.exists(path): texture = load(path)
func draw(world) -> bool:
    if texture == null: return false
    var width := texture.get_width()
    var phase := posmod(roundi(world.player.position.x*0.08),width)
    for tile in range(-1,3):
        world.draw_texture(texture,Vector2(tile*width-phase,54),Color(0.28,0.33,0.30))
    return true
