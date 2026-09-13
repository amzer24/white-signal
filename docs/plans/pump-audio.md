# Pump running feedback

The repaired pump now has a scene-owned, low-register synthesized motor loop.
It plays only in the Pump House after the saved `pump_repaired` flag exists.
Map and pause suspend the same playback; leaving the room stops it. The SFX bus
controls its volume. The pump's rotating impeller and status lamp remain the
sound-off equivalents.

The one-second mono waveform combines 55, 110 and 165 Hz with 4 Hz amplitude
modulation and quantized amplitude. Whole cycles close the boundary. Runtime
gain is -24 dB; this is a provisional environmental mix, not an audition-approved
final level. No external recording or third-party sample is used.

`pump_motor_test.gd` passes repair gating, pause/resume identity, room exit and
return, teardown, nonzero/nonclipping source waveform and endpoint checks. It
does not establish perceptual loop quality, masking by music, or speaker quality.
