# Wire lift motor feedback

Scene-owned SFX AudioStreamPlayer follows actual lift movement. Half-second loop at 22050Hz uses 98/196/392Hz components quantized to 8-bit-style amplitude steps, with runtime gain -20dB and a short gain ramp. These frequencies contain whole cycles per loop. A low 98Hz arrival click plays once on reaching either dock. This is newly synthesized game audio, with no external sample source.

Map/pause freezes playback. Idle fades to silence; room exit frees the motor node; death resets without an arrival click. Effects mute/volume uses the existing SFX bus and is independent of music. No save data is added.

`motor_audio_test.gd`: 0 failures for idle, movement, pause position, resume, mute, single arrival, death and room exit using a disposable exploration profile. Resume observation waits for the node's process callback, rather than inspecting at the preceding SceneTree frame signal. These are lifecycle checks, not listening or mix verification.

`motor_audio_capture.gd` produces a three-second WAV at the intended -20dB source gain for audition. It omits the configurable SFX bus gain and does not simulate the fade envelope. Listening with the dark exploration music, speaker/headphone balance and final mix remain pending. The downloadable Wire ZIP predates this audio change.
