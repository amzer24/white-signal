# Direction review: mission clarity, enemies, and what PixelLab can add (16 Sep 2026)

Three questions from play-testing: *why is the mission still unclear*, *how should enemies work*, and *what more can the paid PixelLab account do for us*. This note records what the best 2D games actually do, what was changed in-game today, and a ranked plan for the rest.

## 1. Why the mission felt unclear (and what changed today)

The story study (`research/exploration/notes/story-arc.md`) is good, but almost none of it reached the screen. A player saw: a room title, a jargon goal line, and doors. Nothing ever said "there are four districts" or "this is district 2".

What the best exploration games do:

| Game | Technique | Lesson |
|---|---|---|
| Hollow Knight | Area title card on entering a region; map bought per area; NPCs restate the immediate goal in one line | Name the place, then name the job. The card is the moment the player re-orients. |
| Ori | Objective marker plus a one-sentence objective on the map screen at all times | The map is where players go when lost; the mission must be written there. |
| Metroid Dread | ADAM briefings: two sentences, what and why, at every checkpoint | Restate the mission at every natural pause. |
| Outer Wilds | Ship log: discoveries phrased as plain observations, with "there's more to find here" | Progress is shown as *knowledge*, never as a quest list of verbs. |
| Tunic | Essential info is placed beside the machinery you operate | Don't hide the answer in optional archives. |

Shipped today (`scripts/exploration_world.gd`):

- **Story intro** on a fresh save: the relay is dead, one receiver is still calling, you are the Spark; mission = fix four districts (named) then the Gate.
- **District cards** on every biome change (`BANNER`): "THE DROWNED — DISTRICT 2 OF 4 . DRAIN THE STREET . RESTART THE PUMP". 3.2 s, fades, never blocks input.
- **`mission_line()`** on the map screen and the pause screen: which districts are left, or "go to the Gate".
- **Progress strip** in the top bar (FIELD / DROWNED / STAND / ARRAY lights up).
- **Plain-language goals** for all 39 rooms (`exploration_guidance.gd`, done earlier today).

Still missing, in order of value:

1. **A ship-log style LOG page** on the map (Tab cycles regions; add a LOG tab): one plain sentence per discovery ("The Field's silence was chosen — someone closed that handle on purpose"). This is where the *why* of the story lives without cutscenes. Data already exists as flags; it needs ~40 lines of text.
2. **The answering window beat** must be unmissable: after the first beacon, hold the camera on the lit window for 1.5 s with the line "SOMETHING ANSWERED . GO THERE". Currently it is a subtle light change.
3. **The Array demonstration** (the story midpoint) needs its two lamps labelled HEALTHY / FAULT on screen so the lesson ("isolation contains a fault") is literally readable.
4. **An end card** at aftermath: who answered, what the Spark changed. Three lines.

## 2. Enemies: what the best 2D games do, and the WHITE SIGNAL answer

Current state: two NOISE routines exist (patroller in `array_inspection`, CLING dropper in `array_cable`), both in optional rooms. The critical path has no enemies at all, so the world feels inert and the dash/stomp verbs are never taught. The GDD's own line is right: **NOISE are patterns, not monsters**.

Principles worth stealing:

| Game | What it does | Apply as |
|---|---|---|
| Celeste | No "enemies" — hazards with perfect readability, instant respawn, death is a 1-second cost | Keep one-hit + instant room reset. Death must never cost more than the room. |
| Hollow Knight | Every enemy has a 2–3 frame telegraph; enemies are part of the region's ecology; first meeting is always in a safe, wide room | Every NOISE gets a visible wind-up and a "safe first observation" ledge. |
| Rain World | Creatures have routines and their own business; you learn the routine, not a health bar | NOISE variants are *routines* tied to machinery (cycling shutters, dripping charge). |
| Inside / Limbo | The chase is the enemy; silhouettes only; no HUD | One chase set-piece per district at most, silhouette-readable in four greys. |
| Downwell | One verb (gunboots) with deep consequences; stomping is movement | Stomp chains (STOMP+ in the GDD) — bouncing off NOISE is traversal, not combat. |
| Metroid | Enemies gate nothing; abilities gate. Enemies exist to make movement expressive | Never lock a door behind a kill. Dash kills NOISE because dash is fun, not because kills matter. |

### The NOISE roster (patterns, not monsters)

All 14×18, one-hit contact, die to DASH and stomp, re-form on death because NOISE is a channel condition (already the fiction). Each has a *tell*, a *routine*, and a *machine it belongs to*.

