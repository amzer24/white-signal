# WHITE SIGNAL — Game Design Document (living, v4)

## 1. High concept
A monochrome pixel side-scroller × deckbuilder. You are a **SPARK** — a small
white signal-creature — crossing a dead relay world to reach the **GATE**
transmitter. You collect **SHARDS** (signal fragments); every 5 shards triggers
a **SIGNAL SURGE**: draft 1 of 3 **GLYPH** power-ups. Deaths are cheap and
instant; builds differ every run.

## 2. Theme / story (one breath)
The world's transmitters went silent. Static (**NOISE**) eats the relay line.
One spark still burns. Carry it zone to zone, wake the **BEACONS**
(checkpoints), and light the GATE.

## 3. Vocabulary (use these words everywhere)
- SPARK = player | SHARDS = coins ◆ | GLYPHS = cards | BEACONS = checkpoints
- NOISE = enemies | STATIC = ambient bg particles | SURGE = card draft
- GATE = goal | SIGNAL LOST = death | CURSED = risk/reward glyph row

## 4. Design pillars
1. **Intent over physics** — coyote, buffer, wall-grace, corner correction. The
   player should feel skilled, never cheated. (Celeste / Dead Cells rule)
2. **Every pickup changes the run** — no filler glyphs; each one enables a new
   verb, route, or survival trick. (Dead Cells rule)
3. **Addition has a cost** — notch capacity forces real build choices; skip is
   always free. Curses pay in safety, not notches. (Slay the Spire rule)
4. **Readable monochrome** — white = important/alive, gray = info, dark =
   body, black = void/death. Danger blinks; it never hides behind color.
5. **Teach without text walls** — safe intro → risk → remix per mechanic;
   signs are 2–4 words max.

## 5. Player verbs + tuning (source of truth)
| Verb | Numbers |
|---|---|
| Run | max 135, accel 1150, friction 1500, air control 780 |
| Jump | vel 325 (~57px rise, apex ≈0.35s), hold = full, release = 45% cut |
| Fall | gravity 920, max fall 390 (FEATHER: fall ×0.7, cap ×0.75) |
| Coyote / buffer | 0.10s / 0.12s |
| Wall slide | clings when holding in, falls 60px/s max, 0.12s wall-grace |
| Wall kick | 0.95× jump up, 1.15× run speed out; grace kick gated to the wall's vertical span (no kicks from above a wall's top edge) |
| Corner correction | ceiling grazes ≤4px slide past instead of dead-stopping |
| Springs | 500–540 launch + momentum bonus, exempt from jump-cut 0.3s |
| DASH (glyph) | 340px/s, 0.13s, gravity-free, ground refill, kills NOISE |
| 2×JUMP (glyph) | +1 air jump @92% height |

## 6. Glyph deck (platformer × deckbuilder)
- **Draft:** SIGNAL SURGE every **5 shards** (24 shards/level ≈ 4–5 surges/run).
  Pauses the world, 1-of-3, keys 1/2/3 or click/tap, S = skip (free).
- **Capacity:** 3 notches, +1 on entering Z2. Costs: DASH 2, 2×JUMP 2, rest 1.
- **Cursed row:** separate 2-notch budget, shown as a second HUD row.
  Costs 1 each, drawn from the same 1-of-3 pool:
  - ⇓HEAVY: +25% jump, 35% heavier fall — big arcs, hard landings.
  - ◇GLASS: +50% run, +1 air jump, but any hit kills (AEGIS void).
- **Pool (10):** ≫DASH · ²2×JUMP · ~FEATHER (−30% fall) · »SWIFT (+25% speed) ·
  ⇑SPRING (+20% jump) · ◎MAGNET (shard vacuum) · ◈AEGIS (survive 1 hit/life) ·
  ▼STOMP+ (shockwave stomps) · ⇓HEAVY · ◇GLASS.
- **Guarantee:** first surge of a run always offers DASH (marquee verb).
- **Persistence:** deck survives checkpoint respawns (deaths are 1-second
  lessons, not run-enders); deck resets only on full replay. Pits ignore
  AEGIS — and ignore GLASS (pits kill everyone).

## 7. World / level structure
- 3 zones, one 3800px run: **Z0 FLATS** (teach: move, jump, walls) →
  **Z1 RUINS** (risk: crumbles, springs, pit secrets) → **Z2 GATE** (remix:
  wall shaft, sprint, spike corridors).
- Per mechanic: safe intro → first risk → checkpoint → combo/remix.
- **Remix routes (v4):** the Z1 corridor offers a safe low road (spike
  corridor) vs a **FEATHER/2×JUMP/Spring-gated HIGH LINE** (58px above the
  spring ledge — past plain-jump rise) with a shard cluster, ending at a
  **DASH-gated shortcut** (112px gap onto a 96px pad: plain jump falls 28px
  short, jump+dash lands with ~60px margin) that skips the corridor AND the
  shaft. Dashed outline = risky optional. Missing it drops you onto the
  corridor floor (spike risk), never a softlock.
- Secrets: shard pit (risk/reward), high spring lines, dash shortcuts.
- Beacons: respawn + mend AEGIS + refill dash/jumps. No shopping, no HP.
- Best run persists in localStorage (lower time wins); shown on menu + win.

## 8. Art direction (1-bit ditherpunk, 4 grays)
Palette: `#0b0b0b #3a3a3a #8a8a8a #f2f2f2`. Canvas 480×270, pixel-snapped.
- BG layers (near→far): deepest cables 1.4x (hugs bottom edge) → foreground
  cables 1.15x → waveform dunes 0.65x w/ white crest → far dunes 0.5x
  (darker swell) → relay-ruin blocks 0.5x w/ blinking lights → antenna-tower
  silhouettes 0.25x (respond to camera height) → drifting STATIC specks →
  static starfield → signal-ghost waveform pulse (~7s, sweeps the sky) →
  dithered horizon depth bands (bayer-edged, subtle y-parallax).
- Foreground never mimics platforms (thin, dark, sparse, bottom third).
- GATE light pillar breathes slowly (alpha 0.06-0.14) — visible across Z2.
- Scanlines + vignette are diegetic (you are inside a dead broadcast).
- Dither patterns index by world coords (no swimming while scrolling).
- STATIC density follows the theme: denser in RUINS (zone-driven atmosphere).

## 9. Audio direction
Square-wave SFX only: jump blip, surge chime (two-tone), draft pick arpeggio,
AEGIS break (saw drop), checkpoint bell. Silence between = tension.

## 10. UI (all in-canvas)
Top HUD bar: ◆ shards + surge pips | zone + time | deaths. Bottom-left: glyph
chips + notch pips (+ cursed row when owned). Title / pause / draft / clear
screens drawn in-canvas; DOM keeps only canvas + touch buttons. Draft cards
are clickable regions; cursed cards are labelled CURSED.

## 11. Juice checklist (every action must feedback)
Squash & stretch, landing dust, skid dust, slide sparks, dash ghosts, stomp
hitstop, surge flash + shake, beacon burst, AEGIS ring, blink invuln, banner
plates, goal shimmer.

## 12. Roadmap
- v3: theme BG, surge economy, in-canvas UI. ✅
- v4 (this pass): corner correction, beacon verb refill, cursed glyph row
  (HEAVY, GLASS), remix routes (high line + dash gate), best-time
  persistence. ✅
- Next: Boss-Cell style heat modifiers (mutators picked at run start),
  3rd cursed glyph (e.g. HOLLOW: magnet always on, shards worth ½), zone
  2+ level expansion, gamepad support.