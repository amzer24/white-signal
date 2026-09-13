extends RefCounted
## Optional climbing archive; saved release, temporary recallable lift position.
var world: Node2D
var lift: AnimatableBody2D
var motor: AudioStreamPlayer
var memory = preload("res://scripts/operator_memory.gd").new()
var y := 224.0
var target := 224.0
var release_amount := 0.0
var housing: Texture2D = load("res://assets/exploration/wire-winch.png")
const BRIDGE := Rect2(167,66,109,8)
func _init(owner_world: Node2D) -> void: world = owner_world
func reset() -> void:
    memory.stop()
    if is_instance_valid(motor):
        motor.stop()
        motor.moving = false
        motor.volume_db = -60
    y = 224
    target = 224
    release_amount = 1.0 if world.profile.has_flag("wire_shaft_released") else 0.0
    if is_instance_valid(lift): lift.position.y = y+4
func build() -> void:
    if is_instance_valid(motor):
        motor.stop()
        motor.queue_free()
    motor = null
    lift = null
    if world.room_id != "wire_shaft": return
    if world.profile.has_flag("wire_shaft_released") and not BRIDGE in world.room.platforms:
        world.room.platforms.append(BRIDGE)
        var body = world._solid(BRIDGE)
        body.get_child(0).one_way_collision = true
    motor = preload("res://scripts/mechanism_motor.gd").new()
    world.add_child(motor)
    lift = AnimatableBody2D.new()
    lift.sync_to_physics = false
    lift.position = Vector2(125,y+4)
    var collider := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(84,8)
    collider.shape = shape
    collider.one_way_collision = true
    lift.add_child(collider)
    world.solids.add_child(lift)
func use(id: String) -> bool:
    if world.room_id != "wire_shaft" or not id in ["shaft_release","shaft_recall","shaft_upper","shaft_ride"]: return false
    if id == "shaft_release":
        if not world.profile.has_flag("wire_shaft_released"):
            if not world.profile.set_flags({"wire_shaft_released":true,"wire_shaft_archive":true}):
                world._notify("SAVE FAILED . RELEASE NOT RECORDED . TRY AGAIN")
                return true
            world._build_geometry()
        memory.play()
        world._notify("OPERATOR LOG . KEEP A RETURN FOR THE NEXT SHIFT")
    elif not world.profile.has_flag("wire_shaft_released"):
        world._notify("BRAKE HELD . CLIMB TO THE UPPER RELEASE")
    elif id == "shaft_recall": target = 224
    elif id == "shaft_upper": target = 66
    else: target = 224 if y < 140 else 66
    return true
func tick(delta: float) -> void:
    if world.room_id != "wire_shaft": return
    memory.tick(delta)
    release_amount = move_toward(release_amount,1.0 if world.profile.has_flag("wire_shaft_released") else 0.0,delta*3)
    y = move_toward(y,target,45*delta)
    if is_instance_valid(lift): lift.position.y = y+4
    for action in world.room.actions:
        if action[0] == "shaft_ride": action[1] = Vector2(125,y-7)
func draw_world() -> void:
    if world.room_id != "wire_shaft": return
    draw_interior()
    world.draw_line(Vector2(125,46),Vector2(125,224),DrawUtil.GRAY,1)
    for mark in range(74,224,12):
        var at := 64+posmod(mark+int(224-y),160)
        if at < y: world.draw_line(Vector2(124,at),Vector2(127,at),DrawUtil.GRAY,1)
    if housing: world.draw_texture(housing,Vector2(93,30),Color(0.8,0.8,0.8))
    var centre := Vector2(125,46)
    world.draw_circle(centre,6,DrawUtil.DARK)
    for i in 3:
        var angle := (224-y)*0.04+i*TAU/3
        world.draw_line(centre,(centre+Vector2(cos(angle),sin(angle))*5).round(),DrawUtil.GRAY,1)
    var spread := roundf(release_amount*3)
    world.draw_rect(Rect2(115-spread,43,3,7),DrawUtil.GRAY)
    world.draw_rect(Rect2(132+spread,43,3,7),DrawUtil.GRAY)
    world._draw_platform(Rect2(83,y,84,8))
    for at in range(107,187,12):
        world.draw_line(Vector2(201,at),Vector2(205,at-4),DrawUtil.GRAY,1)
        world.draw_line(Vector2(255,at),Vector2(259,at-4),DrawUtil.GRAY,1)
    world.text_at(Vector2(292,99),"RETURN RELEASED" if world.profile.has_flag("wire_shaft_released") else "UPPER RELEASE",DrawUtil.GRAY)
    world.text_at(Vector2(292,112),"NEXT SHIFT REMEMBERED" if world.profile.has_flag("wire_shaft_archive") else "OPERATOR ARCHIVE",DrawUtil.GRAY)

