# WHITE SIGNAL: game design document

Living document. Last updated 30 Sep 2026. This replaces `js-original/GDD.md`, which describes the earlier exploration and card-draft designs. That file is kept in git under the tag `legacy-archive`.

## 1. The game in one line

A small spark of signal wakes when a dead line starts ringing, and follows it, gate by gate, to find out who is still calling.

It is a classic Mario-style platformer: short levels, lives, a timer, shards to collect, a mast at the end of each level. Traps are in the Prince of Persia style (loose floors, falling ceilings, presses, plates and gates). Between worlds you return to a Hollow Knight style village whose people carry the story.

**Pillars**

- **P1 Dead simple, hard to master.** Run, jump, dash, stomp. Every level can be finished by anyone. The Pips and best times are for experts.
- **P2 One new idea at a time.** Each level introduces one thing on its own, safely, before it's combined with anything else.
- **P3 Every level is proven.** A checker plays each level with the game's own physics and proves it can be finished, and that every shard can be reached.
- **P4 Quiet, lonely, hopeful.** Four greys, a tint per world, 8-bit music. The Spark is the only pure white thing in the story.

## 2. Where we are

| Area | Status |
|---|---|
| Title screen | Built. Live scene, lit logo, its own music, menu sounds, wide-screen support |
| Story intro | Built. Ten cards, about a minute, its own music and art, skippable, replay from EXTRAS |
| Last Relay (hub village) | Built. Seven villagers, Tally's shop, the radio shack, the switchboard |
| World 1: The Flats | Built and proven. 4 levels, a bonus room and the training yard |
| World 2: The Switchyard | Built and proven. 4 levels, boss |
| World 3: The Aerials | Built and proven. 4 levels, a tall finale |
| World 4: Dead Air | Built and proven. 4 levels, ending with the Howl chasing you to the ring |
| The ending | Built. The ring closes, the ending cutscene and credits play, and Last Relay fills with visitors |
| Pips | Built. Tiny sparks trapped in glass in every level. Dot keeps them in Last Relay and gives gifts as they come home |
| The Howl and cutscenes | The Howl is the antagonist. Cutscenes C1 (the first Gate), C5 (into Dead Air) and C6 (the ending) are built. C2 to C4 are planned |

The earlier exploration mode and the Classic arcade run were removed from the project on 27 Sep 2026. Git keeps them under the tag `legacy-archive`.

## 3. Story

The full arc, World 4, the ending and the style guide for game text are in `docs/story/story-arc.md`.

**The world.** One line once ran across the whole land, relay to relay, gate to gate, and it carried everyone's voices. Then a howling noise came down the line. The crews cut the line apart, one station at a time, to stop it spreading. The noise stopped, and so did the voices. The years since are called the Quiet.

**The Howl.** The noise has a name: the crews called it the Howl, because it swallowed every voice it touched. It is a feedback loop of all those voices, scrambled together, and after the cut it pooled deep underground in Dead Air. When the first Gate lights, the Howl wakes and hears the Spark. It is the antagonist: dangerous, never evil, and in the end mended rather than destroyed.

**The Spark.** A tiny spark of living signal lies asleep at the end of a cut wire. One night the dead line rings three times. The Spark wakes and follows the wire to Last Relay, the last station that still hums. Gates only open for signal, so Old Mast sends it down the line to find out who is calling.

**The arc.** Wren tunes in the call on her radio, and it gets clearer after every world.

| World | What the call says | The turn |
|---|---|---|
| 1 The Flats | It's words, not static. Then a name starting S-P | The Quiet was a choice, made to keep people safe |
| 2 The Switchyard | SPARK, COME HOME | The call is for the Spark |
| 3 The Aerials | SPARK, COME HOME. WE KEPT YOUR PLACE | There are many callers, below in Dead Air, and the static is rising |
| 4 Dead Air | THE RING WON'T CLOSE WITHOUT YOU | The callers are the other Sparks, holding the Howl down in a ring with one empty place |
| Ending | Three rings, from the Sparks | The Spark closes the ring, the Howl comes apart into voices, the line lights up again, and home is everywhere the line goes |

**Theme.** Cutting yourself off can keep you safe, but it also keeps you alone.

**The cast** (all lines in `levels/story/npcs.json`)

| Who | Where you meet them | What they do |
|---|---|---|
| Old Mast | Last Relay, first thing | Finds the Spark and sets the goal. After World 1 he explains the Arc. After World 3 he warns about Dead Air, and before 4-4 he asks the Spark to come back up |
| Tally | Tally's shop in Last Relay | The trader. Counts everything and sells for shards |
| Wren | 1-2 | Works out that the call is words, then tunes it in world by world |
| Brace | 1-4 | Worked on the crews that cut the lines, and explains why |
| Dot | 2-3 | Explains channel switches, then runs the switchboard |
| Hum | 2-4 | Asks you to blow the relay's fuses so it can rest |
| Spire | 3-2 | A mast rigger who kept the masts standing alone. Says the callers are below, not above |

