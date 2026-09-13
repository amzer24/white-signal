# WHITE SIGNAL — Game Design Document (living, v8)

> Active implementation: the **Godot 4.7 port** at repo root. `js-original/` is
> the feel reference. Tuning tables here remain the source of truth for both.



## Exploration design direction (13 September 2026)

The next prototype is **exploration first**: permanent ability discoveries,
interconnected districts and saved world restoration. The [research report](../docs/research/exploration/EXPLORATION-DESIGN.md)
and [interactive atlas](../docs/research/exploration/maps/atlas.html) define the
proposed direction, including biome goals, loops, puzzle states and asset needs.
The [effects study](../docs/research/exploration/notes/effects.md) adds a shortlist
for restrained restoration, lighting, weather and static-water experiments.

The [story study](../docs/research/exploration/notes/story-arc.md) connects the
regional repairs to an arc from following a call to sustaining a network of local
references. It preserves the restored world and supports alternate visit orders.

This is a design decision, not an implemented campaign migration. The current
three-relay run, card economy and boundary save remain live. The old eight-strip
sequence and mandatory random-draft progression below are historical proposals
where they conflict with the exploration direction. Prototype a separate saved
Listening Field loop before expanding later districts or replacing live saves.

## Current build and next design decisions (v8, 12 September 2026)

**Implemented:** R0 tutorial → R1 Listening Field → R2 The Stand. Walk into the
R0 transmitter, then press Enter/Space or click to travel onward. R1 requires
three awakened dishes before its transmitter opens. After R2, the build says
3 of 8 relays are playable; the Signal has not yet been restored at the source.
R3–R7, SKIP/CLING, synergies, tide, overclocking and heat remain design targets.
The older v6/v7 sections below record the full ambition, not shipped features.

**The first strip is the tutorial.** Its FLATS/RUINS/GATE zones are teaching
vignettes inside R0, not the entire world. The old gate silhouette now means a
local transmitter. Reserve THE GATE and SIGNAL RESTORED for the R7 ending.

### What a run remembers

The deck, shard remainder, elapsed run time and deaths carry between relays.
Deaths retain collected shards, consumed blocks and awakened dishes within the
current relay, but re-form NOISE and repair crumbles. A new run reconstructs all
entities. Boundary saves restore the *start* of the current relay with the build
and totals held on entry, not a mid-room quicksave. Press C on the title screen
to continue. Starting a new run replaces that boundary save. Legacy tutorial
best times remain separate; this build does not write a false campaign record.

### Mario lessons, translated into this world

