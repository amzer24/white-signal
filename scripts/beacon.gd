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
            if RunState.lab_active and not RunState.lit_beacons.has(global_position):
                RunState.lit_beacons.append(global_position)
            RunState.relay_time = 0.0
            Sfx.beep(660.0, 0.09)  # checkpoint bell
            var fx := get_tree().get_first_node_in_group("fx")
            if fx:
                fx.burst(global_position + Vector2(0, -12), 6)
        p.shield = int(RunState.mods.shield_max)
        p.dash_ready = bool(RunState.mods.dash)
        p.air_jumps = int(RunState.mods.air_jumps)