extends CharacterBody2D
## WHITE SIGNAL player — full port. Reads tuned mods from RunState (deck-driven).
## move_and_slide() replaces the JS X-then-Y AABB; feel aids reimplemented:
## coyote, buffer, short-hop cut, wall slide/grace + wallTopY gate, overspeed
## decay, corner correction (ceiling graze <= 4px slides past), air jumps, dash.

const HALF_W := 6.0
const HALF_H := 7.0
const DASH_SPEED := 340.0
const DASH_TIME := 0.13
const OVERSPEED_DECAY := 350.0
const CORNER_SLIDE := 4.0

var conduit_cooldown := 0.0
var coyote_t := 0.0
var buffer_t := 0.0
var wall_grace_t := 0.0
var wall_dir := 0
var wall_top_y := 0.0
var jump_held := false
var spring_t := 0.0
var dash_ready := true
var dash_t := 0.0
var dash_dir := 1
var invuln := 0.0
var air_jumps := 0
var shield := 0
var prev_vy := 0.0
var spawn_point := Vector2(36, 187)
# visual state (read by entity_render.gd)
var sx_anim := 1.0
var sy_anim := 1.0
var face := 1
var sliding_anim := false
var anim_t := 0.0
var visual_time := 0.0

func m(key: String) -> Variant:
    return RunState.mods[key]

func _ready() -> void:
    add_to_group("player")

func reset_at(pos: Vector2) -> void:
    global_position = pos
    velocity = Vector2.ZERO
    invuln = 0.5
    wall_grace_t = 0.0
    coyote_t = 0.0
    buffer_t = 0.0
    spring_t = 0.0
    dash_t = 0.0
    air_jumps = int(m("air_jumps"))
    dash_ready = bool(m("dash"))
    shield = int(m("shield_max"))

