# Relay campaign implementation plan

**Goal:** Continue beyond the tutorial with two authored relays, readable exits, persistent builds, memory blocks and conduits.

**Architecture:** RunState owns the relay index and boundary saves. LevelData selects immutable layouts. World rebuilds its level children between relays while keeping HUD, camera and rendering layers. Interactive fixtures own block, conduit and dish feedback. New-run reset rebuilds pickups as well as threats.

**Tech Stack:** Godot 4.7, GDScript, headless integration tests.

1. Add failing campaign tests: tutorial exit is not a win; transition preserves deck; three dishes gate R1; deaths preserve dishes and consumed rewards; replay clears them; conduits move only on deliberate input; boundaries restore safely.
2. Add relay selection and authored R1/R2 layouts to scripts/level_data.gd. All compulsory routes work with no glyphs. Keep the existing tutorial geometry.
3. Extend scripts/run_state.gd with relay_clear / build_complete states, transition, boundary snapshot validation, and cumulative shard accounting. Keep legacy best scores separate.
4. Rebuild only level entities in scripts/world.gd; use the selected layout in renderer/background/props/HUD. Add scripts/relay_fixture.gd and ceiling collision handling in player.gd.
5. Add objective HUD, explicit next-relay input and continue/new-run controls. Use Down/S only for conduits in play.
6. Run the new integration suite, existing traversal suite, and capture the hub, fixtures and transition screen. Fix failures before copying the reviewed source back.
7. Update GDD to v8 with implemented/planned status, level sheets, anti-farming economy, Mario adaptations, baseline route requirement, and pacing risks. Do not claim five unbuilt relays exist.

Validation command: WS_TEST=1 WS_CAMPAIGN=1 Godot_v4.7.2-stable_win64.exe --headless --path <project>
