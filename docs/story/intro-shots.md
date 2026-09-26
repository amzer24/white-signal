# White Signal: intro shot list

Status: draft for Lee, 26 Sep 2026. Built from `docs/story/intro-script.md`. Nothing is built. No code, art or sound was changed.

Who this is for: the pixel artist (section 3), the chiptune composer (section 4) and whoever codes the intro (sections 2 and 5).

## 1. Visual approach

The intro is ten cards shot mostly as held frames, with motion coming from the things inside the frame rather than the camera. It is set in the same land as the title screen. Cards 1, 3, 4 and 5 reuse the title's far and mid strips, poles and sagging wire, so a player who has just left the title recognises the place, now seen in the past. Each act has its own tint, swapped only at a cut or on black. Cards 1 and 2 are amber, the old sodium colour (`TINTS["2"]`), for memory. Cards 3 to 5 are plain grey (`TINTS["test"]`), with the colour drained out. Cards 6 to 8 are cold night blue (`TINTS["1"]`, the title's own tint). Cards 9 and 10 are warm (`TINTS["village"]`), the same tint as the gameplay they hand over to. The rhythm is calm, then tense, then still. Cards 1 to 4 run on the music's 3-second bar. Card 5 is a silent held frame. Cards 6 to 8 are one unbroken close-up where small events (rings, a flare) do the work. Cards 9 and 10 are two slow, warm frames. Text always sits in the same place, two centred lines in the empty sky at the top, in GRAY with a black shadow. No subject ever rises into that band, so text never sits on detail. From card 5 on, the Spark is the only pure white pixel on screen. The text, the rings, the lantern, the keeper's window and the far caller are all GRAY. Card 5 has no white at all, because nothing is alive. The title closes with a circle shutting on the Spark. The intro ends by opening a circle on the Spark in Last Relay, lying at Old Mast's feet, and his first line opens by itself, so there is no menu, loading card or control screen between the story and play.

## 2. Shot list

### Conventions for every shot

- **Coordinates** are in the 480x270 centre column. On a wide screen, screen x = hx + x, where hx = (view width - 480) / 2, as in `title_screen.gd`. Layers marked "extend" tile or stretch across the full view width. The key subject always sits inside x 0 to 480.
- **Text band.** Line 1 top-left y 28, line 2 y 44, centred on x 240, scale 2, GRAY, drawn with `DrawUtil.text_shadow` (black shadow +2,+2). The font is 3x5 glyphs, not 5x7, so a 38-character line is 302 px wide at scale 2 (x 89 to 391). Nothing but sky and stars is drawn above y 60 in any shot, and stars skip the box x 80 to 400, y 20 to 64.
- **Typing.** 40 characters a second. Line 2 starts 0.25 s after line 1 finishes. No typing sound.
- **Text out.** GRAY, then DARK for 0.12 s, then gone. Times below are when the step starts.
- **Reading check.** Every card's text is on screen at least 3 words a second plus the lead-in silence (see each card).
- **Palette fade** means the tint steps one grey darker every 0.12 s (3 steps, 0.36 s), the NES way, instead of an alpha fade. Fade up is the reverse.
- **The land** (cards 1, 3, 4, 5) uses the title's geometry: far strip `title_scene/far` top at y 160 (horizon line y 210), DARK fill y 224 to 252, mid strip `title_scene/mid` top at y 188, BG fill y 252 to 270, poles `title_pole/pole` top-left at (x, 186), wire at y 190 with the title's 6 px sag, pole feet at y 249. Poles at x 40, 200 and 360 (and -120, 520, 680 on wide screens).
- **Stations** in the land are `lamp` posts at pole x + 26, top-left y 217, so the plinth stands on y 249. Bulb centres are at x 74, 234 and 394.
- **Horizon lights** are 1x1 px dots drawn in code at y 209, every 24 px from x 12 (extend).
- **Times** are seconds from the start of the card unless marked "global".
- Global start times assume nobody presses anything.

| Shot | Card | Global start | Length (s) | Tint | Into next |
|---|---|---|---|---|---|
| 1A | 1 | 0.0 | 6.0 | amber | cut |
| 2A | 2 | 6.0 | 6.0 | amber | cut |
| 3A | 3 | 12.0 | 6.0 | grey | none, the shot carries on |
| 4A | 4 | 18.0 | 6.0 | grey | palette fade |
| 5A | 5 | 24.0 | 7.0 | grey | palette fade |
| 6A | 6 | 31.0 | 6.0 | blue | none, the shot carries on |
| 7A | 7 | 37.0 | 7.0 | blue | none, the shot carries on |
| 8A | 8 | 44.0 | 2.5 | blue | cut |
| 8B | 8 | 46.5 | 3.5 | blue | palette fade |
| 9A | 9 | 50.0 | 6.0 | warm | palette fade |
| 10A | 10 | 56.0 | 7.0 | warm | palette fade to black |
| H1 | hand-off | 63.0 | about 1.5, then Old Mast talks | warm | play |

Twelve shots, 63 s of cards. Old Mast's first line opens about 64.5 s after New Game.

---

### Card 1. ONE LINE RAN ACROSS THE WHOLE LAND / JOINING EVERY RELAY AND EVERY GATE

**Shot 1A.** 6.0 s. Wide, amber.

- **Framing.** The whole land, the line running edge to edge at y 190. Low horizon, big empty sky. The line itself is the subject. The middle lamp (bulb 234, 225) sits almost dead centre.
- **Layers, back to front.**
  1. BG sky (extend).
  2. Stars: 60 DARK 1 px dots, the title's hash (extend).
  3. `title_scene/far` at y 160, parallax 0.2 (extend).
  4. Horizon lights, all WHITE, steady (extend).
  5. DARK fill y 224 to 252 (extend).
  6. `title_scene/mid` at y 188, parallax 0.5 (extend).
  7. BG fill y 252 to 270 (extend).
  8. `title_pole/pole`, frame 1 on every fourth pole, parallax 1.
  9. `lamp/on` beside every pole, looping, parallax 1.
  10. Wire in GRAY, drawn in code (extend).
