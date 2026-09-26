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

## Exploration art pass (15 Sep 2026) — PixelLab biome kits
- `assets/exploration/biomes/`: six sidescroller Wang tilesets (flats / field /
  stand / wire / array / source) + six 480×160 skylines, generated on the
  project's PixelLab subscription (ids and prompts in the folder README).
- `scripts/biome_material.gd` (new): proper corner-Wang autotiler for any
  platform rect, per-biome tint; replaces the flat grey bars + tick lines in
  every exploration room. Drowned's wet concrete now goes through the same path.
- `scripts/room_dressing.gd` (new): non-solid ceilings, pillars and ledge
  struts for the interior rooms so they read as rooms. Zero collision changes.
- `exploration_world.gd`: biome skyline layer (mirrored wrap, 0.08x, faded into
  the floor); old procedural arcs / afterlight far layer only used where a
  biome has no sky. `gate_mechanism.gd` Source fill made translucent.
- `scripts/room_sweep_capture.gd` (new tool): `WS_ROOMS=a,b,c godot
  --rendering-driver opengl3 --script res://scripts/room_sweep_capture.gd`
  renders any list of rooms to `test-user/sweep/` for contact-sheet review.
- Verified: `WS_TEST=1` 8/8 and `validate_exploration.py` 13/13 after the change.

## Interaction art (15 Sep 2026) — no more "+" boxes
- Every one of the 53 interaction points was a 16px box with a `+`; exits were
  a box with `>`/`X`. `assets/exploration/props/` now holds 14 PixelLab sprites
  (lever, breaker cabinet, valve wheel, socket, impeller, brake, archive
  terminal, protocol crystal, beacon, dish crank, call post, open/sealed hatch,
  memory block) and `scripts/action_sprites.gd` maps action ids → sprites.
- Behaviour-aware: pickups vanish when collected, sockets show the fitted part,
  hatches switch open/sealed with `can_use_exit`, protocols pulse. Anchoring is
  on the old marker's foot line, so nothing moved; both suites still pass.

## Style unification (15 Sep 2026) — PixelLab output → 1-bit ditherpunk
- Classic's look is entirely coded (baked tiles, props, dithered backdrop in
  `draw_util.gd` / `props.gd` / `background.gd`). PixelLab output is smooth
  greyscale with anti-aliased ramps, so exploration drifted off-style.
- `tools/quantize_pixellab.py` now snaps every PixelLab PNG (mine and Codex's
  earlier ones) to the game ramp `0b/23/3a/8a/f2`: sprites and tilesets hard-
  quantized (play layer capped at GRAY), skylines Bayer-dithered and capped at
  DARK like the classic sky. Untouched originals live in `raw/` next to each.
- Sky tint raised to 0.72 to compensate for the darker cap.

## Classic / Afterlight: floating fixtures (15 Sep 2026)
- All 13 signs Codex authored in R1, R2 and Afterlight hung 31–98px above
  their platforms (posts are 22px; R0's convention is `y = top - 22`).
  `LevelData.ground_signs()` now snaps every sign to the platform beneath it at
  level build; audit reports 0 floating signs across R0/R1/R2/Afterlight.
- Afterlight's three "coherence lamps" were drawn 95px above each lit beacon,
  adrift in the sky; they now hang just above the beacon flag.

## Clarity pass: plain-language goals, first-run intro, menu and return-to-title
- Title menu is now seven plain items: START/CONTINUE JOURNEY, NEW JOURNEY (one confirm, then straight into the Flats), CLASSIC RUN, SETTINGS, HOW TO PLAY, EXTRAS, QUIT. New Journey no longer dead-ends on a recovery page.
- Classic pause: Q (or BACK on a pad) returns to the title; the run is kept at the last relay (`RunState.leave_run`).
- `exploration_guidance.gd` rewritten in plain imperatives ("PICK UP THE IMPELLER . IT IS LYING IN THIS STREET") with a `PLAIN` fallback for all 39 rooms; jargon goals never reach the HUD. Autoload fetched by node so the script also compiles from `--script` tests.
- First run in the Flats shows a one-screen intro (what the game is, the four districts, controls, "any key").
- Top bar now carries a FIELD / DROWNED / STAND / ARRAY progress strip that lights as each district is fixed.
- HOW TO PLAY page states the goal before the controls.
- Tests: `guidance_test` fixed (impeller now lives in `drowned_street`), `new_journey_test`/`extras_menu_test` updated for the new row counts. Classic PORT-VALIDATION 0 failures, exploration validation 0 failures, guidance/tutorial tests pass. `scripts/intro_capture.gd` captures the intro for review.
- Follow-up: memory ghost is now a PixelLab operator sprite (`props/operator.png`) stood on the floor pointing at the dish; Flats dish planted on the floor line. Lever, breaker, crank, callpost and both doors regenerated as strictly flat side-view sprites (the first batch was isometric); conduit room lost its coded box outlines. `quantize_pixellab.py` reads `raw/` — replace the raw when swapping a sprite.
- Parallax rebuilt as real layers instead of one sliding picture: far sky 0.04x, mid 0.12x, near 0.28x (new transparent PixelLab strips for Flats/Stand/Wire), whole-pixel snapping, small vertical parallax, atmospheric tinting by depth, and thin foreground cables at 1.3x in front of the player on exteriors. Interior walls (Field halls, Array, Source) now barely move, since they sit right behind the play layer alongside the static pillars.
- Mission clarity: story-first intro (the dead relay, the calling receiver, you are the Spark, four named districts then the Gate); district title cards on every biome change; `mission_line()` on the map and pause screens listing what is left. Direction review with enemy roster, PixelLab capability audit and ranked plan: `docs/research/direction-2026-09-16.md`.
- Room sweep (all 40 rooms captured via `room_sweep_capture.gd`, contact sheets in `test-user/sweep/sheet_*.png`): causeway "EAST EAR RESTORED" no longer draws through the middle crank (it replaces the hint line at the top instead); door/lever sprites shrink to fit under the HUD bar on top ledges (Float, Gate, Wire shaft); Wire shelter's coded box around the brake spare removed; near parallax layer softened so fence posts no longer read as play-layer objects.
- Levers rebuilt: a coded side-view floor pedestal (plate, notched quadrant, pivot bolt) with a PixelLab arm (`props/lever_arm.png`) rotated about its pivot. Arm swings 0.28 s with ease-out when used, holds its position, and nudges when a use is rejected. Saved-flag levers read their state from the profile (`LEVER_FLAG`); the rest keep a session toggle.
- Prop animation pass (`action_sprites.gd`): breakers have an ON sprite (PixelLab edit of the original, lamp lit) chosen from the saved flag with a short flicker on use; valves spin coded spokes for 0.7 s; crank handles orbit the axle for one turn; call posts blink their lamp; loose parts (impeller, brake) hover; doors slide open (shut door rises out of the frame over 0.5 s) the moment a route becomes usable. Socket sprite regenerated as a flat plate with a round hole. `scripts/anim_capture.gd` captures mid-animation frames for review.