| Name | District | Routine | Tell | Answer |
|---|---|---|---|---|
| **DRIFT** (exists: patroller) | Field halls | Walks a ledge, turns at edges | Inner bars contract before a turn | Jump over, or dash through |
| **CLING** (exists) | Array cable gallery | Hangs, drops when you pass under, climbs back | Dashed guide + floor bracket 0.65 s | Bait then pass, or stomp while grounded |
| **SURGE** (new) | Stand | Runs along a live cable when the conductor is discharging; harmless while the reservoir is charging | Cable glows in 3 pulses first | Wait for the cycle (ties to the Stand's timer fiction) |
| **BLOOM** (new) | Drowned | Static that grows on wet surfaces; shrinks when the pump is live | Grows one pixel-row per second, visible | Repairing the pump *is* the fight; before that, jump the puddles |
| **ECHO** (new) | Wire | Mirrors your last 2 s of movement along the carriage cable, 1 s behind | Faint copy of your silhouette | Change rhythm; don't stand still on the carriage |
| **WALL** (new, one per district) | Set-piece | Not an enemy: a slow static front you outrun for one screen (Inside chase) | Whole left edge fills with dither over 4 s | Run right. Once per district, never twice. |

Rules that keep it honest with the rest of the design:

- Every NOISE is met first in a room where it *cannot* reach the entry ledge (safe observation), as CLING already is.
- No kills are ever required; every room is completable by movement alone.
- Reduced-flash mode disables blink cues but never the shape cues.
- Deaths reset the room, not the district. Repairs never revert.

### Implementation plan (in order)

1. **Put DRIFT on the critical path in two Field halls** (Workshop, Gallery) on ledges that the journey tests never land on — run `validate_exploration.py` after each placement; the tests use exact landing coordinates so this is the guard. Gives the dash something to do the moment it is learned.
2. **SURGE in `conductor`**: reuse the Stand phase machine; the enemy only exists in the `discharge` phase. Small script, big fiction payoff.
3. **BLOOM in `basin`/`drowned_street`**: growth tied to `drowned.water_y`; disappears with `pump_repaired`. Turns the district's repair into a visible victory.
4. **PixelLab sprites** for each: `create_character` (64 px, "static creature, white body, black eye, four greys") then `animate_character` for idle / walk / telegraph, downscaled to 14×18 with `tools/quantize_pixellab.py`. The coded 14×18 outline stays as the contact boundary so hitboxes never change.
5. ECHO and WALL only after 1–3 have been play-tested.

## 3. What PixelLab can do that we haven't used

Tool list checked on 16 Sep 2026. Beyond `create_image_pixen` and the sidescroller tilesets:

| Tool | Use for WHITE SIGNAL | Priority |
|---|---|---|
| `create_font` | A real pixel TTF in the game's letterforms. Our `DrawUtil` 3×5 font is the brand; a matching 5×7 or 7×9 variant for titles/cards would give the district cards and menu more presence without abandoning the look. | High |
| `create_ui_asset` | Panel frames (9-slice) for the map, pause, intro and settings: riveted steel plates in four greys instead of flat black rectangles. | High |
| `create_character` + `animate_character` | NOISE roster above; also an animated **operator** for memories (idle, point, work) instead of one still. | High (with §2) |
| `animate_image` / `animate_image_pixminimax` | Loop the existing skyline strips (drifting static, a slowly turning distant dish) and the door open/close. | Medium |
| `create_building_kit` | Matched wall/floor/doorway/pillar vocabulary per biome — would replace the coded `room_dressing.gd` masses with real architecture. | Medium |
| `create_object_pro_flash` (8 views) | Not needed — everything is side view. | Skip |
| `create_map` / topdown tilesets | Not applicable to a side-scroller; the survey map is a diagram, not terrain. | Skip |
| `create_talking_gif` / lip sync | Skip — the game has no spoken dialogue and the Operators are meant to be absent. | Skip |

The Spark itself stays coded (white block, squash/stretch, scarf). It is the brand mark and its readability against everything else depends on being the only pure-white moving thing.

## 4. Ranked next steps

1. LOG tab on the map (story *why*, plain observations).
2. DRIFT in two Field halls + SURGE in the conductor (enemies on the critical path, both tied to machinery).
3. PixelLab font + UI panels for the cards, map and pause.
4. Animated NOISE and operator sprites via `create_character`/`animate_character`.
5. Answering-window hold, Array lamp labels, aftermath end card.
