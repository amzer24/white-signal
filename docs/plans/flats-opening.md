# Flats opening foundation

New exploration profiles now begin in three tutorial rooms: Flats, Maintenance Conduit and First Receiver. Existing v1 saves retain their room, visited map and abilities; no forced restart or schema conversion is needed. The hub has a return to the Flats.

The opening offers a real ceiling-strike memory block, a two-way contextual conduit around a solid barrier, and a restored beacon that becomes the local respawn anchor. The conduit must be used before its arrival exit opens, and the beacon must be restored before entering the Field. The map has a Flats page; tutorial-room JSON is parsed once and cached rather than read repeatedly during map drawing.

OpenCode `opencode/mimo-v2.5-free`, session `ses_f679002c1ffer6cK8O65NKU4Wf`, drafted the three independent room records at reported cost zero without receiving project source. Local review added its omitted floor rectangles, adjusted low optional platforms, added the actual tunnel barrier/return and integrated the typed room loader. `white-signal-team/prepare_flats.py` preserves that transformation from the recorded worker output.

Controller/state checks cover new-game start, memory collision, both tunnel directions, beacon access/respawn, hub arrival and old-save compatibility. Exploration save/map, Field, Drowned, Stand and existing settings/audio regression checks pass. Room and map captures were inspected. The music integration and final biome art pass remain incomplete; the existing classic tutorial WAV has not been replaced.

Next campaign construction: Wire and Array, then Approach/Gate and the revisitable aftermath. The current rooms are mechanics foundations and still require broader level-design, art, effects, audio, accessibility and release verification.
