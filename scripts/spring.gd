extends Area2D
## Spring — launch + momentum bonus, 0.3s jump-cut exemption (spring_t).

var power := 500.0
var cool := 0.0
var anim_t := 0.0

func _physics_process(delta: float) -> void:
    cool = maxf(0.0, cool - delta)
    anim_t = maxf(0.0, anim_t - delta * 5.0)
    if cool > 0.0 or not RunState.sim_active():
        return
    var p := get_tree().get_first_node_in_group("player")
    if p == null:
        return
    var feet: float = p.global_position.y + 7.0
    var top: float = global_position.y - 9.0
    var over_x: bool = p.global_position.x + 6.0 > global_position.x - 16.0 \
        and p.global_position.x - 6.0 < global_position.x + 16.0
    var on_pad: bool = feet > top - 10.0 and feet < top + 26.0
    if over_x and on_pad and p.velocity.y > -50.0:
        p.velocity.y = -(power + minf(80.0, absf(p.velocity.x) * 0.3))
        p.spring_t = 0.3
        p.buffer_t = 0.0  # JS: a buffered jump must not overwrite the launch
        p.coyote_t = 0.0
        p.sx_anim = 0.7
        p.sy_anim = 1.4
        anim_t = 1.0
        cool = 0.15
        var fx := get_tree().get_first_node_in_group("fx")
        if fx:
            fx.burst(global_position + Vector2(0, -9), 10)
            fx.shake(2.0)
        Sfx.beep(300.0, 0.1)
        get_tree().create_timer(0.06).timeout.connect(Sfx.beep.bind(620.0, 0.1, 0.06, "square"))