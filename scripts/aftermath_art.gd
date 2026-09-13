extends RefCounted
const ORIGIN = Vector2(48,96)
# Recess interiors measured from the unchanged PixelLab image.
const WINDOWS = [Rect2(67,69,26,22),Rect2(127,78,26,21),Rect2(215,70,37,17),Rect2(276,27,27,15)]
var texture: Texture2D
func _init() -> void:
    if ResourceLoader.exists("res://assets/exploration/answering-town.png"):
        texture = load("res://assets/exploration/answering-town.png")
func draw(world: Node2D) -> bool:
    if texture == null: return false
    var restored: bool = world.profile.has_flag("signal_restored")
    world.draw_rect(Rect2(0,29,480,195),Color("0c1011"))
    world.draw_texture(texture,ORIGIN,Color(0.62,0.65,0.63))
    if restored:
        for window in WINDOWS:
            var rect := Rect2(ORIGIN+window.position,window.size)
            world.coherence_light.draw(world,rect.get_center(),0.65,Color(0.75,0.72,0.52,0.13))
            world.draw_rect(rect,Color("777765"))
            world.draw_line(rect.position+Vector2(rect.size.x*0.5,0),rect.position+Vector2(rect.size.x*0.5,rect.size.y),Color("292d2b"),2)
            world.draw_line(rect.position+Vector2(0,rect.size.y*0.55),rect.position+Vector2(rect.size.x,rect.size.y*0.55),Color("292d2b"),2)
    world.text_at(Vector2(240,51),"THE WINDOWS ANSWER . THE CUTS STILL PROTECT" if restored else "WAITING FOR THE CARRIER",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
    world.text_at(Vector2(240,73),"FOLLOW THE LIGHTS HOME" if restored else "LOCAL FEEDS UNLIT",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
    return true
