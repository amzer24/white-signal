extends Node2D
## World rendering — every entity's visual, ported from the JS draw* functions.
## Sits at z_index 10 above the background; reads entity state directly.

const HALF_W := 6.0
const HALF_H := 7.0

var world: Node2D
var particles: Node2D

func _ready() -> void:
	z_index = 10

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if world == null or not is_instance_valid(world):
		return
	var cam := get_viewport().get_camera_2d()
	# We are a WORLD-SPACE Node2D: the Camera2D transform already maps world →
	# screen. Draw at RAW WORLD coordinates — subtracting the camera here
	# double-transforms and makes every visual slide at ~2x camera speed.
	var cam_tl := Vector2(cam.position.x - 240.0, cam.position.y - 135.0) if cam else Vector2.ZERO
	var t := Time.get_ticks_msec() / 1000.0

	_draw_beacons_goal(t)
	_draw_platforms(t)
	_draw_springs(t)
	_draw_signs(cam_tl)
	_draw_spikes(t)
	_draw_gems(t)
	_draw_enemies(t, cam_tl)
	_draw_player(t)

func _draw_beacons_goal(t: float) -> void:
	for c in LevelData.DATA.checkpoints:
		var pos: Vector2 = c.pos
		var active: bool = RunState.checkpoint.is_equal_approx(pos)
		draw_rect(Rect2(pos.x, pos.y - 26, 2, 26), DrawUtil.WHITE if active else DrawUtil.DARK)
		var wave := sin(t * 2.5 + pos.x) if active else 0.0
		draw_rect(Rect2(pos.x + 2, pos.y - 26 + wave, 10 if active else 7, 6),
			DrawUtil.WHITE if active else DrawUtil.GRAY)
	var g: Rect2 = LevelData.DATA.goal
	var pulse := int(t * 2.0) % 2 == 0
	var scroll := int(t * 5.0) % 8
	draw_rect(Rect2(g.position.x - 4, g.position.y - 4, 4, g.size.y + 8), DrawUtil.WHITE)
	draw_rect(Rect2(g.end.x, g.position.y - 4, 4, g.size.y + 8), DrawUtil.WHITE)
	draw_rect(Rect2(g.position.x - 6, g.position.y - 8, g.size.x + 12, 5), DrawUtil.WHITE)
	draw_rect(Rect2(g.position.x - 4, g.position.y - 10, g.size.x + 8, 2), DrawUtil.WHITE if pulse else DrawUtil.GRAY)
	draw_rect(g, DrawUtil.BG)
	var yy := 0.0
	while yy < g.size.y:
		var xx := 0.0
		while xx < g.size.x:
			if int((xx + yy + scroll) / 8.0) % 2 == 0:
				draw_rect(Rect2(g.position.x + xx + 1, g.position.y + yy + 1, 6, 6), DrawUtil.DARK)
			xx += 8
		yy += 8
	draw_rect(Rect2(g.position.x - 6, g.end.y + 4, g.size.x + 12, 2), DrawUtil.GRAY)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(g.position.x + 1, g.position.y - 4), "GATE", HORIZONTAL_ALIGNMENT_CENTER, g.size.x, 8, DrawUtil.BG)
	draw_string(font, Vector2(g.position.x, g.position.y - 5), "GATE", HORIZONTAL_ALIGNMENT_CENTER, g.size.x, 8, DrawUtil.WHITE)

