extends StaticBody2D
## Crumble platform — shakes 0.45s underfoot, breaks, heals on respawn.

var shake_t := 0.0
var broken := false
var respawn_t := 0.0
var size := Vector2(70, 12)

func _physics_process(delta: float) -> void:
    if broken:
        respawn_t -= delta
        if respawn_t <= 0.0:
            heal()
        return
    var p := get_tree().get_first_node_in_group("player")
    if p and RunState.state == "play":
        var pr: Rect2 = p.player_rect()
        var r := Rect2(global_position - size / 2.0, size)
        if absf(pr.position.y + pr.size.y - r.position.y) < 3.0 \
                and pr.position.x + pr.size.x > r.position.x and pr.position.x < r.position.x + r.size.x:
            shake_t += delta
            if shake_t > 0.45:
                broken = true
                respawn_t = 2.0
                set_deferred("collision_layer", 0)
    else:
        shake_t = maxf(0.0, shake_t - delta * 2.0)

func heal() -> void:
    broken = false
    shake_t = 0.0
    respawn_t = 0.0
    collision_layer = 1