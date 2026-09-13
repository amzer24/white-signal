extends RefCounted
const HALF_H := 7.0
static func draw(canvas: Node2D, p: CharacterBody2D, t: float) -> void:
	if p == null or not is_instance_valid(p):
		return
	var pos: Vector2 = p.global_position
	var sx: float = p.sx_anim
	var sy: float = p.sy_anim
	var w := maxf(4.0, 12.0 * sx)
	var h := maxf(6.0, 14.0 * sy)
	var face: int = p.wall_dir if p.sliding_anim else p.face
	var bx: float = pos.x - w / 2.0
	var by: float = pos.y + HALF_H - h
	# ground shadow
	canvas.draw_rect(Rect2(pos.x - 5, pos.y + HALF_H + 1, 10, 2), Color(1, 1, 1, 0.15))
	# invuln blink ghost
	if p.invuln > 0.0 and p.dash_t <= 0.0 and not AppSettings.reduced_flashes and int(t * 14.3) % 2 == 0:
		canvas.draw_rect(Rect2(bx, by, w, h), Color(DrawUtil.WHITE, 0.35))
		return
	canvas.draw_rect(Rect2(bx - 1, by - 1, w + 2, h + 2), DrawUtil.BG)
	canvas.draw_rect(Rect2(bx, by, w, h), DrawUtil.WHITE)
	if p.invuln > 0.0 and AppSettings.reduced_flashes:
		canvas.draw_rect(Rect2(bx-2,by-2,w+4,h+4),DrawUtil.GRAY,false,1)
	canvas.draw_rect(Rect2(bx - 1 if face > 0 else bx + w, by + 1, 1, 3), DrawUtil.WHITE)
	var vx: float = bx + w - 6.0 if face > 0 else bx + 2.0
	canvas.draw_rect(Rect2(vx, by + 3, 4, 3), DrawUtil.BG)
	canvas.draw_rect(Rect2(vx + (0.0 if face > 0 else 3.0), by + 3, 1, 1), DrawUtil.GRAY)
	# scarf
	var fl := int(p.anim_t * 2.0) % 2
	var scx: float = bx - 3.0 if face > 0 else bx + w + 1.0
	canvas.draw_rect(Rect2(scx, by + 4 + fl, 3, 2), DrawUtil.GRAY)
	canvas.draw_rect(Rect2(scx - 2.0 if face > 0 else scx + 2.0, by + 5.0 - fl, 2, 1), DrawUtil.GRAY)
	# legs
	if p.sliding_anim:
		canvas.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), DrawUtil.BG)
		canvas.draw_rect(Rect2(bx + w - 1.0 if face > 0 else bx - 2.0, by + h - 5, 3, 2), DrawUtil.BG)
	elif not p.is_on_floor():
		canvas.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), DrawUtil.BG)
		canvas.draw_rect(Rect2(bx + w - 5, by + h - 3, 3, 3), DrawUtil.BG)
	elif absf(p.velocity.x) > 10.0:
		var fr := int(p.anim_t) % 2
		canvas.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2 + (0 if fr == 1 else 1)), DrawUtil.BG)
		canvas.draw_rect(Rect2(bx + w - 5, by + h - 3 - (1 if fr == 1 else 0), 3, 2 + (1 if fr == 1 else 0)), DrawUtil.BG)
	else:
		canvas.draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), DrawUtil.BG)
		canvas.draw_rect(Rect2(bx + w - 5, by + h - 2, 3, 2), DrawUtil.BG)
	# AEGIS ring
	if p.shield > 0:
		var pulse := AppSettings.reduced_flashes or int(t * 3.33) % 2 == 0
		var ring := DrawUtil.WHITE if pulse else DrawUtil.GRAY
		canvas.draw_rect(Rect2(bx - 2, by - 2, w + 4, 1), ring)
		canvas.draw_rect(Rect2(bx - 2, by + h + 1, w + 4, 1), ring)
		canvas.draw_rect(Rect2(bx - 2, by, 1, h), ring)
		canvas.draw_rect(Rect2(bx + w + 1, by, 1, h), ring)
	# DASH pip
	if bool(RunState.mods.dash):
		canvas.draw_rect(Rect2(bx + w / 2.0 - 1, by - 5, 3, 3), DrawUtil.WHITE if p.dash_ready else DrawUtil.DARK)
		canvas.draw_rect(Rect2(bx + w / 2.0, by - 4, 1, 1), DrawUtil.BG)
