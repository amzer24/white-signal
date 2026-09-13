# Stand mechanic foundation — 13 September 2026

The Observation Shelter and Stored Storm conductor bay connect the Field return and the restored Drowned pump house. Field arrival requires Dash before restoration; Drowned arrival requires its completed feeder. Neither puzzle route requires Air Jump. A latched storm bridge opens a return to the Field.

Charge takes three seconds and holds indefinitely. Diverting gives a 1.5 second steady warning in the marked channel, followed by a 0.35 second discharge. The sheltered controls are outside that channel. A completed discharge commits one permanent `stand_restored` flag and constructs the bridge. Death resets unfinished charge, and a failed completion save retains charge for retry. Completed bridges remain open after death and reload.

Reduced flash defaults on and persists in settings. It removes decorative lightning and uses a constant background illumination; the reservoir gauge, warning frame and discharge line remain. The title settings page and exploration pause's F shortcut expose it. Ambient weather uses its own clock, independent of charging. Map Tab switches between Field/Drowned and Stand pages.

## Worker contribution

OpenCode `opencode/mimo-v2.5-free`, session `ses_f67a8ac2bffeL2HsKTPBDNu5o3`, completed a generic art/sound brief at reported cost zero. No source files were supplied. Local review retained a 32px reservoir, positional lever/latch tells, steady live conduit and low sawtooth sounds. The proposed full-screen flashes, motor-stall flicker and flashing reduced-mode suggestion were rejected. No claim that the proposed sprite kit has been generated.

Production kit still needed: reservoir empty/filling/held poses; selector charge/divert poses; bridge motor idle/operating/latched; broken and restored conduits; latch bolt open/held; distant storm skyline. Current art is procedural. Local synthesized cues use low sawtooth tones; a final thunder/weather mix remains part of audio production.

State checks cover both arrival gates, retained charge, neutral reset, warning timing, permanent bridge and preferences reload. Actual movement checks cover the shelter climb, protected controls, waited charge, latched bridge crossing and return spawn. Captures of held charge, warning, discharge, bridge and map were rendered and inspected. Full campaign content, biome art, audio, accessibility and performance polish remain incomplete.
