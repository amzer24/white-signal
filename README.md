# WHITE SIGNAL

A monochrome deckbuilder × platformer. You are a **SPARK** crossing a dead
relay world — collect **SHARDS**, draft **GLYPHS** at every **SIGNAL SURGE**,
and light the **GATE**.

> 1-bit ditherpunk · 480×270 · deckbuilder × platformer hybrid

![Z0 FLATS](screenshots/ws_shots_z0_vista.png)
![RUINS](screenshots/ws_shots_ruins.png)
![GATE shaft](screenshots/ws_shots_shaft.png)

## Versions in this repo

| Path | What | Status |
|---|---|---|
| `/` (root) | **Godot 4.7 port** — the active project | playable |
| `/js-original` | Vanilla JS canvas engine — the feel reference & spec | playable |

Both implement the same design (see [`js-original/GDD.md`](js-original/GDD.md)):
fixed-clamped loop, coyote/buffer, wall kicks with span-gated grace, dash,
2×JUMP, and a 10-glyph draft deck (incl. cursed row: HEAVY, GLASS).

## Run (Godot)

Open the project with **Godot 4.7+** and press F5, or:

```bash
godot --path . 
```

Headless validation (integration suite, outcome-based assertions):

```bash
WS_TEST=1 godot --headless --path .
```

## Run (JS original)

```bash
cd js-original
python3 -m http.server 8000   # → http://localhost:8000
```

## Controls

Use **Up/Down + Enter/Space** or click a row on the title screen. **Continue**
appears when a saved campaign boundary exists; **New Run** starts the tutorial.
Movement instructions now live under **How to Play**.

Open **Settings** from the title, or press **O while paused**. Music and effects
have separate volume sliders (zero mutes), and fullscreen can be toggled there or
with F11. Settings save automatically to `user://ws_settings.cfg`, separately from
campaign progress. Back from pause settings leaves the game paused.

The supplied **tutorial.wav** plays and loops in **R0**. Death does not restart
the song; pause freezes playback, and entering R1 stops the tutorial music.

### Afterlight lighting study

Press **L on the title screen** for **THE ROOM REMEMBERS**, a separate three-memory
test room. Jump into each diamond block to briefly restore its former workstation;
blocks can replay the memory. Activated beacons leave nearby windows lit.

- **1 / 2 / 3:** ordinary light / authored darkness / readability assist.
- **G:** generated repeating background / original procedural background.
- **H:** gentler memory fade and a stationary service lamp.
- **Q:** return to the title; Enter/Space replays after completion.

The room preserves the saved campaign boundary. Foreground collision geometry
stays visible in every lighting mode. This is a visual experiment, not another
finished campaign relay; exploration design is queued in [the backlog](docs/BACKLOG.md).
See [research and measured results](docs/research/afterlight-results.md) and
[tile asset prompts](assets/backgrounds/afterlight-v2/PROMPTS.md).

### Campaign controls

| Input | Action |
|---|---|
| A/D or ←/→ | Move |
| Space / W / ↑ | Jump (hold = higher) |
| Shift | Dash (glyph) |
| 1/2/3 · S | Draft pick · skip |
| R / P · F11 | Respawn / pause · fullscreen |

## Design docs

- [`js-original/GDD.md`](js-original/GDD.md) — living design doc (v8): pillars,
  tuning table (source of truth), glyph deck, zones, art direction.
- Best-run persistence: Godot saves to `user://ws_best.json`, JS to localStorage.

## Campaign continuation (v8)

The original strip is R0, the tutorial. Reach its transmitter, then press
**Enter/Space or click** to enter R1, **The Listening Field**. Wake its three
EARS using the RISE/CROSS/SEARCH conduits, return to the hub transmitter, then
continue to R2, **The Stand**. There are **3 playable relays of 8 planned**.
The remaining relays are described in the GDD; this build ends honestly at R2.

- Jump into diamond memory blocks from below for one shard; patterned bricks break.
- Stand on a conduit and press **Down or S**; marked exits return you safely.
- Your deck, shards and run totals carry forward. Death retains local rewards and dishes.
- **C** on the title screen resumes the current relay from its entry save.
  **Space/click starts a new run and replaces the saved run.** Mid-relay progress
  is rewound when resuming; checkpoint respawn within play retains it.
- In The Stand, rain intensifies every 40 seconds, shortening crumble life.
  Death or reaching a different beacon calms it.

Campaign integration: `godot --headless --path . --script res://scripts/campaign_test.gd`.
Create `test-user/` before running; test saves are isolated there. The original
`WS_TEST=1` traversal suite still runs. Rendering capture is available through
`scripts/campaign_capture.gd` and writes PNGs into `test-user/`.

Lighting and darkness research is queued in [docs/BACKLOG.md](docs/BACKLOG.md).
