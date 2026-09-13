extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var stream: AudioStreamWAV = root.get_node("Sfx").thunder_stream()
    var peak := 0
    for i in stream.data.size()/2: peak = maxi(peak,absi(stream.data.decode_s16(i*2)))
    var result := stream.save_to_wav("res://test-user/distant-thunder.wav")
    print("THUNDER: seconds=",stream.get_length()," peak=",peak," export=",result)
    quit(0 if result == OK and peak > 0 and peak < 32767 else 1)
