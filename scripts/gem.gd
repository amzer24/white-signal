extends Area2D
## SHARD — pickup + SURGE trigger via RunState.

var collected := false

func collect() -> void:
    if collected:
        return
    collected = true
    RunState.collect_gem()
    queue_free()