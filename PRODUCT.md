# WHITE SIGNAL

<!-- impeccable:product-schema 1 -->

## Platform

Desktop game made in Godot 4.7, for Windows first. Keyboard and gamepad. Earlier versions, including the first JavaScript one, are kept in git under the tag `legacy-archive`.

## Product Purpose

A classic Mario-style pixel platformer for ages 10 and up. A small spark of signal follows a dead line, gate by gate, to find out who is still calling. Levels are short and every one is proven finishable by a checker. Between worlds the player returns to Last Relay, a village whose people tell the story. The aim is dead simple to play and hard to master.

## Operating Context

Open `project.godot` with Godot 4.7 or later and run it. The game starts on the title screen (`scenes/title.tscn`). A new game plays a short story intro, then starts in Last Relay. The logical canvas is 480x270 and widens up to 720x270 on wide screens. Progress saves automatically to `user://w1_progress.json` and settings to `user://ws_settings.cfg`.

## Capabilities and Constraints

- Three worlds of four levels are built and proven: The Flats, The Switchyard and The Aerials. World 4, Dead Air, and the ending are planned.
- Moves: run, jump, wall kick, dash, stomp, drop through girders, and the Arc (an attack earned by clearing World 1).
- Lives, a 300-second timer per level, shards as currency at Tally's shop, 3 big shards hidden in most levels, one checkpoint per level.
- Last Relay has seven villagers with speech bubbles and voices, a shop, a radio shack and a switchboard for replaying levels.
- All music and sound is 8-bit, written as code for the NES's four voices. Every level has its own track.
- All art uses four greys, tinted per world, generated in code.
- Keys can be remapped. Settings cover music and effects volume, fullscreen, reduced flashing and camera shake.
- Text follows an upper middle-grade reading level (Flesch-Kincaid grade 5 to 6.5), with at most three lines per speech bubble.
- The earlier Classic card-draft run and exploration campaign stay in the code, reachable only from EXTRAS.

## Brand Commitments

Keep WHITE SIGNAL's four-grey pixel art, custom pixel lettering and relay-world words (the Spark, the line, relays, gates, Last Relay). From the intro on, the Spark is the only pure white thing in story scenes. Quiet, lonely and hopeful in tone, never grim.

## Evidence on Hand

`docs/GDD.md` is the current design. `docs/levels/` holds each world's design notes, and `docs/story/` holds the intro script, shot list and story arc. Every level has a proof (`levels/world*/*.proof.json`) and a map. The Godot tests are listed in `README.md`. `docs/research/title-screen-2026-09-26.md` backs the title screen design.

## Open Decisions

What big shards unlock, whether there is one caller or many, World 4's design, and the ending. See section 9 of `docs/GDD.md`.