func _physics_process(delta: float) -> void:
    # JS: update() only runs while state == "play" (pause/draft/menu freeze the spark)
    if not RunState.sim_active():
        return
    visual_time += delta
    conduit_cooldown = maxf(0.0, conduit_cooldown - delta)
    var M := RunState.mods
    invuln = maxf(0.0, invuln - delta)
    spring_t = maxf(0.0, spring_t - delta)
    buffer_t = maxf(0.0, buffer_t - delta)
    coyote_t = maxf(0.0, coyote_t - delta)
    wall_grace_t = maxf(0.0, wall_grace_t - delta)

    var dir := Input.get_axis("move_left", "move_right")
    var jd := Input.is_action_pressed("jump")
    if jd and not jump_held:
        buffer_t = float(M.buffer)
    jump_held = jd

    var max_run := float(M.max_run)
    var accel := float(M.accel) if is_on_floor() else float(M.air_accel)

    if dash_t > 0.0:
        dash_t -= delta
        velocity.x = dash_dir * DASH_SPEED
        velocity.y = 0.0
        if dash_t <= 0.0:
            velocity.x = dash_dir * 170.0
    else:
        # horizontal — overspeed decays gently (kick bursts felt)
        if dir > 0.0:
            if velocity.x > max_run:
                velocity.x = maxf(max_run, velocity.x - OVERSPEED_DECAY * delta)
            else:
                velocity.x = minf(max_run, velocity.x + accel * delta)
        elif dir < 0.0:
            if velocity.x < -max_run:
                velocity.x = minf(-max_run, velocity.x + OVERSPEED_DECAY * delta)
            else:
                velocity.x = maxf(-max_run, velocity.x - accel * delta)
        elif is_on_floor():
            var f := float(M.friction) * delta
            velocity.x = 0.0 if absf(velocity.x) <= f else velocity.x - signf(velocity.x) * f
        else:
            velocity.x *= (1.0 - 0.4 * delta)

    if is_on_floor():
        coyote_t = float(M.coyote)
    # spring_t guard: is_on_floor() lags one frame after a spring launch, so a
    # buffered jump would otherwise replace the launch velocity with jump_vel
    if buffer_t > 0.0 and coyote_t > 0.0 and not (spring_t > 0.0 and velocity.y < 0.0):
        velocity.y = -float(M.jump_vel)
        buffer_t = 0.0
        coyote_t = 0.0
        sx_anim = 0.72
        sy_anim = 1.32
        Sfx.beep(440.0 + randf() * 60.0)
        var fx := get_tree().get_first_node_in_group("fx")
        if fx:
            fx.dust(global_position + Vector2(0, 7), 4)
    if not jump_held and spring_t <= 0.0 and dash_t <= 0.0 \
            and velocity.y < -float(M.jump_vel) * float(M.short_hop):
        velocity.y = -float(M.jump_vel) * float(M.short_hop)

    # wall kick — grace gated to wall vertical span
    if buffer_t > 0.0 and not is_on_floor() and wall_grace_t > 0.0 and dash_t <= 0.0 \
            and global_position.y + HALF_H >= wall_top_y - 4.0:
        velocity.y = -float(M.jump_vel) * 0.95
        velocity.x = -float(wall_dir) * max_run * 1.15
        buffer_t = 0.0
        coyote_t = 0.0
        wall_grace_t = 0.0
        face = -wall_dir
        sx_anim = 0.75
        sy_anim = 1.3
        Sfx.beep(500.0 + randf() * 40.0)
        _fx_burst(global_position, 5)

    # air jumps (2xJUMP / GLASS)
    if buffer_t > 0.0 and not is_on_floor() and coyote_t <= 0.0 \
            and air_jumps > 0 and spring_t <= 0.0 and dash_t <= 0.0:
        air_jumps -= 1
        velocity.y = -float(M.jump_vel) * 0.92
        buffer_t = 0.0
        sx_anim = 0.75
        sy_anim = 1.3
        Sfx.beep(560.0 + randf() * 40.0)
        _fx_burst(global_position + Vector2(0, 7), 5)

    # dash (DASH glyph)
    if Input.is_action_just_pressed("dash") and bool(M.dash) and dash_ready and dash_t <= 0.0:
        dash_t = DASH_TIME
        dash_ready = false
        dash_dir = int(signf(dir)) if dir != 0.0 else face  # JS: no input → facing
        face = dash_dir
        velocity.y = 0.0
        invuln = maxf(invuln, 0.2)
        sx_anim = 1.35
        sy_anim = 0.65
        Sfx.beep(700.0, 0.07)
        _fx_burst(global_position, 6)
    if dash_t > 0.0:
        var fx2 := get_tree().get_first_node_in_group("fx")
        if fx2:
            fx2.trail(global_position, dash_dir)

    if dash_t <= 0.0:
        var g := float(M.gravity)
        if velocity.y > 0.0:
            g *= float(M.fall_mult)
        var mf := float(M.max_fall)
        if float(M.fall_mult) < 1.0:
            mf *= 0.75
        velocity.y = minf(mf, velocity.y + g * delta)

    # wall slide
    if not is_on_floor() and is_on_wall() and velocity.y > 0.0 and dash_t <= 0.0 \
            and dir != 0.0 and dir == -float(get_wall_normal().x):
        velocity.y = minf(velocity.y, 60.0)

    prev_vy = velocity.y
    var was_ground := is_on_floor()
    var fall_v := velocity.y
    move_and_slide()

    if prev_vy < 0.0:
        for i in get_slide_collision_count():
            var collision := get_slide_collision(i)
            if collision.get_normal().y > 0.7 and collision.get_collider().has_method("strike"):
                collision.get_collider().strike()
                break

    # face + run anim
    if dir != 0.0:
        face = int(signf(dir))
    anim_t += delta * (11.0 if (absf(velocity.x) > 10.0 and is_on_floor()) else 3.0)
    sliding_anim = not is_on_floor() and is_on_wall() and velocity.y > 0.0 \
        and dir != 0.0 and dir == -float(get_wall_normal().x)
    # squash/stretch relax
    sx_anim += (1.0 - sx_anim) * minf(1.0, delta * 10.0)
    sy_anim += (1.0 - sy_anim) * minf(1.0, delta * 10.0)
    # landing squash + dust
    if not was_ground and is_on_floor():
        var hard := fall_v > 260.0
        sx_anim = 1.35 if hard else 1.18
        sy_anim = 0.65 if hard else 0.8
        var fx3 := get_tree().get_first_node_in_group("fx")
        if fx3:
            fx3.dust(global_position + Vector2(0, 7), 7 if hard else 4)
        if hard:
            Sfx.beep(140.0, 0.05, 0.04)
            _fx_shake(2.0)

    # corner correction: ceiling graze <= 4px slides past (restores arc)
    if is_on_ceiling() and prev_vy < 0.0:
        var fix := _corner_ceiling_fix()
        if fix != Vector2.ZERO:
            global_position.x += fix.x
            velocity.y = prev_vy

    # post-move bookkeeping
    if is_on_floor():
        coyote_t = float(M.coyote)
        dash_ready = bool(M.dash)
        air_jumps = int(M.air_jumps)
        wall_grace_t = 0.0
    elif is_on_wall():
        wall_dir = int(-signf(get_wall_normal().x))
        wall_grace_t = 0.12
        wall_top_y = _wall_top_from_collisions()

