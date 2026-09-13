extends SceneTree
var at_seconds := 0.0
var recorded: Array = []
func _initialize() -> void: call_deferred("run")
func heard(node: Node) -> void:
    if node is AudioStreamPlayer:
        recorded.append({"at":at_seconds,"stream":node.stream})
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/cling-audition-%d.json" % OS.get_process_id()
    scene.save_path = path
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.enter_room("array_cable")
    var enemy = scene.noise_actor
    enemy.set_physics_process(false)
    scene.player.set_physics_process(false)
    scene.player.position = Vector2(enemy.position.x+40,217)
    root.get_node("Sfx").child_entered_tree.connect(heard)
    for i in 240:
        at_seconds = i/60.0
        enemy._physics_process(1.0/60.0)
    root.get_node("Sfx").child_entered_tree.disconnect(heard)
    var samples := PackedInt32Array()
    samples.resize(22050*4)
    for event in recorded:
        var stream: AudioStreamWAV = event.stream
        var offset := int(event.at*22050)
        for i in int(stream.data.size()/2.0):
            if offset+i < samples.size(): samples[offset+i] += stream.data.decode_s16(i*2)
    var bytes := PackedByteArray()
    bytes.resize(samples.size()*2)
    var peak := 0
    for i in samples.size():
        peak = maxi(peak,absi(samples[i]))
        bytes.encode_s16(i*2,clampi(samples[i],-32768,32767))
    var out := AudioStreamWAV.new()
    out.mix_rate = 22050
    out.format = AudioStreamWAV.FORMAT_16_BITS
    out.data = bytes
    print("CLING AUDITION cues=",recorded.size()," peak=",peak," clipped=",peak>32767)
    print("WAV RESULT ",out.save_to_wav("res://test-user/cling-cycle-audition.wav"))
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
