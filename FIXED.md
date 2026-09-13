# FIXED — Godot port audit (2026-09-12)

Every script in the Godot port was diffed against `js-original/game.js` (the
design's source of truth). Headless suite (`WS_TEST=1`) was 8/8 before and after;
visual fixes were verified with the `WS_SHOT=1` screenshot pass on Godot 4.7.2.

## Visual

| # | File | Issue | Fix |
|---|------|-------|-----|
| 1 | `scripts/background.gd` | Used `Camera2D.position` (view **center**) where JS uses `cam.x/y` (view **top-left**). Every parallax layer was offset by (240, 135): horizon bands and dunes sat ~90 px too high, foreground cables and the fog band never drew, the GATE light pillar was 240 px left of the gate. | Subtract half the view (`W*0.5`, `H*0.5`) from the camera position. |
| 2 | `scripts/entity_render.gd` | Sign hint bubble was clamped to *screen* range `[0, 480]` while drawing in *world* space, so every sign past x≈480 (6 of 8) rendered its text off-screen at world x≈440. | Clamp relative to `cam_tl.x`. |

## Gameplay / state

| # | File | Issue | Fix |
|---|------|-------|-----|
| 3 | `scripts/player.gd` | No `RunState.state` check — during **pause** and the **draft overlay** the player kept moving under held input and gravity kept applying. JS only runs `update()` in `play`. | Early-return unless `state == "play"`. |
| 4 | `scripts/mover.gd` | Movers kept oscillating during pause/draft (and carried the player). | Same gate. |
| 5 | `scripts/fx.gd` | Particles kept simulating during pause/draft. | Same gate. |
| 6 | `scripts/hud.gd` | **R (respawn)** was advertised in README and the pause screen but never wired; `RunState.manual_respawn()` existed unused. | `KEY_R` → `manual_respawn()`. |
| 7 | `scripts/hud.gd` | **Mouse click** missing although the menu says "CLICK OR SPACE". | Left click: menu/win → start, pause → resume, draft → card / SKIP hit-test using the same rects as the drawn cards (JS `draftRects`). |
| 8 | `scripts/run_state.gd` | `manual_respawn()` from pause left the game paused; JS `respawn()` always resumes play. | Set `state = "play"` after respawn. |
| 9 | `scripts/player.gd` | Dash with no directional input used `sign(velocity.x)`, so standing still while facing left dashed **right**. | Fall back to `face` (JS behavior). |
| 10 | `scripts/spring.gd` + `scripts/player.gd` | Spring didn't clear `buffer_t`/`coyote_t` (JS does). `is_on_floor()` also lags one physics frame after launch, so a jump pressed on the pad overwrote the 540 launch with a 325 jump. | Spring clears buffer/coyote; ground-jump skipped while `spring_t > 0 and velocity.y < 0`. |
| 11 | `scripts/world.gd` | Camera look-ahead used velocity sign (defaulting right) instead of `player.face`. | Use `player.face` (JS formula). |
| 12 | `scripts/world.gd` | `cam.limit_bottom = 270` blocked the JS `cam.y → +40` look-down into pits. | `limit_bottom = 310`. |
| 13 | `scripts/world.gd` | Two `register_death()` calls in the same frame could both resume after the `await` and double-spawn every NOISE enemy. | Generation counter guard around the deferred `_spawn_enemies()`. |

## Tooling

| # | File | Issue | Fix |
|---|------|-------|-----|
| 14 | `scripts/shot_runner.gd` | Hardcoded `/tmp` — fails on Windows. | `OS.get_temp_dir().path_join(...)`. |
| 15 | `.github/workflows/validate.yml`, `project.godot`, `README.md` | Pinned to Godot 4.6.2 / feature tag `4.6`; project validated on 4.7.2. | Pinned to **4.7.2** / `4.7`. |

## Dead code removed

| File | Why |
|------|-----|
| `scripts/ui_layer.gd` | Never instantiated anywhere. |
| `scripts/sign_post.gd` | Only talked to a root `"UI"` node that never existed; hints are drawn by `entity_render.gd`. Sign-building loop and `SignScript` preload removed from `world.gd`. |
| `scripts/world.gd::_on_banner` | Same nonexistent `"UI"` lookup; banner is drawn by `hud.gd`. |
| `scripts/validate_feel.gd` | Referenced `player.MAX_RUN / KICK_OUT / JUMP_VEL / GRAVITY`, constants that no longer exist — stale, not run by CI. |
| `scripts/validate_port.gd` | Duplicate of `test_runner.gd`, not run by CI. |

## Not changed (noted)

- Mixed indentation (4-space vs tab) across scripts — valid per-file, but inconsistent.
- `gem.gd` is an `Area2D` with no shape; pickup uses a distance check in `world.gd`. Works, just heavier than a plain `Node2D`.

---

# POLISH PASS (2026-09-12)

## Tiles (`scripts/draw_util.gd`, `scripts/entity_render.gd`)
- Platforms are now **baked once** into an `ImageTexture` per rect (world-coord
  bayer/hash so nothing swims) and drawn with `draw_texture`; off-screen
  platforms are culled. Previously every brick line was re-issued every frame.
- Three materials instead of one brick pattern:
  - **ground** — brick courses with hash-driven missing bricks and cracks,
    depth dither darkening toward the base, bright top lip, edge bevels,
    grass tufts.
  - **block** — relay panelling: 16px seams, rivets, vent slits, dead/alive
    status pips (the shaft walls / high blocks now read as dead-transmitter tech).
  - **girder** — thin ledges: rails, cross-hatch braces, end caps (auto for
    anything ≤12px tall; movers use it and get scrolling direction chevrons).
  - **secret** — near-black with a faint lip (unchanged intent).

## Pixel font (`DrawUtil.text / text_shadow / text_width / diamond`)
- Procedural 3×5 bitmap font replaces Godot's anti-aliased fallback font for
  **all** in-game text (HUD, banner, menu, draft, pause, win, signs, GATE,
  spring `^^^`). Scales by integer factor so it stays pixel-crisp.

## HUD (`scripts/hud.gd`)
- Shard counter uses a ◆ glyph and pops on pickup; surge pips show fill state
  and the 5th pulses + "SURGE" label at 4/5.
- Zone | time split in the centre; deaths shown with a pixel ✕; FPS dimmed.
- Notches drawn as filled/hollow diamonds; glyph chips are **live**: DSH lights
  when dash is ready, JMP when an air jump is banked, AEG while the shield holds.
- Cursed row keeps its own diamonds + "CURSED" tag.
- Zone banner slides in, holds, fades; no longer draws over menu/draft/win.
- Draft cards: key tab, big glyph, cost diamonds, 3-line descriptions, dashed
  frame for cursed cards, "SKIP [S] . FREE" plate, click hit-boxes match.
- Pause screen shows deck + run stats. Win screen flashes NEW BEST.
- **Scanlines + vignette** (GDD §8 "diegetic", present in JS, missing in port).
- Surge opens with a white flash.

## Juice the port was missing vs JS (`GDD §11`)
- **Screen shake** (`fx.shake`, decays 20/s): hard landing, spring, stomp,
  dash kill, surge, death, AEGIS break, STOMP+ shockwave.
- **Hitstop** (`RunState.hitstop`): 0.05s on dash kill, 0.06s on stomp; all
  sim nodes gate on `RunState.sim_active()`.
- **Bursts**: shard pickup, enemy kill (size scales with STOMP+), death, spring,
  crumble break, beacon activation, wall kick, air jump, dash start, AEGIS break.
- **SFX cues**: shard pitch-ramp, zone chime, Z2 notch fanfare, surge two-tone,
  draft pick arpeggio, crumble saw, checkpoint bell, dash-kill/stomp blips,
  AEGIS saw drop, death saw, win chord.

## Camera (`scripts/world.gd`)
- Turn-around swing reported as too far (~150px: 40px face lead + 34px velocity
  lead both flipping sign). Face lead is now smoothed (2.5/s) and the velocity
  lead trimmed 0.25 → 0.15, so a reversal glides instead of lurching.

## Biome backdrop (`scripts/background.gd`) — v5
- Rewritten as three biomes (Salt Flats / Relay Ruins / Gate Approach) with
  baked silhouettes placed in world space at depth-correct parallax and
  zone-weighted fades. See GDD §7b for the full layer/biome spec.
- Landmarks: dead broadcast sun (Z0), collapsed dish (Z1), GATE spire with
  signal arcs anchored on the goal (Z2). Weather: wind / static rain / rising
  sparks.

## Level fixes found while testing the lift
- `level_data.gd`: the Z2 vertical lift was `Rect2(2655,190,70,10)` over a
  2640–2700 gap — 15px short on the left, 25px into the right slab. Now
  `Rect2(2640,190,60,10)`.
- `world.gd`: `mover.size` and `crumble.size` were never set from the rect, so
  movers always drew 60×10 and crumbles 70×12 regardless of collision size
  (and crumble break-detection used the wrong footprint). Now copied from data.
- `run_state.gd`: the Z2 shaft wall (x=2436) straddles the Z1/Z2 boundary
  (x=2420), so every wall-kick re-triggered the zone banner + chime. Zone
  changes now need 24px of hysteresis past the boundary (`ZONE_HYST`).

## Shard FX (`entity_render.gd::_draw_gems`)
- Breathing diamond halo (two alpha layers) + bayer-dithered outer ring,
  orbiting spark pair (gray behind, white in front), periodic 4-point glint,
  dark outline + facet highlight, faint ground light pool, and a dotted
  tether toward the spark while MAGNET is held and in range. Off-screen
  shards are culled.

## Biome props (`scripts/props.gd`, new)
- 20 bespoke pixel props, ASCII-authored and baked once, auto-placed on
  ground/block lips by world-coord hash (per-zone density + weighted set),
  never within 22px of spikes / springs / signs / beacons / goal / spawn.
  - **Salt Flats**: salt crystal cluster (rare sparkle), dead shrub, survey post
    with flag, half-buried dish rim, pebbles, carved signal stone.
  - **Relay Ruins**: rubble heap, broken pipe (animated drip), cable coil,
    column stub, tilted X hazard sign, static puddle (shimmer), fallen girder.
  - **Gate Approach**: conduit box (blinking pip), cable bundle with clamps,
    lamp post (breathing glow cone), floor grate, gate crystal shard (pulsing
    tip), warning stripes (edges only), whip antenna (sways).
- Backdrop landmarks added: crashed satellite hull (Z0), freestanding broken
  arches (Z1), transformer yards with live panel lights (Z2).

## Design pass (GDD v6) + sign fix
- `level_data.gd`: shaft sign "WALL JUMP UP" → "HOLD WALL + JUMP . SWAP SIDES"
  (the hardest move in the game had the vaguest hint).
- GDD v6: lore bible, genre lessons table, NOISE bestiary (SKIP / CLING / HUM /
  SWARM / ECHO), glyph synergy pairs + 3 new glyphs + 3 new curses, verb
  chaining, REPEATERS, beacon rest/overclock, hazard grammar per zone, tide
  sketch for Z3, heat/echo-ghost/frequencies meta, accessibility, build order.