func _draw_platforms(t: float) -> void:
	for p in LevelData.DATA.platforms:
		var tufts: bool = p.type != "secret" and p.r.size.y >= 20.0
		DrawUtil.tile_platform(self, p.r, p.type == "secret", tufts)
		if p.type == "secret":
			var x: float = p.r.position.x
			while x < p.r.end.x:
				draw_rect(Rect2(x, p.r.position.y - 2, 3, 1), DrawUtil.WHITE)
				x += 6
	for cr in world.crumbles:
		if not is_instance_valid(cr) or cr.broken:
			continue
		var r := Rect2(cr.position.x - cr.size.x / 2.0, cr.position.y - cr.size.y / 2.0, cr.size.x, cr.size.y)
		var jx := roundf(sin(t * 33.3) * cr.shake_t * 4.0) if cr.shake_t > 0.0 else 0.0
		var urgent: bool = cr.shake_t > 0.2
		var body := DrawUtil.GRAY if urgent and int(t * 10.5) % 2 == 0 else DrawUtil.DARK
		draw_rect(Rect2(r.position.x + jx, r.position.y, r.size.x, r.size.y), body)
		draw_rect(Rect2(r.position.x + jx, r.position.y, r.size.x, 1), DrawUtil.WHITE)
		draw_rect(Rect2(r.position.x + jx + 8, r.position.y + 3, 2, r.size.y - 5), DrawUtil.BG)
		draw_rect(Rect2(r.position.x + jx + r.size.x / 2.0, r.position.y + 2, 2, r.size.y - 4), DrawUtil.BG)
		draw_rect(Rect2(r.position.x + jx + r.size.x - 10, r.position.y + 4, 2, r.size.y - 6), DrawUtil.BG)
	for m in world.movers:
		if not is_instance_valid(m):
			continue
		var r := Rect2(m.position.x - m.size.x / 2.0, m.position.y - m.size.y / 2.0, m.size.x, m.size.y)
		DrawUtil.tile_platform(self, r, false, false)
		var x2: float = r.position.x + 3.0
		while x2 < r.end.x - 5.0:
			draw_rect(Rect2(x2, r.position.y + 6, 3, 2), DrawUtil.WHITE)
			draw_rect(Rect2(x2 + 1, r.position.y + 5, 1, 1), DrawUtil.WHITE)
			x2 += 10

func _draw_springs(t: float) -> void:
	for s in world.springs:
		if not is_instance_valid(s):
			continue
		var comp := roundf(s.anim_t * 6.0)
		var r := Rect2(s.position.x - 12.0, s.position.y - 9.0, 24.0, 18.0)
		draw_rect(Rect2(r.position.x - 1, r.end.y - 1, r.size.x + 2, 3), DrawUtil.BG)
		draw_rect(Rect2(r.position.x, r.position.y + comp, r.size.x, r.size.y - comp), DrawUtil.DARK)
		DrawUtil.tile_platform(self, Rect2(r.position.x, r.position.y + comp, r.size.x, maxf(4.0, r.size.y - comp)), false, false)
		var pad := DrawUtil.WHITE if s.anim_t > 0.3 else DrawUtil.GRAY
		draw_rect(Rect2(r.position.x - 2, r.position.y + comp, r.size.x + 4, 4), pad)
		draw_rect(Rect2(r.position.x, r.position.y + comp + 1, r.size.x, 2), DrawUtil.BG)
		draw_rect(Rect2(r.position.x + 5, r.position.y + 7 + comp, 3, 5), DrawUtil.WHITE)
		draw_rect(Rect2(r.position.x + r.size.x - 8, r.position.y + 7 + comp, 3, 5), DrawUtil.WHITE)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(r.position.x + 1, r.position.y - 3 + comp + 1), "^^^", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8, DrawUtil.BG)
		draw_string(font, Vector2(r.position.x, r.position.y - 3 + comp), "^^^", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8, DrawUtil.WHITE)

