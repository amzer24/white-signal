# East Causeway foundation

Adds a second Field loop: Hub → East Causeway → Counterweight Return → Hub. The causeway is reachable without a traversal upgrade. Three platform-mounted controls turn dish arms to match fixed etched sight lines. Testing the receiver before alignment gives feedback without consuming anything. Correct alignment latches the east ear and opens both sides of the causeway return. Death resets unfinished alignment but preserves the completed ear; reload reconstructs its locked poses.

The standalone `signal_alignment.gd` draft came from OpenCode `opencode/mimo-v2.5-free`, session `ses_f67a08f9dffezFYKar0YHsf1XV`, reported cost zero. No project files were sent. Local review removed the unnecessary global class registration and verified invalid indices, wraparound, failed latching, reset and locked behaviour. Root implemented the room, rendering and persistence integration.

Godot checks pass for actual movement to every dial and the receiver with base abilities, early locked exit, completed exit, death/reload persistence and return spawn. Exploration, Drowned and Stand state regressions pass. Initial/restored room and map captures were inspected. This is the first alignment implementation, not the final puzzle-depth or art pass.

Remaining Field work includes the south intake brick interaction, transmitter sump's three-ear completion, the optional Fourth Dish archive and full arrival/Flats route. Completing the east ear alone does not complete the Field feeder or the full game.
