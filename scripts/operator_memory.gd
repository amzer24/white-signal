extends RefCounted
## Visual archive only: no actor nodes, collisions, input, saves or lift commands.
var time := -1.0
const DURATION := 9.0
func play() -> void: time = 0
func stop() -> void: time = -1
func tick(delta: float) -> void:
    if time < 0: return
    time += delta
    if time >= DURATION: stop()
func rider() -> Vector2:
    if time < 1.5: return Vector2(lerpf(40,125,clampf(time/1.5,0,1)),224)
    if time < 5: return Vector2(125,lerpf(224,66,(time-1.5)/3.5))
    if time < 7: return Vector2(lerpf(125,368,(time-5)/2),66)
    return Vector2(lerpf(368,472,clampf((time-7)/1.4,0,1)),66)
func draw(world: Node2D) -> void:
    if time < 0: return
    var opacity := minf(clampf(time/0.3,0,1),clampf((DURATION-time)/0.7,0,1))
    var color := Color(0.59,0.63,0.63,opacity*0.8)
    var passenger := rider().round()
    var keeper := Vector2(lerpf(365,393,clampf(time,0,1)),66)
    if time > 7: keeper.x = lerpf(393,472,clampf((time-7)/1.1,0,1))
    if time >= 1.5 and time < 5:
        for x in range(86,165,9): world.draw_line(Vector2(x,passenger.y),Vector2(x+4,passenger.y),color,1)
    figure(world,passenger,color,time < 1.5 or time > 5,false)
    figure(world,keeper.round(),color,time < 1 or time > 7,time >= 1 and time < 1.5)
    world.text_at(Vector2(292,130),"MEMORY . LAST SHIFT",color)
func figure(world: Node2D,feet: Vector2,color: Color,walking: bool,reaching: bool) -> void:
    world.draw_rect(Rect2(feet+Vector2(-3,-20),Vector2(6,5)),color,false,1)
    world.draw_rect(Rect2(feet+Vector2(-4,-13),Vector2(8,8)),color,false,1)
    var stride := 2 if walking and not AppSettings.reduced_flashes and int(time*6)%2 == 0 else 0
    world.draw_line(feet+Vector2(-2,-5),feet+Vector2(-2-stride,0),color,1)
    world.draw_line(feet+Vector2(2,-5),feet+Vector2(2+stride,0),color,1)
    world.draw_line(feet+Vector2(4,-12),feet+Vector2(10,-15 if reaching else -7),color,1)
