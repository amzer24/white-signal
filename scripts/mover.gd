extends AnimatableBody2D
## Moving platform — engine carries the rider (sync_to_physics; no manual delta).

var axis := "x"
var travel_range := 30.0
var osc_speed := 1.2
var phase := 0.0
var t := 0.0
var origin := Vector2.ZERO
var size := Vector2(60, 10)

func _ready() -> void:
    origin = position
    t = phase
    sync_to_physics = true

func _physics_process(delta: float) -> void:
    t += delta * osc_speed
    var off := sin(t) * travel_range
    if axis == "x":
        position.x = origin.x + off
    else:
        position.y = origin.y + off