func _corner_ceiling_fix() -> Vector2:
    for i in get_slide_collision_count():
        var col := get_slide_collision(i)
        if col.get_normal().y < -0.7:
            var collider := col.get_collider()
            if collider is StaticBody2D:
                var node := collider as StaticBody2D
                for child in node.get_children():
                    if child is CollisionShape2D and child.shape is RectangleShape2D:
                        var cs := child as CollisionShape2D
                        var rect := cs.shape as RectangleShape2D
                        var c_left := cs.global_position.x - rect.size.x * 0.5
                        var c_right := cs.global_position.x + rect.size.x * 0.5
                        var ov_l := (global_position.x + HALF_W) - c_left
                        var ov_r := c_right - (global_position.x - HALF_W)
                        if minf(ov_l, ov_r) <= CORNER_SLIDE:
                            if ov_l < ov_r:
                                return Vector2(-(ov_l + 0.5), 0)
                            else:
                                return Vector2(ov_r + 0.5, 0)
    return Vector2.ZERO

func _wall_top_from_collisions() -> float:
    for i in get_slide_collision_count():
        var col := get_slide_collision(i)
        if absf(col.get_normal().x) > 0.7:
            var collider := col.get_collider()
            if collider is StaticBody2D:
                var node := collider as StaticBody2D
                for child in node.get_children():
                    if child is CollisionShape2D and child.shape is RectangleShape2D:
                        var cs := child as CollisionShape2D
                        var rect := cs.shape as RectangleShape2D
                        return cs.global_position.y - rect.size.y * 0.5
    return wall_top_y

func _fx_burst(at: Vector2, n: int) -> void:
    var fx := get_tree().get_first_node_in_group("fx")
    if fx:
        fx.burst(at, n)

func _fx_shake(v: float) -> void:
    var fx := get_tree().get_first_node_in_group("fx")
    if fx:
        fx.shake(v)

func player_rect() -> Rect2:
    return Rect2(global_position.x - HALF_W, global_position.y - HALF_H, HALF_W * 2.0, HALF_H * 2.0)

## lethal / shielded hit — port of JS lethalHit()
func player_hit() -> void:
    if invuln > 0.0:
        return
    if bool(m("glass")):
        RunState.register_death()
        return
    if shield > 0:
        shield -= 1
        invuln = 1.2
        velocity.y = -220.0
        Sfx.beep(220.0, 0.15, 0.08, "sawtooth")  # AEGIS break (saw drop)
        _fx_burst(global_position, 12)
        _fx_shake(4.0)
        return
    RunState.register_death()

# --- test hooks (headless validation) ---
func t_press_jump() -> void:
    Input.action_press("jump")

func t_release_jump() -> void:
    Input.action_release("jump")

func t_dash() -> void:
    if bool(m("dash")) and dash_ready and dash_t <= 0.0:
        dash_t = DASH_TIME
        dash_ready = false
        dash_dir = 1
        velocity.y = 0.0
        invuln = maxf(invuln, 0.2)
