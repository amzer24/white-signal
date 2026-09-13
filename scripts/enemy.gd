extends CharacterBody2D
## NOISE patroller — kills stick per life; death re-forms all (world.gd).

var min_x := 0.0
var max_x := 0.0
var speed := 50.0
var dir := 1.0
var dead := false
var size := Vector2(14, 18)

func _ready() -> void:
    add_to_group("enemy")
    size = Vector2(14, 18)

func _physics_process(delta: float) -> void:
    if dead or not RunState.sim_active():
        return
    if not is_inside_tree() or is_queued_for_deletion():
        return
    position.x += dir * speed * delta
    if position.x - 7.0 < min_x:
        position.x = min_x + 7.0
        dir = 1.0
    elif position.x + 7.0 > max_x:
        position.x = max_x - 7.0
        dir = -1.0
    _touch_player()

func _touch_player() -> void:
    var p := get_tree().get_first_node_in_group("player")
    if p == null:
        return
    var pr: Rect2 = p.player_rect()
    var er := Rect2(position.x - 7.0, position.y - 9.0, 14.0, 18.0)
    if not pr.intersects(er):
        return
    if p.dash_t > 0.0:
        kill(12)
        RunState.hitstop = 0.05
        Sfx.beep(760.0, 0.08)
        return
    var stomping: bool = p.velocity.y > 60.0 and (pr.position.y + pr.size.y - (position.y - 9.0)) < 10.0
    if stomping:
        p.velocity.y = -300.0 if bool(RunState.mods.stomp_plus) else -230.0
        p.sy_anim = 1.3
        p.sx_anim = 0.75
        RunState.hitstop = 0.06
        Sfx.beep(520.0, 0.08)
        if bool(RunState.mods.stomp_plus):
            for o in get_tree().get_nodes_in_group("enemy"):
                if o != self and not o.dead and absf(o.position.x - position.x) < 46.0 \
                        and absf(o.position.y - position.y) < 30.0:
                    o.kill(10)
            _shake(5.0)
        kill(16 if bool(RunState.mods.stomp_plus) else 10)
    else:
        if p.invuln <= 0.0:
            p.player_hit()

func kill(burst_n := 10) -> void:
    dead = true
    var fx := get_tree().get_first_node_in_group("fx")
    if fx:
        fx.burst(position, burst_n)
    _shake(3.0)
    queue_free()

func _shake(v: float) -> void:
    var fx := get_tree().get_first_node_in_group("fx")
    if fx:
        fx.shake(v)