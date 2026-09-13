extends SceneTree
func _initialize() -> void:
    var stream = load("res://scripts/mechanism_motor.gd").motor_stream()
    var samples: PackedByteArray = stream.data
    var repeated := PackedByteArray()
    for repeat in 6:
        for i in samples.size()/2:
            var sample := samples.decode_s16(i*2)
            var at := repeated.size()
            repeated.resize(at+2)
            repeated.encode_s16(at,int(sample*0.1))
    stream.data = repeated
    stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    print("AUDITION WAV: ",stream.save_to_wav("res://test-user/wire-motor-audition.wav"))
    quit()