func _draw_signs(cam_tl: Vector2) -> void:
	var font := ThemeDB.fallback_font
	for sg in LevelData.DATA.signs:
		var pos: Vector2 = sg.pos
		if pos.x < cam_tl.x - 20.0 or pos.x > cam_tl.x + 500.0:
			continue
		draw_rect(Rect2(pos.x, pos.y, 2, 22), DrawUtil.GRAY)
		draw_rect(Rect2(pos.x - 3, pos.y - 4, 8, 6), DrawUtil.WHITE)
		draw_rect(Rect2(pos.x - 1, pos.y - 2, 4, 2), DrawUtil.BG)
		var p = world.player
		if p and absf(p.global_position.x - pos.x) < 110.0:
			var txt: String = sg.text
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 8).x + 12.0
			var bx: float = clampf(pos.x, tw / 2.0 + 2.0, 480.0 - tw / 2.0 - 2.0)
			var by := maxf(16.0, pos.y - 26.0)
			draw_rect(Rect2(bx - tw / 2.0 - 1, by - 9, tw + 2, 13), DrawUtil.BG)
			draw_rect(Rect2(bx - tw / 2.0, by - 8, tw, 11), DrawUtil.WHITE)
			draw_string(font, Vector2(bx - tw / 2.0, by), txt, HORIZONTAL_ALIGNMENT_CENTER, tw, 8, DrawUtil.BG)
			draw_rect(Rect2(pos.x, by + 3, 1, 5), DrawUtil.BG)
		else:
			draw_string(font, Vector2(pos.x + 1, pos.y - 6), "?", HORIZONTAL_ALIGNMENT_CENTER, 8, 8, DrawUtil.BG)
			draw_string(font, Vector2(pos.x, pos.y - 7), "?", HORIZONTAL_ALIGNMENT_CENTER, 8, 8, DrawUtil.GRAY)

func _draw_spikes(t: float) -> void:
	var blink := int(t * 6.25) % 2 == 0
	for s in LevelData.DATA.spikes:
		var r: Rect2 = s.r
		draw_rect(Rect2(r.position.x - 1, r.end.y - 2, r.size.x + 2, 3), DrawUtil.BG)
		var n := maxi(1, roundi(r.size.x / 12.0))
		var tw := r.size.x / n
		var col := DrawUtil.WHITE if blink else DrawUtil.GRAY
		for i in n:
			var x0 := r.position.x + i * tw
			draw_colored_polygon(PackedVector2Array([
				Vector2(x0, r.end.y), Vector2(x0 + tw / 2.0, r.position.y), Vector2(x0 + tw, r.end.y)
			]), col)

func _draw_gems(t: float) -> void:
	for g in world.gems:
		if not is_instance_valid(g) or g.collected:
			continue
		var pos: Vector2 = g.global_position + Vector2(0, sin(t * 4.0 + g.get_instance_id() % 7) * 2.0)
		var squish := absf(sin(t * 3.33 + g.get_instance_id() % 7)) * 3.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(pos.x, pos.y - 5), Vector2(pos.x + 5.0 - squish, pos.y),
			Vector2(pos.x, pos.y + 5), Vector2(pos.x - 5.0 + squish, pos.y)
		]), DrawUtil.WHITE)
		draw_rect(Rect2(pos.x - 1, pos.y - 1, 2, 2), DrawUtil.BG)

func _draw_enemies(t: float, cam_tl: Vector2) -> void:
	var f := int(t * 6.67) % 2
	for e in world.enemies:
		if not is_instance_valid(e):
			continue
		var pos: Vector2 = e.position
		if pos.x < cam_tl.x - 30.0 or pos.x > cam_tl.x + 510.0:
			continue
		var turning: bool = (e.dir == 1.0 and e.max_x - pos.x < 20.0) or (e.dir == -1.0 and pos.x - e.min_x < 20.0)
		var blink := turning and int(t * 10.0) % 2 == 0
		var squash := 1.0 if turning else 0.0
		draw_rect(Rect2(pos.x - 8, pos.y - 10 + squash, 16, 20 - squash), DrawUtil.BG)
		draw_rect(Rect2(pos.x - 7, pos.y - 9 + squash, 14, 18 - squash), DrawUtil.GRAY if blink else DrawUtil.WHITE)
		var ex: float = pos.x + 1.0 if e.dir > 0 else pos.x - 5.0
		draw_rect(Rect2(ex, pos.y - 5 + squash, 2, 2), DrawUtil.BG)
		draw_rect(Rect2(ex - (1.0 if e.dir > 0 else -1.0), pos.y - 6 + squash, 3, 1), DrawUtil.BG)
		draw_rect(Rect2(ex, pos.y + 1, 2, 3), DrawUtil.BG)
		draw_rect(Rect2(pos.x - 4, pos.y + 6, 2, 1), DrawUtil.BG)
		draw_rect(Rect2(pos.x + 2, pos.y + 6, 2, 1), DrawUtil.BG)
		draw_rect(Rect2(pos.x - 7, pos.y + 9, 5 if f == 1 else 3, 2), DrawUtil.GRAY)
		draw_rect(Rect2(pos.x + 2 if f == 1 else pos.x + 0, pos.y + 9, 3 if f == 1 else 5, 2), DrawUtil.GRAY)

