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
const SignScript := preload("res://scripts/sign_post.gd")

var player: CharacterBody2D
var cam: Camera2D
var gems: Array = []
var enemies: Array = []
var springs: Array = []
var crumbles: Array = []
var movers: Array = []

func _ready() -> void:
    _build_static()
    _build_entities()
    player = get_node("Player")
    cam = get_node("Camera")
    cam.limit_left = 0
    cam.limit_right = int(LevelData.DATA.width)
    cam.limit_top = -40
    cam.limit_bottom = 270
    RunState.respawned.connect(_on_respawn)
    RunState.banner.connect(_on_banner)
    # wire render + fx + hud layers (CanvasLayer wraps; Node2D draws)
    var bg_layer := CanvasLayer.new()
    bg_layer.name = "BackgroundLayer"
    bg_layer.layer = -1
    add_child(bg_layer)
    var bg := Node2D.new()
    bg.name = "Background"
    bg.set_script(load("res://scripts/background.gd"))
    bg_layer.add_child(bg)
    var fx := Node2D.new()
    fx.name = "FXLayer"
    fx.set_script(load("res://scripts/fx.gd"))
    add_child(fx)
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
    add_child(body)
    return body

func _build_static() -> void:
    for p in LevelData.DATA.platforms:
        _rect_body(p.r, p.type)
    for s in LevelData.DATA.spikes:
        var sp := Area2D.new()
        sp.set_script(SpikeScript)
        sp.position = Rect2(s.r).get_center()
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = Vector2(s.r.size.x - 4.0, s.r.size.y - 5.0)
        cs.shape = shape
        cs.position = Vector2(0, 2.5)
        sp.add_child(cs)
        add_child(sp)
    for sg in LevelData.DATA.signs:
        var node := Node2D.new()
        node.set_script(SignScript)
        node.position = sg.pos
        node.set_meta("text", sg.text)
        add_child(node)

func _build_entities() -> void:
    var player_scene := preload("res://scenes/player.tscn")
    player = player_scene.instantiate()
    player.name = "Player"
    player.position = Vector2(LevelData.DATA.spawn)
    add_child(player)

    for g in LevelData.DATA.gems:
        var gem := Area2D.new()
        gem.set_script(GemScript)
        gem.position = g
        add_child(gem)
        gems.append(gem)

    for e in LevelData.DATA.enemies:
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
        add_child(en)
        enemies.append(en)

    for s in LevelData.DATA.springs:
        var sp := Area2D.new()
        sp.set_script(SpringScript)
        sp.position = Rect2(s.r).get_center()
        sp.power = s.power
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = s.r.size
        cs.shape = shape
        sp.add_child(cs)
        add_child(sp)
        springs.append(sp)

    for c in LevelData.DATA.crumbles:
        var cr := StaticBody2D.new()
        cr.set_script(CrumbleScript)
        cr.position = Rect2(c.r).get_center()
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = c.r.size
        cs.shape = shape
        cr.add_child(cs)
        add_child(cr)
        crumbles.append(cr)

    for mv in LevelData.DATA.movers:
        var mo := AnimatableBody2D.new()
        mo.set_script(MoverScript)
        mo.position = Rect2(mv.r).get_center()
        mo.axis = mv.axis
        mo.travel_range = mv.range
        mo.osc_speed = mv.speed
        mo.phase = mv.phase
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = mv.r.size
        cs.shape = shape
        mo.add_child(cs)
        add_child(mo)
        movers.append(mo)

    for c in LevelData.DATA.checkpoints:
        var b := Node2D.new()
        b.set_script(BeaconScript)
        b.position = c.pos
        add_child(b)

    var goal := Area2D.new()
    goal.name = "Goal"
    goal.position = Rect2(LevelData.DATA.goal).get_center()
    var gcs := CollisionShape2D.new()
    var gshape := RectangleShape2D.new()
    gshape.size = LevelData.DATA.goal.size
    gcs.shape = gshape
    goal.add_child(gcs)
    goal.body_entered.connect(_on_goal_entered)
    add_child(goal)

func _on_goal_entered(body: Node) -> void:
    if body.is_in_group("player"):
        RunState.win()

func _on_respawn() -> void:
    if not is_inside_tree():
        return
    player.reset_at(RunState.checkpoint + Vector2(0, -7.0))
    for cr in crumbles:
        if is_instance_valid(cr):
            cr.heal()
    # world threat reset: dying re-forms every NOISE (kills stick per life)
    for en in enemies:
        if is_instance_valid(en):
            en.queue_free()
    enemies.clear()
    # defer re-spawn one frame: freed nodes must flush before re-adding
    await get_tree().physics_frame
    if is_inside_tree():
        _spawn_enemies()

func _spawn_enemies() -> void:
    for e in LevelData.DATA.enemies:
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
        add_child(en)
        enemies.append(en)

func _on_banner(t: String, s: String) -> void:
    var ui := get_tree().root.get_node_or_null("UI")
    if ui:
        ui.show_banner(t, s)

func _physics_process(delta: float) -> void:
    if RunState.state != "play":
        return
    # kill plane
    if player.global_position.y > LevelData.DATA.kill_y:
        RunState.register_death()
        return
    # camera: look-ahead + velocity lead, clamped (JS formula)
    # camera: JS cam = view TOP-LEFT; Godot Camera2D = view CENTER → +240/+135
    var tx := clampf(player.global_position.x + player.velocity.x * 0.25 + 40.0 * signf(player.velocity.x if absf(player.velocity.x) > 10.0 else 1.0) - 240.0, 0.0, LevelData.DATA.width - 480.0)
    cam.position.x += (tx + 240.0 - cam.position.x) * minf(1.0, delta * 6.0)
    var ty := clampf(player.global_position.y - 155.0, -40.0, 40.0)
    cam.position.y += (ty + 135.0 - cam.position.y) * minf(1.0, delta * 4.0)
    # gem pickup + magnet
    for g in gems:
        if is_instance_valid(g) and not g.collected \
                and g.global_position.distance_to(player.global_position) < float(RunState.mods.magnet_r):
            g.collect()
    RunState.update_zone(player.global_position.x)