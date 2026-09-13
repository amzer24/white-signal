# Tutorial music and menu/settings verification

13 September 2026. The user's tutorial.wav is copied unchanged into assets/audio.
Its source hash and technical metadata are recorded in assets/audio/README.md.

Implemented: separate Music/SFX buses, persistent volume and fullscreen preferences,
R0-only full-track looping music, a compact selectable title menu, dedicated controls
and settings pages, and settings access from pause. Back returns to pause without
resuming gameplay. Preferences use user://ws_settings.cfg; campaign files are separate.

The 20 settings/audio state assertions passed, including independent mute, preference
reload, malformed volume fallback, keyboard adjustment, slider mute, title/pause
navigation, music continuity through death/resume, and byte-identical campaign saves
across settings changes. Existing Afterlight and campaign regression suites also passed.

Seven rendered/audio checks passed in the real Windows Compatibility renderer:
nonzero decoded Music-bus samples, endpoint looping, paused position stability,
resume continuity, stopping in R1, entering fullscreen and returning to windowed.
AudioEffectCapture observed a nonzero peak (~0.508 before master output); Master was
muted during this automated check to avoid playing the test aloud. This is signal
verification, not a subjective listening/mix review. The full composition loops;
musical seam editing was not requested or performed.

Menu/settings/controls captures were inspected at 960×540 and 1280×720. Both use
the existing 480×270 logical layout and pixel font. Fractional display scaling at
1280×720 retains the incumbent appearance; 960×540 is exact 2× scaling. The finish
review found no material visual issue; it requested game-local product documentation
because the enclosing workspace notes describe a different project.

Tests use res://test-user files for settings and campaign saves. Sandbox runs emitted
a certificate-store access warning, and some existing headless suites report teardown
ObjectDB warnings; no script parse failures remained. Native audio playback/loop and
fullscreen were checked separately from the accelerated headless state tests.

Reproduce with Godot 4.7.2:

```text
godot --headless --path . --fixed-fps 120 --script res://scripts/settings_test.gd
godot --path . --script res://scripts/settings_capture.gd
```

The capture helper writes to .impeccable/review and uses its own preference/save paths.
