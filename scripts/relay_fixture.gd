extends StaticBody2D
## Memory blocks are solid; dishes and conduits are non-solid fixtures.

var kind := "memory"
var fixture_id := ""
var destination := Vector2.ZERO
var spent := false
var bump := 0.0
var hold := 0.0

func _ready() -> void:
    z_index = 12
    if kind == "memory" or kind == "brick":
        var shape := RectangleShape2D.new()
        shape.size = Vector2(20, 20)
        var collision := CollisionShape2D.new()
        collision.shape = shape
        add_child(collision)
    else:
        collision_layer = 0
        collision_mask = 0

func strike() -> void:
    if RunState.state != "play":
        return
    if kind == "memory" and RunState.lab_active:
        RunState.remember(position,fixture_id)
        if spent:
            bump = 5.0
            Sfx.beep(620.0,0.08)
            return
    if spent:
        return
    spent = true
    bump = 5.0
    Sfx.beep(820.0, 0.08)
    var fx := get_tree().get_first_node_in_group("fx")
    if fx:
        fx.burst(position, 10)
    if kind == "memory":
        RunState.collect_gem()
    elif kind == "brick":
        get_child(0).set_deferred("disabled", true)

func _physics_process(delta: float) -> void:
    if not RunState.sim_active():
        return
    bump = maxf(0.0, bump - delta * 25.0)
    var p := get_tree().get_first_node_in_group("player")
    if p == null:
        return
    var nearby: bool = absf(p.position.x - position.x) < 16.0 and absf(p.position.y + 7.0 - position.y) < 16.0
    if kind == "ear" and nearby and not RunState.objectives.has(fixture_id):
        RunState.objectives.append(fixture_id)
        Sfx.two(440.0 + RunState.objectives.size() * 110.0, 880.0, 120)
    if kind == "conduit":
        # A deliberate press and a grounded stance; holding Down through an exit
        # cannot bounce the player back into the paired conduit.
        if nearby and p.is_on_floor() and p.conduit_cooldown <= 0.0 and Input.is_action_just_pressed("interact"):
            p.conduit_cooldown = 0.35
            p.reset_at(destination)
            p.jump_held = Input.is_action_pressed("jump")
            get_parent().get_parent().snap_camera()
            Sfx.two(330.0, 165.0, 80)
    queue_redraw()

func _draw() -> void:
    var white := DrawUtil.WHITE
    var gray := DrawUtil.GRAY
    var dark := DrawUtil.DARK
    if kind == "memory" or kind == "brick":
        if kind == "brick" and spent:
            return
        var r := Rect2(-10, -10 - bump, 20, 20)
        draw_rect(r, DrawUtil.BG)
        draw_rect(r, gray if spent else white, false)
        if kind == "memory":
            if spent:
                draw_line(Vector2(-5, -bump), Vector2(5, -bump), dark)
            else:
                DrawUtil.diamond(self, Vector2(-2, -2 - bump), white)
        else:
            draw_line(Vector2(-9, -bump), Vector2(9, -bump), gray)
            draw_line(Vector2(0, -9 - bump), Vector2(0, -bump), gray)
            draw_line(Vector2(-4, -bump), Vector2(-4, 9 - bump), gray)
    elif kind == "conduit":
        draw_rect(Rect2(-17, -5, 34, 5), gray)
        draw_rect(Rect2(-12, -3, 24, 3), DrawUtil.BG)
        draw_line(Vector2(-4, -14), Vector2(0, -10), white)
        draw_line(Vector2(0, -10), Vector2(4, -14), white)
        DrawUtil.text_shadow(self, Vector2(0, 7), fixture_id, gray, 1, HORIZONTAL_ALIGNMENT_CENTER)
    elif kind == "ear":
        var lit: bool = RunState.objectives.has(fixture_id)
        draw_line(Vector2(0, 0), Vector2(0, -26), gray, 2)
        draw_arc(Vector2(0, -37), 16, 0.0 if lit else 0.3, PI if lit else PI + 0.3, 16, white if lit else gray, 2)
        draw_line(Vector2(0, -24), Vector2(0, -42), white if lit else gray)
        draw_circle(Vector2(0, -42), 2, white if lit else dark)
        if lit:
            draw_arc(Vector2(0, -43), 23, PI + 0.4, TAU - 0.4, 12, gray)
        DrawUtil.text_shadow(self, Vector2(0, 7), "AWAKE" if lit else "WAKE", white if lit else gray, 1, HORIZONTAL_ALIGNMENT_CENTER)
