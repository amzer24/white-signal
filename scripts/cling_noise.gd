extends "res://scripts/enemy.gd"
## Fixed-lane exploration encounter: telegraph, drop, grounded recovery, physical climb back.
var world: Node2D
var encounter_id := ""
var phase := "hang"
var timer := 0.0
var fall_speed := 0.0
var sprite: Texture2D = load("res://assets/exploration/cling-noise.png")
const HOME := 112.0
const FLOOR := 215.0
func _physics_process(delta: float) -> void:
    if dead or not RunState.sim_active(): return
    var player := get_tree().get_first_node_in_group("player")
    match phase:
        "hang":
            if player and absf(player.position.x-position.x)<55 and player.position.y>135:
                phase = "warning"
                timer = 0.65
                Sfx.beep(185.0,0.09,0.018,"sawtooth")
        "warning":
            timer = maxf(0,timer-delta)
            if timer == 0:
                phase = "drop"
                fall_speed = 0
        "drop":
            fall_speed += 720*delta
            position.y = minf(FLOOR,position.y+fall_speed*delta)
            if position.y == FLOOR:
                phase = "landed"
                timer = 1.0
                Sfx.beep(65.0,0.07,0.025)
        "landed":
            timer = maxf(0,timer-delta)
            if timer == 0: phase = "return"
        "return":
            position.y = move_toward(position.y,HOME,90*delta)
            if position.y == HOME: phase = "hang"
    _touch_player()
    queue_redraw()
func _draw() -> void:
    draw_rect(Rect2(-7,-9,14,18),DrawUtil.GRAY,false,1)
    draw_rect(Rect2(-5,-6,10,12),DrawUtil.DARK)
    # Sample the chassis only; generated antenna is replaced by readable grip arms.
    draw_texture_rect_region(sprite,Rect2(-6,-8,12,16),Rect2(8,9,17,16))
    var inset := 2 if phase == "warning" else 0
    draw_rect(Rect2(-4,-3,8,2),DrawUtil.BG)
    draw_rect(Rect2(-4+inset,-3,8-inset*2,2),DrawUtil.WHITE)
    if phase in ["hang","warning"]:
        draw_line(Vector2(-6,-8),Vector2(-10,-16),DrawUtil.GRAY,1)
        draw_line(Vector2(6,-8),Vector2(10,-16),DrawUtil.GRAY,1)
    if phase == "warning":
        for at in range(14,int(FLOOR-position.y),9): draw_line(Vector2(0,at),Vector2(0,at+3),DrawUtil.GRAY,1)
        draw_rect(Rect2(-11,224-position.y-2,22,2),DrawUtil.WHITE)

func kill(burst_n := 10) -> void:
    if dead: return
    if is_instance_valid(world): world.noise_cleared[encounter_id] = true
    super.kill(burst_n)