Full script: `docs/story/intro-script.md`. Shot list: `docs/story/intro-shots.md`.

## 4. How it plays

**Moves**

| Move | Control (keyboard / pad) | Notes |
|---|---|---|
| Run | Arrows or A/D / stick or D-pad | |
| Jump | Space, W or Up / A | Hold for height. Up to 3 tiles |
| Wall kick | Jump while against a wall | Locked away from the wall for 0.16 s, so a single wall can't be climbed |
| Dash | Shift / RB | Once per jump. Refills on the ground or at a lift ring |
| Stomp | Land on an enemy | Jump as you land, or just before or just after, for a high bounce. Each stomp in a chain goes higher |
| Drop down | Down + jump on a girder | Drops through thin girders |
| Talk, doors, pipes | Down | Next to someone, a door or a pipe |
| The Arc | X / X | Learned by clearing World 1. Knocks out any enemy in front, spiked walkers included, and breaks cracked walls |
| Pause | Esc / Start | |

Every key can be remapped in Settings.

**Rules**

| Area | Rule |
|---|---|
| Lives | Start with 5. Game over sends you back to Last Relay |
| Timer | 300 seconds a level. Run out and you lose a life |
| Shards | Collected everywhere. They are Tally's currency, so passing 100 no longer resets them. Every 100 collected also gives a free life, with a message on screen. A game over empties them |
| Pips | 3 in most levels (2 in 2-2, 2-3 and 2-4), plus one in the training yard and one in the bonus room: 47 in all. A Pip is a tiny spark of signal trapped in a glass insulator. It calls out when you are near, and touching the glass sets it free. Kept across new games |
| CHARGE | The one power-up. Survives one hit, and breaks bricks when you bump them |
| Blocks | Bump blocks give shards, CHARGE or a life. Hidden blocks give lives or 5 shards. Bumping a block knocks out an enemy standing on it |
| Checkpoint | One midway beacon per level |
| Goal | A mast. The higher you touch it, the bigger the bonus |
| Saving | Automatic at the start of every level, and on Save and Quit. New Game restarts the story but keeps the Pips, Dot's gifts and best times |

## 5. Structure

Title screen, then the intro (new games only), then **Last Relay**. From the village's signpost you set off to the first level you haven't cleared. Each world is 4 levels, and the fourth ends at a Gate or a boss. Clearing a world, or a game over, brings you back to Last Relay, where what people say has changed.

## 6. Biomes and levels

Each world has its own look (a colour tint over the four greys), its own weather, its own 8-bit music for every level, and new things to learn. The level files are in `levels/world<N>/`, and each has a proof map (`.png`) and proof results (`.proof.json`) next to it.

### Hub: Last Relay

A warm village, the last station on the line that still hums. **Look:** warm window light. **Music:** `village_theme`.

