extends AudioStreamPlayer
## Scene-owned machine loop. Parameters are read from its parent world's shaft.
var moving := false
var arrivals := 0
func _ready() -> void:
    bus = "SFX"
    volume_db = -60
    stream = motor_stream()
static func motor_stream() -> AudioStreamWAV:
    var rate := 22050
    var count := rate/2
    var bytes := PackedByteArray()
    bytes.resize(count*2)
    for i in count:
        var t := float(i)/rate
        var wave := 0.16*sin(TAU*98*t)+0.035*sin(TAU*196*t)+0.02*sin(TAU*392*t)
        var sample := roundf(wave*127)/127
        bytes.encode_s16(i*2,int(sample*32767))
    var audio := AudioStreamWAV.new()
    audio.format = AudioStreamWAV.FORMAT_16_BITS
    audio.mix_rate = rate
    audio.data = bytes
    audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
    audio.loop_begin = 0
    audio.loop_end = count
    return audio
func _process(delta: float) -> void:
    var world = get_parent()
    if world.room_id != "wire_shaft":
        stop()
        moving = false
        return
    stream_paused = world.paused or world.map_open
    if stream_paused: return
    var requested: bool = not is_equal_approx(world.network.shaft.y,world.network.shaft.target)
    if moving and not requested:
        arrivals += 1
        Sfx.beep(98,0.065,0.018,"sawtooth")
    moving = requested
    if moving and not playing: play()
    volume_db = move_toward(volume_db,-20.0 if moving else -60.0,delta*500)
    if not moving and volume_db <= -60: stop()
