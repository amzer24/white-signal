extends Node2D
## Draft/pause/menu/win UI overlay — CanvasLayer, process_mode ALWAYS.

var banner_t := 0.0
var hint_text := ""
var hint_pos := Vector2.ZERO

func show_banner(t: String, sub: String) -> void:
    banner_t = 2.5
    set_meta("banner_sub", sub)
    set_meta("banner_text", t)

func hint(text: String, world_pos: Vector2) -> void:
    hint_text = text
    hint_pos = world_pos

func _process(_d: float) -> void:
    queue_redraw()

func _draw() -> void:
    var font := ThemeDB.fallback_font
    if banner_t > 0.0:
        draw_rect(Rect2(120, 40, 240, 42), Color(0.043, 0.043, 0.043))
        draw_string(font, Vector2(240 - 60, 62), String(get_meta("banner_text", "")), HORIZONTAL_ALIGNMENT_CENTER, 120, 16, Color(0.949, 0.949, 0.949))
        draw_string(font, Vector2(240 - 60, 76), String(get_meta("banner_sub", "")), HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(0.541, 0.541, 0.541))
    if RunState.state == "draft":
        var afford := true
        draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.72))
        draw_string(font, Vector2(240 - 70, 40), "SIGNAL SURGE", HORIZONTAL_ALIGNMENT_CENTER, 140, 14, Color(0.949, 0.949, 0.949))
        var u: int = RunState.used_notches()
        draw_string(font, Vector2(240 - 110, 54), "CHOOSE A GLYPH . 1/2/3 . S SKIP . NOTCHES %d/%d" % [u, RunState.notches_max], HORIZONTAL_ALIGNMENT_CENTER, 220, 8, Color(0.541, 0.541, 0.541))
        for i in RunState.draft_opts.size():
            var id: String = RunState.draft_opts[i]
            var c: Dictionary = RunState.CARDS[id]
            var cx := 30 + i * 144
            if c.cursed:
                afford = RunState.used_cursed() + int(c.cost) <= RunState.cursed_max
            else:
                afford = u + int(c.cost) <= RunState.notches_max
            var col := Color(0.949, 0.949, 0.949) if afford else Color(0.541, 0.541, 0.541)
            draw_rect(Rect2(cx, 84, 132, 108), col)
            draw_rect(Rect2(cx + 2, 86, 128, 104), Color(0.043, 0.043, 0.043))
            draw_string(font, Vector2(cx + 66 - 20, 110), String(c.g), HORIZONTAL_ALIGNMENT_CENTER, 40, 16, col)
            draw_string(font, Vector2(cx + 66 - 30, 124), String(c.n), HORIZONTAL_ALIGNMENT_CENTER, 60, 8, col)
            var cost_str := ""
            for j in int(c.cost):
                cost_str += "o"
            draw_string(font, Vector2(cx + 66 - 20, 138), cost_str, HORIZONTAL_ALIGNMENT_CENTER, 40, 8, Color(0.541, 0.541, 0.541))
            var label := "CURSED [%d]" % (i + 1) if c.cursed else "[%d]" % (i + 1)
            if not afford:
                label = "LOCKED"
            draw_string(font, Vector2(cx + 66 - 30, 184), label, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color(0.227, 0.227, 0.227))
        draw_rect(Rect2(170, 204, 140, 16), Color(0.541, 0.541, 0.541), false, 1.0)
        draw_string(font, Vector2(240 - 20, 216), "SKIP [S]", HORIZONTAL_ALIGNMENT_CENTER, 40, 8, Color(0.541, 0.541, 0.541))
    elif hint_text != "" and RunState.state == "play":
        var sx: float = clampf(hint_pos.x - get_viewport().get_camera_2d().position.x, 20.0, 460.0)
        draw_string(font, Vector2(sx - 40, hint_pos.y - 30.0), hint_text, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color(0.949, 0.949, 0.949))
        hint_text = ""