- **Camera.** Pan right, x 0 to 60 over 6.0 s, linear, whole pixels only (10 px/s, the title's own drift speed).
- **Text.** In at 0.8. Out at 5.6. That is 13 words in a 4.8 s window.
- **Transition.** Fade up from black over the first 0.36 s. Hard cut to 2A at 6.0, on the bar line.
- **Sound.** Music `intro_line` starts at 0.0. `amb_w1` fades in from silence over 1.0 s at its normal level. Its blip and faint answer suit a line that is alive.
- **Sheets.** `title_scene` (far, mid), `title_pole` (pole), `lamp` (on). No new art.

### Card 2. THE RELAYS CARRIED EVERY VOICE ALONG / SO NO ONE WAS EVER TOO FAR AWAY

**Shot 2A.** 6.0 s. Medium, amber.

- **Framing.** One relay station, centred, standing on flat ground. A small listener sits against its left wall looking up at the wire. A pulse of light runs in from the left, through the station, and out to the right.
- **Layers, back to front.**
  1. BG sky and stars.
  2. `title_scene/far` at y 160, drifting 2 px/s (extend).
  3. DARK fill y 224 to 270 (extend).
  4. Ground tiles: `ground/top` at y 232, `ground/mid` at y 248, `ground/deep` at y 264 (extend).
  5. `backdrop_w2/pieces` frame 0 (the relay tower on its hut), drawn at 100% opacity with top-left (192, 104), so its bottom sits on y 232. Its three cables end at frame x 0 and 95, at frame y 16, 38 and 58, which is screen y 120, 142 and 162. Code carries each cable on from x 192 to the left edge and from x 287 to the right edge as a flat GRAY line (extend).
  6. Lit window: a 5x4 WHITE rect drawn in code on the hut wall right of the door. The door is at frame x 44 to 52, so start at about frame (60, 116), screen (252, 220). Check the exact spot against the art.
  7. `intro_npc/listener_sit` (NEW), mirrored to face right, top-left (176, 208), feet on y 232.
  8. The pulse: a 3x1 WHITE bead with a 6 px GRAY tail, drawn in code on the middle cable (y 142).
- **Motion.** The bead runs from x -10 at 1.5 to the tower's centre (x 240) at 3.0. There the window grows to 7x6 for 0.2 s and `fx_light/ring` plays centred on the tower top at (240, 112). A second bead leaves at 3.3 and runs to x 500 by 4.9. On wide screens the bead starts at the left edge of the view and keeps the same speed, 167 px/s. The listener shows frame 1 (head up) from 2.9 to 3.5 as the pulse passes, then frame 0.
- **Camera.** Held still. This card is the safe one.
- **Text.** In at 0.8. Out at 5.6. That is 14 words in 4.8 s.
- **Transition.** Hard cut to 3A at 6.0. The tint swaps from amber to grey on the cut.
- **Sound.** `relay_hum` loops under the whole shot at -12 dB and stops at the cut. `line_pulse` (NEW) plays at 1.5, panned left, and again at 3.3, 2 semitones up, panned right. `intro_line` carries on (bars 3 and 4). `amb_w1` carries on.
- **Sheets.** `backdrop_w2` (pieces 0), `ground` (top, mid, deep), `fx_light` (ring), `intro_npc` (listener_sit, NEW).

### Card 3. THEN A HOWLING NOISE FILLED THE LINE / AND SPREAD FROM STATION TO STATION

**Shot 3A.** 6.0 s. Wide, grey. This is the land from 1A, held still.

- **Framing.** The 1A set with the camera at x 0. The pole at x 200 is replaced by `intro_poles/switch_ready` (NEW), top-left (188, 186). It is a pole with an isolation switch at the top, and a crew listener stands at its foot on the left, idle, watching. Everything else is lit as in 1A.
- **Layers.** As 1A, plus:
  - `intro_poles/switch_ready` at (188, 186).
  - `intro_static/crawl` (NEW) riding the wire, centred on it, with top-left (x - 16, wire y at x - 8).
- **Motion.** The static enters at x 500 at 0.5 and crawls left at 36 px/s, so it reaches x 302 at the end of the card. Behind it (to its right) the wire turns from GRAY to DARK, and each horizon light goes out as the static passes its x. The lamp at bulb x 394 goes out at 3.44: `lamp/ignite` played backwards (0.25 s), then `lamp/off`. On wide screens, lamps and horizon lights right of x 480 start off, because the noise came from further east.
- **Camera.** Held still. The stillness is what makes it uneasy.
- **Text.** In at 0.8. Out at 5.6. That is 13 words in 4.8 s.
- **Transition.** No cut. The same shot carries on as 4A.
- **Sound.**
  - Music `intro_noise` (NEW) starts at 0.0.
  - `static_crawl` (NEW) loops from 0.5. Its pan follows the static's x, and its level rises from -6 dB to 0 dB over the card.
  - `lamp_off` (NEW) at 3.44.
  - `amb_w1` carries on.
- **Sheets.** `title_scene`, `title_pole`, `lamp` (on, ignite reversed, off), `intro_poles` (switch_ready, NEW), `intro_static` (crawl, NEW).

### Card 4. SO THE CREWS CUT THE LINE APART / ONE STATION AFTER ANOTHER

**Shot 4A.** 6.0 s. Wide, grey. The same frame as 3A, carrying on.

- **Framing.** The crew listener at the switch pole (x 188 to 236) is the subject, just left of centre. The static comes at them from the right.
- **Motion.**
  - The static carries on from x 302, still at 36 px/s.
  - At 0.9 the crew plays `intro_poles/switch_pull` (5 frames, 0.7 s). The switch blade opens on frame 3, at 1.25. From then on the code leaves a gap in the wire between the switch contacts, screen x 203 to 220.
  - At 1.25, `arc_hit/hit` plays centred on (212, 190), with a 2 px shake for 0.25 s.
  - From 1.6 the crew plays `switch_after` (head bowed, looping).
  - The lamp at bulb x 234 goes out at 1.89 as the static passes it.
  - The static reaches the gap at x 222 at 2.22 and switches to `intro_static/stall` (a fizzing pile-up, looping). At 3.2 it plays `die` (0.4 s) and is gone.
  - "One station after another": from 3.6, the lights left of the gap go out one by one, right to left, every 0.3 s. The lamp at bulb x 74 takes its turn at about 4.4. The last horizon light goes out at about 5.4.
- **Camera.** Held still, apart from the shake.
- **Text.** In at 0.8. Out at 5.6. That is 11 words in 4.8 s.
- **Transition.** Palette fade to black from 5.64. Time passes here.
- **Sound.**
  - `lever_pull` at 0.9.
  - `wire_snap` (NEW) at 1.25.
  - At 1.25, `intro_noise` stops dead with a 20 ms fade and `amb_w1` fades out over 0.3 s. The music is the line, so cutting the line cuts the music.
  - `static_crawl` goes on until 3.2. `static_die` (NEW) plays at 3.2.
  - `lamp_off` at 1.89 at full level. For the lights going out left of the gap, play `lamp_off` at -10 dB and 0.8 pitch on the lamp and on every second horizon light.
  - Nothing else. The card ends almost silent.
- **Sheets.** As 3A, plus `intro_poles` (switch_pull, switch_after), `intro_static` (stall, die), `arc_hit` (hit).

### Card 5. THE NOISE STOPPED . SO DID THE VOICES / EACH STATION ALONE IN THE QUIET

**Shot 5A.** 7.0 s. Wide, grey. The same land, years later. The low point.

- **Framing.** The 1A set from the same camera position, with everything dead. There is no white anywhere in this frame.
- **Layers, back to front.**
  1. Sky and stars.
  2. `title_scene/far` at y 160. The caller light is not drawn.
  3. DARK fill.
  4. `title_scene/mid` at y 188.
  5. BG fill.
  6. Poles:
     - `intro_poles/dead` frame 0 (leaning left) at (28, 186).
     - `title_pole/pole` frame 1 at (200, 186), standing, with the gap still open.
     - `intro_poles/dead` frame 1 (leaning right) at (348, 186).
     - `intro_poles/dead` frame 2 (a snapped stump) at (508, 186) for wide screens.
  7. `lamp/off` at all three lamp spots.
  8. The wire in pieces, DARK, drawn in code. From each pole's insulator a piece hangs down to the ground about 40 px away (for example from (220, 190) down to (262, 246)), and from the next pole's insulator another piece hangs back toward it. No two pieces meet.
  9. No horizon lights.
- **Camera.** Held still. Nothing moves except the text.
- **Text.** In at 2.0, to let the silence land first. Out at 6.4. That is 13 words in 4.4 s.
- **Transition.** Fade up from black over the first 0.36 s. Palette fade to black from 6.64.
- **Sound.** None at all. No music, no ambience, no effects. This is the only silent card.
- **Sheets.** `title_scene`, `title_pole`, `lamp` (off), `intro_poles` (dead, NEW).

### Card 6. AT THE END OF ONE CUT WIRE / A TINY SPARK OF SIGNAL LAY SLEEPING

**Shot 6A.** 6.0 s. Close-up at grass level, night blue.

- **Framing.** Low camera. The cut end of a wire lies in the grass. It comes in from the right edge (east, where the call will come from) and ends at a frayed tip at x 180, y 216. The Spark, drawn at close-up size, is curled up just left of the tip, with its feet at (160, 226). The Spark sits on the left third, with the empty wire to its right for the rings to travel along later.
- **Layers, back to front.**
  1. BG sky, with sparser stars (30).
  2. `title_scene/far` at y 118 (horizon y 168), still. It is far away, so it keeps its normal pixel size (extend).
  3. DARK fill y 182 to 270 (extend).
  4. Back grass: `intro_wire_close/grass` (NEW), frames picked by hash, every 32 px at top-left y 190 (extend).
  5. The wire: `intro_wire_close/wire` tiles every 32 px at y 200, from x 208 to the right edge (extend), with `intro_wire_close/wire_end` at top-left (176, 200). The cable centre is frame y 16, so screen y 216.
  6. `spark_close/curled` (NEW), mirrored to face right, anchored bottom-centre at (160, 226).
  7. Front grass: `intro_wire_close/grass` at top-left y 226, every 32 px, leaving x 136 to 184 clear so the Spark shows (extend).
- **Light.** The darkness pass from `world_fx.gdshader` is on across the whole view at strength 0.6, with one light on the Spark at (160, 212), radius 24. That is the "barely glowing".
- **Camera.** A slow drift: x from -12 to 0 over 6.0 s, ease out.
- **Text.** In at 0.8. Out at 5.6. That is 14 words in 4.8 s.
- **Transition.** Fade up from black over the first 0.36 s. There is no cut into card 7. The shot carries on.
- **Sound.** Music `intro_still` (NEW) starts at 0.0. No ambience.
- **Sheets.** `title_scene` (far), `intro_wire_close` (grass, wire, wire_end, NEW), `spark_close` (curled, NEW).

### Card 7. UNTIL ONE NIGHT THE DEAD LINE RANG / ONCE . TWICE . THREE TIMES

**Shot 7A.** 7.0 s. The same close-up, carrying on (camera now still at x 0).

- **Motion.** Three rings of light run along the wire from the right edge to the tip at x 180, as `intro_wire_close/ring` (NEW, GRAY bead with a DARK halo, never white), at 256 px/s.

  | Ring | Leaves | Arrives | Pops | Spark shows | Spark light radius |
  |---|---|---|---|---|---|
  | 1 | 1.40 | 2.65 | `ring_pop` | `stir` frame 0 | 32 |
  | 2 | 2.60 | 3.85 | `ring_pop` | `stir` frame 1 | 40 |
  | 3 | 3.80 | 5.05 | `ring_pop` | `stir` frame 2 (eye open) | 48 |

  On wide screens each ring leaves from the right edge of the view 0.25 s earlier per extra 64 px, so it still arrives on time. Each held stir frame lasts until the next ring arrives.
- **Camera.** Held still.
- **Text.** Line 1 types from 0.6. Line 2 is typed in step with the rings: "ONCE ." at 2.65, "TWICE ." at 3.85, "THREE TIMES" at 5.05. Out at 6.6. That is 11 words in 6.0 s.
- **Transition.** No cut into card 8.
- **Sound.** `intro_still` fades out over 0.6 s from 0.0, so everyone holds their breath. `line_ring` (NEW) plays at each arrival: 2.65, 3.85 and 5.05. Nothing else.
- **Sheets.** `intro_wire_close` (ring, ring_pop, NEW), `spark_close` (stir, NEW).

### Card 8. NOTHING SHOULD RING ON A DEAD LINE / BUT SOMEONE IS STILL CALLING

**Shot 8A.** 2.5 s. The same close-up. The flare.

- **Motion.**
  - At 0.2, `spark_close/flare` (4 frames, 0.34 s), then `spark_close/sit` (looping). The Spark sits up.
  - The Spark's light jumps from radius 48 to 88 over 0.3 s.
  - The wire lights up from the tip outward: `wire_end` becomes `wire_lit` frame 1 at 0.3, and the wire tiles at x 208, 240 and 272 become `wire_lit` frame 0 at 0.35, 0.45 and 0.55. That is three tiles, GRAY. The light circle shows the grass on both sides of the Spark.
  - A 1 px shake for 0.2 s at 0.2.
- **Text.** Line 1 in at 0.8.
- **Transition.** Hard cut at 2.5 to 8B. The text carries on over the cut.
- **Sound.** Music `intro_wake` (NEW) starts at 0.0. Its downbeat lands at 0.2, with the flare. `spark_flare` (NEW) at 0.2.
- **Sheets.** `spark_close` (flare, sit, NEW), `intro_wire_close` (wire_lit, NEW).

**Shot 8B.** 3.5 s (card time 2.5 to 6.0). Normal game scale, night blue. It bridges from the close-up to the wide shots.

- **Framing.** The Spark at normal size stands on flat ground at the tip of the dead wire, looking east. The far caller light is on the horizon to the right.
- **Layers, back to front.**
  1. Sky and stars.
  2. `title_scene/far` at y 160, with its origin at x 186 so the caller's mast tip lands at (392, 166).
  3. `title_caller/blink_gray` (NEW row) at (389, 163).
  4. DARK fill y 224 to 270.
  5. Ground tiles, top at y 232 (extend).
  6. `intro_poles/dead` frame 1 (leaning) at (300, 186).
  7. The wire, drawn in code:
     - It hangs from the leaning pole's insulator down to the ground at (290, 231).
     - It lies along y 231 leftwards to the tip at x 212.
     - Right of the pole it runs on to the right edge with the usual sag.
     - From the tip to x 260 (three tiles) it is GRAY. The rest is DARK.
  8. The Spark: `J.spark`, feet at (204, 232), facing right, pose "stand", scale 1.
- **Light.** The darkness pass is on across the whole view at strength 0.8, with a light on the Spark at radius 56.
- **Motion.** At card time 3.0 the caller blinks once. Code forces the `blink_gray` cycle to start then. At 3.3 the Spark hops once where it stands, 6 px high, over 0.3 s (`J.arc`).
- **Camera.** Held still.
- **Text.** Line 2 types from card time 2.9, as the far light answers. Out at 5.6. That is 12 words in 4.8 s.
- **Transition.** Palette fade to black from card time 5.64. The tint changes to warm on black.
- **Sound.** `intro_wake` flows straight into the `intro_home` loop at card time 3.2. `caller_blip` (NEW) plays at card time 3.0 at -8 dB.
- **Sheets.** `title_scene` (far), `title_caller` (blink_gray, NEW row), `ground` (top, mid), `intro_poles` (dead, NEW), Spark in code.

### Card 9. IT FOLLOWED THE WIRE TO THE LAST LIGHT / A HILLTOP STATION CALLED LAST RELAY

**Shot 9A.** 6.0 s. Wide, warm night.

- **Framing.** A hill rises from bottom left to top right. The Spark starts small at bottom left and climbs a stepped path beside the wire. The keeper's house stands on the top at the right, with one lit window. Old Mast comes out with a lantern and walks down to meet it. They meet a little right of centre.
- **The hill.** Ground tiles at game scale, so this already looks like the game.
  - Flat ground at y 240 from the left edge to x 128.
  - Then seven steps, each 32 px wide and 16 px higher. Step k (1 to 7) runs from x 128 + 32(k - 1) to 128 + 32k, with its top at y 240 - 16k.
  - The top (y 128) runs on from x 320 to the right edge (extend).
  - Under every step, `ground/mid` and `ground/deep` fill down to y 270.
- **Layers, back to front.**
  1. Sky and stars.
  2. `title_scene/far` at y 160. The caller is not drawn.
  3. DARK fill y 224 to 270.
  4. The hill tiles.
  5. Poles: `title_pole/pole` at (72, 177), (200, 129) and (328, 65). Each stands on its step, with the wire at y 181, 133 and 69.
  6. The wire, GRAY, drawn in code. It comes in from the left edge at y 181, runs pole to pole, and ends at the house wall at about (372, 84). Take the exact bracket pixel from the art.
  7. `intro_far/keeper_night` (NEW) at top-left (368, 64), on the top at y 128. Its window is GRAY.
  8. Old Mast: `intro_npc/mast_lantern_walk` (NEW), then `mast_lantern_stand`.
  9. The Spark in code.
- **Light.** The darkness pass is on across the whole view at strength 0.85, with three lights:
  - the Spark, radius 40
  - the lantern, radius 56 (at the lantern pixel on Mast's sprite)
  - the window, radius 24, at about (385, 96)
- **Motion.** Paths are `J.path` keys, written as (time, feet x, feet y).
  - The Spark:
    - runs (pose "run") from (0.0, 24, 240) to (1.8, 104, 240)
    - hops up three steps (pose "air" in each hop, 0.35 s per hop, `J.arc` 8 px high), to (2.15, 142, 224), (2.5, 174, 208) and (2.85, 212, 192)
    - stands facing right from 2.85
    - hops once where it stands at 5.0
  - Old Mast:
    - comes out of the keeper's door at (0.6, 400, 128), facing left
    - walks to (2.1, 334, 128)
    - steps down to (2.9, 304, 144), (3.7, 272, 160) and (4.5, 248, 176)
    - plays `mast_lantern_stand` from 4.5, lantern held out toward the Spark
- **Camera.** Held still. The two walkers carry the motion.
- **Text.** In at 0.8. Out at 5.6. That is 14 words in 4.8 s. The house top (y 64) and top pole (y 65) stay under the text band.
- **Transition.** Fade up from black over the first 0.36 s. Palette fade to black from 5.64.
- **Sound.**
  - `intro_home` carries on.
  - `amb_village` fades in from -20 dB to -8 dB over the shot.
  - `door_open` at 0.6, at -10 dB (far off).
- **Sheets.** `title_scene` (far), `ground` (top, mid, deep), `title_pole` (pole), `intro_far` (keeper_night, NEW), `intro_npc` (mast_lantern_walk, mast_lantern_stand, NEW), Spark in code.

### Card 10. FOLLOW THE LINE AND LIGHT THE GATES / TO FIND WHO IS ON THE OTHER END

**Shot 10A.** 7.0 s. Inside the keeper's house, looking east out of the window. Warm.

- **Framing.** The room is unlit and fills the frame in black. A window sits centred below the text band. The Spark sits on the sill at the lower left of the window, facing right. Through the window the flats run away to the horizon. The dead line runs east, past a small gate on the horizon. Beyond it, the caller's light blinks. The eye travels Spark, then line, then gate, then light, left to right.
- **Layers, back to front.**
  1. BG sky with 80 stars.
  2. `title_scene/far` at y 150, origin x 140, so the horizon is at y 200 and the caller's mast tip is at (346, 156).
  3. `title_caller/blink_gray` (NEW row) at (343, 153).
  4. `intro_far/gate_far` (NEW) with top-left (270, 136), so its foot is on the horizon at y 200 and its centre is at about x 286.
  5. DARK fill y 214 to 270.
  6. The line, drawn in code. Tiny pole ticks (a 1x6 DARK post with a 3x1 bar) at x 120, 170, 216, 258, 296 and 330, with bases rising from y 214 to 201 as they go east. A GRAY wire runs through their tops and on past the gate.
  7. The room: BG everywhere outside the window opening (extend).
  8. `intro_window/frame` (NEW) at top-left (80, 64). The opening runs from screen (92, 74) to (388, 214). The sill top is at y 214.
  9. The Spark in code: feet at (150, 214) on the sill, facing right, pose "stand".
- **Motion.** The caller blinks (forced) at 2.5 and again at 5.0. The Spark hops once, 6 px, at 2.8, after the first blink. Nothing else moves.
- **Camera.** Held still.
- **Text.** In at 1.0. Out at 6.6. That is 15 words in 5.6 s. The wall above the window is plain black, so the GRAY text reads cleanly.
- **Transition.** Fade up from black over the first 0.36 s. Palette fade to black from 6.64, into H1.
- **Sound.**
  - `caller_blip` at 2.5 and 5.0, at -10 dB.
  - `amb_village` at -8 dB.
  - `intro_home` fades out from 5.4 to 6.6 (global 61.4 to 62.6), ending on its unresolved A chord.
  - `amb_village` fades out from 6.2 to 7.0. The game restarts its own copy.
- **Sheets.** `title_scene` (far), `title_caller` (blink_gray, NEW row), `intro_far` (gate_far, NEW), `intro_window` (frame, NEW), Spark in code.

### Hand-off

**Shot H1.** From global 63.0. This is the real game in Last Relay, not the intro scene.

- **0.0.** Black. The intro changes scene to `world1_play` as a new game. The game draws its first frame under black. Hold black for at least 0.3 s.
- **What the game sets up.**
  - The Spark lies, in a new code pose "lie", at village column 7, feet (120, 224).
  - Old Mast stands at his own cell (column 9, feet (152, 224)), facing left toward the Spark, showing `intro_npc/mast_lantern_look` (bent over, lantern low).
  - The village tint, music and ambience are as normal. This start point needs no change to `levels/village/village.txt`. See Q2.
- **0.3.** An iris opens centred on the Spark (its feet minus 6 px in y), with the radius going from 0 to 520 over 0.6 s, ease out. It is the title's closing circle played in reverse. `village_theme` starts from bar 1 at 0.3. Its D chord resolves the A chord `intro_home` ended on. `amb_village` starts at 0.3.
- **1.1.** The Spark sits up: pose "stand", a 2 px hop, `fx_dust/land` under its feet, `land_soft` at -6 dB.
- **1.4.** Old Mast plays `mast_lantern_stand`, and his first conversation opens by itself (`talk_open`, then `voice_mast` blips), exactly as if the player had pressed Down next to him. The player can't move until it ends. After the last line he goes back to `npc/mast_idle` and `met_mast` is set as usual.
- **Sheets.** `intro_npc` (mast_lantern_look, mast_lantern_stand, NEW), `fx_dust` (land), `npc` (mast_idle), Spark in code.

## 3. Asset request (pixel artist)

Seven new sheets and one new row on an existing sheet. Same rules as every other sheet: four greys only, all sprites face left unless noted, and animation rows as in `sheets.json`. From card 5 on, nothing in these sheets may be pure white except the Spark itself, so the lantern, the rings, the lit wire, the keeper's window and the far gate's lamp all top out at GRAY.

**N1. `intro_npc`** (16x24 frames, anchored like `npc`: top-left (cell x, cell y - 8), feet on the floor.)

| Row | Anim | Frames | Timing | Loops | What it shows |
|---|---|---|---|---|---|
| 0 | listener_sit | 2 | static | | A generic listener (not a named villager) sitting on the ground, knees up, with small headphones. Frame 0 looks ahead. Frame 1 tilts the head up at a passing pulse. Card 2. |
| 1 | mast_lantern_walk | 4 | 0.2 s each | yes | Old Mast walking slowly with his cane in one hand and a lantern held forward in the other. Card 9. |
| 2 | mast_lantern_stand | 2 | 0.4 s each | yes | Mast standing, lantern held out at chest height, swaying 1 px. Card 9 and the hand-off. |
| 3 | mast_lantern_look | 2 | 0.5 s each | yes | Mast bent over, looking down, lantern low near the ground. Hand-off. |

Notes: the lantern body is GRAY with a DARK cage. Put the lantern's centre on the same pixel in every Mast frame, or list it per frame, because the code hangs a light there.

**N2. `intro_poles`** (48x64 frames.) Top-left = (pole x - 12, wire y - 4). The switch contacts and the insulators sit at frame (15, 4) and (32, 4), the same as `title_pole`'s (3, 4) and (20, 4) moved 12 px right. The pole foot is on frame row 63 (screen y 249).

| Row | Anim | Frames | Timing | Loops | What it shows |
|---|---|---|---|---|---|
| 0 | switch_ready | 2 | 0.5 s each | yes | A pole with an isolation switch at the top: a blade across the two contacts and an operating rod running down the pole to a notched handle at chest height. It is the notched isolation handle from Brace's belt and the switch hut, as a story signature. A crew listener in a work coat and hard hat stands on the left with one hand on the handle. |
| 1 | switch_pull | 5 | 0.1 / 0.1 / 0.15 / 0.1 / 0.25 s | no | The crew grips, leans, heaves the handle down, and the blade swings open at the top (frame 2 onward), with a small DARK scorch mark at the contacts. The last frame is the crew still holding the handle down. |
| 2 | switch_after | 2 | 0.6 s each | yes | The switch is open and the crew stands with the head bowed, hand off the handle. |
| 3 | dead | 3 | static | | 0 a plain pole leaning left about 12 degrees, 1 leaning right, 2 a snapped stump about 24 px tall. No crew. Hand-drawn, not rotated in code. List the new insulator pixels for frames 0 and 1 in the README, because the code hangs wire from them. |

**N3. `intro_static`** (32x16 frames.) Centre it on the wire: top-left = (x - 16, wire y - 8).

| Row | Anim | Frames | Timing | Loops | What it shows |
|---|---|---|---|---|---|
| 0 | crawl | 4 | 0.06 s each | yes | The noise: a jagged white-and-DARK striped scribble riding the wire, leaning left the way it moves. It should read as danger, like the white striped enemies, and not like the Spark or the Arc. |
| 1 | stall | 3 | 0.08 s each | yes | Piled up against a gap, climbing over itself, sparks spitting forward into nothing. |
| 2 | die | 4 | 0.1 s each | no | Breaks into flecks that go GRAY, then DARK, then gone. |

**N4. `spark_close`** (48x48 frames.) The Spark at close-up size, twice the size of the in-game block (body 24x28 when standing). It has the same design as `J.spark`: white body, black visor with a GRAY pupil, GRAY trailing flicker at the back. Anchor bottom-centre: feet at frame (24, 47), so top-left = (feet x - 24, feet y - 47). Faces left like the other sheets, and the intro mirrors it. Changed from 32x32 with feet at (16, 31) when the art was made, because at twice size the flicker trails 10 px behind the body and the flare's rays need room round it. The anchor point on screen is unchanged, so shot 6A still puts the feet at (160, 226).

| Row | Anim | Frames | Timing | Loops | What it shows |
|---|---|---|---|---|---|
| 0 | curled | 2 | 1.2 s each | yes | Squashed low (about 24x14), curled, visor closed to a 1 px line. Mostly GRAY with a small WHITE core that grows 1 px on frame 1, like slow breathing. |
| 1 | stir | 3 | static | | Held one at a time by the code, one per ring: 0 a twitch, the core a little bigger. 1 half the body white, raised slightly. 2 the eye open. |
| 2 | flare | 4 | 0.06 / 0.06 / 0.1 / 0.12 s | no | A burst of white rays around the body, the body popping upright. The rays shrink back into a sitting Spark. |
| 3 | sit | 2 | 0.5 s each | yes | Sitting up, alert, facing the wire, the trailing flicker moving. |

**N5. `intro_wire_close`** (32x32 frames.) The close-up set pieces, also at twice game scale.

| Row | Anim | Frames | Timing | Loops | What it shows |
|---|---|---|---|---|---|
| 0 | grass | 4 | static | | Grass tufts, DARK and GRAY, bottoms on frame row 31, tiling edge to edge in any order. |
| 1 | wire | 2 | static | | A thick cable lying straight across the frame, centred on frame y 16 (3 px core with insulation joins), tiling left to right. DARK with a GRAY top edge. |
| 2 | wire_end | 1 | static | | The cut end: the cable arrives from the right and stops at frame x 4, with frayed strands splaying from the tip. The tip is at frame (4, 16). |
| 3 | wire_lit | 2 | static | | 0 the wire tile and 1 the wire_end tile, lit: the core GRAY and brighter, with a thin DARK glow dither above and below. No white. |
| 4 | ring | 3 | 0.06 s each | yes | A ring of light travelling along the cable: a GRAY bead with a DARK halo that pulses, centred on (16, 16). |
| 5 | ring_pop | 3 | 0.05 s each | no | The ring reaches the tip and bursts into four GRAY flecks, centred on (16, 16). |

**N6. `intro_far`** (64x64 frames.) Night silhouettes where the normal art would show white.

| Row | Anim | Frames | Timing | Loops | What it shows |
|---|---|---|---|---|---|
| 0 | keeper_night | 2 | 0.8 / 0.15 s | yes | `house` facade 0 (the keeper's house) as a night silhouette. The same outline and position, with the lit window (and its broken diagonal mullion) in GRAY instead of white. Frame 1 is a flicker of the window. Same anchor as `house`. |
| 1 | gate_far | 1 | static | | The World 1 gate transmitter seen from far off: about 32x60, a DARK lattice silhouette with one GRAY lamp pixel near the top, foot on frame row 63. The player will reach this in 1-4. |

**N7. `intro_window`** (320x176, one frame.)

| Row | Anim | Frames | Timing | Loops | What it shows |
|---|---|---|---|---|---|
| 0 | frame | 1 | static | | The keeper's window seen from inside, in DARK with GRAY edges. |

Notes for the window:

- The opening is transparent, from frame (12, 10) to (308, 150).
- There is one vertical mullion at frame x 146 to 150 and a transom at frame y 44.
- The upper left pane carries the broken diagonal mullion, the keeper's story signature.
- The sill runs from frame y 150 to 175, and its top edge (frame y 150) is the surface the Spark sits on.
- Keep the lower right pane (frame x 170 to 300, y 60 to 148) completely clear, because the gate and the caller show through it.

**N8. `title_caller` new row `blink_gray`** (8x8, an addition to the existing sheet.) The same 4-frame blink and timing as `blink`, with the white centre replaced by GRAY. It is used in cards 8 and 10 to keep the white-only-for-the-Spark rule.

Existing art reused, with nothing to redraw: `title_scene`, `title_pole`, `lamp`, `backdrop_w2` (relay tower), `ground`, `fx_light`, `arc_hit`, `fx_dust`, `npc`.

## 4. Sound request (chiptune composer)

All pieces use the house rules in `assets/audio/sfx8/README.md`: the four NES voices, D major for hope, falling to D minor for loss, and `lock=True` on every music loop. The intro runs at **80 BPM** (3600 / 45, so it fits the generator's clock), which makes one bar 3.0 s and a 6-second card two bars.

The sound is built (26 Sep 2026). Every file below is in `assets/audio/sfx8/`, and its README describes each one. 80 BPM is one of the generator's own tempos, so no timing in this list had to change. The lengths in the effects table are the built files' lengths.

### Music cues

Players can advance cards early, so the music is five pieces, not one fixed track. A cue starts when its act's first card starts. It keeps going if the player moves between cards in the same act. It crossfades over 0.3 s if they jump to another act. Every loop must sit well under a slow reader.

**M1. `intro_line`.** D major, 4 bars, 12.0 s, loops. Cards 1 and 2. Warm, a little old, like a music box.

| Bar | Global time | What happens |
|---|---|---|
| 1 | 0 to 3 s | A thin 12.5% arpeggio on D, F sharp and A alone, with the triangle on low D. |
| 2 | 3 to 6 s | Pulse 1 sings the FIRST LIGHT motif in D (A D D E F# D, short short short short long long). This is "the voice". |
| 3 | 6 to 9 s | Pulse 2 repeats the motif an octave down, one beat late. The relay passes the voice along. `amb_w1`'s two-note blip sits in a rest. |
| 4 | 9 to 12 s | The triangle answers with the motif's first three notes, and the bar turns to A to loop. |

Soft off-beat hi-hat on the noise voice throughout.

**M2. `intro_noise`.** D minor, 4 bars, 12.0 s, loops. Cards 3 and 4. Uneasy.

| Bar | Global time | What happens |
|---|---|---|
| 1 | 12 to 15 s | The same motif in D minor (A D D E F D). |
| 2 | 15 to 18 s | The noise voice crackles in, getting louder, and pulse 2 wavers a quarter-tone flat. |
| 3 | 18 to 21 s | The motif stutters, repeating its first two notes like a skipping line. |
| 4 | 21 to 24 s | A triangle pedal on A with noise swells. |

The code cuts it dead at global 19.25, when the line is cut, so it must sound fine stopped mid-bar. There is no need for an ending. In bar 3 every voice drops out from 7.125 s to 7.5 s into the cue (global 19.125 to 19.5), so if no card was skipped the cut lands in silence. Keep the 20 ms fade for when it lands anywhere else.

**Card 5.** No music.

**M3. `intro_still`.** D minor, 2 bars, 6.0 s, loops. Card 6. Tender and small. A soft triangle heartbeat on low D on beats 1 and 3. A very quiet 12.5% pulse holds a high A with slow vibrato. Pulse 2 plays one note a bar, F then E. It fades out at the start of card 7.

**M4. `intro_wake`.** D major, a 0.2 s pickup and then 1 bar, 3.2 s, plays once. Card 8, the flare. It follows the model of `title_intro`.

1. 0.2 s of static crackle as a pickup.
2. The downbeat at 0.2 s: both pulses at 50% on a D major chord, and the triangle leaping from D2 to D3.
3. A quick run up D, F sharp, A to a held high D.
4. It settles into the pickup of `intro_home` so the two join with no gap, the same way `title_intro` joins `title_theme`.

**M5. `intro_home`.** D major, 6 bars, 18.0 s, loops. Cards 8 (second half), 9 and 10. Relief and company.

| Bars | What happens |
|---|---|
| 1 and 2 | The FIRST LIGHT motif at half speed on a 25% lead, as `title_theme` does. |
| 3 and 4 | Warm broken chords on pulse 2 and a walking triangle bass, a nod to `village_theme`. |
| 5 | The title theme's faint two-note call goes out into the rests on beat 1. For the first time, it gets an answer: a softer copy two beats later, as the chord turns to A. With no skips, the call is at card 10 time 3.2 and the answer at 4.7. |
| 6 | Ends on A major, unresolved. It resolves into D when `village_theme` starts at the hand-off. |

The code fades it out over card 10's last 1.2 s. Card 10's second forced blink, at 5.0, comes 0.3 s after the music's answer. Moving it to 4.7 would land the far light on the answer.

### New sound effects

| Code | Name | Length | Feel | When |
|---|---|---|---|---|
| S1 | `line_pulse` | 0.45 s | A voice passing down the wire. A 12.5% pulse gliding quickly up from D5 to A5, with a quiet echo on pulse 2. | Card 2, at 1.5 and 3.3 (the second one 2 semitones up). |
| S2 | `static_crawl` | 1.0 s, loops | The noise on the line. Short-mode noise (metallic buzz) jumping pitch about 30 times a second, with an irregular 12.5% tick under it. | Cards 3 and 4, from 12.5 to 21.2 global. The code pans it with the static. |
| S3 | `lamp_off` | 0.28 s | A station light dying. `lamp_on` in reverse: a warm note falling a fifth, then two small crackles and out. | Cards 3 and 4, as each lamp goes out. It is also played quieter and lower for distant lights. |
| S4 | `wire_snap` | 0.63 s | The switch opens and the line breaks. A heavy clack (falling triangle and low noise), a bright arc crackle, a fast falling whip on a pulse, then a short ring-down. | Card 4, at 1.25 (global 19.25). `lever_pull` plays 0.35 s before it. |
| S5 | `static_die` | 0.50 s | The noise fizzling out at the gap. Crackle that thins and slows to single ticks, then stops. | Card 4, at 3.2. |
| S6 | `line_ring` | 0.89 s | The dead line ringing. An old phone bell: two 50% pulses trilling fast between A5 and D6 for about 0.6 s, with a soft triangle thump at the start, a fading tail and a slight wobble, as if heard down a long dead wire. It should be easy to hear as one "ring", so three in a row count clearly. The game can reuse it for Old Mast's "three rings". | Card 7, at 2.65, 3.85 and 5.05. |
| S7 | `spark_flare` | 0.60 s | The Spark wakes. A crackle of static swelling into a bright rising blip. It belongs with `arc_learn` but is shorter, and it must sit on top of `intro_wake`. | Card 8, at 0.2. |
| S8 | `caller_blip` | 0.34 s | The far light answering. The same two-note call as in `title_theme` and `amb_w1`, so players recognise it, with a softer echo replying. | Card 8 (at card time 3.0), card 10 (at 2.5 and 5.0). |

Existing sounds reused: `amb_w1`, `relay_hum`, `lever_pull`, `amb_village`, `door_open`, `village_theme`, `talk_open`, `voice_mast`, `land_soft`, plus `menu_tick` and `menu_confirm` for the skip bar.

## 5. Code notes

### Where it goes

- New scene `scenes/intro.tscn` with `scripts/intro/intro_scene.gd`. It uses the same fx layer (tint shader) and CRT layer set-up as `title_screen.gd`.
- The shot data lives in `levels/story/intro_shots.json`, next to `npcs.json`.
- `title_screen.gd` `_leave("new")` changes scene to the intro instead of `world1_play.tscn`. CONTINUE is unchanged.
- The intro sets `Game.start_mode = "new"` plus a new static flag, `Game.intro_handoff = true`, then changes scene to `world1_play.tscn`.

### Data format

The intro is a list of cards. Each card has its text and one or more shots, and each shot has layers, an optional camera move, and timed events. Times inside a shot are seconds from the shot's own start. The player moves card to card, so cards are the unit for skipping.

```json
{
  "bpm": 80,
  "text": {"scale": 2, "y": [28, 44], "color": "GRAY", "shadow": true, "cps": 40, "line_gap": 0.25},
  "tints": {"amber": "2", "grey": "test", "blue": "1", "warm": "village"},
  "cards": [
    {
      "id": 4, "dur": 6.0, "music": "intro_noise",
      "lines": ["SO THE CREWS CUT THE LINE TO STOP IT", "ONE STATION AT A TIME"],
      "text_in": 0.8, "text_out": 5.6,
      "shots": [
        {
          "id": "4A", "dur": 6.0, "tint": "grey", "carry": "3A",
          "in": {"type": "none"}, "out": {"type": "palette_fade", "at": 5.64},
          "camera": {"from": [0, 0], "to": [0, 0], "ease": "linear"},
          "layers": [
            {"type": "fill", "rect": [0, 0, 480, 270], "color": "BG", "extend": true},
            {"type": "stars", "n": 60, "seed": 91},
            {"type": "strip", "sheet": "title_scene", "anim": "far", "y": 160, "parallax": 0.2, "extend": true},
            {"type": "dots", "y": 209, "step": 24, "x0": 12, "color": "WHITE", "id": "horizon"},
            {"type": "fill", "rect": [0, 224, 480, 28], "color": "DARK", "extend": true},
            {"type": "strip", "sheet": "title_scene", "anim": "mid", "y": 188, "parallax": 0.5, "extend": true},
            {"type": "fill", "rect": [0, 252, 480, 18], "color": "BG", "extend": true},
            {"type": "sprite", "id": "switch", "sheet": "intro_poles", "anim": "switch_ready", "at": [188, 186]},
            {"type": "sprite", "id": "lamp2", "sheet": "lamp", "anim": "on", "at": [226, 217]},
            {"type": "wire", "id": "line", "y": 190, "sag": 6, "poles": [40, 200, 360], "color": "GRAY"},
            {"type": "sprite", "id": "noise", "sheet": "intro_static", "anim": "crawl",
             "path": [[0.0, 302, 190], [2.22, 222, 190]], "on_wire": "line", "center": true}
          ],
          "events": [
            {"t": 0.9,  "do": "anim",  "target": "switch", "anim": "switch_pull"},
            {"t": 0.9,  "do": "sfx",   "name": "lever_pull"},
            {"t": 1.25, "do": "sfx",   "name": "wire_snap"},
            {"t": 1.25, "do": "fx",    "sheet": "arc_hit", "anim": "hit", "center": [212, 190]},
            {"t": 1.25, "do": "shake", "amp": 2, "dur": 0.25},
            {"t": 1.25, "do": "wire_gap", "target": "line", "x": [203, 220]},
            {"t": 1.25, "do": "music_stop", "fade": 0.02},
            {"t": 1.25, "do": "amb_stop", "fade": 0.3},
            {"t": 1.6,  "do": "anim",  "target": "switch", "anim": "switch_after"},
            {"t": 1.89, "do": "lamp_out", "target": "lamp2"},
            {"t": 2.22, "do": "anim",  "target": "noise", "anim": "stall"},
            {"t": 3.2,  "do": "anim",  "target": "noise", "anim": "die"},
            {"t": 3.2,  "do": "sfx",   "name": "static_die"},
            {"t": 3.6,  "do": "lights_out", "target": "horizon", "from_x": 203, "dir": -1, "every": 0.3}
          ]
        }
      ]
    }
  ]
}
```

What the format covers:

- **Layer types:** `fill`, `stars`, `strip`, `dots`, `sprite`, `wire`, `tiles` (a grid of ground cells), `spark` (the code Spark, with pose, face, scale and path), `light` (a light for the darkness pass: position, radius, radius keys).
- **Paths.** `path` holds `[t, x, y]` keys and runs through `J.path`. A `hop` key uses `J.arc`.
- **`carry`** means "keep the state of that shot", so 3A to 4A and 6A to 8A are one continuous picture.
- **Positions** are always floored to whole pixels.
- **Camera** moves are pans only: `from`, `to` and `ease` (`linear`, `in_out_sine` or `out_quad`), floored to whole pixels, with each layer multiplied by its `parallax`. There is no fractional zoom. Close-ups are their own sprites.
- **Shake** respects `AppSettings.camera_shake`.
- **Tints** are only swapped on a cut or on black.
- **Palette fade** steps the shader's four `ramp` colours down one grey at a time, every 0.12 s.
- **Text** belongs to the card, not the shot, so it carries across the 8A to 8B cut.
- **Wide screens.** `extend` layers tile across the full view. Everything else is placed at hx + x.
- **Reduced flashes** (`AppSettings.reduced_flashes`):
  - no shake
  - the flare plays only frames 0 and 3
  - `fx_light` is skipped
  - the hand-off iris becomes a palette fade up

### Skipping

- **Settling in.** Ignore all input for the first 0.5 s, and count a button only after it has been released once. The title's confirm press is often still held when the intro starts.
- **Tap Jump or Down.** If the card's text is still typing, finish typing it. Otherwise go to the next card's start. The script asks for this.
- **Hold Jump or Down for 0.6 s.** A skip bar appears after 0.15 s of holding. It is 40x3 px at (430, 258) in the 480 column, GRAY filling a DARK track, with "HOLD TO SKIP" in GRAY at scale 1 to its left. `menu_tick` plays at each quarter. When it fills, `menu_confirm` plays, then a palette fade, then the hand-off. Let go early and it drains over 0.2 s. The brief asks for this.
- **Tap Pause (Esc or Start).** Skip the whole intro at once, with the same fade and hand-off. The script asks for this.
- **Always the same landing.** Skipping always lands in H1, with the Spark lying by Old Mast and his conversation opening. It never lands in plain play.
- **Music when skipping cards.** Moving to a card in the same act leaves the music alone. Moving into a new act crossfades over 0.3 s to that act's cue. Skipping into card 5 stops all sound, and skipping out of card 7 starts `intro_home` at its start. Skipping the rest of the intro fades any cue over 0.36 s.

### Hand-off into the village

- In `w1_game.gd`, when `start_mode == "new"` and `intro_handoff` is set, do the following. Clear the flag afterwards.
  1. Load the village.
  2. Put the Spark at column 7, feet (120, 224), in a new "lie" pose. Add it to `J.spark`: a body about 14x8, the visor as a closed 1 px line, no feet gaps.
  3. Show Old Mast with `intro_npc/mast_lantern_look`.
  4. Lock input.
  5. Run the iris and the timings in H1.
  6. Open Mast's `!met_mast` talk entry automatically.
- Mast shows `mast_lantern_stand` while he talks, and `npc/mast_idle` afterwards.
- A new game started without the intro (only possible if the intro scene fails to load) behaves as today.
- **Old Mast's lines.** Use the script's proposed replacements in `levels/story/npcs.json`, `mast`, entry `!met_mast`. Keep his other three lines.

  1. OH. YOU'RE AWAKE. GOOD. YOU CAME IN ALONG THE WIRE LAST NIGHT, RIGHT AFTER THE RINGING.
  2. THIS IS LAST RELAY. THE LAST STATION ON THE LINE THAT STILL HUMS. WE'VE HELD ON HERE ALL THROUGH THE QUIET.

### Open questions for Lee

- **Q1.** The script says tapping Pause skips the whole intro. The brief also asks for a hold-to-skip bar. This list does both. If only one is wanted, keep the hold bar, because a single tap can skip the story by accident.
- **Q2.** The script puts the Spark "by the signpost". The signpost is at the far east end of the village (section C). Old Mast stands near the west end (column 9 of section A), about 60 tiles away. This list puts the Spark next to Mast, which needs no level change. The signpost version would need Mast moved for the first meeting.
- **Q3.** In card 3 the noise arrives from the east, the same direction the call later comes from. That quietly links the two. Say if that link is unwanted, and the noise can come from the west instead.
- **Q4.** Whether the intro plays on every New Game or only the first. This list assumes every New Game, since it is skippable. If it should play only once, store `intro_seen` in the progress file.
