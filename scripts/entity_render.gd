extends Node2D
## World rendering — every entity's visual, ported from the JS draw* functions.
## Sits at z_index 10 above the background; reads entity state directly.

const HALF_W := 6.0
const HALF_H := 7.0

var world: Node2D
var _tex_cache := {}
var props: Props

func _tile(r: Rect2, type: String) -> ImageTexture:
	var key := "%s_%d_%d_%d_%d" % [type, int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]
	if not _tex_cache.has(key):
		_tex_cache[key] = DrawUtil.platform_texture(r, type)
	return _tex_cache[key]

func _ready() -> void:
	z_index = 10
	props = Props.new()
	props.bake_all()
	props.place_all()

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
	_draw_platforms(t, cam_tl)
	props.draw(self, t, cam_tl)
	_draw_springs(t)
	_draw_signs(cam_tl, t)
	_draw_spikes(t)
	_draw_gems(t, cam_tl)
	_draw_enemies(t, cam_tl)
	_draw_player(t)

func _draw_beacons_goal(t: float) -> void:
	for c in RunState.level.checkpoints:
		var pos: Vector2 = c.pos
		var active: bool = RunState.checkpoint.is_equal_approx(pos)
		draw_rect(Rect2(pos.x, pos.y - 26, 2, 26), DrawUtil.WHITE if active else DrawUtil.DARK)
		var wave := sin(t * 2.5 + pos.x) if active else 0.0
		draw_rect(Rect2(pos.x + 2, pos.y - 26 + wave, 10 if active else 7, 6),
			DrawUtil.WHITE if active else DrawUtil.GRAY)
	var g: Rect2 = RunState.level.goal
	var gate_col := DrawUtil.WHITE if RunState.exit_ready() else DrawUtil.GRAY
	var pulse := int(t * 2.0) % 2 == 0
	var scroll := int(t * 5.0) % 8
	draw_rect(Rect2(g.position.x - 4, g.position.y - 4, 4, g.size.y + 8), gate_col)
	draw_rect(Rect2(g.end.x, g.position.y - 4, 4, g.size.y + 8), gate_col)
	draw_rect(Rect2(g.position.x - 6, g.position.y - 8, g.size.x + 12, 5), gate_col)
	draw_rect(Rect2(g.position.x - 4, g.position.y - 10, g.size.x + 8, 2), gate_col if pulse else DrawUtil.GRAY)
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
	DrawUtil.text_shadow(self, Vector2(g.position.x + g.size.x / 2.0, g.position.y - 17), "TRANSMITTER" if RunState.exit_ready() else "WAKE THREE EARS", gate_col, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_platforms(t: float, cam_tl: Vector2) -> void:
	for p in RunState.level.platforms:
		var pr: Rect2 = p.r
		if pr.end.x < cam_tl.x - 8.0 or pr.position.x > cam_tl.x + 488.0:
			continue
		draw_texture(_tile(pr, p.type), pr.position - Vector2(0, DrawUtil.TILE_MARGIN))
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
		draw_texture(_tile(Rect2(Vector2.ZERO, r.size), "girder"), r.position - Vector2(0, DrawUtil.TILE_MARGIN))
		# direction chevrons scroll with travel so the ferry reads as moving
		var ph := int(m.t * 6.0) % 10
		var x2: float = r.position.x + 4.0 + ph
		while x2 < r.end.x - 6.0:
			draw_rect(Rect2(x2, r.position.y + 5, 2, 1), DrawUtil.WHITE)
			draw_rect(Rect2(x2 + 1, r.position.y + 6, 2, 1), DrawUtil.WHITE)
			x2 += 10

func _draw_springs(t: float) -> void:
	for s in world.springs:
		if not is_instance_valid(s):
			continue
		var comp := roundf(s.anim_t * 6.0)
		var r := Rect2(s.position.x - 12.0, s.position.y - 9.0, 24.0, 18.0)
		draw_rect(Rect2(r.position.x - 1, r.end.y - 1, r.size.x + 2, 3), DrawUtil.BG)
		draw_rect(Rect2(r.position.x, r.position.y + comp, r.size.x, r.size.y - comp), DrawUtil.DARK)
		var pad_tex := _tile(Rect2(Vector2.ZERO, r.size), "pad")
		draw_texture_rect_region(pad_tex, Rect2(r.position.x, r.position.y + comp, r.size.x, r.size.y - comp),
			Rect2(0, DrawUtil.TILE_MARGIN, r.size.x, r.size.y - comp))
		var pad := DrawUtil.WHITE if s.anim_t > 0.3 else DrawUtil.GRAY
		draw_rect(Rect2(r.position.x - 2, r.position.y + comp, r.size.x + 4, 4), pad)
		draw_rect(Rect2(r.position.x, r.position.y + comp + 1, r.size.x, 2), DrawUtil.BG)
		draw_rect(Rect2(r.position.x + 5, r.position.y + 7 + comp, 3, 5), DrawUtil.WHITE)
		draw_rect(Rect2(r.position.x + r.size.x - 8, r.position.y + 7 + comp, 3, 5), DrawUtil.WHITE)
		var bob := -1.0 if s.anim_t <= 0.0 and int(t * 4.0) % 2 == 0 else 0.0
		DrawUtil.text_shadow(self, Vector2(r.position.x + r.size.x / 2.0, r.position.y - 8 + comp + bob), "^^^", DrawUtil.WHITE, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_signs(cam_tl: Vector2, t: float) -> void:
	for sg in RunState.level.signs:
		var pos: Vector2 = sg.pos
		if pos.x < cam_tl.x - 20.0 or pos.x > cam_tl.x + 500.0:
			continue
		draw_rect(Rect2(pos.x, pos.y, 2, 22), DrawUtil.GRAY)
		draw_rect(Rect2(pos.x - 3, pos.y - 4, 8, 6), DrawUtil.WHITE)
		draw_rect(Rect2(pos.x - 1, pos.y - 2, 4, 2), DrawUtil.BG)
		var p = world.player
		if p and RunState.state != "menu" and absf(p.global_position.x - pos.x) < 110.0:
			var txt: String = sg.text
			var tw := float(DrawUtil.text_width(txt) + 10)
			# clamp the bubble to the visible view (we draw in world space)
			var bx: float = roundf(clampf(pos.x, cam_tl.x + tw / 2.0 + 2.0, cam_tl.x + 480.0 - tw / 2.0 - 2.0))
			var by := maxf(16.0, pos.y - 26.0)
			draw_rect(Rect2(bx - tw / 2.0 - 1, by - 9, tw + 2, 13), DrawUtil.BG)
			draw_rect(Rect2(bx - tw / 2.0, by - 8, tw, 11), DrawUtil.WHITE)
			DrawUtil.text(self, Vector2(bx, by - 5), txt, DrawUtil.BG, 1, HORIZONTAL_ALIGNMENT_CENTER)
			draw_rect(Rect2(pos.x, by + 3, 1, 5), DrawUtil.BG)
		else:
			var bob := -1.0 if int(t * 2.0) % 2 == 0 else 0.0
			DrawUtil.text_shadow(self, Vector2(pos.x + 1, pos.y - 12 + bob), "?", DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_spikes(t: float) -> void:
	var blink := int(t * 6.25) % 2 == 0
	for s in RunState.level.spikes:
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

func _halo(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x, c.y - r), Vector2(c.x + r, c.y), Vector2(c.x, c.y + r), Vector2(c.x - r, c.y)
	]), col)

