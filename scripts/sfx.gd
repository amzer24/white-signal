extends Node
## Sfx autoload — square-wave synthesis (JS beep() port, WebAudio → AudioStreamWAV).

var _cache := {}

func beep(freq: float, dur := 0.07, vol := 0.06, type := "square") -> void:
	var key := "%s_%d_%d_%d" % [type, int(freq), int(dur * 1000.0), int(vol * 1000.0)]
	var stream: AudioStreamWAV = _cache.get(key)
	if stream == null:
		var rate := 22050
		var n := int(dur * rate)
		var data := PackedByteArray()
		data.resize(n * 2)
		for i in n:
			var phase := fmod(freq * float(i) / rate, 1.0)
			var v: float
			if type == "sawtooth":
				v = phase * 2.0 - 1.0
			else:
				v = 1.0 if phase < 0.5 else -1.0
			var env := 1.0 - float(i) / float(n)
			var s := int(clampf(v * env * vol * 4.0, -1.0, 1.0) * 32000.0)
			data.encode_s16(i * 2, s)
		stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = rate
		stream.data = data
		_cache[key] = stream
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func two(freq_a: float, freq_b: float, gap_ms := 90) -> void:
	beep(freq_a)
	get_tree().create_timer(gap_ms / 1000.0).timeout.connect(beep.bind(freq_b, 0.12))

func mechanism(kind: String) -> void:
	# Short, low-register machine phrases; all obey the existing effects bus.
	var notes: Array = {
		"valve": [[150.0,0.045],[95.0,0.08]],
		"part": [[196.0,0.055],[294.0,0.09]],
		"repair": [[98.0,0.07],[147.0,0.07],[196.0,0.14]],
		"reject": [[73.0,0.045],[65.0,0.08]],
		"hazard": [[110.0,0.06],[55.0,0.16]],
		"protocol": [[147.0,0.05],[220.0,0.05],[330.0,0.16]],
	}.get(kind,[[98.0,0.05]])
	for i in notes.size():
		var note: Array = notes[i]
		if i == 0: beep(note[0],note[1],0.035,"sawtooth")
		else: get_tree().create_timer(i*0.075).timeout.connect(beep.bind(note[0],note[1],0.035,"sawtooth"))

func thunder_stream() -> AudioStreamWAV:
	if _cache.has("distant_thunder"): return _cache["distant_thunder"]
	var rate := 22050
	var count := int(rate*1.2)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var random := RandomNumberGenerator.new()
	random.seed = 81427
	var low := 0.0
	var grain := 0.0
	for i in count:
		var t := float(i)/rate
		if i%3 == 0: grain = random.randf_range(-1,1)
		low = lerpf(low,grain,0.035)
		var envelope := minf(1,t/0.045)*pow(maxf(0,1-t/1.2),1.8)
		var rumble := sin(TAU*43*t)+0.45*sin(TAU*67*t)
		var sample := (low*0.65+rumble*0.07+grain*0.012)*envelope
		bytes.encode_s16(i*2,int(clampf(sample,-0.3,0.3)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	_cache["distant_thunder"] = stream
	return stream

func thunder() -> void:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = thunder_stream()
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
