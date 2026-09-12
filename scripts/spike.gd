extends Area2D
## Spikes — lethal bed, AEGIS does not apply differently (pits ignore it too).

func _physics_process(_d: float) -> void:
    if RunState.state != "play":
        return
    var p := get_tree().get_first_node_in_group("player")
    if p and overlaps_body(p) and p.invuln <= 0.0:
        p.player_hit()