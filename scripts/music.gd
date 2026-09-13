extends Node
## Scores follow the session, preserving playback across room changes and deaths.

var player: AudioStreamPlayer
var exploration_active := false
var track_id := ""

func _ready() -> void:
    player = AudioStreamPlayer.new()
    player.bus = "Music"
    add_child(player)
    RunState.state_changed.connect(_sync)
    RunState.relay_changed.connect(_new_relay)

func begin_exploration() -> void:
    exploration_active = true
    _sync(RunState.state)

func end_exploration() -> void:
    exploration_active = false
    player.stop()
    player.stream_paused = false

func _process(_delta: float) -> void:
    # Exploration map/pause state is assigned directly, without legacy signals.
    if exploration_active: _sync(RunState.state)

func _new_relay() -> void:
    player.stop()
    player.stream_paused = false

func _sync(state: String) -> void:
    var tutorial := not RunState.lab_active and RunState.relay_index == 0
    if (not exploration_active and not tutorial) or state in ["menu","loading","win","build_complete","lab_complete"]:
        player.stop()
        return
    var wanted := "exploration" if exploration_active else "tutorial"
    if wanted != track_id:
        player.stop()
        player.stream_paused = false
        if exploration_active:
            var track: AudioStreamOggVorbis = load("res://assets/audio/dead-carrier.ogg").duplicate()
            track.loop = true
            player.stream = track
            player.volume_db = -8.0 # Provisional cue-first mix, before user Music bus gain.
        else:
            var track: AudioStreamWAV = load("res://assets/audio/tutorial.wav").duplicate()
            track.loop_mode = AudioStreamWAV.LOOP_FORWARD
            track.loop_begin = 0
            track.loop_end = int(roundf(track.get_length()*track.mix_rate))
            player.stream = track
            player.volume_db = 0.0
        track_id = wanted
    if state in ["play","draft","relay_clear"]:
        player.stream_paused = false
        if not player.playing: player.play()
    elif state == "pause":
        player.stream_paused = true
