extends AudioStreamPlayer
## Quiet scene-owned pump; all component frequencies complete whole loop cycles.
func _ready() -> void:
    bus = "SFX"
    volume_db = -24
    stream = make_stream()

static func make_stream() -> AudioStreamWAV:
    var rate := 22050
    var bytes := PackedByteArray()
    bytes.resize(rate*2)
    for i in rate:
        var t := float(i)/rate
        var rotor := 0.72+0.28*cos(TAU*4*t)
        var wave := (0.14*sin(TAU*55*t)+0.035*sin(TAU*110*t)+0.018*sin(TAU*165*t))*rotor
        bytes.encode_s16(i*2,int(roundf(wave*127)/127*32767))
    var audio := AudioStreamWAV.new()
    audio.format = AudioStreamWAV.FORMAT_16_BITS
    audio.mix_rate = rate
    audio.data = bytes
    audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
    audio.loop_begin = 0
    audio.loop_end = rate
    return audio

func _process(_delta: float) -> void:
    var world = get_parent()
    if world.exiting or world.room_id != "pump" or not world.profile.has_flag("pump_repaired"):
        stop()
        return
    stream_paused = world.paused or world.map_open
    if stream_paused: return
    if not playing: play()