func _draw_player(t: float) -> void:
	var p = world.player
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
	draw_rect(Rect2(pos.x - 5, pos.y + HALF_H + 1, 10, 2), Color(1, 1, 1, 0.15))
	# invuln blink ghost
	if p.invuln > 0.0 and p.dash_t <= 0.0 and int(t * 14.3) % 2 == 0:
		draw_rect(Rect2(bx, by, w, h), Color(DrawUtil.WHITE, 0.35))
		return
	draw_rect(Rect2(bx - 1, by - 1, w + 2, h + 2), DrawUtil.BG)
	draw_rect(Rect2(bx, by, w, h), DrawUtil.WHITE)
	draw_rect(Rect2(bx - 1 if face > 0 else bx + w, by + 1, 1, 3), DrawUtil.WHITE)
	var vx: float = bx + w - 6.0 if face > 0 else bx + 2.0
	draw_rect(Rect2(vx, by + 3, 4, 3), DrawUtil.BG)
	draw_rect(Rect2(vx + (0.0 if face > 0 else 3.0), by + 3, 1, 1), DrawUtil.GRAY)
	# scarf
	var fl := int(p.anim_t * 2.0) % 2
	var scx: float = bx - 3.0 if face > 0 else bx + w + 1.0
	draw_rect(Rect2(scx, by + 4 + fl, 3, 2), DrawUtil.GRAY)
	draw_rect(Rect2(scx - 2.0 if face > 0 else scx + 2.0, by + 5.0 - fl, 2, 1), DrawUtil.GRAY)
	# legs
	if p.sliding_anim:
		draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), DrawUtil.BG)
		draw_rect(Rect2(bx + w - 1.0 if face > 0 else bx - 2.0, by + h - 5, 3, 2), DrawUtil.BG)
	elif not p.is_on_floor():
		draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), DrawUtil.BG)
		draw_rect(Rect2(bx + w - 5, by + h - 3, 3, 3), DrawUtil.BG)
	elif absf(p.velocity.x) > 10.0:
		var fr := int(p.anim_t) % 2
		draw_rect(Rect2(bx + 2, by + h - 2, 3, 2 + (0 if fr == 1 else 1)), DrawUtil.BG)
		draw_rect(Rect2(bx + w - 5, by + h - 3 - (1 if fr == 1 else 0), 3, 2 + (1 if fr == 1 else 0)), DrawUtil.BG)
	else:
		draw_rect(Rect2(bx + 2, by + h - 2, 3, 2), DrawUtil.BG)
		draw_rect(Rect2(bx + w - 5, by + h - 2, 3, 2), DrawUtil.BG)
	# AEGIS ring
	if p.shield > 0:
		var pulse := int(t * 3.33) % 2 == 0
		var ring := DrawUtil.WHITE if pulse else DrawUtil.GRAY
		draw_rect(Rect2(bx - 2, by - 2, w + 4, 1), ring)
		draw_rect(Rect2(bx - 2, by + h + 1, w + 4, 1), ring)
		draw_rect(Rect2(bx - 2, by, 1, h), ring)
		draw_rect(Rect2(bx + w + 1, by, 1, h), ring)
	# DASH pip
	if bool(RunState.mods.dash):
		draw_rect(Rect2(bx + w / 2.0 - 1, by - 5, 3, 3), DrawUtil.WHITE if p.dash_ready else DrawUtil.DARK)
		draw_rect(Rect2(bx + w / 2.0, by - 4, 1, 1), DrawUtil.BG)

func _draw_ghost_text(cx: float) -> void:
	pass