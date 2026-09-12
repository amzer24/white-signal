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
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func two(freq_a: float, freq_b: float, gap_ms := 90) -> void:
	beep(freq_a)
	get_tree().create_timer(gap_ms / 1000.0).timeout.connect(beep.bind(freq_b, 0.12))