| Place | What's there |
|---|---|
| The street | Old Mast, the switchboard (pick any level you've reached), the signpost (next level), Spire after World 3 |
| Tally's | The shop: extra life 40, charged start 25, lantern 60 (see further in the dark) |
| Dot | Keeps the Pips beside the switchboard, where they gather as a crowd. Gifts, each given once: an extra life (5 Pips), the Pip tuner that points to the nearest trapped Pip (10), one more starting life (18), another (27), and a thank-you that sets up the ending (all 47) |
| The radio shack | Wren and the listeners you've met, and the call as it's pieced together |

No timer and no lives lost here. Design: `docs/levels/village.md`.

### World 1: The Flats

Flat farmland and old broadcast gear at first light. **Look:** cold blue. **Teaches:** the moves and the machinery. **Ends at:** the Gate, guarded by the warden. **Reward:** the Arc.

| Level | Name | New idea | Notes |
|---|---|---|---|
| 1-1 | First Light | Run, jump, bump, stomp, dash | Pipe to a bonus room with 21 shards |
| 1-2 | Loose Ground | Loose floors, loose ceilings, plates and gates | Meet Wren |
| 1-3 | The Presses | Presses, moving girders, spike vents, lift rings | Signal static in the air |
| 1-4 | The Gate | Droppers, timed gates, the warden (boss) | Dark stretches with lamps. Meet Brace |
| Training yard | | Every World 1 item, one station each | From the switchboard |

Design: `docs/levels/world-1.md`.

### World 2: The Switchyard

A dead relay yard where the line splits into two channels. **Look:** sodium amber. **Weather:** rain, lightning, dark buildings. **Teaches:** enemies with rules, and switching the world. **Ends at:** the relay, a boss you beat by blowing its three fuses.

| Level | Name | New idea | Notes |
|---|---|---|---|
| 2-1 | Rail Hoppers | Hoppers (jump on a beat), the Arc | Opens with the cracked-wall shed that teaches the Arc. Chain-stomp three hoppers for a Pip |
| 2-2 | Spiked Line | Spiked walkers | Can't be stomped: bump them from below, crush them, or Arc them from the side |
| 2-3 | Channels | Channel switches | Only one channel of blocks is solid at a time. Meet Dot |
| 2-4 | The Relay | The relay (boss) | It swaps the channels on a beat. Blow its fuses. Meet Hum |

Design: `docs/levels/world-2.md`.

### World 3: The Aerials

Broadcast masts high above the drowned city, at dawn. Wind carries the signal. **Look:** violet dawn. **Teaches:** things in the air. **Ends at:** the top of the Spire.

| Level | Name | New idea | Notes |
|---|---|---|---|
| 3-1 | Wave Flyers | Flyers that bob on a wave | Stomp across a gap on them |
| 3-2 | Carrier Wind | Side wind, updrafts, gusts | Wind blows 2 s in every 3. Meet Spire |
| 3-3 | Sweep Arms | Turning bars of static | Walk under when the bar has passed |
| 3-4 | The Spire | Everything, going up | Three screens tall. Falling drops you to the foot, never to your death |

Design: `docs/levels/world-3.md`.

### World 4: Dead Air

The deep exchange under the network, where every cut line ends, and where the Howl lives. **Look:** cold sea green, underground, one screen tall with a ceiling of cables. **Teaches:** reading threats that react to you. **Ends at:** the ring of Sparks.

| Level | Name | New idea | Notes |
|---|---|---|---|
| 4-1 | Relay Turrets | Turrets that fire bolts along their row | Brace waits at the start |
| 4-2 | Echoes in the Dark | Echoes that drift after you while you look away | Mostly dark, lit by lamps |
| 4-3 | The Rising Static | A wall of static rising up a shaft | Four screens tall |
| 4-4 | The Last Gate | Everything, with the Howl chasing you | Ends at the ring and the ending |

Design: `docs/levels/world-4.md`.

### Hidden things in every world

- **Cracked walls** (`%`). A shed or wall you can only open with the Arc, hiding shards. One in every World 2 and 3 level.
- **Hidden blocks.** Two in most World 1 and 2 levels (one in 2-1), giving 5 shards or a life. World 3 has none yet.
- **Pips.** Off the main route, often needing a skill move. A trapped Pip calls out when you're near, so players can hunt by ear.

## 7. Presentation

**Art.** 480x270 pixel canvas, 16 px tiles, four greys only. A shader tints the greys per world, and a light CRT filter sits on top. Characters have a dark outline so they read against any background. On wide screens the view widens up to 720x270 and shows more of the level. The HUD and menus stay in a centred 480 column. Sprite sheets are generated in code: `assets/world1/src/make_sheets.py`.

**Sound.** Everything is written as code for the NES's four sound voices (`tools/audio/sfx8.py`). Hopeful moments are in D major and losses fall to D minor. Every level has its own 8-bit track. The music fades for jingles and stops when you die. Guide: `assets/audio/sfx8/README.md`.

**Title and intro.** The title is a live night scene with the logo lighting up letter by letter. Research and spec: `docs/research/title-screen-2026-09-26.md`. The intro is ten story cards that end with the Spark waking next to Old Mast.

## 8. How levels are made and proven

Levels are text files, one character per tile (legend in `tools/levels/levelkit.py`). `python tools/levels/build_maps.py` plays each level with the game's own physics. It proves the level can be finished and that every shard, block and cracked wall can be reached, then draws the map. The game replays every proven route in `scripts/world1/w1_replay_test.gd`, so the checker and the game can't drift apart. Other tests cover the village, the Arc, the title and the intro.

## 9. Open decisions

- **Q1 What do big shards do?** Decided 29 Sep 2026: they became the Pips, kept by Dot (see above).
- **Q2 One caller or many?** Decided 30 Sep 2026: many. The callers are the Sparks of the line, holding the Howl down in a ring.
- **Q3 World 4.** Decided and built 30 Sep 2026 (see above).
- **Q4 The ending.** Decided and built 30 Sep 2026: the Spark closes the ring and the Howl comes apart into the voices it swallowed.
- **Q5 Pip counts.** 2-2, 2-3 and 2-4 have 2 Pips, not 3.
- **Q6 Name.** White Signal is kept for now. "The Signal" was considered and set aside because it's hard to find in searches.

## 10. Where things live

| What | Where |
|---|---|
| Levels | `levels/world1`, `world2`, `world3`, `village` |
| Story and dialogue | `levels/story/npcs.json`, `docs/story/` |
| Game rules | `scripts/world1/w1_sim.gd` (mirrored by `tools/levels/sim.py` and `physics.py`) |
| The game, drawing and menus | `scripts/world1/w1_game.gd` |
| Title and intro | `scripts/title/`, `scripts/intro/` |
| Art | `assets/world1/` |
| Sound and music | `assets/audio/sfx8/` |
| Level design notes | `docs/levels/` |
