# Stand ambient thunder

Original procedural sound, 1.2 seconds at 22050 Hz, mono 16-bit PCM. Deterministic low-pass noise, sparse high-frequency grain and low 43/67 Hz rumble with tapered onset/release. Cached per session, routed through existing SFX bus. Measured peak 7716/32767; exported without sample clipping. This measurement does not establish final mix quality.

Stand weather triggers once after the distant lightning phase, at 0.65 seconds in each nine-second cycle. No shared state with machine hazard timing. Reduced flashes continues to suppress lightning visuals while ambient sound obeys effects volume. No warning relies on thunder. Listening review and wider soundtrack mixing remain pending. Preview: test-user/distant-thunder.wav; exporter: scripts/thunder_capture.gd.

Also removed the obsolete bright horizontal line behind Broken Rim, which looked like a platform despite having no collision. Landmark and actual platforms remain.
