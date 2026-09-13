extends StaticBody2D
var world: Node
var action_id := "memory"
func strike() -> void:
    if is_instance_valid(world):
        world.activate(action_id)