The aim is tactile curiosity: test a familiar surface, receive a clear response,
and learn that infrastructure can hold secrets. Nintendo's Wonder developers
emphasise recovering surprise even in familiar interactions; our translation is
that a familiar object can reveal how the Operators lived, as well as a reward.
Primary reference: [Nintendo, Ask the Developer: Wonder, part 1](https://www.nintendo.com/us/whatsnew/ask-the-developer-vol-11-super-mario-bros-wonder-part-1/).
These WHITE SIGNAL adaptations are design proposals/implementation choices,
not claims that Nintendo prescribed them.

- **Memory block (implemented):** outlined block with a diamond. Jump into its
  underside to release one shard, bump the face and empty its core. It remains
  solid and cannot be farmed through deaths. It is a stored packet, not a coin box.
- **Relay brick (implemented):** mortar pattern; strike from below to break it.
  No special glyph required. Breaking it does not award another currency.
- **Maintenance conduit (implemented):** recessed lip and down chevron. Stand
  over it and press Down/S to travel. Every branch and archive has a marked
  return. No accidental entry while landing; a short transit lock prevents
  same-frame re-entry. Conduits are non-solid mouths cut into existing floors.
- **Memory afterimage (research):** a struck block lights the room as it was
  before the Silence: occupied chairs become empty again as the image decays.
- **Conductive shell (future prototype):** a knocked-loose NOISE casing slides
  along a cable, waking remote relays or striking brick chains. Give it a visible
  rebound tell and a safe first demonstration before combining with hazards.
- **Secret grammar:** show the exit convention before hiding an entrance. Teach
  one intact conduit safely; later reveal one behind patterned breakable masonry.
  Prefer an optional pocket that changes the player's reading of the place to
  a mandatory invisible wall. No required exit depends on a random draft.

### Authored relay sheets for this build

| Relay | Player goal / owned interaction | Route and remix | Environmental beat | Current budget |
|---|---|---|---|---|
| R0 The Flats Line | Reach; learn the basic verbs | Existing 3800px tutorial, unchanged geometry | Hardware still works without its people | 24 shards, 4 beacons |
| R1 The Listening Field | Wake three dishes in any order; enter conduits and strike memory | Safe hub → RISE steps / CROSS crumbles / SEARCH masonry; optional archive; return to open transmitter | Maintenance routes outlast their maintainers; archive receiver beside an empty seat | 16 loose + 6 block shards, 4 beacons |
| R2 The Stand | Cross the fallen dish; maintain movement over fragile bridges | Four bridge stretches, masonry, optional high braces and spring; safe receiver after each crossing | Transmission hardware became a failing road | 19 loose + 4 block shards, 5 beacons |

R1 deliberately uses accessible 36px steps for its first authored pass rather
than requiring a purchased air jump. Each spoke is physically separated and
returns to the hub. R2's rain grows every 40 seconds since death or reaching a
different beacon: 22/38/54 drops, with crumble delay 0.45/0.35/0.25 seconds.
Death calms the rain; revisiting the current beacon does not repeatedly reset it.
The escalating state is also shown as RAIN 1/3–3/3. No hidden lethal puddles yet.

### Full campaign guardrails

The eight-relay sequence in §7d remains the destination: REACH → WAKE → CROSS →
RIDE → HOLD → CLIMB → OUTRUN → PLANT. Every relay needs a safe introduction,
one harder application, one combination, a quiet aftermath, and a visible exit.
The short Wire interlude must provide environmental dash sources if dash is
required; random glyphs may change the line, never decide whether it is possible.
The finale should resolve the repeated act of carrying a signal, not introduce
a new combat verb. Final narrative interpretation needs its own deliberate pass.

**Economy risk:** 69 available shards in this three-relay build yield 13 surges,
with remainder 4. A four-notch build can fill long before the end. Do not simply
multiply that cadence across eight relays. Next economy experiment: retain five
shards as an early tutorial rhythm, then offer *replace or skip* at relay boundaries
and budget optional secrets as alternate draft access. Test replacement before
adding further glyphs. Current pickups and block rewards stay once per relay;
retrying an entry save rewinds rewards and totals together.

**Art direction:** new levels reuse the established dithered materials and biome
backdrops. Bespoke landmarks, dish animation, lit-window persistence and advanced
NOISE silhouettes need another pass. Lighting/darkness is queued as a dedicated
research brief in [docs/BACKLOG.md](../docs/BACKLOG.md), including gameplay light,
afterimages, navigation, Godot feasibility and accessibility.

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

## 2b. Lore bible (v6)
Everything below is **shown, never told**. No cutscenes, no text walls. The
world explains itself through what's standing, what fell, and what still blinks.

### The Relay
Before the Silence, a chain of transmitters carried the WHITE SIGNAL across the
world — not radio, not light: the thing that let things *cohere*. Machines ran
on it. Halls stood because of it. The Operators tended the chain from the FLATS
(the receiving end) to the GATE (the source).

### The Silence
The Signal didn't fail — it was **drowned**. NOISE is what fills a channel when
the carrier drops: a static that eats structure. It came in from the far end
(the GATE, where the Signal was strongest, so its absence is loudest) and rolled
down the chain. The RUINS are where the Operators made their stand: they
crowded the halls with dishes trying to re-catch a carrier that was already
gone. The FLATS never fought — they just went quiet.

### The Spark
You are what's left of the Signal: one coherent packet, small enough to have
survived in a dead receiver on the FLATS. You don't know you're the last one.
You move because moving is what Signal does. You carry the carrier.

### Shards
Fragments of Signal that crystallised where the carrier died mid-transmission.
Touching one re-absorbs it — you get brighter (surge pips) and every 5th one
is enough coherence to **re-write yourself** (a SURGE: draft a GLYPH). Glyphs
are the Operators' old protocol words — DASH, AEGIS, MAGNET — instructions the
Signal used to obey. Cursed glyphs are corrupted words: they still work, but
they were written *by the NOISE*.

### Beacons
Repeaters. The Operators' last automatic systems: each one wakes when Signal
touches it, and holds a copy of you (that's the respawn — the beacon re-sends
you). Beacons also *mend* (AEGIS refill) because a repeater cleans a signal.

### NOISE
Not monsters — **patterns**. Static that learned a shape by eating one. The
walkers are the ghosts of maintenance drones. They can't see you; they *hear*
you (they turn when you land hard — future hook). Killing one doesn't end it:
NOISE is a channel condition, so when you die (lose coherence) the whole
channel re-fills. That's why every death re-forms every NOISE.

### The GATE
The source transmitter. Its beacon still blinks because the *hardware* never
broke — there was simply nothing left to send. Reaching it with the Spark
intact is the win: the carrier is re-seeded, the chain re-lights (win screen
title: SIGNAL RESTORED). But the run is a loop by design — the Signal has to
keep being carried. (Meta layer, §13: each restored run raises the *heat*.)

### Environmental storytelling checklist (what the biomes must say)
| Biome | What you should infer without being told |
|---|---|
| Salt Flats | The receiving end. Dead calm. One sun that is a signal, not a star. Dishes half-buried = nobody listened here for a long time. Survey posts = someone once measured the silence. |
| Relay Ruins | The stand. Too many dishes. Halls cracked open. Hazard signs. Rain of static = the NOISE still falls here. Lit windows = *one or two things still have power*. |
| Gate Approach | The source. Live infrastructure: lamps still lit, conduits blinking, transformer yards humming. Sparks rise = residual Signal leaking upward toward the spire. It's the most alive place — and the most NOISE. |

## 2c. Learning from the best (what we steal, and what we refuse)
| Game | The lesson | How WHITE SIGNAL applies it |
|---|---|---|
| **Celeste** | Forgiveness tech is the game (coyote, buffer, corner correction); dash is a *resource* you read on the character (hair colour); every screen teaches one thing; assist mode is not shameful. | Already in: all four feel aids; DASH pip over the head + live DSH chip. **Add**: REPEATER crystals (§7c) that refill dash mid-air = Celeste's diamonds. Assist toggles (§15). |
| **Hollow Knight** | Charm notches make builds a *budget*, not a list; the map is the story; benches as the emotional heartbeat. | Notches are in. **Deepen**: notch *slots* on the HUD show shape, not just count; beacons get a resting idle so they feel like benches (§7c). |
| **Dead Cells** | Every pickup changes how you *move*; kills flow into movement; the run is a loop with escalating "cells" difficulty. | Glyphs must be verbs — no +5% stats (checked: SWIFT is borderline; keep but pair it with a verb synergy §6b). **Add**: heat modifiers (§13). |
| **Slay the Spire** | Skip is a real choice; synergies emerge from ~10 simple cards; risk cards pay in a different currency. | Skip is free. **Add**: explicit **synergy pairs** (§6b) so drafts have "I'm building toward X" moments; cursed row already pays in safety. |
| **Ori** | Momentum chains (bash → jump → dash) make traversal expressive; the world lights up as you restore it. | **Add**: verb chaining rules — a wall-kick within 0.15s of a dash keeps 100% of dash speed (§7c). Beacons re-light the local backdrop (window pixels flip on) when activated. |
| **Downwell / Spelunky** | One mechanic, deep consequences (gunboots); the level itself is the enemy. | STOMP+ is our gunboots seed: stomp chains with rising bounce (§6b). Crumbles + movers + NOISE timing already make the level hostile; **add** hazard *combinations* per zone (§7c). |
| **Rain World** | Ecosystems, not enemies: creatures have their own business; weather is a clock. | NOISE variants with *routines* (§5b) rather than "walk left-right"; the static rain and rising sparks become a **visible timer** for the tide mechanic in Z3. |
| **Inside / Limbo** | Silhouette readability; the background *is* the narrative; no HUD noise. | Our 4-gray rule. Every biome has one landmark you walk toward. **Keep HUD minimal**: the top plate hides during the first 3s of a zone banner (§10). |
| **Super Meat Boy** | Instant respawn; death is a lesson measured in <1s; the replay ghost shows you what you did. | Respawn is instant. **Add**: best-run **echo ghost** (a gray spark replaying your best time; §13). |
| **Shovel Knight** | Sub-weapon economy is readable at a glance; checkpoints you can *break* for reward. | **Add**: optional **overclock** a beacon — spend it (no respawn here) for a guaranteed rare draft (§7c). Risk you opt into. |
| **Katana Zero / Hyper Light Drifter** | Hitstop + screen shake + a single clean SFX per action = weight without gore. | In: hitstop on kills, shake table. Keep SFX square-wave, one voice per action. |
| **What we refuse** | HP bars, shops, currencies, dialogue boxes, colour-coded threat, permanent upgrades that trivialise movement. | The Spark has no HP; the only economies are shards → drafts and notches. All text is ≤ 4 words on a sign or a 1-line banner. |

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

## 5b. NOISE bestiary (patterns, not monsters)
All NOISE: 14×18 white body, black eye, dies to DASH and stomp; every death
re-forms every NOISE. Each variant is a **routine** you can read from 1 screen
away, and each has a **tell** (blink) before its dangerous move. GDD §4: danger
blinks, it never hides.

| Name | Routine | Tell | Kill rule | Zone debut |
|---|---|---|---|---|
| **WALKER** (current) | Patrols a span, turns at ends. | Squash + blink 20px before a turn. | Stomp / dash. | Z0 |
| **SKIP** | Walker that hops a 40px arc every 1.6s — jumps over your low dash. | Crouches (squash 2px) for 0.25s before the hop. | Stomp at apex / dash while grounded. | Z1 |
| **CLING** | Sits on a wall, drops when you pass beneath, then crawls back up. | Eye turns white 0.3s before the drop. | Dash while it's on the wall; stomp when it's on the floor. | Z1 (shaft) |
| **HUM** | Stationary turret; fires a 1px static bolt horizontally every 2.2s (bolt = lethal, blockable by AEGIS). | Pulses brighter 0.4s before firing; the bolt has a 0.15s wind-up line. | Stomp only (dash bounces off — it's anchored). | Z2 |
| **SWARM** | Cloud of 6 static specks that drifts toward you at 40px/s; lethal on contact; dissolves if you outrun it for 3s. | Specks tighten before a lunge. | Dash through it (kills 3), STOMP+ shockwave clears it. | Z2 sprint |
| **ECHO** (cursed glyph spawn) | A gray copy of the Spark spawned where you last died; walks your last 3s of input on loop. | It's the only gray thing that moves like you. | Any. | Only with the ECHO curse (§6b) |

Rules: max 2 variants on any screen; a variant is introduced alone on a safe
screen before it appears with hazards (§4 pillar 5).

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

## 6b. Glyph deck v6 — synergies, new words, new curses
### Synergy pairs (drafting should feel like building toward something)
When both are held, the pair unlocks a named combo; the HUD chips touch
(drawn as one plate) so you can see the link.
| Pair | Combo | What it does |
|---|---|---|
| DASH + STOMP+ | **PILEDRIVE** | Dash, then jump: the dash becomes a downward slam with a 60px shockwave on landing. |
| DASH + 2×JUMP | **RELAY** | An air jump refunds the dash (once per airtime). Ori-style chains. |
| FEATHER + SPRING | **KITE** | Springs launch 20% higher and you can steer 40% more in the air off them. |
| SWIFT + MAGNET | **TRAWL** | Above 150px/s, shards within 80px fly to you. Speed is rewarded with drafts. |
| AEGIS + HEAVY | **ANVIL** | A shielded hard landing (>260px/s) kills NOISE within 30px instead of just squashing. |
| GLASS + SWIFT | **RAZOR** | Above 200px/s you are lethal on touch (you become the dash). Any hit still kills you. |

### New normal glyphs (pool grows 8 → 11; still 1-of-3)
- **REPEAT** (cost 1): touching a beacon while at full shield gives one *stored*
  dash usable after death (respawn with dash charged even off-ground).
- **DRIFT** (cost 1): wall slide is 30px/s slower and wall grace is 0.2s — the
  climbing verb.
- **PULSE** (cost 2): STOMP+ and dash kills emit a 90px ring that pops shards
  free from NOISE (each NOISE now drops a shard on kill). Kills feed drafts.

### New cursed glyphs (row grows 2 → 4; still a 2-notch budget)
- **HOLLOW**: MAGNET always on, but shards are worth ½ toward the next SURGE.
- **STATIC**: the screen edge fills with static proportional to your speed
  (vignette becomes noise); at max run you can see ~360px. +30% run speed.
- **ECHO**: when you die, an ECHO NOISE spawns where you died. +1 notch capacity.

### Draft economy tweak
- Surge cadence stays 5 shards, but every SURGE after the third offers one
  **synergy-aware** card: if you hold half of a pair, the other half is
  guaranteed in slot 3 (like the DASH marquee guarantee). Builds *complete*.

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

## 7b. World & biomes (v5)
The relay line is one continuous 3800px walk from the last dead transmitter to
the GATE. Each zone is a **biome**: its own skyline, its own weather, its own
silhouette vocabulary — so the player always knows where they are without
reading the HUD, and the horizon tells the story before the platforms do.

### The world in one breath
Long ago the relay chain carried the WHITE SIGNAL across the flats, through the
ruined relay city, up to the GATE transmitter. When the signal died, NOISE
crept in from the far end. You walk the chain **backwards along its decay**:
the FLATS are simply dead, the RUINS are where the collapse happened, and the
GATE is where the signal — and the NOISE — is strongest.

### Biome table
| Zone | Biome name | Mood | Sky | Skyline (far) | Mid | Weather / ambient | Landmark |
|---|---|---|---|---|---|---|---|
| Z0 FLATS | **The Salt Flats** | empty, calm, learn | The **dead broadcast sun**: a huge dithered disc with dropped scanlines, barely parallaxing (0.06x) | Flat stepped **mesas** (0.2x), antenna-tower silhouettes (0.25x) | **Fallen pylons** lying at 25° (0.5x), relay-ruin blocks with breathing lights | **Wind**: dust streaks racing right, low over the dunes; sparse STATIC | the sun — it never sets, it never rises |
| Z1 RUINS | **Relay Ruins** | cluttered, risk, vertical | Darker, horizon bands sit 10px lower, thicker fog | **Broken relay halls** with arched window holes (sky shows through; rare lit window) forming a jagged skyline (0.3x) | A **collapsed dish** on its struts (0.4x); **broken pillars** strung with sagging cable; rubble on the dune line (0.5x) | **Static rain**: short vertical drops; densest STATIC and starfield; antenna towers fade out (they fell here) | the dish |
| Z2 GATE | **The Gate Approach** | ascending, climax, sprint | **Gate glow**: sky brightens toward the goal; the light pillar breathes | The **GATE spire**: a 230px tapered lattice tower anchored on the goal (0.2x) — it appears at the screen edge when you enter Z2 and slides to centre as you approach; **signal arcs** crackle off its tip every ~4s | **Cliff slabs** with strata (0.5x); a march of **tall lattice pylons** (0.35x) | **Rising sparks**: bright pixels drifting up toward the spire; dunes flatten to rock | the spire |

### Rules for biome art
- **Silhouettes, not scenes.** Everything behind the play layer is a flat
  dithered cut-out in `#0e0e0e`–`#2e2e2e`. Nothing back there is ever brighter
  than DARK except a single lit pixel (tower light, window, spire beacon).
- **One landmark per biome**, anchored in world space, that the player walks
  toward or past. Landmarks are the wayfinding; signs are the teaching.
- **Parallax is depth-correct**: an element at world `wx` with speed `s` is
  drawn at `screen_x = (wx − cam_center) · s + 240`, so it is centred on screen
  exactly when the camera is centred on it, at any depth. This is what lets the
  spire behave like a real far object you approach.
- **Biome layers fade by zone weight** (smoothstep ±150px across each boundary)
  so a far RUINS hall doesn't haunt the FLATS, while shared layers (stars,
  dunes, cables, signal-ghost pulse) run the whole world.
- **Weather is directional and tells you where you're going**: wind blows
  toward the GATE in the FLATS; rain falls in the RUINS; sparks rise in Z2.
- **Baked once, drawn cheap**: complex silhouettes are painted into textures at
  boot (world-coord dither so nothing swims) and blitted per frame.

### Biome props (play-layer dressing)
Small baked pixel props stand on platform lips, auto-placed by world-coord hash
(density Z0 16% · Z1 26% · Z2 24% per 14px probe) and never within 22px of a
spike, spring, sign, beacon, goal or spawn. Rule: DARK body, GRAY detail, one
WHITE pixel at most — a prop must never read as platform, hazard or pickup.
| Biome | Props |
|---|---|
| Salt Flats | salt crystal cluster · dead shrub · survey post · buried dish rim · pebbles · carved signal stone |
| Relay Ruins | rubble heap · broken pipe (drips) · cable coil · column stub · hazard sign · static puddle (shimmers) · fallen girder |
| Gate Approach | conduit box (pip blinks) · cable bundle · lamp post (glow cone) · floor grate · gate crystal shard (pulses) · warning stripes (platform edges) · whip antenna (sways) |
Extra landmarks: crashed satellite hull (Z0, 0.5x), broken arches (Z1, 0.3x),
transformer yards with live panel lights (Z2, 0.5x).

### Zone beats (what the player should feel, in order)
1. **Z0** — open sky, one sun, one sign: *ARROWS MOVE*. Space to breathe and
   learn. First wall, first beacon, first SURGE (DASH guaranteed).
2. **Z1** — the horizon fills with broken halls; rain starts. Crumble bridge,
   spring, the HIGH LINE tempting above. The world is a hazard now.
3. **Z2** — the spire is visible from the first step. Every screen it gets
   bigger. Notch capacity +1 ("bigger builds for the Gate sprint"). Shaft
   climb → spike corridor → spring → the GATE.

### Future biomes (roadmap, not built)
- **Z3 STATIC SEA** — a flooded array field: the ground is dithered "water"
  that reflects the skyline; drowned dishes as islands; the NOISE swims.
  Mechanic: rising/falling tide platforms (timed movers on a global clock).
- **Z4 THE ARRAY** — inside the transmitter: vertical shafts, moving girders,
  the light pillar becomes the level. Mechanic: signal-charged walls that only
  hold a wall-slide while lit.
- **INTERLUDE: THE WIRE** — a single long cable between two pylons; pure
  momentum test between biomes; no ground.

## 7c. Traversal verbs & level grammar (v6)
### Verb chaining (Ori rule)
- A wall-kick within 0.15s of a dash ending keeps 100% of dash speed (no
  overspeed decay for that kick). A dash *into* a spring during the 0.3s
  spring window adds the momentum bonus on top (capped 120).
- Stomp bounces are **rising**: each consecutive NOISE stomped without touching
  ground adds +40px/s to the bounce (Downwell). Chains reset on landing.

### REPEATERS (Celeste crystals, in our language)
Small floating ◇ rings placed in the air. Touching one refills DASH and air
jumps *mid-air* and pops with a chime; it re-lights 2s later. They let a level
ask for two dashes in a row without giving you a permanent second dash. Placed
only where a route is *optional* (secret shard lines) until Z3.

### Beacon interactions
- **Rest**: standing still on a beacon for 1s plays a 2-note idle and shows
  your deck as glyph names (Hollow Knight bench moment). The local backdrop
  re-lights: nearest hall windows / conduit pips flip on and stay on.
- **Overclock** (opt-in risk): hold DOWN on a beacon for 1s to *spend* it — it
  goes dark (no respawn here; you fall back to the previous beacon) and the next
  SURGE is guaranteed to offer a 2-cost glyph and a cursed glyph.

### Hazard grammar per zone (safe intro → risk → remix, §7)
| Zone | Verbs taught | Hazard combos allowed |
|---|---|---|
| Z0 FLATS | run, jump, hold-jump, wall-kick | single hazard per screen |
| Z1 RUINS | crumble timing, springs, movers, SKIP | crumble + NOISE, spring + spikes |
| Z2 GATE | shaft climbing, lifts, CLING, HUM, sprint | mover + HUM, spikes + SWARM in the sprint |
| Z3 STATIC SEA (future) | tide timing (global clock), REPEATER chains | tide + NOISE, tide + spikes |
| Z4 THE ARRAY (future) | signal-charged walls (slide only while lit), vertical girders | lit-wall + HUM, lift + SWARM |

### The tide (Z3 mechanic sketch)
A world clock (the static rain becomes the visible timer: it *stops* for 2s
before a tide change). Every 6s the water line rises/falls 40px: low tide
exposes platforms and drowned dishes; high tide drowns spikes (safe!) but
also NOISE swims faster. Tide platforms are movers on the global clock.

## 7d. The campaign — THE RELAY CHAIN (v7)
The current 3800px strip is **RELAY 0**, the tutorial. A full run is the whole
chain: **8 relays, ~30 min**, deck carried throughout, each relay ending at
its own transmitter (a "gate" you *light*, which becomes the next relay's
beacon). Deaths respawn at beacons; only quitting ends a run (the run is
saved at each lit relay so you can resume from a relay start with your deck).

### The level design template (every relay must answer all nine)
| Field | Question it answers |
|---|---|
| **Goal verb** | What is the player *doing* on this level, in one verb? (reach / wake / cross / ride / hold / climb / outrun / plant) |
| **Owns** | Which mechanic does this level *own* (introduce alone, then remix)? |
| **Lore beat** | What does the player learn about the world *without text*? |
| **Landmark** | The one thing on the horizon you walk toward. |
| **Twist** | The remix at ~70%: the owned mechanic + one earlier mechanic. |
| **Secret** | One optional route, glyph-gated, worth a shard cluster. |
| **NOISE roster** | Which patterns, max 2 variants per screen. |
| **Economy** | Shards / surges / beacons / target time. |
| **Exit** | How the transmitter is lit (varies — never just "touch the door"). |

### The eight relays
| # | Relay | Biome | Goal verb | Owns | Lore beat |
|---|---|---|---|---|---|
| **R0** | **THE FLATS LINE** *(current)* | Salt Flats → Ruins edge → Gate spire glimpse | **REACH** the gate | Run / jump / wall-kick / first draft | The world is dead but the hardware isn't. |
| **R1** | **THE LISTENING FIELD** | Salt Flats, deep | **WAKE** three EARS (dead dishes) in any order | Non-linear hub; SKIP NOISE; MAGNET tempts | Someone measured the silence for years. Nobody listened back. |
| **R2** | **THE STAND** | Relay Ruins | **CROSS** before the roof comes down (static rain intensifies; crumbles break faster over time) | Crumble timing under pressure; CLING; springs | Where the Operators fought — and lost — trying to re-catch a carrier that was already gone. |
| **R3** | **THE DROWNED ARRAY** | Static Sea (new) | **RIDE** the tide; carry the three CARRIER shards to the gate at low tide | The tide clock (rain stops = tide turns); REPEATER chains | The sea isn't water. It's static that pooled where the ground was lowest. |
| **R4** | **THE WIRE** *(interlude)* | A single cable over the abyss | **HOLD** momentum; no beacons; 60s | Verb chaining (dash → kick → spring); AEGIS matters | The last link the Operators strung by hand. It still holds. |
| **R5** | **THE ARRAY** | Inside the transmitter (new, vertical) | **CLIMB** 1200px | Signal-charged walls (slide only while lit, on a 4s clock); HUM turrets; lifts | The machine still runs. It has had nothing to send for a very long time. |
| **R6** | **THE APPROACH** | Gate Approach, expanded | **OUTRUN** the SWARM wall (Ori escape, 90s) | Sprint under pressure; every verb at speed; SWARM | The NOISE is thickest where the Signal was strongest. It's waiting at the source. |
| **R7** | **THE GATE** | The source | **PLANT** the Spark in three sockets while THE HOWL cycles | Finale: all tells combined; no new verbs | The Howl is what the Signal became. You are not restoring it. You are replacing it. |

### Relay sheets
**R0 · THE FLATS LINE** — as built. Exit: touch the gate. Economy: 24 shards / 4–5 surges / 4 beacons / ~2:30.

**R1 · THE LISTENING FIELD** — a hub with three spokes. Landmark: the dead
sun, now *huge* (0.04x), with the three EARS silhouetted against it. Each EAR
is a dish on a plinth; touching its feed horn wakes it (beacon chime, dish
turns to face the sun, backdrop windows re-light). Spokes: *north* (wall-kick
chimney, SKIP NOISE on the ledges), *east* (crumble field, first time crumbles
+ NOISE), *south* (a pit with a MAGNET-tempting shard bed — MAGNET is the
marquee glyph here, guaranteed at the first surge). Twist: waking the 3rd EAR
makes the hub *hum* — the sun brightens and a SWARM seed drifts toward you for
the walk back to the gate (a taste of R6). Secret: DASH gate above the north
spoke → a fourth, broken EAR with 5 shards. Exit: the gate lights when all 3
EARS face the sun. Economy: 30 shards / 5 surges / 4 beacons (hub + 3) / ~4:00.
NOISE: WALKER, SKIP.

**R2 · THE STAND** — a long ruin interior/exterior. Landmark: the collapsed
dish, walked *through* (its rim is the mid-level bridge). The static rain
gets heavier every 40s (visible: density + sound); each rain tier shortens
crumble time (0.45 → 0.35 → 0.25s) and makes puddles lethal (static pools,
AEGIS blocks). Owns: pressure. Beats: exterior crumble bridge → hall interior
(CLING introduced alone on the walls) → spring gauntlet under the roof →
dish rim bridge (crumble + CLING + spring, the twist) → the gate in the hall's
last standing tower. Secret: FEATHER/2×JUMP high line through the broken roof
with a shard cluster + a still-lit control room (lore: the last Operator's
chair, a glyph carved into the wall = a free REPEAT glyph). Exit: kick the
gate's fuse (a spring) — you *spring* into the transmitter. Economy: 28
shards / 5 surges / 5 beacons / ~4:30. NOISE: WALKER, SKIP, CLING.

**R3 · THE DROWNED ARRAY** — the first new biome. Ground is dithered static
"water" that reflects the skyline; drowned dishes are islands. The tide: every
6s the line rises/falls 40px; low tide exposes girders and the three CARRIER
shards (◆ with a ring, they don't count as normal shards); high tide drowns
spikes (safe) but NOISE swims faster. The rain stopping for 2s is the tell.
REPEATERS appear between islands so DASH chains cross wide water at high tide
only. Twist: carrying a CARRIER makes you heavier (HEAVY stats) until you
socket it at the gate — so the return trip is a different jump. Secret: the
deepest island, reachable only at the *lowest* tide (every 4th cycle), holds
a cursed-only draft. Exit: socket all three carriers → the gate rises from the
water. Economy: 26 shards + 3 carriers / 4 surges / 4 beacons / ~5:00. NOISE:
WALKER (swimming variant: same pattern, submerged = only its eye shows), SKIP.

**R4 · THE WIRE** — one screen tall, 2400px long, a single sagging cable with
pylons every 300px. No beacons: fall = restart the wire (not a death — the
chime is different, "line dropped"). Springs on the pylon caps, REPEATERS mid-
span, SWARM seeds drifting across the cable. Pure verb chaining: dash → kick
off a pylon → spring → REPEATER → dash. AEGIS turns one fall into a catch.
Exit: reach the far pylon, which *is* the next relay's beacon. Economy: 12
shards / 2 surges / 0 beacons / ~1:00. Lore: the Operators' handwriting — the
pylons are numbered by hand, and the last one has a name scratched on it.

**R5 · THE ARRAY** — vertical, inside the transmitter. 1200px tall, camera
follows up. Walls are relay panels; a wall only holds a slide *while its
status pips are lit* (4s on / 2s off, staggered per column — the level's
heartbeat, audible as a hum). HUM turrets on the girders fire across the
shaft on the same clock. Lifts on the clock too. Twist: the top third's
clock *inverts* (walls lit while HUMs fire). Secret: a maintenance shaft
behind a vent grate (STOMP+ breaks it) with the level's only 2-cost draft.
Exit: reach the top and *stomp* the master breaker — every pip in the level
lights and stays lit; the background spire beacon (visible from R0!) turns on.
Economy: 24 shards / 4 surges / 3 beacons / ~4:00. NOISE: CLING, HUM.

**R6 · THE APPROACH** — R0's Z2 expanded to 3000px and turned into an escape:
a SWARM *wall* (screen-wide static) advances from the left at 90px/s from the
moment you cross the first beacon. It never speeds up; the level does — spike
corridors, lifts on clocks, SKIP NOISE placed to cost you a jump. Every glyph
you hold is a second gained. Beacons here are *checkpoints for the wall too*
(die → wall resets 200px behind the beacon). Twist: the last 500px is
downhill onto springs — a victory-lap sprint where speed is free. Secret:
none (the sprint is the reward). Exit: the gate is open; run through it.
Economy: 22 shards / 3 surges / 4 beacons / ~1:30. NOISE: SKIP, SWARM.

**R7 · THE GATE** — the finale, one arena screen-set (1200px) around the
source transmitter. THE HOWL is the NOISE that ate the Signal: a screen-tall
static column that cycles patterns (WALKER sweep → SKIP arcs → HUM bolts →
SWARM burst), each with the bestiary's tells. No HP bar. Goal: PLANT the Spark
in three sockets around the arena (stand on a socket 1.5s while the pattern
plays — a stand-still challenge in a game about moving). Each planted socket
lights a third of the arena's pips and removes one pattern from the cycle.
Twist: after the second socket, the Howl inverts the arena (springs become
crumbles, crumbles become springs — the glyph chips flip too). Exit: third
socket → SIGNAL RESTORED. Lore beat on the win screen, one line only: *THE
CARRIER IS YOU.* Economy: 12 shards / 2 surges / 3 beacons (one per socket)
/ ~3:00. NOISE: all, as patterns of the Howl.

### Relay hardware — the Mario layer (v7)
Classic block-and-pipe verbs, re-skinned into the fiction. They make levels
*tactile*: the world has things in it you can act on, not just cross.

| Mario | Ours | Rule |
|---|---|---|
| `?` block | **CACHE** — a relay storage box, `[?]` glyph pulsing on its face | Bump from below (head-hit while rising): the box hops 4px, chimes, pops its contents out of the top, goes dark (`[ ]`). Contents by weight: 1 shard (70%) · 3-shard burst (20%) · a **free GLYPH draft** (10%, marquee `[!]` face so you can tell). Bumping a cache that has a NOISE standing on it kills the NOISE (Mario's koopa rule). |
| Brick | **PANEL** — a cracked relay panel | Bump from below with HEAVY or while dashing: it shatters (burst + saw). Otherwise it just hops. Hides shards, secret routes, or nothing (a lie — the crack pattern differs subtly: 3 cracks = something inside). |
| Hidden block | **GHOST CACHE** | Invisible until bumped; a faint 1px static flicker every ~3s is the only tell. Never required for progress. |
| Pipe | **CONDUIT** — signal ducting, a stubby vertical pipe with a lit collar | Stand on the mouth and hold DOWN 0.4s: the Spark is *sent* (drop in, 0.3s black with a descending square-wave, emerge from the linked conduit). Conduits link to **SUB-RELAYS**: small bonus rooms (shard beds, a cursed draft, a lore room) with an exit conduit that returns you *further along* the level (Mario's pipe-skip). Some conduits are one-way and just shortcuts. |
| Side pipe | **HORIZONTAL CONDUIT** | Walk into the mouth holding toward it. Used in the RUINS to tunnel under a spike corridor. |
| Flagpole | **THE MAST** — the gate's antenna | Every gate has a 60px mast. Touch it *higher* for a bigger bonus: base → +1 shard, mid → +3, tip → a free draft. Springs near the gate exist to tempt the tip. The mast slides you down with a rising chime as the gate lights. |
| Coin room | **SUB-RELAY** | A single-screen room reached by conduit: no NOISE, a shard bed in a shape (a glyph, a word), one way out. The RUINS control room is a sub-relay. |
| Star | *(no)* | Invulnerability is AEGIS/dash; we don't hand out free power. |

Rules: caches never gate progress (they're rewards for looking up); conduits
are always visible from the main path; sub-relays never contain hazards; a
GHOST CACHE is never in a spot you'd jump through by accident on the main
line (it must be *found*).

Where they appear: R0 gets two CACHES (one on the first block staircase,
under a sign: **BUMP FROM BELOW**) and one CONDUIT to a tiny sub-relay (teach
DOWN). R1's hub spokes are joined by conduits. R2 tunnels under the spike
corridor by horizontal conduit. R5's vent grate is a PANEL. Every gate has a
MAST from R1 on.

### Deck economy across the chain
- **Notch capacity grows with the chain**: 3 → 4 (R2) → 5 (R4) → 6 (R6).
  Cursed budget: 2 → 3 (R3) → 4 (R5).
- **Pool grows with mechanics** (protocol words are *found*): R0 pool of 10;
  DRIFT joins at R2 (walls), REPEAT at R2 (secret), PULSE at R3, HOLLOW at R3,
  STATIC at R5, ECHO at R6. New words are marquee-guaranteed at their debut.
- **Surge cadence**: 5 shards (R0–R2) → 6 (R3–R5) → 7 (R6–R7). Keeps ~4
  surges per relay as shard counts rise, ~28 per run.
- **Rewrite**: from R3, a full deck gets a fourth surge option: SWAP (drop one
  glyph, take one). Never a dead surge.
- **Run save**: at each lit relay: deck, deaths, time, heat. Resume = relay
  start with that deck.

### Difficulty curve (target deaths for a first clear)
R0 3 · R1 5 · R2 8 · R3 8 · R4 6 (falls) · R5 10 · R6 8 · R7 10 → ~60 deaths,
~30 min. Speedrun target under 12:00 with a RELAY/RAZOR build.

## 8. Art direction (1-bit ditherpunk, 4 grays)
Palette: `#0b0b0b #3a3a3a #8a8a8a #f2f2f2`. Canvas 480×270, pixel-snapped.
- BG layer stack (near→far), all with matching y-parallax:
  | Speed | Layer | Biome |
  |---|---|---|
  | 1.4x | deepest cables (hug the bottom edge) | all |
  | 1.15x | foreground cables | all |
  | 0.9x | wind dust streaks | Z0 |
  | 0.65x | waveform dunes w/ pale crest, rubble scatter | all / Z1 |
  | 0.6–0.7x | static rain / rising sparks | Z1 / Z2 |
  | 0.5x | far dunes (flatten in Z1/Z2), fallen pylons, ruin blocks, pillars + cables, cliff slabs | Z0 / Z0+Z1 / Z1 / Z2 |
  | 0.4x | collapsed dish | Z1 |
  | 0.35x | tall lattice pylons | Z2 |
  | 0.3x | broken relay halls (skyline) | Z1 |
  | 0.25x | antenna towers (fade out in Z1) | Z0, Z2 |
  | 0.2x | mesas / the GATE spire + signal arcs | Z0 / Z2 |
  | 0.1x | starfield | all |
  | 0.06x | the dead broadcast sun | Z0 |
  | 0.3x (sky) | signal-ghost waveform pulse (~7s) | all |
  | 0.2x (sky) | dithered horizon depth bands (Z1: lower, darker); gate glow gradient (Z2) | all |
- Platform materials (baked): **ground** (brick courses, wear, depth dither,
  tufts), **block** (relay panelling: seams, rivets, vents, status pips),
  **girder** (thin ledges: rails + braces; movers add scrolling chevrons),
  **secret** (near-black, faint lip).
- Text is a 3×5 pixel font, integer-scaled. Never anti-aliased.
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

## 13. Run structure & meta (v6)
- **The loop**: reach the GATE → SIGNAL RESTORED → the next run starts at
  **heat +1** (Boss-Cell style). Heat is visible on the menu as filled ◆ under
  the title; it never gates content, it modifies it.
- **Heat modifiers** (pick 1 of 3 at run start, from heat 1 onward; they stack
  as heat rises): *NOISE is faster*, *crumbles break in 0.3s*, *beacons don't
  mend AEGIS*, *shards decay after 20s*, *cursed budget +1 / normal −1*, *the
  first SURGE is a cursed-only draft*.
- **Echo ghost**: your best run replays as a gray spark with 30% alpha. Toggle
  on the pause screen. Beating it mid-run pings a chime.
- **Frequencies** (unlocks by *doing*, not by grinding): finish with a synergy
  pair → that pair becomes a selectable *starting frequency* (start the run
  with one half of the pair already held, notch cost paid). Frequencies are
  the only persistent progression, and they trade flexibility for a head start.
- **Records**: best time, fewest deaths, all-shards, per-heat. One line each on
  the win screen, nothing else.

## 15. Accessibility & options (Celeste assist rule: no shame, no lock-outs)
- Assist toggles (pause screen, off by default): game speed 70/85/100%,
  infinite dash, invulnerable to NOISE (spikes/pits still kill — execution
  beats protection), skip a screen after 10 deaths.
- Visual: scanlines off, vignette off, screen shake 0/50/100, flash reduction
  (surge flash → fade), high-contrast NOISE (outline pulses).
- Input: full rebinding, gamepad (left stick + A jump / X dash / Y respawn /
  Start pause), hold-to-slide toggle (hold vs. tap into wall).

## 12. Roadmap
- v3: theme BG, surge economy, in-canvas UI. ✅
- v4 (this pass): corner correction, beacon verb refill, cursed glyph row
  (HEAVY, GLASS), remix routes (high line + dash gate), best-time
  persistence. ✅
- v5 (Godot port polish): biome backdrops (§7b), baked tile materials, pixel
  font, live HUD chips, scanlines/vignette, shake + hitstop + full juice list,
  camera lead smoothing. ✅
- v6 (design, this doc): lore bible (§2b), genre lessons (§2c), NOISE
  bestiary (§5b), glyph synergies + new glyphs/curses (§6b), verb chaining +
  REPEATERS + beacon rest/overclock (§7c), heat/echo/frequencies (§13),
  accessibility (§15).
- v7 (this doc + code): campaign structure (§7d) — 8 relays with goal verbs;
  **multi-level framework** proposed here; implemented in v8 via
  LevelData.get_level, relay-clear screen, carried deck and boundary save.
- **Build order (recommended)**: 1) R1 THE LISTENING FIELD (hub + EARS +
  SKIP) → 2) synergy pairs + linked HUD chips → 3) R2 THE STAND (rain
  pressure + CLING) → 4) REPEATERS + verb chaining → 5) R4 THE WIRE (short,
  tests chaining) → 6) R3 tide biome → 7) R5 ARRAY → 8) R6 escape → 9) R7
  finale → 10) heat / echo ghost / assist / gamepad.
- Audio: per-biome ambience beds (wind hiss / rain crackle / spire hum as
  filtered noise), NOISE tells get a 1-note cue each.