extends Node2D
## All lighting stays behind the collision scene; required edges are never masked.

const ART_ROOT := "res://assets/backgrounds/afterlight-v2/"
const LIGHT_SHADER := preload("res://shaders/afterlight.gdshader")
const MEMORY_SECONDS := 6.0
var memory_left := 0.0
var memory_origin := Vector2.ZERO
var clock := 0.0
var layers: Array = []
var materials: Array[ShaderMaterial] = []
var marks := [Vector2(340,230), Vector2(1110,230), Vector2(1710,230)]
var layer_layout := [
    {"asset":"far-terrain.png", "speed":0.12,"size":Vector2(960,320),"y":-75.0,"ceiling":0.19},
    {"asset":"mid-ruins.png", "speed":0.28,"size":Vector2(768,256),"y":20.0,"ceiling":0.25},
    {"asset":"near-cables-straight.png", "speed":0.48,"size":Vector2(960,320),"y":-20.0,"ceiling":0.14},
]

func _ready() -> void:
    RunState.memory_triggered.connect(_remember)
    RunState.relay_changed.connect(_reset)
    for spec in layer_layout:
        var sprite := Sprite2D.new()
        sprite.texture = load(ART_ROOT + spec.asset)
        sprite.centered = false
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.scale = Vector2(spec.size) / sprite.texture.get_size()
        var mat := ShaderMaterial.new()
        mat.shader = LIGHT_SHADER
        mat.set_shader_parameter("logical_size",spec.size)
        mat.set_shader_parameter("ceiling",spec.ceiling)
        sprite.material = mat
        add_child(sprite)
        layers.append(sprite)
        materials.append(mat)
        # One adjacent copy covers the 480px view: every period is at least 768px.
        # Copy exactly the scaled period; do not mirror or crossfade the artwork.
        var next := Sprite2D.new()
        next.texture = sprite.texture
        next.centered = false
        next.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        next.material = mat
        next.position.x = sprite.texture.get_width()
        sprite.add_child(next)
    # Drawing node after sprites keeps memory silhouettes visible above the art.
    var details := Node2D.new()
    details.draw.connect(_draw_details.bind(details))
    details.name = "Memories"
    add_child(details)

func _reset() -> void:
    memory_left = 0.0
    clock = 0.0

func _remember(at: Vector2) -> void:
    memory_origin = at
    memory_left = MEMORY_SECONDS

func reveal_strength() -> float:
    var elapsed := MEMORY_SECONDS - memory_left
    var attack := 0.8 if RunState.lab_gentle else 0.35
    return smoothstep(0.0,attack,elapsed) * smoothstep(0.0,1.6,memory_left)

func _process(delta: float) -> void:
    visible = RunState.lab_active
    if not visible: return
    if RunState.sim_active():
        clock += delta
        memory_left = maxf(0.0,memory_left-delta)
    var cam := get_viewport().get_camera_2d()
    var cx := cam.position.x - 240.0
    var cy := cam.position.y - 135.0
    var player := get_tree().get_first_node_in_group("player")
    var lamp := lamp_position()
    var beacons := Vector4(-1000,-1000,-1000,-1000)
    for i in mini(4,RunState.lit_beacons.size()):
        beacons[i] = RunState.lit_beacons[i].x - cx
    for i in layers.size():
        var sprite: Sprite2D = layers[i]
        var spec: Dictionary = layer_layout[i]
        # Round before wrapping so both sides of a reset stay on the pixel grid.
        var x := -fposmod(roundf(cx*float(spec.speed)),Vector2(spec.size).x)
        sprite.position = Vector2(roundf(x),roundf(float(spec.y)-cy*float(spec.speed)))
        sprite.visible = RunState.lab_generated
        materials[i].set_shader_parameter("mode",float(RunState.lab_mode))
        materials[i].set_shader_parameter("reveal",reveal_strength())
        materials[i].set_shader_parameter("memory_at",memory_origin-Vector2(cx,cy))
        materials[i].set_shader_parameter("player_at",player.position-Vector2(cx,cy))
        materials[i].set_shader_parameter("lamp_at",lamp-Vector2(cx,cy))
        materials[i].set_shader_parameter("beacon_x",beacons)
    get_node("Memories").queue_redraw()

func lamp_position() -> Vector2:
    return Vector2(1210 + (0.0 if RunState.lab_gentle else sin(clock*0.55)*100.0),72)

func _draw_details(n: Node2D) -> void:
    if not RunState.lab_active: return
    var cam := get_viewport().get_camera_2d()
    var offset := cam.position-Vector2(240,135)
    var strength := reveal_strength()
    for mark in marks:
        var at: Vector2 = (mark-offset).round()
        var local_reveal := strength * (1.0-smoothstep(160.0,410.0,absf(mark.x-memory_origin.x)))
        # One persistent empty chair; the person and live screen are only memories.
        n.draw_rect(Rect2(at.x-13,at.y-26,3,25),Color("262626"))
        n.draw_rect(Rect2(at.x-13,at.y-14,14,3),Color("262626"))
        n.draw_rect(Rect2(at.x+10,at.y-31,34,3),Color("303030"))
        n.draw_rect(Rect2(at.x+35,at.y-29,3,29),Color("262626"))
        n.draw_rect(Rect2(at.x+15,at.y-49,18,15),Color("202020"))
        if local_reveal > 0.01:
            var glow := Color(0.30,0.30,0.30,local_reveal)
            n.draw_rect(Rect2(at.x+17,at.y-47,14,10),glow)
            n.draw_rect(Rect2(at.x-7,at.y-43,7,7),glow)
            n.draw_rect(Rect2(at.x-9,at.y-34,10,17),glow)
            n.draw_line(at+Vector2(1,-27),at+Vector2(14,-30),glow,2)
            for k in 4:
                n.draw_rect(Rect2(at.x-55+k*25,at.y-105,10,18),Color(0.24,0.24,0.24,local_reveal))
    for beacon in RunState.lit_beacons:
        var at: Vector2 = (beacon-offset).round()
        for i in 3:
            n.draw_rect(Rect2(at.x-12+i*13,at.y-95,7,13),Color("555555"))
            n.draw_line(Vector2(at.x-9+i*13,at.y-95),Vector2(at.x-9+i*13,at.y-82),Color("303030"))
    # The lamp's rhythm is visual, not a timer that hides safe ground.
    var lamp := (lamp_position()-offset).round()
    n.draw_line(Vector2(1070-offset.x,45-offset.y),Vector2(1360-offset.x,45-offset.y),Color("3a3a3a"))
    n.draw_line(Vector2(lamp.x,45-offset.y),lamp,Color("3a3a3a"))
    n.draw_rect(Rect2(lamp.x-9,lamp.y,18,4),Color("555555"))
    n.draw_rect(Rect2(lamp.x-5,lamp.y+4,10,2),Color("777777"))
