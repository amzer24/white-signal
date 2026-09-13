## Drafted by OpenCode mimo-v2.5-free; locally reviewed and tested.
extends RefCounted

var positions: Array[int] = [0, 0, 0]
var target: Array[int] = [2, 1, 3]
var locked: bool = false

func rotate(index: int) -> bool:
    if locked:
        return false
    if index < 0 or index >= positions.size():
        return false
    positions[index] = (positions[index] + 1) % 4
    return true

func is_aligned() -> bool:
    for i in range(positions.size()):
        if positions[i] != target[i]:
            return false
    return true

func latch() -> bool:
    if is_aligned():
        locked = true
        return true
    return false

func reset() -> bool:
    if locked:
        return false
    for i in range(positions.size()):
        positions[i] = 0
    return true
