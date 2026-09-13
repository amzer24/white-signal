extends "res://scripts/enemy.gd"
## Exploration NOISE: a readable pause before every direction change.
var world: Node2D
var encounter_id := ""
var turn_time := 0.0
var phase_time := 0.0
var sprite: Texture2D = preload("res://assets/exploration/inspection-noise.png")
var sprite_region := Rect2()
func _ready() -> void:
    super._ready()
    sprite_region = Rect2(sprite.get_image().get_used_rect())

func _physics_process(delta: float) -> void:
    if dead or not RunState.sim_active(): return
    phase_time += delta
    if turn_time > 0:
        turn_time = maxf(0,turn_time-delta)
        if turn_time == 0: dir *= -1
    else:
        position.x += dir*speed*delta
        if position.x-7 <= min_x:
            position.x = min_x+7
            turn_time = 0.35
        elif position.x+7 >= max_x:
            position.x = max_x-7
            turn_time = 0.35
    queue_redraw()
    _touch_player()
func _draw() -> void:
    # Stable outline carries the contact boundary; inner bars show the turn cue.
    draw_rect(Rect2(-7,-9,14,18),Color("7d8984"),false,1)
    # Only the original PNG's nontransparent region is sampled; source is unmodified.
    draw_texture_rect_region(sprite,Rect2(-6,-8,12,16),sprite_region)
    var inset := 2 if turn_time > 0 else 0
    draw_rect(Rect2(-4,-4,8,3),DrawUtil.BG)
    draw_rect(Rect2(-4+inset,-4,8-inset*2,2),DrawUtil.WHITE)
    var step := 1 if turn_time <= 0 and not AppSettings.reduced_flashes and int(phase_time*6)%2 == 0 else 0
    draw_rect(Rect2(-5,7+step,3,1),DrawUtil.GRAY)
    draw_rect(Rect2(2,8-step,3,1),DrawUtil.GRAY)

func kill(burst_n := 10) -> void:
    if dead: return
    if is_instance_valid(world): world.noise_cleared[encounter_id] = true
    super.kill(burst_n)
