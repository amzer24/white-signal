extends Node2D
## Beacon checkpoint — activate on proximity, mend AEGIS + refill dash/jumps.

var active := false

func _physics_process(_d: float) -> void:
    if RunState.state != "play":
        return
    var p := get_tree().get_first_node_in_group("player")
    if p == null:
        return
    if absf(p.global_position.x - global_position.x) < 14.0 \
            and absf(p.global_position.y + 7.0 - global_position.y) < 30.0:
        if RunState.checkpoint != global_position:
            RunState.checkpoint = global_position
            active = true
        p.shield = int(RunState.mods.shield_max)
        p.dash_ready = bool(RunState.mods.dash)
        p.air_jumps = int(RunState.mods.air_jumps)