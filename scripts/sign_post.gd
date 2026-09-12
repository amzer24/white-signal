extends Node2D
## Teach sign — GDD: 2-4 words, shown via UI when player is near.

func _physics_process(_d: float) -> void:
    var p := get_tree().get_first_node_in_group("player")
    if p and absf(p.global_position.x - global_position.x) < 110.0:
        var ui := get_tree().root.get_node_or_null("UI")
        if ui:
            ui.hint(String(get_meta("text", "?")), global_position)