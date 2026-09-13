# WHITE SIGNAL

<!-- impeccable:product-schema 1 -->

## Platform

Desktop Godot game. This directory is the active Godot 4.7 project; `js-original/` is the playable JavaScript feel reference and design specification. The enclosing workspace's Sprite Studio web documentation does not describe this game.

## Product Purpose

An exploration-first pixel platformer about repairing a collapsed relay network. Permanent abilities, discovered rooms, local repairs and return routes persist. The separate Classic mode retains the original shard/glyph draft-run design. The Signal represents coherence; restoring the network reconnects places and reveals traces of the Operators.

## Operating Context

Open `project.godot` with Godot 4.7+ and run `scenes/main.tscn`. The game uses a 480×270 logical canvas with nearest-neighbor texture filtering and canvas scaling. Keyboard, mouse menu input and gamepad mappings are implemented. Physical controller verification and remapping remain outstanding.

The title offers Start/Resume Exploration, Resume Classic when a relay-boundary save exists, New Classic Run, Settings, How to Play and Afterlight. Exploration displays the saved room and resumes permanent discoveries. Classic resumes at a relay boundary; starting Classic does not replace the exploration profile. Map: M/Y, district: Tab/LB, legend: H/X. Settings are available from the title and exploration pause screen.

## Capabilities and Constraints

- Exploration connects Flats, Field, Drowned, Stand, Wire/Array and the Source, with saved restoration, aftermath and revisits. Drowned and Stand have seven-room expansions; optional Siphon, Array inspection and Wire maintenance-shaft branches are implemented. Overall biome breadth, art, encounter roster and pacing are unfinished. The design atlas remains a plan, not shipped scope.
- The Wire shaft supports base wall-kick ascent, transactional archive/release, a recallable service lift, interior relighting, motor feedback and a replayable Operator memory. The Array inspection bay introduces a patroller with dash, stomp and avoidance routes.
- Classic preserves the original relay/draft framework. It is a separate mode, not the progression model for exploration.
- Afterlight, titled THE ROOM REMEMBERS, is an optional lighting study with three replayable memories. It preserves the campaign boundary and is not another finished campaign relay.
- Exploration currently uses a provisional dark Dead Carrier loop; listening and mixing remain pending. The supplied `assets/audio/tutorial.wav` is the Classic tutorial score. It loops during R0, continues through death/respawn, pauses and resumes with the run, and stops when leaving R0 for R1. It does not score Afterlight. Runtime loop configuration is applied to a duplicated audio resource; the supplied source is unchanged.
- Music and effects have separate volume controls, with zero muting the corresponding bus. Defaults are 65% music and 80% effects. Fullscreen can be changed in Settings or with F11.
- Preferences persist through Godot ConfigFile at `user://ws_settings.cfg`, separately from campaign progress. Changes apply immediately; the settings page reports a save failure when persistence fails.

## Brand Commitments

Preserve WHITE SIGNAL's established monochrome pixel-art identity, custom pixel lettering, and relay-world terminology. Menu additions extend that incumbent style.

## Evidence on Hand

`docs/plans/RELEASE-GATES.md` records incomplete release requirements and scoped evidence. Recent `docs/plans/*` records distinguish installed functionality from prototypes and older packages. `README.md` contains run instructions but historical scope descriptions must be checked against those current records. `js-original/GDD.md` contains the broader game design. `scripts/menu_ui.gd`, `scripts/app_settings.gd`, `scripts/music.gd`, and `scripts/draw_util.gd` define the shipped menu, preferences, score lifecycle, and drawing vocabulary. See `docs/UI.md` for the observed menu/settings design and its reference captures.

## Open Decisions

Audience demographics and a formal accessibility standard have not been established in this scope. Planned campaign content is not a shipped capability.
