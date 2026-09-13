extends Node2D
## Particle system — port of JS burst()/dust(): white→gray fading squares.

var parts: Array = []
var shake_amt := 0.0

## screen shake request (JS `shake = max(shake, v)`), decays 20/s in world.gd
func shake(v: float) -> void:
	shake_amt = maxf(shake_amt, v)

func _ready() -> void:
	add_to_group("fx")
	z_index = 20

func burst(at: Vector2, n := 8, spread := 160.0) -> void:
	for i in n:
		parts.append({
			"p": at, "v": Vector2(randf_range(-0.5, 0.5) * spread, -randf() * 140.0 - 20.0),
			"life": 0.4 + randf() * 0.35, "t": 0.0, "s": 1 if randf() < 0.6 else 2,
		})

func dust(at: Vector2, n := 4) -> void:
	for i in n:
		parts.append({
			"p": at + Vector2(randf_range(-4.0, 4.0), -randf() * 2.0),
			"v": Vector2(randf_range(-0.5, 0.5) * 70.0, -randf() * 40.0),
			"life": 0.3 + randf() * 0.2, "t": 0.0, "s": 1,
		})

func trail(at: Vector2, vx: float) -> void:
	parts.append({"p": at, "v": Vector2(-vx * 30.0, 0), "life": 0.25, "t": 0.0, "s": 2})

func _physics_process(delta: float) -> void:
	if not RunState.sim_active():
		return
	var alive: Array = []
	for p in parts:
		p.t += delta
		if p.t < p.life:
			p.p += p.v * delta
			p.v.y += 500.0 * delta
			alive.append(p)
	parts = alive
	queue_redraw()

func _draw() -> void:
	for p in parts:
		var col := DrawUtil.WHITE if p.t < p.life / 2.0 else DrawUtil.GRAY
		draw_rect(Rect2(p.p - Vector2(p.s / 2.0, p.s / 2.0), Vector2(p.s, p.s)), col)