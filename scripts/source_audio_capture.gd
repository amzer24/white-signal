extends SceneTree
var at_seconds := 0.0
var recorded: Array = []
func _initialize() -> void: call_deferred("run")
func heard(node: Node) -> void:
    if node is AudioStreamPlayer:
        recorded.append({"at":at_seconds,"stream":node.stream})
func run() -> void:
    var scene = load("res://scenes/exploration.tscn").instantiate()
    var path := "res://test-user/source-audition-%d.json" % OS.get_process_id()
    scene.save_path = path
    root.add_child(scene)
    scene.set_physics_process(false)
    for flag in ["field_restored","stand_restored","drowned_restored","array_restored","gate_latched"]: scene.profile.set_flag(flag)
    scene.enter_room("source_return")
    root.get_node("Sfx").child_entered_tree.connect(heard)
    scene.gate.use("gate_isolate")
    for i in 4:
        at_seconds = 0.25+(i+1)*0.375
        scene.gate.tick(0.375)
    at_seconds = 3.0
    scene.gate._result("save_failed")
    root.get_node("Sfx").child_entered_tree.disconnect(heard)
    var samples := PackedInt32Array()
    samples.resize(22050*4)
    for event in recorded:
        var stream: AudioStreamWAV = event.stream
        var offset := int(event.at*22050)
        for i in stream.data.size()/2:
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
    print("SOURCE AUDITION cues=",recorded.size()," peak=",peak," clipped=",peak>32767)
    print("WAV RESULT ",out.save_to_wav("res://test-user/source-repair-audition.wav"))
    scene.queue_free()
    await process_frame
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(path+suffix)
    quit()