func _draw_gems(t: float, cam_tl: Vector2) -> void:
	var magnet: bool = float(RunState.mods.magnet_r) > 20.0
	var p = world.player
	for g in world.gems:
		if not is_instance_valid(g) or g.collected:
			continue
		var base: Vector2 = g.global_position
		if base.x < cam_tl.x - 30.0 or base.x > cam_tl.x + 510.0:
			continue
		var ph := float(g.get_instance_id() % 7)
		var pos: Vector2 = base + Vector2(0, sin(t * 4.0 + ph) * 2.0)
		var squish := absf(sin(t * 3.33 + ph)) * 3.0
		var pulse := 0.5 + 0.5 * sin(t * 2.6 + ph)  # slow breathe, per-shard phase
		# --- glow: soft halo (alpha) + a bayer-dithered outer ring for the 1-bit look
		var r_out := 9.0 + pulse * 2.0
		_halo(pos, r_out + 3.0, Color(DrawUtil.WHITE, 0.04 + pulse * 0.03))
		_halo(pos, 8.0, Color(DrawUtil.WHITE, 0.07 + pulse * 0.05))
		var ring := int(r_out)
		var yy := -ring
		while yy <= ring:
			var xx := -ring
			while xx <= ring:
				var d := absi(xx) + absi(yy)  # diamond metric
				if d == ring or d == ring - 1:
					if DrawUtil.bayer(int(pos.x) + xx, int(pos.y) + yy) < 4:
						draw_rect(Rect2(pos.x + xx, pos.y + yy, 1, 1), Color(DrawUtil.GRAY, 0.35 + pulse * 0.25))
				xx += 1
			yy += 1
		# --- magnet pull: when MAGNET is held, a faint tether toward the spark in range
		if magnet and p and base.distance_to(p.global_position) < float(RunState.mods.magnet_r) * 2.2:
			var to: Vector2 = p.global_position - pos
			var n := to.normalized()
			for k in 4:
				var q: Vector2 = pos + n * (8.0 + k * 6.0 + fmod(t * 40.0, 6.0))
				draw_rect(Rect2(q.x, q.y, 1, 1), Color(DrawUtil.GRAY, 0.5 - k * 0.1))
		# --- orbiting sparks (the pair on the far side of the orbit, drawn behind)
		for k in 2:
			var ang := t * 2.2 + ph + k * PI
			if sin(ang) < 0.0:
				var sp: Vector2 = pos + Vector2(cos(ang) * 8.0, sin(ang) * 4.0 - 1.0)
				draw_rect(Rect2(roundf(sp.x), roundf(sp.y), 1, 1), DrawUtil.GRAY)
		# --- the shard
		draw_colored_polygon(PackedVector2Array([
			Vector2(pos.x, pos.y - 6), Vector2(pos.x + 6.0 - squish, pos.y),
			Vector2(pos.x, pos.y + 6), Vector2(pos.x - 6.0 + squish, pos.y)
		]), DrawUtil.BG)
		draw_colored_polygon(PackedVector2Array([
			Vector2(pos.x, pos.y - 5), Vector2(pos.x + 5.0 - squish, pos.y),
			Vector2(pos.x, pos.y + 5), Vector2(pos.x - 5.0 + squish, pos.y)
		]), DrawUtil.WHITE)
		draw_rect(Rect2(pos.x - 1, pos.y - 1, 2, 2), DrawUtil.BG)
		# facet highlight on the upper-left edge
		draw_rect(Rect2(pos.x - 2, pos.y - 2, 1, 1), DrawUtil.GRAY)
		# --- glint: a brief 4-point star every ~2.5s (staggered per shard)
		var gt := fmod(t * 0.4 + ph * 0.13, 1.0)
		if gt < 0.08:
			var glint_length := 4.0 + (1.0 - gt / 0.08) * 6.0
			draw_rect(Rect2(pos.x - glint_length, pos.y - 0.5, glint_length * 2.0, 1), Color(DrawUtil.WHITE, 0.8))
			draw_rect(Rect2(pos.x - 0.5, pos.y - glint_length, 1, glint_length * 2.0), Color(DrawUtil.WHITE, 0.8))
		# --- orbiting spark in front
		for k in 2:
			var ang := t * 2.2 + ph + k * PI
			if sin(ang) >= 0.0:
				var sp: Vector2 = pos + Vector2(cos(ang) * 8.0, sin(ang) * 4.0 - 1.0)
				draw_rect(Rect2(roundf(sp.x), roundf(sp.y), 1, 1), DrawUtil.WHITE)
		# --- ground light: soft pool if the shard hangs near a floor
		draw_rect(Rect2(pos.x - 7, pos.y + 9, 14, 1), Color(DrawUtil.WHITE, 0.05 + pulse * 0.04))

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

func _draw_player(_t: float) -> void:
	if world.player != null:
		preload("res://scripts/spark_visual.gd").draw(self,world.player,world.player.visual_time)