func draw_controls() -> void:
    if world.room_id != "wire_shaft": return
    memory.draw(world)
    for action in world.room.actions:
        var at: Vector2 = action[1].round()
        if action[0] == "shaft_release":
            world.draw_rect(Rect2(at+Vector2(-8,1),Vector2(16,6)),DrawUtil.GRAY)
            var tip := at+Vector2(lerpf(-8,8,release_amount),-12)
            world.draw_line(at,tip.round(),DrawUtil.WHITE,2)
            world.draw_rect(Rect2(tip.round()-Vector2(2,2),Vector2(5,4)),DrawUtil.WHITE)
        else:
            world.draw_rect(Rect2(at-Vector2(6,9),Vector2(12,16)),DrawUtil.GRAY,false,1)
            var up: bool = action[0] == "shaft_upper" or (action[0] == "shaft_ride" and y >= 140)
            var direction := -1 if up else 1
            world.draw_line(at-Vector2(0,5),at+Vector2(0,3),DrawUtil.WHITE,1)
            var head := at+Vector2(0,-5 if up else 3)
            world.draw_line(head,head+Vector2(-3,-direction*3),DrawUtil.WHITE,1)
            world.draw_line(head,head+Vector2(3,-direction*3),DrawUtil.WHITE,1)

func draw_interior() -> void:
    # Enclosed depth layer, behind all collidable silhouettes and controls.
    world.draw_rect(Rect2(0,29,480,195),Color("101214"))
    for panel in [Rect2(12,40,65,172),Rect2(176,40,96,172),Rect2(284,80,182,132)]:
        world.draw_rect(panel,Color("181b1e"))
        world.draw_rect(panel,Color("262a2d"),false,1)
        for point in [panel.position+Vector2(4,4),Vector2(panel.end.x-5,panel.position.y+4),panel.end-Vector2(5,5)]:
            world.draw_rect(Rect2(point,Vector2(2,2)),Color("34383a"))
    # A recessed service chase separates the moving cable from the masonry.
    world.draw_rect(Rect2(83,29,84,195),Color("0b0d0f"))
    for x in [88,161]:
        world.draw_line(Vector2(x,30),Vector2(x,223),Color("24292c"),2)
        for at in range(74,220,30): world.draw_line(Vector2(x-3,at),Vector2(x+3,at),Color("303538"),1)
    world.draw_polyline(PackedVector2Array([Vector2(140,48),Vector2(153,48),Vector2(153,34),Vector2(451,34),Vector2(451,50)]),Color("383a38") if release_amount > 0.5 else Color("25292b"),1)
    # Fixed equipment shadows and disconnected terminal slots occupy the far wall.
    for x in [303,340,377,414]:
        world.draw_rect(Rect2(x,151,24,46),Color("0c0e10"))
        world.draw_rect(Rect2(x+2,153,20,4),Color("34383a"))
        for at in [165,174,183]: world.draw_line(Vector2(x+4,at),Vector2(x+19,at),Color("252a2d"),1)
    world.coherence_light.draw(world,Vector2(45,195),0.65,Color(0.45,0.54,0.60,0.16))
    for x in [309,379,449]:
        world.coherence_light.draw(world,Vector2(x,69),release_amount,Color(0.72,0.68,0.55,0.30))
        world.draw_rect(Rect2(x-6,37,12,3),DrawUtil.GRAY)
        world.draw_rect(Rect2(x-4,40,8,2),Color("c2bba4") if release_amount > 0.5 else DrawUtil.DARK)
