## OpenCode mimo-v2.5-free draft; locally reviewed.
extends RefCounted

var position: float = 150.0
var target: float = 150.0
var speed: float = 50.0

const LEFT: float = 150.0
const RIGHT: float = 350.0

func send_right() -> void:
    target = RIGHT

func recall() -> void:
    target = LEFT

func reset() -> void:
    position = LEFT
    target = LEFT

func tick(delta: float) -> void:
    var step := speed * maxf(delta, 0.0)
    if position < target:
        position = minf(position + step, target)
    elif position > target:
        position = maxf(position - step, target)

func arrived() -> bool:
    return absf(position - target) < 0.01
