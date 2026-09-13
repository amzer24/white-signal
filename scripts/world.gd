extends Node2D
## World — builds every entity from LevelData and owns per-frame entity logic.

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const GemScript := preload("res://scripts/gem.gd")
const SpringScript := preload("res://scripts/spring.gd")
const CrumbleScript := preload("res://scripts/crumble.gd")
const MoverScript := preload("res://scripts/mover.gd")
const SpikeScript := preload("res://scripts/spike.gd")
const BeaconScript := preload("res://scripts/beacon.gd")

var level_root: Node2D
var fixtures: Array = []
var player: CharacterBody2D
var cam: Camera2D
var gems: Array = []
var enemies: Array = []
var springs: Array = []
var crumbles: Array = []
var movers: Array = []
var _respawn_gen := 0
var _look := 40.0  # smoothed face look-ahead (px)
var fx_node: Node2D

func _ready() -> void:
    cam = get_node("Camera")
    RunState.relay_changed.connect(_rebuild_level)
    _rebuild_level()
    cam.limit_left = 0
    cam.limit_right = int(RunState.level.width)
    cam.limit_top = -40
    cam.limit_bottom = 310  # JS cam.y clamps to +40 → view may look down into pits
    RunState.respawned.connect(_on_respawn)
    # wire render + fx + hud layers (CanvasLayer wraps; Node2D draws)
    var bg_layer := CanvasLayer.new()
    bg_layer.name = "BackgroundLayer"
    bg_layer.layer = -1
    add_child(bg_layer)
    var bg := Node2D.new()
    bg.name = "Background"
    bg.set_script(load("res://scripts/background.gd"))
    bg_layer.add_child(bg)
    var lab_layer := CanvasLayer.new()
    lab_layer.name = "AfterlightLayer"
    lab_layer.layer = -1
    add_child(lab_layer)
    var lab_view := Node2D.new()
    lab_view.name = "View"
    lab_view.set_script(load("res://scripts/afterlight_view.gd"))
    lab_layer.add_child(lab_view)
    var fx := Node2D.new()
    fx.name = "FXLayer"
    fx.set_script(load("res://scripts/fx.gd"))
    add_child(fx)
    fx_node = fx
    RunState.state_changed.connect(_on_state)
    var er := Node2D.new()
    er.name = "EntityRenderLayer"
    er.set_script(load("res://scripts/entity_render.gd"))
    add_child(er)
    er.set("world", self)
    var hud_layer := CanvasLayer.new()
    hud_layer.name = "HUDLayer"
    hud_layer.layer = 50
    add_child(hud_layer)
    var hud := Node2D.new()
    hud.name = "HUD"
    hud.set_script(load("res://scripts/hud.gd"))
    hud_layer.add_child(hud)
    # integration tests: WS_TEST=1 godot --headless
    if OS.get_environment("WS_TEST") == "1":
        var runner := Node.new()
        runner.set_script(load("res://scripts/test_runner.gd"))
        add_child(runner)
    # screenshot pass: WS_SHOT=1 (displayed or xvfb)
    if OS.get_environment("WS_SHOT") == "1":
        var sh := Node.new()
        sh.set_script(load("res://scripts/shot_runner.gd"))
        add_child(sh)

func _rect_body(r: Rect2, kind: String) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.position = r.get_center()
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = r.size
    cs.shape = shape
    body.add_child(cs)
    body.set_meta("kind", kind)
    body.set_meta("rect", r)
    body.set_meta("top", r.position.y)
    level_root.add_child(body)
    return body

func _build_static() -> void:
    for p in RunState.level.platforms:
        _rect_body(p.r, p.type)
    for s in RunState.level.spikes:
        var sp := Area2D.new()
        sp.set_script(SpikeScript)
        sp.position = Rect2(s.r).get_center()
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(s.r.size.x - 4.0, s.r.size.y - 5.0)
        cs.shape = shape
        cs.position = Vector2(0, 2.5)
        sp.add_child(cs)
        level_root.add_child(sp)

func _build_entities() -> void:
    var player_scene := preload("res://scenes/player.tscn")
    player = player_scene.instantiate()
    player.name = "Player"
    player.position = Vector2(RunState.level.spawn)
    level_root.add_child(player)

    for g in RunState.level.gems:
        var gem := Area2D.new()
        gem.set_script(GemScript)
        gem.position = g
        level_root.add_child(gem)
        gems.append(gem)

    for e in RunState.level.enemies:
        var en := CharacterBody2D.new()
        en.set_script(EnemyScript)
        en.position = Rect2(e.r).get_center()
        en.min_x = e.min_x
        en.max_x = e.max_x
        en.speed = e.speed
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = e.r.size
        cs.shape = shape
        en.add_child(cs)
        # JS fidelity: NOISE are non-solid (damage zones, not walls)
        en.collision_layer = 0
        en.collision_mask = 0
        level_root.add_child(en)
        enemies.append(en)

    for s in RunState.level.springs:
        var sp := Area2D.new()
        sp.set_script(SpringScript)
        sp.position = Rect2(s.r).get_center()
        sp.power = s.power
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = s.r.size
        cs.shape = shape
        sp.add_child(cs)
        level_root.add_child(sp)
        springs.append(sp)

    for c in RunState.level.crumbles:
        var cr := StaticBody2D.new()
        cr.set_script(CrumbleScript)
        cr.position = Rect2(c.r).get_center()
        cr.size = c.r.size
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = c.r.size
        cs.shape = shape
        cr.add_child(cs)
        level_root.add_child(cr)
        crumbles.append(cr)

    for mv in RunState.level.movers:
        var mo := AnimatableBody2D.new()
        mo.set_script(MoverScript)
        mo.position = Rect2(mv.r).get_center()
        mo.size = mv.r.size
        mo.axis = mv.axis
        mo.travel_range = mv.range
        mo.osc_speed = mv.speed
        mo.phase = mv.phase
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = mv.r.size
        cs.shape = shape
        mo.add_child(cs)
        level_root.add_child(mo)
        movers.append(mo)

    for c in RunState.level.checkpoints:
        var b := Node2D.new()
        b.set_script(BeaconScript)
        b.position = c.pos
        level_root.add_child(b)

    var goal := Area2D.new()
    goal.name = "Goal"
    goal.position = Rect2(RunState.level.goal).get_center()
    var gcs := CollisionShape2D.new()
    var gshape := RectangleShape2D.new()
    gshape.size = RunState.level.goal.size
    gcs.shape = gshape
    goal.add_child(gcs)
    goal.body_entered.connect(_on_goal_entered)
    level_root.add_child(goal)

func _on_goal_entered(body: Node) -> void:
    if body.is_in_group("player"):
        RunState.win()

func _on_state(s: String) -> void:
    if s == "draft" and fx_node:
        fx_node.shake(3.0)  # surge flash + shake (GDD §11)

func _on_respawn() -> void:
    if not is_inside_tree():
        return
    if RunState.state == "play" and fx_node:
        fx_node.burst(player.global_position, 14)
        fx_node.shake(5.0)
    player.reset_at(RunState.checkpoint + Vector2(0, -7.0))
    for cr in crumbles:
        if is_instance_valid(cr):
            cr.heal()
    # world threat reset: dying re-forms every NOISE (kills stick per life)
    for en in enemies:
        if is_instance_valid(en):
            en.queue_free()
    enemies.clear()
    # defer re-spawn one frame: freed nodes must flush before re-adding.
    # Generation guard: two deaths before the frame flips must not double-spawn.
    _respawn_gen += 1
    var gen := _respawn_gen
    await get_tree().physics_frame
    if is_inside_tree() and gen == _respawn_gen:
        _spawn_enemies()

func _spawn_enemies() -> void:
    for e in RunState.level.enemies:
        var en := CharacterBody2D.new()
        en.set_script(EnemyScript)
        en.position = Rect2(e.r).get_center()
        en.min_x = e.min_x
        en.max_x = e.max_x
        en.speed = e.speed
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = e.r.size
        cs.shape = shape
        en.add_child(cs)
        en.collision_layer = 0
        en.collision_mask = 0
        level_root.add_child(en)
        enemies.append(en)

func _physics_process(delta: float) -> void:
    # shake decays even while paused so it never sticks
    if fx_node:
        fx_node.shake_amt = maxf(0.0, fx_node.shake_amt - delta * 20.0)
        var s: float = fx_node.shake_amt if AppSettings.camera_shake else 0.0
        cam.offset = Vector2(roundf(randf_range(-0.5, 0.5) * s), roundf(randf_range(-0.5, 0.5) * s)) if s > 0.0 else Vector2.ZERO
    if not RunState.sim_active():
        return
    # kill plane
    if player.global_position.y > RunState.level.kill_y:
        RunState.register_death()
        return
    # camera: look-ahead + velocity lead, clamped. The face lead is smoothed
    # (not snapped) and the velocity lead trimmed so a turn-around doesn't
    # throw the view ~150px; JS cam = view TOP-LEFT, Camera2D = CENTER → +240/+135
    _look += (40.0 * float(player.face) - _look) * minf(1.0, delta * 2.5)
    var tx := clampf(player.global_position.x + player.velocity.x * 0.15 + _look - 240.0, 0.0, RunState.level.width - 480.0)
    cam.position.x += (tx + 240.0 - cam.position.x) * minf(1.0, delta * 6.0)
    var ty := clampf(player.global_position.y - 155.0, -40.0, 40.0)
    cam.position.y += (ty + 135.0 - cam.position.y) * minf(1.0, delta * 4.0)
    # gem pickup + magnet
    for g in gems:
        if RunState.state != "play": break
        if is_instance_valid(g) and not g.collected \
                and g.global_position.distance_to(player.global_position) < float(RunState.mods.magnet_r):
            if fx_node:
                fx_node.burst(g.global_position, 9)
            Sfx.beep(880.0 + float(RunState.gems + 1) * 40.0, 0.09)
            g.collect()
    RunState.update_zone(player.global_position.x)
func _rebuild_level() -> void:
    _respawn_gen += 1
    if is_instance_valid(level_root):
        remove_child(level_root)
        level_root.queue_free()
    level_root = Node2D.new()
    level_root.name = "Relay"
    add_child(level_root)
    gems.clear()
    enemies.clear()
    springs.clear()
    crumbles.clear()
    movers.clear()
    fixtures.clear()
    _build_static()
    _build_entities()
    for item in RunState.level.get("fixtures", []):
        var f := StaticBody2D.new()
        f.set_script(load("res://scripts/relay_fixture.gd"))
        f.kind = item.kind
        f.fixture_id = item.id
        f.position = item.pos
        f.destination = item.destination
        level_root.add_child(f)
        fixtures.append(f)
    player.reset_at(RunState.level.spawn)
    cam.limit_right = int(RunState.level.width)
    snap_camera()
    var er := get_node_or_null("EntityRenderLayer")
    if er:
        er.props.place_all()
        er._tex_cache.clear()

func snap_camera() -> void:
    _look = 40.0
    cam.position = Vector2(clampf(player.position.x + 40.0, 240.0, RunState.level.width - 240.0), 135)
    cam.reset_smoothing()
